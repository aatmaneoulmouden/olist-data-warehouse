/*
===============================================================================
Script: 01_ddl_silver.sql

Purpose:
    Creates all Silver layer tables for the Olist Data Warehouse.

Description:
    - Creates all physical tables in the Silver schema.
    - Defines the cleansed and standardized data structure.
    - Uses optimized PostgreSQL data types for analytics.
    - Includes technical metadata columns.
    - Stores transformed, validated, and business-ready data loaded from
      the Bronze layer.

Phase:
    Phase 6 – Silver Layer Implementation
===============================================================================
*/

/*==============================================================================
  Geolocations
==============================================================================*/

CREATE TABLE IF NOT EXISTS silver.olist_geolocations (
    geolocation_zip_code_prefix     VARCHAR(5) PRIMARY KEY,
    geolocation_city                VARCHAR(100) NOT NULL,
    geolocation_state               VARCHAR(2) NOT NULL,
    dwh_load_timestamp              TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_geolocation_zip_code_prefix
        CHECK (geolocation_zip_code_prefix ~ '^[0-9]{5}$'),

    CONSTRAINT chk_geolocation_state
        CHECK (geolocation_state ~ '^[A-Z]{2}$')
);

/*==============================================================================
  Product Category Translations
==============================================================================*/

CREATE TABLE IF NOT EXISTS silver.olist_product_category_translations (
    product_category_name           VARCHAR(100) PRIMARY KEY,
    product_category_name_english   VARCHAR(100) NOT NULL,
    dwh_load_timestamp              TIMESTAMP NOT NULL DEFAULT NOW()
);

/*==============================================================================
  Customers
==============================================================================*/

CREATE TABLE IF NOT EXISTS silver.olist_customers (
    customer_id                     VARCHAR(32) PRIMARY KEY,
    customer_unique_id              VARCHAR(32) NOT NULL,
    customer_zip_code_prefix        VARCHAR(5) NOT NULL,
    customer_city                   VARCHAR(100) NOT NULL,
    customer_state                  VARCHAR(2) NOT NULL,
    dwh_load_timestamp              TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_customers_geolocations
        FOREIGN KEY (customer_zip_code_prefix)
        REFERENCES silver.olist_geolocations (geolocation_zip_code_prefix),

    CONSTRAINT chk_customer_zip_code_prefix
        CHECK (customer_zip_code_prefix ~ '^[0-9]{5}$'),

    CONSTRAINT chk_customer_state
        CHECK (customer_state ~ '^[A-Z]{2}$')
);

/*==============================================================================
  Sellers
==============================================================================*/

CREATE TABLE IF NOT EXISTS silver.olist_sellers (
    seller_id                       VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix          VARCHAR(5) NOT NULL,
    seller_city                     VARCHAR(100) NOT NULL,
    seller_state                    VARCHAR(2) NOT NULL,
    dwh_load_timestamp              TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_sellers_geolocations
        FOREIGN KEY (seller_zip_code_prefix)
        REFERENCES silver.olist_geolocations (geolocation_zip_code_prefix),

    CONSTRAINT chk_seller_zip_code_prefix
        CHECK (seller_zip_code_prefix ~ '^[0-9]{5}$'),

    CONSTRAINT chk_seller_state
        CHECK (seller_state ~ '^[A-Z]{2}$')
);

/*==============================================================================
  Products
==============================================================================*/

CREATE TABLE IF NOT EXISTS silver.olist_products (
    product_id                      VARCHAR(32) PRIMARY KEY,
    product_category_name           VARCHAR(100),
    product_name_length             INTEGER NOT NULL,
    product_description_length      INTEGER NOT NULL,
    product_photos_qty              INTEGER NOT NULL,
    product_weight_g                NUMERIC(10, 2),
    product_length_cm               NUMERIC(10, 2),
    product_height_cm               NUMERIC(10, 2),
    product_width_cm                NUMERIC(10, 2),
    dwh_load_timestamp              TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_products_product_category_translations
        FOREIGN KEY (product_category_name)
        REFERENCES silver.olist_product_category_translations (product_category_name),

    CONSTRAINT chk_product_name_length
        CHECK (product_name_length >= 0),
        
    CONSTRAINT chk_product_description_length
        CHECK (product_description_length >= 0),

    CONSTRAINT chk_product_photos_qty
        CHECK (product_photos_qty >= 0),

    CONSTRAINT chk_product_weight_g
        CHECK (product_weight_g IS NULL OR product_weight_g >= 0),

    CONSTRAINT chk_product_length_cm
        CHECK (product_length_cm IS NULL OR product_length_cm >= 0),

    CONSTRAINT chk_product_height_cm
        CHECK (product_height_cm IS NULL OR product_height_cm >= 0),

    CONSTRAINT chk_product_width_cm
        CHECK (product_width_cm IS NULL OR product_width_cm >= 0)
);

/*==============================================================================
  Orders
==============================================================================*/

CREATE TABLE IF NOT EXISTS silver.olist_orders (
    order_id                        VARCHAR(32) PRIMARY KEY,
    customer_id                     VARCHAR(32) NOT NULL,
    order_status                    VARCHAR(12) NOT NULL,
    order_purchase_timestamp        TIMESTAMP NOT NULL,
    order_approved_at               TIMESTAMP,
    order_delivered_carrier_date    TIMESTAMP,
    order_delivered_customer_date   TIMESTAMP,
    order_estimated_delivery_date   TIMESTAMP,
    dwh_load_timestamp              TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_orders_customers
        FOREIGN KEY (customer_id)
        REFERENCES silver.olist_customers (customer_id),

    CONSTRAINT chk_order_status
        CHECK (order_status IN ('approved', 'canceled', 'created', 'delivered', 'invoiced', 'processing', 'shipped', 'unavailable'))
);

/*==============================================================================
  Order Items
==============================================================================*/

CREATE TABLE IF NOT EXISTS silver.olist_order_items (
    order_id                        VARCHAR(32) NOT NULL,
    order_item_id                   INTEGER NOT NULL,
    product_id                      VARCHAR(32) NOT NULL,
    seller_id                       VARCHAR(32) NOT NULL,
    shipping_limit_date             TIMESTAMP NOT NULL,
    price                           NUMERIC(10, 2) NOT NULL,
    freight_value                   NUMERIC(10, 2) NOT NULL,
    dwh_load_timestamp              TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_order_items
        PRIMARY KEY (order_id, order_item_id),

    CONSTRAINT fk_order_items_orders
        FOREIGN KEY (order_id)
        REFERENCES silver.olist_orders (order_id),
        
    CONSTRAINT fk_order_items_products
        FOREIGN KEY (product_id)
        REFERENCES silver.olist_products (product_id),

    CONSTRAINT fk_order_items_sellers
        FOREIGN KEY (seller_id)
        REFERENCES silver.olist_sellers (seller_id),

    CONSTRAINT chk_order_item_id
        CHECK (order_item_id > 0),

    CONSTRAINT chk_price
        CHECK (price >= 0),

    CONSTRAINT chk_freight_value
        CHECK (freight_value >= 0)
);

/*==============================================================================
  Order Payments
==============================================================================*/

CREATE TABLE IF NOT EXISTS silver.olist_order_payments (
    order_id                        VARCHAR(32) NOT NULL,
    payment_sequential              INTEGER NOT NULL,
    payment_type                    VARCHAR(12) NOT NULL,
    payment_installments            INTEGER NOT NULL,
    payment_value                   NUMERIC(10, 2) NOT NULL,
    dwh_load_timestamp              TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_order_payments
        PRIMARY KEY (order_id, payment_sequential),

    CONSTRAINT fk_order_payments_orders
        FOREIGN KEY (order_id)
        REFERENCES silver.olist_orders (order_id),

    CONSTRAINT chk_payment_type
        CHECK (payment_type IN ('boleto', 'credit_card', 'debit_card', 'not_defined', 'voucher')),

    CONSTRAINT chk_payment_sequential
        CHECK (payment_sequential > 0),

    CONSTRAINT chk_payment_installments
        CHECK (payment_installments >= 0),

    CONSTRAINT chk_payment_value
        CHECK (payment_value >= 0)
);

/*==============================================================================
  Order Reviews
==============================================================================*/

CREATE TABLE IF NOT EXISTS silver.olist_order_reviews (
    review_id                       VARCHAR(32) PRIMARY KEY,
    order_id                        VARCHAR(32) NOT NULL,
    review_score                    INTEGER NOT NULL,
    review_comment_title            TEXT,
    review_comment_message          TEXT,
    review_creation_date            TIMESTAMP,
    review_answer_timestamp         TIMESTAMP,
    dwh_load_timestamp              TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_order_reviews_orders
        FOREIGN KEY (order_id)
        REFERENCES silver.olist_orders (order_id),
    
    CONSTRAINT chk_review_score
        CHECK (review_score BETWEEN 1 AND 5)
);