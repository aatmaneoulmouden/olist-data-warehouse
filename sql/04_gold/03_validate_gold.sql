/*
===============================================================================
Script: 03_validate_gold.sql

Purpose:
    Validates the Gold layer to ensure analytical correctness and data
    consistency.

Description:
    - Verifies row counts for all Gold views.
    - Validates fact-to-dimension relationships.
    - Identifies missing dimension lookups.
    - Verifies the accuracy of business measures.
    - Validates KPI calculations against the Silver layer.
    - Performs read-only validation without modifying any data.

Phase:
    Phase 8 – Gold Layer Implementation
===============================================================================
*/