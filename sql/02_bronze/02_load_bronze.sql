/*
===============================================================================
Script: 02_load_bronze.sql
Purpose:
    Loads source CSV files into the Bronze tables.

Description:
    - Creates the load_bronze() stored procedure.
    - Performs full-load ingestion using PostgreSQL COPY.
    - Records load metadata.

Phase:
    Phase 4 – Bronze Layer Implementation
===============================================================================
*/