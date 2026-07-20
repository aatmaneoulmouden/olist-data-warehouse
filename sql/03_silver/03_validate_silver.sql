/*
===============================================================================
Script: 03_validate_silver.sql

Purpose:
    Validates the Silver layer after data has been cleansed and loaded from
    the Bronze layer.

Description:
    - Verifies row counts for all Silver tables.
    - Confirms that transformation metadata is populated.
    - Identifies duplicate business keys.
    - Detects NULL values in required business columns.
    - Validates data cleansing, standardization, and business rules.
    - Performs read-only validation without modifying the Silver layer data.

Phase:
    Phase 5 – Silver Layer Implementation
===============================================================================
*/