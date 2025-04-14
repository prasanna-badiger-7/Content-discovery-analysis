
-- SQL Script to Create Database Schema
-- Target Database: PostgreSQL

-- Drop existing tables in reverse order of dependency to avoid foreign key errors
-- This makes the script runnable multiple times.
DROP TABLE IF EXISTS user_search_queries;
DROP TABLE IF EXISTS user_interactions;
DROP TABLE IF EXISTS content_metadata;

--------------------------------------
-- Table: content_metadata
-- Stores details about each piece of non-live content.
--------------------------------------
CREATE TABLE content_metadata (
    content_id INT PRIMARY KEY,             -- Unique identifier for the content item
    title VARCHAR(255) NOT NULL,            -- Title of the content
    content_type VARCHAR(50) NOT NULL,     -- Type: Replay, Highlight, Documentary, Interview
    sport VARCHAR(50),                      -- Associated sport (e.g., Football, Boxing)
    duration_minutes INT,                   -- Duration of the content in minutes
    date_added DATE NOT NULL                -- Date the content was added to the platform
);

-- Add indexes for columns frequently used in filtering or joining
CREATE INDEX idx_content_metadata_type ON content_metadata(content_type);
CREATE INDEX idx_content_metadata_sport ON content_metadata(sport);
CREATE INDEX idx_content_metadata_date_added ON content_metadata(date_added);


--------------------------------------
-- Table: user_interactions
-- Logs user interactions with content items.
--------------------------------------
CREATE TABLE user_interactions (
    interaction_id BIGSERIAL PRIMARY KEY,   -- Auto-incrementing unique ID for the interaction log
    user_id INT NOT NULL,                   -- Identifier of the user performing the interaction
    content_id INT NOT NULL,                -- Identifier of the content interacted with
    interaction_timestamp TIMESTAMP NOT NULL, -- Precise timestamp of the interaction
    interaction_type VARCHAR(50) NOT NULL, -- Type of interaction (e.g., View, Add_To_Watchlist)
    source VARCHAR(50),                     -- Source of discovery (e.g., Homepage, Search, Recommendation)

    -- Define Foreign Key to link interactions to content metadata
    CONSTRAINT fk_content
        FOREIGN KEY(content_id)
        REFERENCES content_metadata(content_id)
        ON DELETE CASCADE -- If content is deleted, remove its associated interactions
);

-- Add indexes for faster querying
CREATE INDEX idx_interactions_user_id ON user_interactions(user_id);
CREATE INDEX idx_interactions_content_id ON user_interactions(content_id); -- Important for joins
CREATE INDEX idx_interactions_timestamp ON user_interactions(interaction_timestamp); -- For time-based analysis
CREATE INDEX idx_interactions_type ON user_interactions(interaction_type); -- For filtering by action
CREATE INDEX idx_interactions_source ON user_interactions(source); -- For filtering/grouping by discovery source


--------------------------------------
-- Table: user_search_queries
-- Logs user search queries performed on the platform.
--------------------------------------
CREATE TABLE user_search_queries (
    search_id BIGSERIAL PRIMARY KEY,        -- Auto-incrementing unique ID for the search log
    user_id INT NOT NULL,                   -- Identifier of the user performing the search
    search_timestamp TIMESTAMP NOT NULL,    -- Precise timestamp of the search
    search_term TEXT                        -- The actual text query entered by the user
                                            -- TEXT allows for potentially long search terms
);

-- Add indexes for faster querying
CREATE INDEX idx_search_user_id ON user_search_queries(user_id);
CREATE INDEX idx_search_timestamp ON user_search_queries(search_timestamp);
