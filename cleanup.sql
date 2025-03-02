-- Cleanup script to remove all objects created for the UPS analytics database
-- Disable notices for dropped objects
SET client_min_messages = warning;

-- Drop functions first
DROP FUNCTION IF EXISTS create_transportation_partition(int, int) CASCADE;

DROP FUNCTION IF EXISTS drop_old_transportation_partition(int) CASCADE;

DROP FUNCTION IF EXISTS generate_data() CASCADE;

-- Drop tables with CASCADE to remove dependencies
DROP TABLE IF EXISTS item_transportation CASCADE;

DROP TABLE IF EXISTS shipped_item CASCADE;

DROP TABLE IF EXISTS transport_event CASCADE;

DROP TABLE IF EXISTS retail_center CASCADE;

-- Drop any partition tables that might not be automatically dropped
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Find all tables that start with item_transportation_
    FOR r IN
    SELECT
        tablename
    FROM
        pg_tables
    WHERE
        tablename LIKE 'item_transportation_%'
        AND schemaname = 'public' LOOP
            EXECUTE 'DROP TABLE IF EXISTS public.' || quote_ident(r.tablename) || ' CASCADE';
        END LOOP;
END
$$;

-- Remove any backup tables
DROP TABLE IF EXISTS item_transportation_backup CASCADE;

-- Reset any altered parameters
RESET client_min_messages;

-- Output success message
DO $$
BEGIN
    RAISE NOTICE 'Database cleanup completed successfully!';
END
$$;

