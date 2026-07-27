/*
===============================================================================
Script: 01_create_dimensions.sql

Purpose:
    Creates the Gold layer dimension views used for business reporting and
    analytical workloads.

Description:
    - Creates the `gold.dim_dates` view.
    - Creates the `gold.dim_customers` view.
    - Creates the `gold.dim_products` view.
    - Creates the `gold.dim_sellers` view.
    - Generates surrogate keys for each dimension.
    - Exposes business-ready dimension attributes using cleansed and
      standardized data from the Silver layer.

Phase:
    Phase 8 – Gold Layer Implementation
===============================================================================
*/

/*==============================================================================
  dim_dates
==============================================================================*/

CREATE OR REPLACE VIEW gold.dim_dates AS
WITH date_boundaries AS
(
    SELECT
        MIN(business_date) AS min_date,
        MAX(business_date) AS max_date
    FROM
    (
        SELECT order_purchase_timestamp::date AS business_date
        FROM silver.olist_orders
        UNION ALL
        SELECT order_approved_at::date
        FROM silver.olist_orders
        UNION ALL
        SELECT shipping_limit_date::date
        FROM silver.olist_order_items
        UNION ALL
        SELECT order_delivered_carrier_date::date
        FROM silver.olist_orders
        UNION ALL
        SELECT order_delivered_customer_date::date
        FROM silver.olist_orders
        UNION ALL
        SELECT order_estimated_delivery_date::date
        FROM silver.olist_orders
        UNION ALL
        SELECT review_creation_date::date
        FROM silver.olist_order_reviews
    ) AS dates
    WHERE business_date IS NOT NULL
),
calendar AS
(
    SELECT
        GENERATE_SERIES(
            min_date,
            max_date,
            INTERVAL '1 day'
        )::date AS full_date
    FROM date_boundaries
)
SELECT
    TO_CHAR(full_date, 'YYYYMMDD')::integer   AS date_key,
    full_date,
    EXTRACT(YEAR FROM full_date)::smallint    AS year,
    EXTRACT(QUARTER FROM full_date)::smallint AS quarter,
    'Q' || EXTRACT(QUARTER FROM full_date)    AS quarter_name,
    EXTRACT(MONTH FROM full_date)::smallint   AS month,
    TO_CHAR(full_date, 'FMMonth')             AS month_name,
    EXTRACT(DAY FROM full_date)::smallint     AS day_of_month,
    EXTRACT(ISODOW FROM full_date)::smallint  AS day_of_week,
    TO_CHAR(full_date, 'FMDay')               AS day_name,
    EXTRACT(WEEK FROM full_date)::smallint    AS week_of_year,
    EXTRACT(ISODOW FROM full_date) IN (6, 7)  AS is_weekend
FROM calendar;

/*==============================================================================
  dim_customers
==============================================================================*/

CREATE OR REPLACE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY oc.customer_id)::integer AS customer_key,
    oc.customer_id,
    oc.customer_unique_id,
    oc.customer_city,
    oc.customer_state,
    oc.customer_zip_code_prefix
FROM silver.olist_customers AS oc;

/*==============================================================================
  dim_products
==============================================================================*/

CREATE OR REPLACE VIEW gold.dim_products AS
WITH products AS
(
    SELECT
        op.product_id,
        INITCAP(REPLACE(op.product_category_name, '_', ' ')) AS product_category_name,
        INITCAP(REPLACE(opct.product_category_name_english, '_', ' ')) AS product_category_name_english,
        op.product_name_length,
        op.product_description_length,
        op.product_photos_qty,
        op.product_weight_g,
        op.product_length_cm,
        op.product_height_cm,
        op.product_width_cm
    FROM silver.olist_products AS op
    LEFT JOIN silver.olist_product_category_translations AS opct
        ON op.product_category_name = opct.product_category_name
)
SELECT
    ROW_NUMBER() OVER (ORDER BY p.product_id)::integer AS product_key,
    p.product_id,
    p.product_category_name,
    p.product_category_name_english,
    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM products AS p;

/*==============================================================================
  dim_sellers
==============================================================================*/

CREATE OR REPLACE VIEW gold.dim_sellers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY os.seller_id)::integer AS seller_key,
    os.seller_id,
    os.seller_city,
    os.seller_state,
    os.seller_zip_code_prefix
FROM silver.olist_sellers AS os;