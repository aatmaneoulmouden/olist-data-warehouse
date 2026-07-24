/*
===============================================================================
Script: 02_create_facts.sql

Purpose:
    Creates the Gold layer fact views that support business reporting,
    analytics, and KPI calculations.

Description:
    - Creates the `gold.fact_sales` view.
    - Creates the `gold.fact_payments` view.
    - Creates the `gold.fact_reviews` view.
    - Resolves surrogate keys by joining fact records with the corresponding
      Gold dimensions.
    - Preserves the defined business grain for each fact view.
    - Exposes business-ready measures and descriptive attributes for
      analytical queries.

Phase:
    Phase 8 – Gold Layer Implementation
===============================================================================
*/