/*
===============================================================================
Script: 02_load_bronze.sql
Purpose:
    Loads raw data from the Olist CSV source files into the Bronze layer.

Description:
    - Creates the `bronze.load_bronze()` stored procedure.
    - Performs full-load ingestion using PostgreSQL's `COPY` command.
    - Truncates Bronze tables before loading new data.
    - Populates the `dwh_load_timestamp` metadata column.
    - Logs loading progress, row counts, and execution time using `RAISE NOTICE`.

Usage:
    Execute the following command to load all Bronze tables: CALL bronze.load_bronze();

Phase:
    Phase 4 – Bronze Layer Implementation
===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $procedure$
DECLARE
    v_start_time         TIMESTAMP;
    v_start_loading_time TIMESTAMP;
    v_end_loading_time   TIMESTAMP;
    v_end_time           TIMESTAMP;
    v_row_count          INTEGER;
    v_ttl_rows           INTEGER := 0;
BEGIN
    v_start_loading_time := clock_timestamp();

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Bronze Layer';
    RAISE NOTICE '================================================';

    /*==============================================================================
      Customers
    ==============================================================================*/

    v_start_time := clock_timestamp();

    TRUNCATE TABLE bronze.olist_customers;

    COPY bronze.olist_customers (
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    )
    FROM '/Users/aatmane/postgres_import/olist/olist_customers_dataset.csv'
    DELIMITER ','
    CSV HEADER;

    SELECT COUNT(*)
    INTO v_row_count
    FROM bronze.olist_customers;

    v_end_time := clock_timestamp();
    v_ttl_rows := v_ttl_rows + v_row_count;

    RAISE NOTICE '> bronze.olist_customers loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;

    /*==============================================================================
      Geolocations
    ==============================================================================*/

    v_start_time := clock_timestamp();

    TRUNCATE TABLE bronze.olist_geolocations;

    COPY bronze.olist_geolocations (
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    )
    FROM '/Users/aatmane/postgres_import/olist/olist_geolocation_dataset.csv'
    DELIMITER ','
    CSV HEADER;

    SELECT COUNT(*)
    INTO v_row_count
    FROM bronze.olist_geolocations;

    v_end_time := clock_timestamp();
    v_ttl_rows := v_ttl_rows + v_row_count;

    RAISE NOTICE '> bronze.olist_geolocations loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;


    /*==============================================================================
      Order Items
    ==============================================================================*/

    v_start_time := clock_timestamp();

    TRUNCATE TABLE bronze.olist_order_items;

    COPY bronze.olist_order_items (
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
    )
    FROM '/Users/aatmane/postgres_import/olist/olist_order_items_dataset.csv'
    DELIMITER ','
    CSV HEADER;

    SELECT COUNT(*)
    INTO v_row_count
    FROM bronze.olist_order_items;

    v_end_time := clock_timestamp();
    v_ttl_rows := v_ttl_rows + v_row_count;

    RAISE NOTICE '> bronze.olist_order_items loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;


    /*==============================================================================
      Order Payments
    ==============================================================================*/

    v_start_time := clock_timestamp();

    TRUNCATE TABLE bronze.olist_order_payments;

    COPY bronze.olist_order_payments (
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value
    )
    FROM '/Users/aatmane/postgres_import/olist/olist_order_payments_dataset.csv'
    DELIMITER ','
    CSV HEADER;

    SELECT COUNT(*)
    INTO v_row_count
    FROM bronze.olist_order_payments;

    v_end_time := clock_timestamp();
    v_ttl_rows := v_ttl_rows + v_row_count;

    RAISE NOTICE '> bronze.olist_order_payments loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;


    /*==============================================================================
      Order Reviews
    ==============================================================================*/

    v_start_time := clock_timestamp();

    TRUNCATE TABLE bronze.olist_order_reviews;

    COPY bronze.olist_order_reviews (
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp
    )
    FROM '/Users/aatmane/postgres_import/olist/olist_order_reviews_dataset.csv'
    DELIMITER ','
    CSV HEADER;

    SELECT COUNT(*)
    INTO v_row_count
    FROM bronze.olist_order_reviews;

    v_end_time := clock_timestamp();
    v_ttl_rows := v_ttl_rows + v_row_count;

    RAISE NOTICE '> bronze.olist_order_reviews loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;


    /*==============================================================================
      Orders
    ==============================================================================*/

    v_start_time := clock_timestamp();

    TRUNCATE TABLE bronze.olist_orders;

    COPY bronze.olist_orders (
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date
    )
    FROM '/Users/aatmane/postgres_import/olist/olist_orders_dataset.csv'
    DELIMITER ','
    CSV HEADER;

    SELECT COUNT(*)
    INTO v_row_count
    FROM bronze.olist_orders;

    v_end_time := clock_timestamp();
    v_ttl_rows := v_ttl_rows + v_row_count;

    RAISE NOTICE '> bronze.olist_orders loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;


    /*==============================================================================
      Products
    ==============================================================================*/

    v_start_time := clock_timestamp();

    TRUNCATE TABLE bronze.olist_products;

    COPY bronze.olist_products (
        product_id,
        product_category_name,
        product_name_lenght,
        product_description_lenght,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    )
    FROM '/Users/aatmane/postgres_import/olist/olist_products_dataset.csv'
    DELIMITER ','
    CSV HEADER;

    SELECT COUNT(*)
    INTO v_row_count
    FROM bronze.olist_products;

    v_end_time := clock_timestamp();
    v_ttl_rows := v_ttl_rows + v_row_count;

    RAISE NOTICE '> bronze.olist_products loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;


    /*==============================================================================
      Sellers
    ==============================================================================*/

    v_start_time := clock_timestamp();

    TRUNCATE TABLE bronze.olist_sellers;

    COPY bronze.olist_sellers (
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    )
    FROM '/Users/aatmane/postgres_import/olist/olist_sellers_dataset.csv'
    DELIMITER ','
    CSV HEADER;

    SELECT COUNT(*)
    INTO v_row_count
    FROM bronze.olist_sellers;

    v_end_time := clock_timestamp();
    v_ttl_rows := v_ttl_rows + v_row_count;

    RAISE NOTICE '> bronze.olist_sellers loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;


    /*==============================================================================
      Product Category Translations
    ==============================================================================*/

    v_start_time := clock_timestamp();

    TRUNCATE TABLE bronze.olist_product_category_translations;

    COPY bronze.olist_product_category_translations (
        product_category_name,
        product_category_name_english
    )
    FROM '/Users/aatmane/postgres_import/olist/product_category_name_translation.csv'
    DELIMITER ','
    CSV HEADER;

    SELECT COUNT(*)
    INTO v_row_count
    FROM bronze.olist_product_category_translations;

    v_end_time := clock_timestamp();
    v_ttl_rows := v_ttl_rows + v_row_count;

    RAISE NOTICE '> bronze.olist_product_category_translations loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;

    v_end_loading_time := clock_timestamp();

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Bronze layer load complete';
    RAISE NOTICE 'Total rows loaded: %', v_ttl_rows;
    RAISE NOTICE 'Total duration: %', v_end_loading_time - v_start_loading_time;
    RAISE NOTICE '================================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Bronze layer load failed.';
        RAISE NOTICE 'Error: %', SQLERRM;
        RAISE;
END;
$procedure$;