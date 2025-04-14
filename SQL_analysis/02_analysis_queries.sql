
-- SQL Script for Analyzing Data
-- Target Database: PostgreSQL

-- Note: Assumes tables (content_metadata, user_interactions, user_search_queries)
-- have been created and populated with data.

-- =========================================
-- === 0. Data Exploration & Validation ===
-- =========================================

-- 0.1 View Sample Data from each table
SELECT * FROM content_metadata LIMIT 5;
SELECT * FROM user_interactions LIMIT 5;
SELECT * FROM user_search_queries LIMIT 5;

-- 0.2 Check Distinct Categorical Values
SELECT DISTINCT content_type FROM content_metadata ORDER BY content_type;
SELECT DISTINCT sport FROM content_metadata ORDER BY sport;
SELECT DISTINCT interaction_type FROM user_interactions ORDER BY interaction_type;
SELECT DISTINCT source FROM user_interactions ORDER BY source;

-- 0.3 Check Date/Timestamp Ranges
SELECT MIN(date_added) AS min_content_added_date, MAX(date_added) AS max_content_added_date FROM content_metadata;
SELECT MIN(interaction_timestamp) AS min_interaction_ts, MAX(interaction_timestamp) AS max_interaction_ts FROM user_interactions;
SELECT MIN(search_timestamp) AS min_search_ts, MAX(search_timestamp) AS max_search_ts FROM user_search_queries;


-- ==================================
-- === 1. Content Popularity Analysis ===
-- ==================================

-- 1.1 Popularity by Content Type (based on total interactions)
SELECT
    cm.content_type,
    COUNT(ui.interaction_id) AS total_interactions,
    COUNT(DISTINCT ui.user_id) AS unique_interacting_users,
    COUNT(DISTINCT ui.content_id) AS unique_content_items_interacted_with
FROM
    user_interactions ui
JOIN
    content_metadata cm ON ui.content_id = cm.content_id
GROUP BY
    cm.content_type
ORDER BY
    total_interactions DESC;

-- 1.2 Popularity by Sport (based on total interactions)
SELECT
    cm.sport,
    COUNT(ui.interaction_id) AS total_interactions,
    COUNT(DISTINCT ui.user_id) AS unique_interacting_users
FROM
    user_interactions ui
JOIN
    content_metadata cm ON ui.content_id = cm.content_id
WHERE
    cm.sport IS NOT NULL -- Exclude any potential NULL sports
GROUP BY
    cm.sport
ORDER BY
    total_interactions DESC;

-- 1.3 Most Interacted-With Individual Content Items (Top 20)
SELECT
    cm.content_id,
    cm.title,
    cm.content_type,
    cm.sport,
    COUNT(ui.interaction_id) AS total_interactions
FROM
    user_interactions ui
JOIN
    content_metadata cm ON ui.content_id = cm.content_id
GROUP BY
    cm.content_id, cm.title, cm.content_type, cm.sport
ORDER BY
    total_interactions DESC
LIMIT 20;


-- =========================================
-- === 2. Discovery Source Effectiveness ===
-- =========================================

-- 2.1 Overall interaction count by source (Percentage of Total)
SELECT
    source,
    COUNT(interaction_id) AS total_interactions,
    ROUND(COUNT(interaction_id) * 100.0 / SUM(COUNT(interaction_id)) OVER (), 2) AS percentage_of_total
FROM
    user_interactions
WHERE
    source IS NOT NULL AND source <> 'Unknown' -- Focus on known sources
GROUP BY
    source
ORDER BY
    total_interactions DESC;

-- 2.2 Source effectiveness for driving Views/Playback Starts
WITH ViewInteractions AS (
    SELECT source, COUNT(interaction_id) as view_count
    FROM user_interactions
    WHERE interaction_type IN ('View', 'Playback_Start') -- Combine View and Playback_Start as "views"
      AND source IS NOT NULL AND source <> 'Unknown'
    GROUP BY source
), TotalViews AS (
    SELECT SUM(view_count) as total_view_count FROM ViewInteractions
)
SELECT
    vi.source,
    vi.view_count,
    CASE
        WHEN tv.total_view_count > 0 THEN ROUND(vi.view_count * 100.0 / tv.total_view_count, 2)
        ELSE 0.00
    END AS percentage_of_total_views
FROM
    ViewInteractions vi, TotalViews tv
ORDER BY
    percentage_of_total_views DESC;


-- =======================================
-- === 3. Interaction Pathway Analysis ===
-- =======================================

-- 3.1 Distribution of interaction types immediately following discovery from a source
SELECT
    source,
    interaction_type,
    COUNT(interaction_id) AS interaction_count,
    ROUND(COUNT(interaction_id) * 100.0 / SUM(COUNT(interaction_id)) OVER (PARTITION BY source), 2) AS percentage_within_source
FROM
    user_interactions
WHERE
    source IS NOT NULL AND source <> 'Unknown'
GROUP BY
    source, interaction_type
ORDER BY
    source, interaction_count DESC;

-- 3.2 How Content Types are Discovered (Focus on Views/Playback)
SELECT
    cm.content_type,
    ui.source,
    COUNT(ui.interaction_id) AS view_interactions
FROM
    user_interactions ui
JOIN
    content_metadata cm ON ui.content_id = cm.content_id
WHERE
    ui.interaction_type IN ('View', 'Playback_Start')
    AND ui.source IS NOT NULL AND ui.source <> 'Unknown'
GROUP BY
    cm.content_type, ui.source
ORDER BY
    cm.content_type, view_interactions DESC;


-- =============================
-- === 4. Search Query Analysis ===
-- =============================

-- 4.1 Most frequent search terms (Top 50)
SELECT
    LOWER(search_term) AS normalized_search_term, -- Normalize to lowercase
    COUNT(*) AS search_frequency
FROM
    user_search_queries
GROUP BY
    LOWER(search_term)
ORDER BY
    search_frequency DESC
LIMIT 50;

-- 4.2 Basic Search Term Categorization
SELECT
    CASE
        WHEN LOWER(search_term) LIKE '%highlight%' THEN 'Contains Highlight'
        WHEN LOWER(search_term) LIKE '%replay%' THEN 'Contains Replay'
        WHEN LOWER(search_term) LIKE '%full match%' THEN 'Contains Replay' -- Group with replay
        WHEN LOWER(search_term) LIKE '%documentary%' THEN 'Contains Documentary'
        WHEN LOWER(search_term) LIKE '%interview%' THEN 'Contains Interview'
        WHEN LOWER(search_term) LIKE '%football%' OR LOWER(search_term) LIKE '%soccer%' THEN 'Contains Sport: Football'
        WHEN LOWER(search_term) LIKE '%boxing%' THEN 'Contains Sport: Boxing'
        WHEN LOWER(search_term) LIKE '%f1%' OR LOWER(search_term) LIKE '%formula 1%' THEN 'Contains Sport: F1'
        WHEN LOWER(search_term) LIKE '%nfl%' THEN 'Contains Sport: NFL'
        -- Add more sport/league checks here if needed based on your data
        ELSE 'Other/Entity Search'
    END AS search_term_category,
    COUNT(*) AS search_frequency
FROM
    user_search_queries
GROUP BY
    search_term_category
ORDER BY
    search_frequency DESC;
