-- =====================================================================
-- 06_cleanup.sql  (optional)
-- Removes everything this project created.
-- =====================================================================

USE DATABASE PRACTICE_DB;
USE SCHEMA   ETL;

ALTER TASK IF EXISTS TASK_DAILY_CUSTOMER_SUMMARY SUSPEND;
DROP TASK      IF EXISTS TASK_DAILY_CUSTOMER_SUMMARY;
DROP PROCEDURE IF EXISTS SP_LOAD_CUSTOMER_ORDER_SUMMARY(DATE);
DROP TABLE     IF EXISTS CUSTOMER_ORDER_SUMMARY;
DROP TABLE     IF EXISTS ETL_AUDIT_LOG;

-- Uncomment to drop the whole database
-- DROP DATABASE IF EXISTS PRACTICE_DB;
