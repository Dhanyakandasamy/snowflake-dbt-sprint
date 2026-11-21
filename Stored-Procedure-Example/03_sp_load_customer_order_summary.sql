-- =====================================================================
-- 03_sp_load_customer_order_summary.sql
--
-- Procedure : SP_LOAD_CUSTOMER_ORDER_SUMMARY
-- Purpose   : Incrementally load/refresh CUSTOMER_ORDER_SUMMARY from
--             TPC-H sample data (CUSTOMER, ORDERS).
-- Parameter : P_FROM_DATE - reprocess customers who placed any order
--             on or after this date.
-- Returns   : 'SUCCESS: <n> rows merged' or 'FAILED: <reason>'
--
-- Key features:
--   * Input validation
--   * Incremental + idempotent load using MERGE (safe to re-run)
--   * Segment ranking with DENSE_RANK() over the full table
--   * Transaction with COMMIT / ROLLBACK
--   * Audit logging of every run (success and failure)
-- =====================================================================

USE DATABASE PRACTICE_DB;
USE SCHEMA   ETL;

CREATE OR REPLACE PROCEDURE SP_LOAD_CUSTOMER_ORDER_SUMMARY(P_FROM_DATE DATE)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    v_start  TIMESTAMP DEFAULT CURRENT_TIMESTAMP();  -- run start time for the audit log
    v_rows   NUMBER    DEFAULT 0;                    -- rows inserted/updated by MERGE
    v_err    VARCHAR;                                -- error message if something fails
BEGIN
    -- -----------------------------------------------------------------
    -- 1. Validate input
    -- -----------------------------------------------------------------
    IF (P_FROM_DATE IS NULL OR P_FROM_DATE > CURRENT_DATE()) THEN
        RETURN 'FAILED: invalid P_FROM_DATE';
    END IF;

    BEGIN TRANSACTION;

    -- -----------------------------------------------------------------
    -- 2. Upsert affected customers (incremental + idempotent)
    --    Source = customers who ordered on/after P_FROM_DATE,
    --    with metrics recalculated over ALL their orders.
    -- -----------------------------------------------------------------
    MERGE INTO CUSTOMER_ORDER_SUMMARY tgt
    USING (
        SELECT
            C.C_CUSTKEY,
            C.C_NAME,
            C.C_MKTSEGMENT,
            COUNT(O.O_ORDERKEY)  AS ORDERS_COUNT,
            SUM(O.O_TOTALPRICE)  AS TOTAL_SPEND,
            MAX(O.O_ORDERDATE)   AS LAST_ORDER_DATE
        FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER C
        JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS   O
            ON O.O_CUSTKEY = C.C_CUSTKEY
        WHERE C.C_CUSTKEY IN (
            SELECT DISTINCT O_CUSTKEY
            FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
            WHERE O_ORDERDATE >= :P_FROM_DATE
        )
        GROUP BY C.C_CUSTKEY, C.C_NAME, C.C_MKTSEGMENT
    ) src
    ON tgt.C_CUSTKEY = src.C_CUSTKEY
    WHEN MATCHED THEN UPDATE SET
        ORDERS_COUNT    = src.ORDERS_COUNT,
        TOTAL_SPEND     = src.TOTAL_SPEND,
        LAST_ORDER_DATE = src.LAST_ORDER_DATE,
        UPDATED_AT      = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN INSERT
        (C_CUSTKEY, C_NAME, C_MKTSEGMENT, ORDERS_COUNT, TOTAL_SPEND,
         LAST_ORDER_DATE, UPDATED_AT)
    VALUES
        (src.C_CUSTKEY, src.C_NAME, src.C_MKTSEGMENT, src.ORDERS_COUNT,
         src.TOTAL_SPEND, src.LAST_ORDER_DATE, CURRENT_TIMESTAMP());

    v_rows := SQLROWCOUNT;

    -- -----------------------------------------------------------------
    -- 3. Recalculate segment ranks across the WHOLE summary table
    --    (ranking only the merged subset would give wrong ranks)
    -- -----------------------------------------------------------------
    UPDATE CUSTOMER_ORDER_SUMMARY tgt
    SET SEGMENT_RANK = r.RNK
    FROM (
        SELECT C_CUSTKEY,
               DENSE_RANK() OVER (PARTITION BY C_MKTSEGMENT
                                  ORDER BY TOTAL_SPEND DESC) AS RNK
        FROM CUSTOMER_ORDER_SUMMARY
    ) r
    WHERE tgt.C_CUSTKEY = r.C_CUSTKEY;

    -- -----------------------------------------------------------------
    -- 4. Log success and commit
    -- -----------------------------------------------------------------
    INSERT INTO ETL_AUDIT_LOG (PROC_NAME, START_TIME, END_TIME, STATUS, ROWS_AFFECTED)
    VALUES ('SP_LOAD_CUSTOMER_ORDER_SUMMARY', :v_start, CURRENT_TIMESTAMP(), 'SUCCESS', :v_rows);

    COMMIT;
    RETURN 'SUCCESS: ' || v_rows || ' rows merged';

-- ---------------------------------------------------------------------
-- 5. Error handling: undo partial work, log the failure
-- ---------------------------------------------------------------------
EXCEPTION
    WHEN OTHER THEN
        ROLLBACK;
        v_err := SQLERRM;
        INSERT INTO ETL_AUDIT_LOG (PROC_NAME, START_TIME, END_TIME, STATUS, ERROR_MESSAGE)
        VALUES ('SP_LOAD_CUSTOMER_ORDER_SUMMARY', :v_start, CURRENT_TIMESTAMP(), 'FAILED', :v_err);
        RETURN 'FAILED: ' || v_err;
END;
$$;
