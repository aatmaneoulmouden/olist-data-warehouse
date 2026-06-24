/*
===============================================================================
Purpose:
    Create the Medallion Architecture schemas used by the Olist Data Warehouse.

    Bronze Layer:
        Stores raw data ingested from source systems with minimal transformation.

    Silver Layer:
        Stores cleansed, standardized, and validated data.

    Gold Layer:
        Stores business-ready data models, analytical views, and reporting assets.
===============================================================================
*/

CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;