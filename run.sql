\set ON_ERROR_STOP on
-- First clean up any previous data and objects
\i 'cleanup.sql'
-- Create the database schema
\i 'schema.sql'
-- Include the data generator script
\i 'data_generator.sql'
-- Generate data
DO $$
DECLARE
    result text;
BEGIN
    SELECT
        generate_data() INTO result;
    -- Check if generation was successful
    IF result LIKE 'Data generation completed successfully!%' THEN
        RAISE NOTICE '%', result;
    ELSE
        RAISE EXCEPTION E'%', result;
    END IF;
END
$$;

-- Create indexes for query optimization
\i 'indexes.sql'
SELECT
    'Indexes created successfully!' AS message;

-- Run and analyze queries without indexes
SET enable_indexscan = OFF;

SET enable_bitmapscan = OFF;

\echo 'Running queries without using indexes...'
\i 'queries.sql'
-- Run and analyze queries with indexes
\echo 'Running queries with indexes enabled...'
SET enable_indexscan = ON;

SET enable_bitmapscan = ON;

\i 'queries.sql'
-- Apply table partitioning for better performance
\echo 'Applying table partitioning...'
\i 'table_partitioning.sql'
SELECT
    'Table partitioning applied successfully!' AS message;

-- Showcase partition management functions
\echo 'Demonstrating partition management functions:'
-- Create a new partition for 2026-01
\echo 'Creating a new partition for January 2026...'
SELECT
    create_transportation_partition(2026, 1);

-- Create a new partition for 2026-02
\echo 'Creating a new partition for February 2026...'
SELECT
    create_transportation_partition(2026, 2);

-- List all partitions
\echo 'Listing all partitions of item_transportation table:'
SELECT
    nmsp_child.nspname AS schema_name,
    child.relname AS partition_name
FROM
    pg_inherits
    JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
    JOIN pg_class child ON pg_inherits.inhrelid = child.oid
    JOIN pg_namespace nmsp_parent ON nmsp_parent.oid = parent.relnamespace
    JOIN pg_namespace nmsp_child ON nmsp_child.oid = child.relnamespace
WHERE
    parent.relname = 'item_transportation'
    AND nmsp_parent.nspname = 'public'
ORDER BY
    child.relname;

-- Demonstrate dropping old partitions
\echo 'Demonstrating dropping partitions older than 6 months...'
-- Since we don't have actual old partitions, this won't drop anything
-- but it will demonstrate the function call
SELECT
    drop_old_transportation_partition(6);

-- Show database statistics
\echo 'Database statistics:'
SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid)) AS table_size,
    pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS index_size
FROM
    pg_catalog.pg_statio_user_tables
ORDER BY
    pg_total_relation_size(relid) DESC;

-- Show specific partition information
\echo 'Partition sizes:'
SELECT
    child.relname AS partition_name,
    pg_size_pretty(pg_relation_size(child.oid)) AS partition_size,
    pg_size_pretty(pg_indexes_size(child.oid)) AS index_size
FROM
    pg_inherits
    JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
    JOIN pg_class child ON pg_inherits.inhrelid = child.oid
    JOIN pg_namespace nmsp_parent ON nmsp_parent.oid = parent.relnamespace
    JOIN pg_namespace nmsp_child ON nmsp_child.oid = child.relnamespace
WHERE
    parent.relname = 'item_transportation'
    AND nmsp_parent.nspname = 'public'
ORDER BY
    child.relname;

