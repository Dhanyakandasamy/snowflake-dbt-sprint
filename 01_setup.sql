-- =====================================================================
-- 01_setup.sql
-- Creates a working database and schema for this project.
-- SNOWFLAKE_SAMPLE_DATA is a read-only shared database, so all project
-- objects (tables, procedures, tasks) must live in our own database.
-- =====================================================================

USE ROLE SYSADMIN;   -- or any role that can create databases

CREATE DATABASE IF NOT EXISTS PRACTICE_DB;
CREATE SCHEMA   IF NOT EXISTS PRACTICE_DB.ETL;

USE DATABASE PRACTICE_DB;
USE SCHEMA   ETL;

-- Check which warehouse you have (needed for queries and the task)
SHOW WAREHOUSES;
