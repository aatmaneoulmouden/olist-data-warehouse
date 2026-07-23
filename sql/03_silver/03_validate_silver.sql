/*
===============================================================================
Script: 03_validate_silver.sql

Purpose:
    Validates the Silver layer after data cleansing and transformation.

Description:
    - Compares row counts between the Bronze and Silver layers.
    - Validates data standardization rules.
    - Validates data cleansing rules.
    - Validates numeric business rules.
    - Validates deduplication logic.
    - Validates lookup completeness after data enrichment.
    - Documents the exclusion of business rule validation.

Business Rule Validation:
    Business rule validations (for example, timestamp chronology and order
    lifecycle) are intentionally excluded from this validation script.

    The Olist source dataset contains known business anomalies that cannot be
    corrected without fabricating data. These issues are documented in
    `docs/silver_data_quality_report.md` and were intentionally preserved
    during the Silver ETL process to maintain data integrity.

Phase:
    Phase 6 – Silver Layer Implementation
===============================================================================
*/ 
 
/*==============================================================================
  Row Count Validation
==============================================================================*/

SELECT
    'olist_geolocations' AS table_name,
    (SELECT COUNT(*) FROM bronze.olist_geolocations)        AS bronze_rows,
    (SELECT COUNT(*) FROM silver.olist_geolocations)        AS silver_rows,
    (SELECT COUNT(*) FROM silver.olist_geolocations)
        - (SELECT COUNT(*) FROM bronze.olist_geolocations)  AS difference,
    'YES'                                                   AS expected_difference,
    'Duplicate ZIP codes removed during Silver deduplication.'
                                                            AS reason
UNION ALL
SELECT
    'olist_product_category_translations',
    (SELECT COUNT(*) FROM bronze.olist_product_category_translations),
    (SELECT COUNT(*) FROM silver.olist_product_category_translations),
    (SELECT COUNT(*) FROM silver.olist_product_category_translations)
        - (SELECT COUNT(*) FROM bronze.olist_product_category_translations),
    'YES',
    'Added missing product categories referenced by olist_products.'
UNION ALL
SELECT
    'olist_customers',
    (SELECT COUNT(*) FROM bronze.olist_customers),
    (SELECT COUNT(*) FROM silver.olist_customers),
    (SELECT COUNT(*) FROM silver.olist_customers)
        - (SELECT COUNT(*) FROM bronze.olist_customers),
    'NO',
    'Row counts should match.'
UNION ALL
SELECT
    'olist_order_items',
    (SELECT COUNT(*) FROM bronze.olist_order_items),
    (SELECT COUNT(*) FROM silver.olist_order_items),
    (SELECT COUNT(*) FROM silver.olist_order_items)
        - (SELECT COUNT(*) FROM bronze.olist_order_items),
    'NO',
    'Row counts should match.'
UNION ALL
SELECT
    'olist_order_payments',
    (SELECT COUNT(*) FROM bronze.olist_order_payments),
    (SELECT COUNT(*) FROM silver.olist_order_payments),
    (SELECT COUNT(*) FROM silver.olist_order_payments)
        - (SELECT COUNT(*) FROM bronze.olist_order_payments),
    'NO',
    'Row counts should match.'
UNION ALL
SELECT
    'olist_order_reviews',
    (SELECT COUNT(*) FROM bronze.olist_order_reviews),
    (SELECT COUNT(*) FROM silver.olist_order_reviews),
    (SELECT COUNT(*) FROM silver.olist_order_reviews)
        - (SELECT COUNT(*) FROM bronze.olist_order_reviews),
    'YES',
    'Duplicate review IDs removed during Silver deduplication.'
UNION ALL
SELECT
    'olist_orders',
    (SELECT COUNT(*) FROM bronze.olist_orders),
    (SELECT COUNT(*) FROM silver.olist_orders),
    (SELECT COUNT(*) FROM silver.olist_orders)
        - (SELECT COUNT(*) FROM bronze.olist_orders),
    'NO',
    'Row counts should match.'
UNION ALL
SELECT
    'olist_products',
    (SELECT COUNT(*) FROM bronze.olist_products),
    (SELECT COUNT(*) FROM silver.olist_products),
    (SELECT COUNT(*) FROM silver.olist_products)
        - (SELECT COUNT(*) FROM bronze.olist_products),
    'NO',
    'Row counts should match.'
UNION ALL
SELECT
    'olist_sellers',
    (SELECT COUNT(*) FROM bronze.olist_sellers),
    (SELECT COUNT(*) FROM silver.olist_sellers),
    (SELECT COUNT(*) FROM silver.olist_sellers)
        - (SELECT COUNT(*) FROM bronze.olist_sellers),
    'NO',
    'Row counts should match.'
ORDER BY table_name;

/*==============================================================================
  Data Standardization Validation
==============================================================================*/

-- Validate customer cities are capitalized.
-- Expected Result: 0 rows.
SELECT
    customer_id,
    customer_city
FROM silver.olist_customers
WHERE customer_city <> INITCAP(customer_city);

-- Validate customer states are uppercase.
-- Expected Result: 0 rows.
SELECT
    customer_id,
    customer_state
FROM silver.olist_customers
WHERE customer_state <> UPPER(customer_state);

-- Validate customer ZIP codes contain exactly 5 digits.
-- Expected Result: 0 rows.
SELECT
    customer_id,
    customer_zip_code_prefix
FROM silver.olist_customers
WHERE LENGTH(customer_zip_code_prefix) <> 5;

-- Validate seller cities are capitalized.
-- Expected Result: 0 rows.
SELECT
    seller_id,
    seller_city
FROM silver.olist_sellers
WHERE seller_city <> INITCAP(seller_city);

-- Validate seller states are uppercase.
-- Expected Result: 0 rows.
SELECT
    seller_id,
    seller_state
FROM silver.olist_sellers
WHERE seller_state <> UPPER(seller_state);

-- Validate seller ZIP codes contain exactly 5 digits.
-- Expected Result: 0 rows.
SELECT
    seller_id,
    seller_zip_code_prefix
FROM silver.olist_sellers
WHERE LENGTH(seller_zip_code_prefix) <> 5;

-- Validate geolocation cities are capitalized.
-- Expected Result: 0 rows.
SELECT
    geolocation_zip_code_prefix,
    geolocation_city
FROM silver.olist_geolocations
WHERE geolocation_city <> INITCAP(geolocation_city);

-- Validate geolocation states are uppercase.
-- Expected Result: 0 rows.
SELECT
    geolocation_zip_code_prefix,
    geolocation_state
FROM silver.olist_geolocations
WHERE geolocation_state <> UPPER(geolocation_state);

-- Validate geolocation ZIP codes contain exactly 5 digits.
-- Expected Result: 0 rows.
SELECT
    geolocation_zip_code_prefix
FROM silver.olist_geolocations
WHERE LENGTH(geolocation_zip_code_prefix) <> 5;

-- Validate product categories are lowercase.
-- Expected Result: 0 rows.
SELECT
    product_id,
    product_category_name
FROM silver.olist_products
WHERE product_category_name IS NOT NULL
  AND product_category_name <> LOWER(product_category_name);

-- Validate product category translations are lowercase.
-- Expected Result: 0 rows.
SELECT
    product_category_name,
    product_category_name_english
FROM silver.olist_product_category_translations
WHERE product_category_name <> LOWER(product_category_name)
   OR product_category_name_english <> LOWER(product_category_name_english);

-- Validate order statuses are lowercase.
-- Expected Result: 0 rows.
SELECT
    order_id,
    order_status
FROM silver.olist_orders
WHERE order_status <> LOWER(order_status);

-- Validate payment types are lowercase.
-- Expected Result: 0 rows.
SELECT
    order_id,
    payment_type
FROM silver.olist_order_payments
WHERE payment_type <> LOWER(payment_type);

/*==============================================================================
  Data Cleansing Validation
==============================================================================*/

-- Validate customer text fields do not contain leading or trailing spaces.
-- Expected Result: 0 rows.
SELECT
    customer_id,
    customer_unique_id,
    customer_city,
    customer_state
FROM silver.olist_customers
WHERE customer_id <> TRIM(customer_id)
   OR customer_unique_id <> TRIM(customer_unique_id)
   OR customer_city <> TRIM(customer_city)
   OR customer_state <> TRIM(customer_state);

-- Validate seller text fields do not contain leading or trailing spaces.
-- Expected Result: 0 rows.
SELECT
    seller_id,
    seller_city,
    seller_state
FROM silver.olist_sellers
WHERE seller_id <> TRIM(seller_id)
   OR seller_city <> TRIM(seller_city)
   OR seller_state <> TRIM(seller_state);

-- Validate product text fields do not contain leading or trailing spaces.
-- Expected Result: 0 rows.
SELECT
    product_id,
    product_category_name
FROM silver.olist_products
WHERE product_id <> TRIM(product_id)
   OR (
        product_category_name IS NOT NULL
    AND product_category_name <> TRIM(product_category_name)
   );

-- Validate order text fields do not contain leading or trailing spaces.
-- Expected Result: 0 rows.
SELECT
    order_id,
    customer_id,
    order_status
FROM silver.olist_orders
WHERE order_id <> TRIM(order_id)
   OR customer_id <> TRIM(customer_id)
   OR order_status <> TRIM(order_status);

-- Validate order item text fields do not contain leading or trailing spaces.
-- Expected Result: 0 rows.
SELECT
    order_id,
    product_id,
    seller_id
FROM silver.olist_order_items
WHERE order_id <> TRIM(order_id)
   OR product_id <> TRIM(product_id)
   OR seller_id <> TRIM(seller_id);

-- Validate payment text fields do not contain leading or trailing spaces.
-- Expected Result: 0 rows.
SELECT
    order_id,
    payment_type
FROM silver.olist_order_payments
WHERE order_id <> TRIM(order_id)
   OR payment_type <> TRIM(payment_type);

-- Validate review text fields do not contain leading or trailing spaces.
-- Expected Result: 0 rows.
SELECT
    review_id,
    order_id,
    review_comment_title,
    review_comment_message
FROM silver.olist_order_reviews
WHERE review_id <> TRIM(review_id)
   OR order_id <> TRIM(order_id)
   OR (
        review_comment_title IS NOT NULL
    AND review_comment_title <> TRIM(review_comment_title)
   )
   OR (
        review_comment_message IS NOT NULL
    AND review_comment_message <> TRIM(review_comment_message)
   );

-- Validate NULL product length attributes were replaced with zero.
-- Expected Result: 0 rows.
SELECT
    product_id,
    product_name_length,
    product_description_length,
    product_photos_qty
FROM silver.olist_products
WHERE product_name_length IS NULL
   OR product_description_length IS NULL
   OR product_photos_qty IS NULL;

/*==============================================================================
  Numeric Validation
==============================================================================*/

-- Validate product dimensions are non-negative.
-- Expected Result: 0 rows.
SELECT
    product_id,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM silver.olist_products
WHERE product_weight_g < 0
   OR product_length_cm < 0
   OR product_height_cm < 0
   OR product_width_cm < 0;

-- Validate product length attributes are non-negative.
-- Expected Result: 0 rows.
SELECT
    product_id,
    product_name_length,
    product_description_length,
    product_photos_qty
FROM silver.olist_products
WHERE product_name_length < 0
   OR product_description_length < 0
   OR product_photos_qty < 0;

-- Validate order item prices are non-negative.
-- Expected Result: 0 rows.
SELECT
    order_id,
    product_id,
    price,
    freight_value
FROM silver.olist_order_items
WHERE price < 0
   OR freight_value < 0;

-- Validate payment values are non-negative.
-- Expected Result: 0 rows.
SELECT
    order_id,
    payment_sequential,
    payment_value,
    payment_installments
FROM silver.olist_order_payments
WHERE payment_value < 0
   OR payment_installments < 0;

-- Validate review scores are between 1 and 5.
-- Expected Result: 0 rows.
SELECT
    review_id,
    review_score
FROM silver.olist_order_reviews
WHERE review_score NOT BETWEEN 1 AND 5;

/*==============================================================================
  Deduplication Validation
==============================================================================*/

-- Validate geolocation ZIP codes are unique.
-- Expected Result: 0 rows.
SELECT
    geolocation_zip_code_prefix,
    COUNT(*) AS record_count
FROM silver.olist_geolocations
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1;

-- Validate product category names are unique.
-- Expected Result: 0 rows.
SELECT
    product_category_name,
    COUNT(*) AS record_count
FROM silver.olist_product_category_translations
GROUP BY product_category_name
HAVING COUNT(*) > 1;

-- Validate review IDs are unique.
-- Expected Result: 0 rows.
SELECT
    review_id,
    COUNT(*) AS record_count
FROM silver.olist_order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

/*==============================================================================
  Lookup Completeness Validation
==============================================================================*/

-- Validate customer ZIP codes exist in Geolocations.
-- Expected Result: 0 rows.
SELECT
    oc.customer_id,
    oc.customer_zip_code_prefix
FROM silver.olist_customers oc
LEFT JOIN silver.olist_geolocations og
    ON oc.customer_zip_code_prefix = og.geolocation_zip_code_prefix
WHERE og.geolocation_zip_code_prefix IS NULL;

-- Validate seller ZIP codes exist in Geolocations.
-- Expected Result: 0 rows.
SELECT
    os.seller_id,
    os.seller_zip_code_prefix
FROM silver.olist_sellers os
LEFT JOIN silver.olist_geolocations og
    ON os.seller_zip_code_prefix = og.geolocation_zip_code_prefix
WHERE og.geolocation_zip_code_prefix IS NULL;

-- Validate non-null product categories exist in the product category translation table.
-- Expected Result: 0 rows.
SELECT
    op.product_id,
    op.product_category_name
FROM silver.olist_products op
LEFT JOIN silver.olist_product_category_translations opct
    ON op.product_category_name = opct.product_category_name
WHERE op.product_category_name IS NOT NULL
  AND opct.product_category_name IS NULL;