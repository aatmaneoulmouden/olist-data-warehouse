/*
===============================================================================
Script: 02_load_silver.sql

Purpose:
    Loads cleansed and standardized data from the Bronze layer into the Silver
    layer.

Description:
    - Creates the `silver.load_silver()` stored procedure.
    - Performs a full refresh of all Silver tables.
    - Truncates Silver tables before loading transformed data.
    - Cleanses, validates, standardizes, and deduplicates source data.
    - Supplements lookup tables with missing source-referenced values.
    - Populates `dwh_create_date` through each table's default value.
    - Logs loading progress, row counts, and execution time using `RAISE NOTICE`.

Usage:
    Execute the following command to load all Silver tables:

    CALL silver.load_silver();

Phase:
    Phase 5 – Silver Layer Implementation
===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $procedure$
DECLARE
    v_start_time         TIMESTAMP;
    v_start_loading_time TIMESTAMP;
    v_end_time           TIMESTAMP;
    v_end_loading_time   TIMESTAMP;
    v_row_count          INTEGER;
    v_total_rows         INTEGER := 0;
BEGIN
    v_start_loading_time := clock_timestamp();

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer';
    RAISE NOTICE '================================================';

    /*
    Truncate all Silver tables together so PostgreSQL can safely handle foreign
    key relationships without using CASCADE.
    */
    TRUNCATE TABLE
        silver.olist_order_reviews,
        silver.olist_order_payments,
        silver.olist_order_items,
        silver.olist_orders,
        silver.olist_products,
        silver.olist_sellers,
        silver.olist_customers,
        silver.olist_product_category_translations,
        silver.olist_geolocations;

/*==============================================================================
  Geolocations
==============================================================================*/

    v_start_time := clock_timestamp();

    -- Load one standardized location per ZIP code from the geolocation source.
    WITH cleaned_geolocations AS (
        SELECT
            LPAD(TRIM(geolocation_zip_code_prefix::TEXT), 5, '0')   AS geolocation_zip_code_prefix,
            INITCAP(TRIM(geolocation_city))                         AS geolocation_city,
            UPPER(TRIM(geolocation_state))                          AS geolocation_state
        FROM bronze.olist_geolocations
        WHERE geolocation_zip_code_prefix IS NOT NULL
    ),
    ranked_geolocations AS (
        SELECT
            geolocation_zip_code_prefix,
            geolocation_city,
            geolocation_state,
            ROW_NUMBER() OVER (
                PARTITION BY geolocation_zip_code_prefix
                ORDER BY
                    geolocation_city,
                    geolocation_state
            ) AS row_num
        FROM cleaned_geolocations
    )
    INSERT INTO silver.olist_geolocations (
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state
    )
    SELECT
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state
    FROM ranked_geolocations
    WHERE row_num = 1;

    /*
    Add ZIP codes referenced by customers but missing from the geolocation
    source. City and state are taken directly from the customer source.
    */
    WITH cleaned_customers AS (
        SELECT
            LPAD(TRIM(customer_zip_code_prefix::TEXT), 5, '0')      AS customer_zip_code_prefix,
            INITCAP(TRIM(customer_city))                            AS customer_city,
            UPPER(TRIM(customer_state))                             AS customer_state
        FROM bronze.olist_customers
        WHERE customer_zip_code_prefix IS NOT NULL
    ),
    missing_customer_locations AS (
        SELECT
            customer_zip_code_prefix,
            customer_city,
            customer_state,
            ROW_NUMBER() OVER (
                PARTITION BY customer_zip_code_prefix
                ORDER BY
                    customer_city,
                    customer_state
            ) AS row_num
        FROM cleaned_customers AS c
        WHERE NOT EXISTS (
            SELECT 1
            FROM silver.olist_geolocations AS og
            WHERE og.geolocation_zip_code_prefix =
                  c.customer_zip_code_prefix
        )
    )
    INSERT INTO silver.olist_geolocations (
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state
    )
    SELECT
        customer_zip_code_prefix,
        customer_city,
        customer_state
    FROM missing_customer_locations
    WHERE row_num = 1;

    /*
    Add ZIP codes referenced by sellers but still missing after customer ZIP
    codes have been loaded.
    */
    WITH cleaned_sellers AS (
        SELECT
            LPAD(TRIM(seller_zip_code_prefix::TEXT), 5, '0')        AS seller_zip_code_prefix,
            INITCAP(TRIM(seller_city))                              AS seller_city,
            UPPER(TRIM(seller_state))                               AS seller_state
        FROM bronze.olist_sellers
        WHERE seller_zip_code_prefix IS NOT NULL
    ),
    missing_seller_locations AS (
        SELECT
            seller_zip_code_prefix,
            seller_city,
            seller_state,
            ROW_NUMBER() OVER (
                PARTITION BY seller_zip_code_prefix
                ORDER BY
                    seller_city,
                    seller_state
            ) AS row_num
        FROM cleaned_sellers AS s
        WHERE NOT EXISTS (
            SELECT 1
            FROM silver.olist_geolocations AS og
            WHERE og.geolocation_zip_code_prefix =
                  s.seller_zip_code_prefix
        )
    )
    INSERT INTO silver.olist_geolocations (
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state
    )
    SELECT
        seller_zip_code_prefix,
        seller_city,
        seller_state
    FROM missing_seller_locations
    WHERE row_num = 1;

    SELECT COUNT(*)
    INTO v_row_count
    FROM silver.olist_geolocations;

    v_end_time := clock_timestamp();
    v_total_rows := v_total_rows + v_row_count;

    RAISE NOTICE '> silver.olist_geolocations loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;

/*==============================================================================
  Product Category Translations
==============================================================================*/

    v_start_time := clock_timestamp();

    -- Load and standardize all available category translations.
    INSERT INTO silver.olist_product_category_translations (
        product_category_name,
        product_category_name_english
    )
    SELECT
        LOWER(TRIM(product_category_name)),
        LOWER(TRIM(product_category_name_english))
    FROM bronze.olist_product_category_translations;

    /*
    Add categories referenced by products but absent from the translation
    source. The placeholder indicates that no English translation is available.
    */
    WITH cleaned_product_categories AS (
        SELECT DISTINCT
            LOWER(TRIM(product_category_name))                      AS product_category_name
        FROM bronze.olist_products
        WHERE product_category_name IS NOT NULL
    )
    INSERT INTO silver.olist_product_category_translations (
        product_category_name,
        product_category_name_english
    )
    SELECT
        c.product_category_name,
        'not_available'
    FROM cleaned_product_categories AS c
    WHERE NOT EXISTS (
        SELECT 1
        FROM silver.olist_product_category_translations AS t
        WHERE t.product_category_name = c.product_category_name
    );

    SELECT COUNT(*)
    INTO v_row_count
    FROM silver.olist_product_category_translations;

    v_end_time := clock_timestamp();
    v_total_rows := v_total_rows + v_row_count;

    RAISE NOTICE '> silver.olist_product_category_translations loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;

/*==============================================================================
  Customers
==============================================================================*/

    v_start_time := clock_timestamp();

    WITH cleaned_customers AS (
        SELECT
            TRIM(customer_id)                                       AS customer_id,
            TRIM(customer_unique_id)                                AS customer_unique_id,
            LPAD(TRIM(customer_zip_code_prefix::TEXT), 5, '0')      AS customer_zip_code_prefix,
            INITCAP(TRIM(customer_city))                            AS customer_city,
            UPPER(TRIM(customer_state))                             AS customer_state
        FROM bronze.olist_customers
    )
    INSERT INTO silver.olist_customers (
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    )
    SELECT
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    FROM cleaned_customers;

    SELECT COUNT(*)
    INTO v_row_count
    FROM silver.olist_customers;

    v_end_time := clock_timestamp();
    v_total_rows := v_total_rows + v_row_count;

    RAISE NOTICE '> silver.olist_customers loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;

/*==============================================================================
  Sellers
==============================================================================*/

    v_start_time := clock_timestamp();

    WITH cleaned_sellers AS (
        SELECT
            TRIM(seller_id)                                         AS seller_id,
            LPAD(TRIM(seller_zip_code_prefix::TEXT), 5, '0')        AS seller_zip_code_prefix,
            INITCAP(TRIM(seller_city))                              AS seller_city,
            UPPER(TRIM(seller_state))                               AS seller_state
        FROM bronze.olist_sellers
    )
    INSERT INTO silver.olist_sellers (
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    )
    SELECT
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    FROM cleaned_sellers;

    SELECT COUNT(*)
    INTO v_row_count
    FROM silver.olist_sellers;

    v_end_time := clock_timestamp();
    v_total_rows := v_total_rows + v_row_count;

    RAISE NOTICE '> silver.olist_sellers loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;

/*==============================================================================
  Products
==============================================================================*/

    v_start_time := clock_timestamp();

    WITH cleaned_products AS (
        SELECT
            TRIM(product_id)                                        AS product_id,
            LOWER(TRIM(product_category_name))                      AS product_category_name,
            COALESCE(product_name_lenght, 0)                        AS product_name_length,
            COALESCE(product_description_lenght, 0)                 AS product_description_length,
            COALESCE(product_photos_qty, 0)                         AS product_photos_qty,
            product_weight_g::NUMERIC(10, 2)                        AS product_weight_g,
            product_length_cm::NUMERIC(10, 2)                       AS product_length_cm,
            product_height_cm::NUMERIC(10, 2)                       AS product_height_cm,
            product_width_cm::NUMERIC(10, 2)                        AS product_width_cm
        FROM bronze.olist_products
    )
    INSERT INTO silver.olist_products (
        product_id,
        product_category_name,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    )
    SELECT
        product_id,
        product_category_name,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    FROM cleaned_products;

    SELECT COUNT(*)
    INTO v_row_count
    FROM silver.olist_products;

    v_end_time := clock_timestamp();
    v_total_rows := v_total_rows + v_row_count;

    RAISE NOTICE '> silver.olist_products loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;

/*==============================================================================
  Orders
==============================================================================*/

    v_start_time := clock_timestamp();

    WITH cleaned_orders AS (
        SELECT
            TRIM(order_id)                                          AS order_id,
            TRIM(customer_id)                                       AS customer_id,
            LOWER(TRIM(order_status))                               AS order_status,
            order_purchase_timestamp,
            order_approved_at,
            order_delivered_carrier_date,
            order_delivered_customer_date,
            order_estimated_delivery_date
        FROM bronze.olist_orders
    )
    INSERT INTO silver.olist_orders (
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date
    )
    SELECT
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date
    FROM cleaned_orders;

    SELECT COUNT(*)
    INTO v_row_count
    FROM silver.olist_orders;

    v_end_time := clock_timestamp();
    v_total_rows := v_total_rows + v_row_count;

    RAISE NOTICE '> silver.olist_orders loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;

/*==============================================================================
  Order Items
==============================================================================*/

    v_start_time := clock_timestamp();

    WITH cleaned_order_items AS (
        SELECT
            TRIM(order_id)                                          AS order_id,
            order_item_id,
            TRIM(product_id)                                        AS product_id,
            TRIM(seller_id)                                         AS seller_id,
            shipping_limit_date,
            price::NUMERIC(10, 2)                                   AS price,
            freight_value::NUMERIC(10, 2)                           AS freight_value
        FROM bronze.olist_order_items
    )
    INSERT INTO silver.olist_order_items (
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
    )
    SELECT
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
    FROM cleaned_order_items;

    SELECT COUNT(*)
    INTO v_row_count
    FROM silver.olist_order_items;

    v_end_time := clock_timestamp();
    v_total_rows := v_total_rows + v_row_count;

    RAISE NOTICE '> silver.olist_order_items loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;

/*==============================================================================
  Order Payments
==============================================================================*/

    v_start_time := clock_timestamp();

    WITH cleaned_order_payments AS (
        SELECT
            TRIM(order_id)                                          AS order_id,
            payment_sequential,
            LOWER(TRIM(payment_type))                               AS payment_type,
            payment_installments,
            payment_value::NUMERIC(10, 2)                           AS payment_value
        FROM bronze.olist_order_payments
    )
    INSERT INTO silver.olist_order_payments (
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value
    )
    SELECT
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value
    FROM cleaned_order_payments;

    SELECT COUNT(*)
    INTO v_row_count
    FROM silver.olist_order_payments;

    v_end_time := clock_timestamp();
    v_total_rows := v_total_rows + v_row_count;

    RAISE NOTICE '> silver.olist_order_payments loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;

/*==============================================================================
  Order Reviews
==============================================================================*/

    v_start_time := clock_timestamp();

    /*
    Retain one row per review ID. The earliest review creation timestamp is
    retained; answer timestamp and order ID provide deterministic tie-breakers.
    */
    WITH cleaned_reviews AS (
        SELECT
            TRIM(review_id)                                         AS review_id,
            TRIM(order_id)                                          AS order_id,
            review_score,
            TRIM(review_comment_title)                              AS review_comment_title,
            TRIM(review_comment_message)                            AS review_comment_message,
            review_creation_date::DATE                              AS review_creation_date,
            review_answer_timestamp
        FROM bronze.olist_order_reviews
    ),
    ranked_reviews AS (
        SELECT
            review_id,
            order_id,
            review_score,
            review_comment_title,
            review_comment_message,
            review_creation_date,
            review_answer_timestamp,
            ROW_NUMBER() OVER (
                PARTITION BY review_id
                ORDER BY
                    review_creation_date,
                    review_answer_timestamp,
                    order_id
            ) AS row_num
        FROM cleaned_reviews
    )
    INSERT INTO silver.olist_order_reviews (
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp
    )
    SELECT
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp
    FROM ranked_reviews
    WHERE row_num = 1;

    SELECT COUNT(*)
    INTO v_row_count
    FROM silver.olist_order_reviews;

    v_end_time := clock_timestamp();
    v_total_rows := v_total_rows + v_row_count;

    RAISE NOTICE '> silver.olist_order_reviews loaded successfully with % rows', v_row_count;
    RAISE NOTICE '> Duration: %', v_end_time - v_start_time;

    v_end_loading_time := clock_timestamp();

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Silver layer load complete';
    RAISE NOTICE 'Total rows loaded: %', v_total_rows;
    RAISE NOTICE 'Total duration: %', v_end_loading_time - v_start_loading_time;
    RAISE NOTICE '================================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Silver layer load failed.';
        RAISE NOTICE 'Error: %', SQLERRM;
        RAISE;
END;
$procedure$;