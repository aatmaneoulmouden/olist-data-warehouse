/*
===============================================================================
Script: 01_create_dimensions.sql

Purpose:
    Creates the Gold layer dimension views used for business reporting and
    analytical workloads.

Description:
    - Creates the `gold.dim_customers` view.
    - Creates the `gold.dim_products` view.
    - Creates the `gold.dim_sellers` view.
    - Creates the `gold.dim_dates` view.
    - Generates surrogate keys for each dimension.
    - Exposes business-ready dimension attributes using cleansed and
      standardized data from the Silver layer.

Phase:
    Phase 8 – Gold Layer Implementation
===============================================================================
*/