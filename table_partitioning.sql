-- First, backup existing data
CREATE TABLE item_transportation_backup AS
SELECT
    *
FROM
    item_transportation;

-- Drop the original table
DROP TABLE item_transportation CASCADE;

-- Create a partitioned table with id column
CREATE TABLE item_transportation(
    id serial NOT NULL,
    transportation_event_seq_number integer NOT NULL,
    comment character varying(255) NOT NULL,
    shipped_item_item_num integer NOT NULL,
    created_at date NOT NULL DEFAULT CURRENT_DATE
)
PARTITION BY RANGE (created_at);

-- Create partitions by month (example for a year)
CREATE TABLE item_transportation_y2025m01 PARTITION OF item_transportation
FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE item_transportation_y2025m02 PARTITION OF item_transportation
FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

CREATE TABLE item_transportation_y2025m03 PARTITION OF item_transportation
FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

CREATE TABLE item_transportation_y2025m04 PARTITION OF item_transportation
FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');

CREATE TABLE item_transportation_y2025m05 PARTITION OF item_transportation
FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');

CREATE TABLE item_transportation_y2025m06 PARTITION OF item_transportation
FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');

CREATE TABLE item_transportation_y2025m07 PARTITION OF item_transportation
FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');

CREATE TABLE item_transportation_y2025m08 PARTITION OF item_transportation
FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');

CREATE TABLE item_transportation_y2025m09 PARTITION OF item_transportation
FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');

CREATE TABLE item_transportation_y2025m10 PARTITION OF item_transportation
FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

CREATE TABLE item_transportation_y2025m11 PARTITION OF item_transportation
FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

CREATE TABLE item_transportation_y2025m12 PARTITION OF item_transportation
FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- Create default partition for future data
CREATE TABLE item_transportation_default PARTITION OF item_transportation DEFAULT;

-- Add primary key constraint on id and created_at (partitioning column)
ALTER TABLE item_transportation
    ADD PRIMARY KEY (id, created_at);

-- Add foreign key constraints
ALTER TABLE item_transportation
    ADD CONSTRAINT "Shipped_item_item_num" FOREIGN KEY (shipped_item_item_num) REFERENCES public.shipped_item(item_num);

ALTER TABLE item_transportation
    ADD CONSTRAINT "Transportation_event_seq_number" FOREIGN KEY (transportation_event_seq_number) REFERENCES public.transport_event(seq_number);

-- Create an index on the combination for better query performance
CREATE INDEX idx_item_transportation_combined ON item_transportation(transportation_event_seq_number, shipped_item_item_num);

-- Recreate indexes on the partitioned table
CREATE INDEX idx_item_transportation_comment_trgm ON item_transportation USING gin(comment gin_trgm_ops);

CREATE INDEX idx_item_transportation_comment_ts ON item_transportation USING gin(to_tsvector('english', comment));

-- Insert data from backup table, preserving the id
INSERT INTO item_transportation(id, transportation_event_seq_number, comment, shipped_item_item_num, created_at)
SELECT
    id,
    transportation_event_seq_number,
    comment,
    shipped_item_item_num,
    CURRENT_DATE -(RANDOM() * 180)::integer -- Distribute over last ~6 months randomly
FROM
    item_transportation_backup;

-- Create function to easily add new partitions
CREATE OR REPLACE FUNCTION create_transportation_partition(year int, month int)
    RETURNS VOID
    AS $$
DECLARE
    partition_name text;
    start_date date;
    end_date date;
BEGIN
    -- Format the partition name
    partition_name := 'item_transportation_y' || year::text || 'm' || LPAD(month::text, 2, '0');
    -- Calculate start and end dates
    start_date := make_date(year, month, 1);
    -- For the end date, add 1 month to start_date
    IF month = 12 THEN
        end_date := make_date(year + 1, 1, 1);
    ELSE
        end_date := make_date(year, month + 1, 1);
    END IF;
    -- Create the partition
    EXECUTE format('CREATE TABLE %I PARTITION OF item_transportation 
                    FOR VALUES FROM (%L) TO (%L);', partition_name, start_date, end_date);
    RAISE NOTICE 'Created partition: % for date range: % to %', partition_name, start_date, end_date;
END;
$$
LANGUAGE plpgsql;

-- Function to drop old partitions
CREATE OR REPLACE FUNCTION drop_old_transportation_partition(months_old int)
    RETURNS VOID
    AS $$
DECLARE
    partition_name text;
    partition_date date;
    cutoff_date date;
    partition_record RECORD;
BEGIN
    -- Calculate cutoff date
    cutoff_date := CURRENT_DATE -(months_old * interval '1 month');
    FOR partition_record IN
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
        AND nmsp_parent.nspname = 'public' LOOP
            -- Extract date from partition name if possible
            BEGIN
                -- Assuming pattern like item_transportation_y2025m01
                IF partition_record.partition_name ~ '^item_transportation_y[0-9]{4}m[0-9]{2}$' THEN
                    partition_name := partition_record.partition_name;
                    -- Extract year and month from partition name
                    DECLARE year_str TEXT := substring(partition_name FROM 'y([0-9]{4})m');
                    month_str TEXT := substring(partition_name FROM 'm([0-9]{2})$');
                    year_int INT;
                    month_int INT;
                    BEGIN
                        year_int := year_str::int;
                        month_int := month_str::int;
                        -- Create date from year and month
                        partition_date := make_date(year_int, month_int, 1);
                        -- Check if partition is older than cutoff date
                        IF partition_date < cutoff_date THEN
                            EXECUTE format('DROP TABLE %I', partition_name);
                            RAISE NOTICE 'Dropped old partition: % (date: %)', partition_name, partition_date;
                        END IF;
                    END;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE NOTICE 'Error processing partition %: %', partition_record.partition_name, SQLERRM;
            END;
    END LOOP;
END;

$$
LANGUAGE plpgsql;

