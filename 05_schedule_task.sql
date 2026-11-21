-- =====================================================================
-- 05_schedule_task.sql  (optional)
-- Schedule the procedure to run daily at 2 AM IST using a Snowflake Task.
--
-- Notes:
--   * Replace COMPUTE_WH with your warehouse name (SHOW WAREHOUSES;).
--   * Your role needs the EXECUTE TASK privilege.
--   * TPC-H data ends in 1998, so a real "last 3 days" run will merge
--     0 rows here. In a live project the source data keeps growing.
--   * A running task uses warehouse credits: suspend it when done.
-- =====================================================================

USE DATABASE PRACTICE_DB;
USE SCHEMA   ETL;

CREATE OR REPLACE TASK TASK_DAILY_CUSTOMER_SUMMARY
    WAREHOUSE = COMPUTE_WH
    SCHEDULE  = 'USING CRON 0 2 * * * Asia/Kolkata'
AS
    CALL SP_LOAD_CUSTOMER_ORDER_SUMMARY(DATEADD(day, -3, CURRENT_DATE()));

-- Tasks are created suspended; resume to start the schedule
ALTER TASK TASK_DAILY_CUSTOMER_SUMMARY RESUME;

-- Run once immediately (for testing)
EXECUTE TASK TASK_DAILY_CUSTOMER_SUMMARY;

-- Check task run history
SELECT *
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(TASK_NAME => 'TASK_DAILY_CUSTOMER_SUMMARY'))
ORDER BY SCHEDULED_TIME DESC;

-- Stop the schedule when you are done practicing
ALTER TASK TASK_DAILY_CUSTOMER_SUMMARY SUSPEND;
