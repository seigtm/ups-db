-- Indexes for shipped_item table
CREATE INDEX idx_shipped_item_retail_center_id ON shipped_item(retail_center_id);

CREATE INDEX idx_shipped_item_final_delivery_date ON shipped_item(final_delivery_date);

CREATE INDEX idx_shipped_item_destination ON shipped_item(destination);

CREATE INDEX idx_shipped_item_weight ON shipped_item(weight);

-- Indexes for item_transportation table
CREATE INDEX idx_item_transportation_shipped_item_item_num ON item_transportation(shipped_item_item_num);

CREATE INDEX idx_item_transportation_transportation_event_seq_number ON item_transportation(transportation_event_seq_number);

-- Full-text search index for comments
-- First create a GIN index on the comment field
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_item_transportation_comment_trgm ON item_transportation USING gin(comment gin_trgm_ops);

-- Create a functional index for faster full-text search
CREATE INDEX idx_item_transportation_comment_ts ON item_transportation USING gin(to_tsvector('english', comment));

