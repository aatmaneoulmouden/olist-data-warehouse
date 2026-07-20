/*
===============================================================================
Script: 02_load_silver.sql

Purpose:
    Loads cleansed and standardized data from the Bronze layer into the Silver layer.

Description:
    - Creates the `silver.load_silver()` stored procedure.
    - Performs a full refresh of all Silver tables.
    - Truncates Silver tables before loading transformed data.
    - Cleanses, validates, and standardizes data during the load process.
    - Populates the `dwh_create_date` metadata column.
    - Logs loading progress, row counts, and execution time using `RAISE NOTICE`.

Usage:
    Execute the following command to load all Silver tables:
    CALL silver.load_silver();

Phase:
    Phase 5 – Silver Layer Implementation
===============================================================================
*/