/*
===============================================================================
Script: 03_validate_bronze.sql

Purpose:
    Validates the Bronze layer after raw source data has been loaded.

Description:
    - Verifies row counts for all Bronze tables.
    - Confirms that ingestion metadata is populated.
    - Identifies duplicate expected business keys.
    - Identifies child records whose referenced parent records do not exist.
    - Validates logical ZIP code and product category relationships.
    - Performs read-only validation without modifying the raw source data.

Phase:
    Phase 4 – Bronze Layer Implementation
===============================================================================
*/

/*==============================================================================
  Row Count Checks
==============================================================================*/

SELECT COUNT(*) AS customer_count
FROM bronze.olist_customers;

SELECT COUNT(*) AS geolocation_count
FROM bronze.olist_geolocations;

SELECT COUNT(*) AS order_item_count
FROM bronze.olist_order_items;

SELECT COUNT(*) AS order_payment_count
FROM bronze.olist_order_payments;

SELECT COUNT(*) AS order_review_count
FROM bronze.olist_order_reviews;

SELECT COUNT(*) AS order_count
FROM bronze.olist_orders;

SELECT COUNT(*) AS product_category_translation_count
FROM bronze.olist_product_category_translations;

SELECT COUNT(*) AS product_count
FROM bronze.olist_products;

SELECT COUNT(*) AS seller_count
FROM bronze.olist_sellers;


/*==============================================================================
  Metadata Checks
==============================================================================*/

SELECT COUNT(*) AS missing_load_timestamp
FROM bronze.olist_customers
WHERE dwh_load_timestamp IS NULL;

SELECT COUNT(*) AS missing_load_timestamp
FROM bronze.olist_geolocations
WHERE dwh_load_timestamp IS NULL;

SELECT COUNT(*) AS missing_load_timestamp
FROM bronze.olist_order_items
WHERE dwh_load_timestamp IS NULL;

SELECT COUNT(*) AS missing_load_timestamp
FROM bronze.olist_order_payments
WHERE dwh_load_timestamp IS NULL;

SELECT COUNT(*) AS missing_load_timestamp
FROM bronze.olist_order_reviews
WHERE dwh_load_timestamp IS NULL;

SELECT COUNT(*) AS missing_load_timestamp
FROM bronze.olist_orders
WHERE dwh_load_timestamp IS NULL;

SELECT COUNT(*) AS missing_load_timestamp
FROM bronze.olist_product_category_translations
WHERE dwh_load_timestamp IS NULL;

SELECT COUNT(*) AS missing_load_timestamp
FROM bronze.olist_products
WHERE dwh_load_timestamp IS NULL;

SELECT COUNT(*) AS missing_load_timestamp
FROM bronze.olist_sellers
WHERE dwh_load_timestamp IS NULL;


/*==============================================================================
  Duplicate Key Checks
==============================================================================*/

-- Expected unique key: customer_id
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM bronze.olist_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Expected composite key: (order_id, order_item_id)
SELECT
    order_id,
    order_item_id,
    COUNT(*) AS duplicate_count
FROM bronze.olist_order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- Expected composite key: (order_id, payment_sequential)
SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS duplicate_count
FROM bronze.olist_order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;

-- Expected unique key: review_id
SELECT
    review_id,
    COUNT(*) AS duplicate_count
FROM bronze.olist_order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

-- Expected unique key: order_id
SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM bronze.olist_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Expected unique key: product_category_name
SELECT
    product_category_name,
    COUNT(*) AS duplicate_count
FROM bronze.olist_product_category_translations
GROUP BY product_category_name
HAVING COUNT(*) > 1;

-- Expected unique key: product_id
SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM bronze.olist_products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Expected unique key: seller_id
SELECT
    seller_id,
    COUNT(*) AS duplicate_count
FROM bronze.olist_sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;


/*==============================================================================
  Relationship Checks
==============================================================================*/

-- Identifies orders whose referenced customer does not exist.
SELECT
    COUNT(*) AS orders_without_customers
FROM bronze.olist_orders oo
LEFT JOIN bronze.olist_customers oc
    ON oo.customer_id = oc.customer_id
WHERE oc.customer_id IS NULL;

-- Identifies order items whose referenced order does not exist.
SELECT
    COUNT(*) AS order_items_without_orders
FROM bronze.olist_order_items ooi
LEFT JOIN bronze.olist_orders oo
    ON ooi.order_id = oo.order_id
WHERE oo.order_id IS NULL;

-- Identifies order items whose referenced product does not exist.
SELECT
    COUNT(*) AS order_items_without_products
FROM bronze.olist_order_items ooi
LEFT JOIN bronze.olist_products op
    ON ooi.product_id = op.product_id
WHERE op.product_id IS NULL;

-- Identifies order items whose referenced seller does not exist.
SELECT
    COUNT(*) AS order_items_without_sellers
FROM bronze.olist_order_items ooi
LEFT JOIN bronze.olist_sellers os
    ON ooi.seller_id = os.seller_id
WHERE os.seller_id IS NULL;

-- Identifies payments whose referenced order does not exist.
SELECT
    COUNT(*) AS payments_without_orders
FROM bronze.olist_order_payments oop
LEFT JOIN bronze.olist_orders oo
    ON oop.order_id = oo.order_id
WHERE oo.order_id IS NULL;

-- Identifies reviews whose referenced order does not exist.
SELECT
    COUNT(*) AS reviews_without_orders
FROM bronze.olist_order_reviews oor
LEFT JOIN bronze.olist_orders oo
    ON oor.order_id = oo.order_id
WHERE oo.order_id IS NULL;

-- ZIP code relationships are logical lookups because geolocation ZIP prefixes are not unique.
SELECT
    COUNT(*) AS customers_without_geolocations
FROM bronze.olist_customers oc
WHERE NOT EXISTS (
    SELECT 1
    FROM bronze.olist_geolocations og
    WHERE og.geolocation_zip_code_prefix = oc.customer_zip_code_prefix
);

SELECT
    COUNT(*) AS sellers_without_geolocations
FROM bronze.olist_sellers os
WHERE NOT EXISTS (
    SELECT 1
    FROM bronze.olist_geolocations og
    WHERE og.geolocation_zip_code_prefix = os.seller_zip_code_prefix
);

-- Excludes products with NULL categories because those represent missing source values,
-- not missing category translations.
SELECT
    COUNT(*) AS products_without_category_translation
FROM bronze.olist_products op
WHERE op.product_category_name IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM bronze.olist_product_category_translations opct
      WHERE opct.product_category_name = op.product_category_name
  );