/*
===============================================================================
Script: 01_ddl_bronze.sql
Purpose:
    Creates all Bronze layer tables for the Olist Data Warehouse.

Description:
    - Creates all physical tables in the Bronze schema.
    - Preserves the source system structure.
    - Uses source-aligned PostgreSQL data types.
    - Adds technical metadata columns.
    - No business transformations or constraints are applied.

Phase:
    Phase 4 – Bronze Layer Implementation
===============================================================================
*/

/*==============================================================================
  Customers
==============================================================================*/

CREATE TABLE IF NOT EXISTS bronze.olist_customers (
    customer_id                     TEXT,
    customer_unique_id              TEXT,
    customer_zip_code_prefix        INTEGER,
    customer_city                   TEXT,
    customer_state                  TEXT,
    dwh_load_timestamp              TIMESTAMP DEFAULT NOW()
);

/*==============================================================================
  Geolocations
==============================================================================*/

CREATE TABLE IF NOT EXISTS bronze.olist_geolocations (
    geolocation_zip_code_prefix     INTEGER,
    geolocation_lat                 NUMERIC,
    geolocation_lng                 NUMERIC,
    geolocation_city                TEXT,
    geolocation_state               TEXT,
    dwh_load_timestamp              TIMESTAMP DEFAULT NOW()
);

/*==============================================================================
  Order Items
==============================================================================*/

CREATE TABLE IF NOT EXISTS bronze.olist_order_items (
    order_id                        TEXT,
    order_item_id                   INTEGER,
    product_id                      TEXT,
    seller_id                       TEXT,
    shipping_limit_date             TIMESTAMP,
    price                           NUMERIC,
    freight_value                   NUMERIC,
    dwh_load_timestamp              TIMESTAMP DEFAULT NOW()
);

/*==============================================================================
  Order Payments
==============================================================================*/

CREATE TABLE IF NOT EXISTS bronze.olist_order_payments (
    order_id                        TEXT,
    payment_sequential              INTEGER,
    payment_type                    TEXT,
    payment_installments            INTEGER,
    payment_value                   NUMERIC,
    dwh_load_timestamp              TIMESTAMP DEFAULT NOW()
);

/*==============================================================================
  Order Reviews
==============================================================================*/

CREATE TABLE IF NOT EXISTS bronze.olist_order_reviews (
    review_id                       TEXT,
    order_id                        TEXT,
    review_score                    INTEGER,
    review_comment_title            TEXT,
    review_comment_message          TEXT,
    review_creation_date            TIMESTAMP,
    review_answer_timestamp         TIMESTAMP,
    dwh_load_timestamp              TIMESTAMP DEFAULT NOW()
);

/*==============================================================================
  Orders
==============================================================================*/

CREATE TABLE IF NOT EXISTS bronze.olist_orders (
    order_id                        TEXT,
    customer_id                     TEXT,
    order_status                    TEXT,
    order_purchase_timestamp        TIMESTAMP,
    order_approved_at               TIMESTAMP,
    order_delivered_carrier_date    TIMESTAMP,
    order_delivered_customer_date   TIMESTAMP,
    order_estimated_delivery_date   TIMESTAMP,
    dwh_load_timestamp              TIMESTAMP DEFAULT NOW()
);

/*==============================================================================
  Products
==============================================================================*/

CREATE TABLE IF NOT EXISTS bronze.olist_products (
    product_id                      TEXT,
    product_category_name           TEXT,
    product_name_lenght             INTEGER,
    product_description_lenght      INTEGER,
    product_photos_qty              INTEGER,
    product_weight_g                INTEGER,
    product_length_cm               INTEGER,
    product_height_cm               INTEGER,
    product_width_cm                INTEGER,
    dwh_load_timestamp              TIMESTAMP DEFAULT NOW()
);

/*==============================================================================
  Sellers
==============================================================================*/

CREATE TABLE IF NOT EXISTS bronze.olist_sellers (
    seller_id                       TEXT,
    seller_zip_code_prefix          INTEGER,
    seller_city                     TEXT,
    seller_state                    TEXT,
    dwh_load_timestamp              TIMESTAMP DEFAULT NOW()
);

/*==============================================================================
  Product Category Translations
==============================================================================*/

CREATE TABLE IF NOT EXISTS bronze.olist_product_category_translations (
    product_category_name           TEXT,
    product_category_name_english   TEXT,
    dwh_load_timestamp              TIMESTAMP DEFAULT NOW()
);