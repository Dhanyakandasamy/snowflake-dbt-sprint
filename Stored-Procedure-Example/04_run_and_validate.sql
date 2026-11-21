-- =====================================================================
-- 04_run_and_validate.sql
-- Run the procedure and verify the results.
-- Note: TPC-H order dates range from 1992-01-01 to 1998-08-02.
-- =====================================================================

USE DATABASE PRACTICE_DB;
USE SCHEMA   ETL;

-- 1. Full initial load (all customers with orders, ~100K rows)
CALL SP_LOAD_CUSTOMER_ORDER_SUMMARY('1992-01-01');

-- 2. Incremental load (only customers who ordered since this date)
CALL SP_LOAD_CUSTOMER_ORDER_SUMMARY('1998-07-01');

-- 3. Re-run the same incremental load: table data should not change
CALL SP_LOAD_CUSTOMER_ORDER_SUMMARY('1998-07-01');

-- 4. Invalid input test: should return 'FAILED: invalid P_FROM_DATE'
CALL SP_LOAD_CUSTOMER_ORDER_SUMMARY(NULL);

-- ---------------------------------------------------------------------
-- Validation queries
-- ---------------------------------------------------------------------

-- Top 5 customers by spend in each market segment
SELECT *
FROM CUSTOMER_ORDER_SUMMARY
WHERE SEGMENT_RANK <= 5
ORDER BY C_MKTSEGMENT, SEGMENT_RANK;

-- Row count and duplicates check (both counts should match)
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT C_CUSTKEY) AS distinct_customers
FROM CUSTOMER_ORDER_SUMMARY;

-- Reconcile with source: total orders should match
SELECT
    (SELECT SUM(ORDERS_COUNT) FROM CUSTOMER_ORDER_SUMMARY)            AS summary_orders,
    (SELECT COUNT(*) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS)      AS source_orders;

-- Audit log: latest runs first
SELECT * FROM ETL_AUDIT_LOG ORDER BY RUN_ID DESC;
