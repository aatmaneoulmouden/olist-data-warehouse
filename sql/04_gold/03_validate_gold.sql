/*
===============================================================================
Script: 03_validate_gold.sql

Purpose:
    Validates the Gold layer to ensure analytical correctness, dimensional
    integrity, and consistency with the Silver layer.

Description:
    - Verifies row counts for all Gold dimension views.
    - Validates dimension surrogate key uniqueness.
    - Validates the integrity and continuity of the date dimension.
    - Reconciles Gold fact row counts with their Silver source tables.
    - Identifies unresolved dimension surrogate keys.
    - Identifies unresolved date dimension lookups.
    - Reconciles financial measures between the Silver and Gold layers.
    - Verifies descriptive transformations applied in the Gold layer.
    - Validates review comment indicator business rules.
    - Performs read-only validation without modifying warehouse data.

Phase:
    Phase 8 – Gold Layer Implementation
===============================================================================
*/

/*==============================================================================
  Validate dimension row counts

  Expected:
    - Every dimension should contain at least one row.
==============================================================================*/

SELECT
    'dim_dates' AS object_name,
    COUNT(*)    AS row_count
FROM gold.dim_dates
UNION ALL
SELECT
    'dim_customers',
    COUNT(*)
FROM gold.dim_customers
UNION ALL
SELECT
    'dim_products',
    COUNT(*)
FROM gold.dim_products
UNION ALL
SELECT
    'dim_sellers',
    COUNT(*)
FROM gold.dim_sellers;

/*==============================================================================
  Validate dimension surrogate key uniqueness

  Expected:
    - duplicate_key_count = 0 for every dimension.
==============================================================================*/

SELECT
    'dim_dates' AS object_name,
    COUNT(*) - COUNT(DISTINCT date_key) AS duplicate_key_count
FROM gold.dim_dates
UNION ALL
SELECT
    'dim_customers',
    COUNT(*) - COUNT(DISTINCT customer_key)
FROM gold.dim_customers
UNION ALL
SELECT
    'dim_products',
    COUNT(*) - COUNT(DISTINCT product_key)
FROM gold.dim_products
UNION ALL
SELECT
    'dim_sellers',
    COUNT(*) - COUNT(DISTINCT seller_key)
FROM gold.dim_sellers;

/*==============================================================================
  Validate the date dimension
==============================================================================*/

-- Expected: 0 rows.
SELECT
    dd.full_date,
    COUNT(*) AS duplicate_count
FROM gold.dim_dates AS dd
GROUP BY dd.full_date
HAVING COUNT(*) > 1;

-- Expected: 0 rows.
WITH date_boundaries AS (
    SELECT
        MIN(dd.full_date) AS min_date,
        MAX(dd.full_date) AS max_date
    FROM gold.dim_dates AS dd
),
expected_dates AS (
    SELECT
        GENERATE_SERIES(
            db.min_date,
            db.max_date,
            INTERVAL '1 day'
        )::date AS full_date
    FROM date_boundaries AS db
)
SELECT
    ed.full_date AS missing_date
FROM expected_dates AS ed
LEFT JOIN gold.dim_dates AS dd
    ON ed.full_date = dd.full_date
WHERE dd.full_date IS NULL;

-- Expected: 0 rows.
SELECT
    dd.date_key,
    dd.full_date
FROM gold.dim_dates AS dd
WHERE dd.date_key <> TO_CHAR(dd.full_date, 'YYYYMMDD')::integer;

/*==============================================================================
  Validate fact row counts

  Expected:
    - silver_row_count = gold_row_count
    - is_match = TRUE
==============================================================================*/

SELECT
    'fact_sales' AS object_name,
    (SELECT COUNT(*) FROM silver.olist_order_items) AS silver_row_count,
    (SELECT COUNT(*) FROM gold.fact_sales)          AS gold_row_count,
    (SELECT COUNT(*) FROM silver.olist_order_items)
        = (SELECT COUNT(*) FROM gold.fact_sales)     AS is_match
UNION ALL
SELECT
    'fact_payments',
    (SELECT COUNT(*) FROM silver.olist_order_payments),
    (SELECT COUNT(*) FROM gold.fact_payments),
    (SELECT COUNT(*) FROM silver.olist_order_payments)
        = (SELECT COUNT(*) FROM gold.fact_payments)
UNION ALL
SELECT
    'fact_reviews',
    (SELECT COUNT(*) FROM silver.olist_order_reviews),
    (SELECT COUNT(*) FROM gold.fact_reviews),
    (SELECT COUNT(*) FROM silver.olist_order_reviews)
        = (SELECT COUNT(*) FROM gold.fact_reviews);

/*==============================================================================
  Validate surrogate key resolution

  Expected:
    - missing_count = 0 for every surrogate key.
==============================================================================*/

SELECT
    'fact_sales'  AS object_name,
    'customer_key' AS surrogate_key,
    COUNT(*)       AS missing_count
FROM gold.fact_sales AS fs
WHERE fs.customer_key IS NULL
UNION ALL
SELECT
    'fact_sales',
    'product_key',
    COUNT(*)
FROM gold.fact_sales AS fs
WHERE fs.product_key IS NULL
UNION ALL
SELECT
    'fact_sales',
    'seller_key',
    COUNT(*)
FROM gold.fact_sales AS fs
WHERE fs.seller_key IS NULL
UNION ALL
SELECT
    'fact_payments',
    'customer_key',
    COUNT(*)
FROM gold.fact_payments AS fp
WHERE fp.customer_key IS NULL
UNION ALL
SELECT
    'fact_reviews',
    'customer_key',
    COUNT(*)
FROM gold.fact_reviews AS fr
WHERE fr.customer_key IS NULL;

/*==============================================================================
  Validate date-key resolution

  Expected:
    - unresolved_date_count = 0 for every date type.
    - A NULL date key is only considered unresolved when its Silver source
      date is not NULL.
==============================================================================*/

SELECT
    'purchase_date' AS date_type,
    COUNT(*)        AS unresolved_date_count
FROM silver.olist_order_items AS ooi
INNER JOIN silver.olist_orders AS oo
    ON ooi.order_id = oo.order_id
LEFT JOIN gold.fact_sales AS fs
    ON ooi.order_id = fs.order_id
   AND ooi.order_item_id = fs.order_item_id
WHERE oo.order_purchase_timestamp IS NOT NULL
  AND fs.purchase_date_key IS NULL
UNION ALL
SELECT
    'approval_date',
    COUNT(*)
FROM silver.olist_order_items AS ooi
INNER JOIN silver.olist_orders AS oo
    ON ooi.order_id = oo.order_id
LEFT JOIN gold.fact_sales AS fs
    ON ooi.order_id = fs.order_id
   AND ooi.order_item_id = fs.order_item_id
WHERE oo.order_approved_at IS NOT NULL
  AND fs.approval_date_key IS NULL
UNION ALL
SELECT
    'shipping_limit_date',
    COUNT(*)
FROM silver.olist_order_items AS ooi
LEFT JOIN gold.fact_sales AS fs
    ON ooi.order_id = fs.order_id
   AND ooi.order_item_id = fs.order_item_id
WHERE ooi.shipping_limit_date IS NOT NULL
  AND fs.shipping_limit_date_key IS NULL
UNION ALL
SELECT
    'carrier_delivery_date',
    COUNT(*)
FROM silver.olist_order_items AS ooi
INNER JOIN silver.olist_orders AS oo
    ON ooi.order_id = oo.order_id
LEFT JOIN gold.fact_sales AS fs
    ON ooi.order_id = fs.order_id
   AND ooi.order_item_id = fs.order_item_id
WHERE oo.order_delivered_carrier_date IS NOT NULL
  AND fs.carrier_delivery_date_key IS NULL
UNION ALL
SELECT
    'customer_delivery_date',
    COUNT(*)
FROM silver.olist_order_items AS ooi
INNER JOIN silver.olist_orders AS oo
    ON ooi.order_id = oo.order_id
LEFT JOIN gold.fact_sales AS fs
    ON ooi.order_id = fs.order_id
   AND ooi.order_item_id = fs.order_item_id
WHERE oo.order_delivered_customer_date IS NOT NULL
  AND fs.customer_delivery_date_key IS NULL
UNION ALL
SELECT
    'estimated_delivery_date',
    COUNT(*)
FROM silver.olist_order_items AS ooi
INNER JOIN silver.olist_orders AS oo
    ON ooi.order_id = oo.order_id
LEFT JOIN gold.fact_sales AS fs
    ON ooi.order_id = fs.order_id
   AND ooi.order_item_id = fs.order_item_id
WHERE oo.order_estimated_delivery_date IS NOT NULL
  AND fs.estimated_delivery_date_key IS NULL
UNION ALL
SELECT
    'payment_date',
    COUNT(*)
FROM silver.olist_order_payments AS oop
INNER JOIN silver.olist_orders AS oo
    ON oop.order_id = oo.order_id
LEFT JOIN gold.fact_payments AS fp
    ON oop.order_id = fp.order_id
   AND oop.payment_sequential = fp.payment_sequential
WHERE oo.order_purchase_timestamp IS NOT NULL
  AND fp.payment_date_key IS NULL
UNION ALL
SELECT
    'review_creation_date',
    COUNT(*)
FROM silver.olist_order_reviews AS oor
LEFT JOIN gold.fact_reviews AS fr
    ON oor.review_id = fr.review_id
   AND oor.order_id = fr.order_id
WHERE oor.review_creation_date IS NOT NULL
  AND fr.review_creation_date_key IS NULL;

/*==============================================================================
  Reconcile financial totals

  Expected:
    - difference = 0
    - is_match = TRUE
==============================================================================*/

WITH reconciliation AS (
    SELECT
        'sales_amount' AS financial_key,
        (SELECT SUM(price)
         FROM silver.olist_order_items) AS silver_amount,
        (SELECT SUM(sales_amount)
         FROM gold.fact_sales) AS gold_amount
    UNION ALL
    SELECT
        'freight_amount',
        (SELECT SUM(freight_value)
         FROM silver.olist_order_items),
        (SELECT SUM(freight_amount)
         FROM gold.fact_sales)
    UNION ALL
    SELECT
        'payment_value',
        (SELECT SUM(payment_value)
         FROM silver.olist_order_payments),
        (SELECT SUM(payment_value)
         FROM gold.fact_payments)
)
SELECT
    financial_key,
    silver_amount,
    gold_amount,
    gold_amount - silver_amount AS difference,
    gold_amount = silver_amount AS is_match
FROM reconciliation;

/*==============================================================================
  Validate descriptive transformations

  Expected:
    - Gold order statuses should be formatted using INITCAP().
    - Gold payment types should replace underscores with spaces and use
      INITCAP().
==============================================================================*/

SELECT DISTINCT
    oo.order_status AS silver_order_status,
    fs.order_status AS gold_order_status
FROM silver.olist_orders AS oo
INNER JOIN gold.fact_sales AS fs
    ON oo.order_id = fs.order_id
ORDER BY oo.order_status;

SELECT DISTINCT
    oop.payment_type AS silver_payment_type,
    fp.payment_type  AS gold_payment_type
FROM silver.olist_order_payments AS oop
INNER JOIN gold.fact_payments AS fp
    ON oop.order_id = fp.order_id
   AND oop.payment_sequential = fp.payment_sequential
ORDER BY oop.payment_type;

/*==============================================================================
  Validate review boolean flags

  Expected:
    - invalid_flag_count = 0
==============================================================================*/

SELECT
    COUNT(*) AS invalid_flag_count
FROM silver.olist_order_reviews AS oor
INNER JOIN gold.fact_reviews AS fr
    ON oor.review_id = fr.review_id
   AND oor.order_id = fr.order_id
WHERE fr.has_comment_title
          IS DISTINCT FROM (oor.review_comment_title IS NOT NULL)
   OR fr.has_comment_message
          IS DISTINCT FROM (oor.review_comment_message IS NOT NULL);