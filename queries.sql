-- Query 1: Query to a single table with filtering (shipped_item)
-- Without using indexes (use SET enable_indexscan = off; to disable index usage)
EXPLAIN (
    ANALYZE,
    VERBOSE,
    COSTS,
    TIMING,
    FORMAT TEXT
)
SELECT
    *
FROM
    shipped_item
WHERE
    weight > 50
    AND dimension < 20
    AND destination = 'Dallas'
    AND final_delivery_date BETWEEN '2025-03-30' AND '2025-04-20';

-- Query 2: Query to multiple related tables with filtering
-- Without using indexes
EXPLAIN (
    ANALYZE,
    VERBOSE,
    COSTS,
    TIMING,
    FORMAT TEXT
)
SELECT
    s.item_num,
    s.destination,
    s.final_delivery_date,
    r.type AS retail_center_type,
    r.address,
    t.type AS transport_type,
    t.delivery_rout,
    it.comment
FROM
    shipped_item s
    JOIN retail_center r ON s.retail_center_id = r.id
    JOIN item_transportation it ON s.item_num = it.shipped_item_item_num
    JOIN transport_event t ON it.transportation_event_seq_number = t.seq_number
WHERE
    s.weight > 40
    AND s.final_delivery_date > '2025-05-01'
    AND r.type = 'Distribution Center'
    AND t.type = 'Express';

-- Query 3: Full-text search query
-- Without using indexes
EXPLAIN (
    ANALYZE,
    VERBOSE,
    COSTS,
    TIMING,
    FORMAT TEXT
)
SELECT
    it.transportation_event_seq_number,
    it.shipped_item_item_num,
    it.comment,
    s.destination,
    s.final_delivery_date
FROM
    item_transportation it
    JOIN shipped_item s ON it.shipped_item_item_num = s.item_num
WHERE
    it.comment LIKE '%delayed%address%'
    AND s.final_delivery_date > '2025-05-01';

-- Using to_tsvector and to_tsquery for full-text search
EXPLAIN (
    ANALYZE,
    VERBOSE,
    COSTS,
    TIMING,
    FORMAT TEXT
)
SELECT
    it.transportation_event_seq_number,
    it.shipped_item_item_num,
    it.comment,
    s.destination,
    s.final_delivery_date
FROM
    item_transportation it
    JOIN shipped_item s ON it.shipped_item_item_num = s.item_num
WHERE
    to_tsvector('english', it.comment) @@ to_tsquery('english', 'delayed & address')
    AND s.final_delivery_date > '2025-05-01';

