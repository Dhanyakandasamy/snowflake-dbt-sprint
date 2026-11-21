-- =====================================================================
-- 02_create_tables.sql
-- Target summary table (read by dashboards) and ETL audit log table.
-- =====================================================================

USE DATABASE PRACTICE_DB;
USE SCHEMA   ETL;

-- One row per customer with their order metrics
CREATE TABLE IF NOT EXISTS CUSTOMER_ORDER_SUMMARY (
    C_CUSTKEY        NUMBER PRIMARY KEY,   -- business key (informational in Snowflake)
    C_NAME           VARCHAR,
    C_MKTSEGMENT     VARCHAR,
    ORDERS_COUNT     NUMBER,
    TOTAL_SPEND      NUMBER(18,2),
    LAST_ORDER_DATE  DATE,
    SEGMENT_RANK     NUMBER,               -- rank by spend within market segment
    UPDATED_AT       TIMESTAMP
);

-- One row per procedure run: success or failure
CREATE TABLE IF NOT EXISTS ETL_AUDIT_LOG (
    RUN_ID         NUMBER AUTOINCREMENT,
    PROC_NAME      VARCHAR,
    START_TIME     TIMESTAMP,
    END_TIME       TIMESTAMP,
    STATUS         VARCHAR,                -- SUCCESS / FAILED
    ROWS_AFFECTED  NUMBER,
    ERROR_MESSAGE  VARCHAR
);
