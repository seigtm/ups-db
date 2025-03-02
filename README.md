# PostgreSQL Analytical Database Design Project

This project implements an analytical database for a UPS delivery system with features for optimized query performance, full-text search capabilities, and table partitioning.

## Project Structure

- `schema.sql` - Creates tables without constraints for faster data loading
- `data_generator.sql` - Generates test data using `plpython3u` with optimized batch processing
- `indexes.sql` - Creates strategic indexes for query optimization
- `queries.sql` - Contains sample analytical queries with execution plans
- `table_partitioning.sql` - Implements date-based table partitioning
- `run.sql` - Main script that executes all components in sequence
- `cleanup.sql` - Removes all database objects for clean restarts
- `details.md` - Technical documentation of implementation decisions
- `TODO.md` - Original assignment and requirements

## Prerequisites

- `PostgreSQL` 16 or higher
- `plpython3u` extension enabled

### Installing `plpython3u` Extension

To install the `plpython3u` extension on Ubuntu:

```bash
# Determine your PostgreSQL version
psql --version

# Install the appropriate package
sudo apt update
sudo apt install postgresql-plpython3-16  # adjust version number as needed

# Restart PostgreSQL
sudo systemctl restart postgresql
```

## Setup Instructions

1. Clone this repository
2. Create a database for the project:

```bash
psql -U postgres -c "CREATE DATABASE ups_analytics;"
```

3. Run the main script:

```bash
psql -U postgres -d ups_analytics -f ./run.sql
```

## Key Features

### Optimized Data Generation

This project uses several techniques to generate millions of records efficiently:

- **Batch Processing**: Records are inserted in configurable batch sizes (10,000-50,000)
- **Deferred Constraints**: Foreign keys and other constraints are added after data generation
- **Progress Reporting**: Real-time feedback on generation progress and insertion rates
- **Realistic Data**: Transportation comments are generated with varied vocabulary for testing full-text search

### Optimized Query Performance

The project demonstrates several PostgreSQL optimization techniques:

- **Strategic B-Tree Indexes**: Created on columns commonly used in WHERE clauses and joins
- **GIN Indexes**: For efficient full-text search operations
- **Query Analysis**: EXPLAIN ANALYZE output to compare optimized vs. non-optimized queries
- **Index Toggling**: Queries are run with and without indexes to demonstrate performance impact

### Table Partitioning

The `item_transportation` table (10+ million rows) is partitioned by date:

- **Range Partitioning**: Monthly partitions based on the `created_at` column
- **Utility Functions**: Helper functions provided to create new partitions and drop old ones:
  - `create_transportation_partition(year, month)` - Creates a new partition
  - `drop_old_transportation_partition(months_old)` - Drops partitions older than specified months
- **Partition Management Demo**: `run.sql` includes a demonstration of these functions in action

### Full-Text Search

The project provides a comprehensive implementation of PostgreSQL's text search:

- **Functional GIN Index**: On `to_tsvector('english', comment)` for optimized search
- **Trigram Index**: Using the `pg_trgm` extension for `LIKE`/`ILIKE` queries
- **Performance Comparison**: Queries demonstrate both approaches, allowing performance comparison

## Database Volumes

When run with default settings, the script generates:

- 10 retail centers
- 10 transport events
- 1,000,000 shipped items
- 10,000,000 item transportation records

For testing purposes, you can adjust these volumes in `data_generator.sql`.
