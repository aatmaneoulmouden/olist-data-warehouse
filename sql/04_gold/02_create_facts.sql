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

/*==============================================================================
  fact_sales
==============================================================================*/

CREATE OR REPLACE VIEW gold.fact_sales AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY ooi.order_id, ooi.order_item_id
    )::integer                                        AS sales_key,
    dc.customer_key,
    dp.product_key,
    ds.seller_key,
    dd_purchase.date_key                              AS purchase_date_key,
    dd_approval.date_key                              AS approval_date_key,
    dd_shipping_limit.date_key                        AS shipping_limit_date_key,
    dd_carrier_delivery.date_key                      AS carrier_delivery_date_key,
    dd_customer_delivery.date_key                     AS customer_delivery_date_key,
    dd_estimated_delivery.date_key                    AS estimated_delivery_date_key,
    ooi.order_id,
    ooi.order_item_id,
    INITCAP(oo.order_status)                          AS order_status,
    ooi.price                                         AS sales_amount,
    ooi.freight_value                                 AS freight_amount,
    1::smallint                                       AS quantity
FROM silver.olist_order_items AS ooi
INNER JOIN silver.olist_orders AS oo
    ON ooi.order_id = oo.order_id
LEFT JOIN gold.dim_customers AS dc
    ON oo.customer_id = dc.customer_id
LEFT JOIN gold.dim_products AS dp
    ON ooi.product_id = dp.product_id
LEFT JOIN gold.dim_sellers AS ds
    ON ooi.seller_id = ds.seller_id
LEFT JOIN gold.dim_dates AS dd_purchase
    ON oo.order_purchase_timestamp::date = dd_purchase.full_date
LEFT JOIN gold.dim_dates AS dd_approval
    ON oo.order_approved_at::date = dd_approval.full_date
LEFT JOIN gold.dim_dates AS dd_shipping_limit
    ON ooi.shipping_limit_date::date = dd_shipping_limit.full_date
LEFT JOIN gold.dim_dates AS dd_carrier_delivery
    ON oo.order_delivered_carrier_date::date = dd_carrier_delivery.full_date
LEFT JOIN gold.dim_dates AS dd_customer_delivery
    ON oo.order_delivered_customer_date::date = dd_customer_delivery.full_date
LEFT JOIN gold.dim_dates AS dd_estimated_delivery
    ON oo.order_estimated_delivery_date::date = dd_estimated_delivery.full_date;

/*==============================================================================
  fact_payments
==============================================================================*/

CREATE OR REPLACE VIEW gold.fact_payments AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY oop.order_id, oop.payment_sequential
    )::integer                                        AS payment_key,
    dc.customer_key,
    dd_payment.date_key                               AS payment_date_key,
    oop.order_id,
    oop.payment_sequential,
    INITCAP(REPLACE(oop.payment_type, '_', ' '))      AS payment_type,
    oop.payment_installments,
    oop.payment_value
FROM silver.olist_order_payments AS oop
INNER JOIN silver.olist_orders AS oo
    ON oop.order_id = oo.order_id
LEFT JOIN gold.dim_customers AS dc
    ON oo.customer_id = dc.customer_id
LEFT JOIN gold.dim_dates AS dd_payment
    ON oo.order_purchase_timestamp::date = dd_payment.full_date;

/*==============================================================================
  fact_reviews
==============================================================================*/

CREATE OR REPLACE VIEW gold.fact_reviews AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY oor.review_id, oor.order_id
    )::integer                                        AS review_key,
    dc.customer_key,
    dd_review.date_key                                AS review_creation_date_key,
    oor.review_id,
    oor.order_id,
    oor.review_score,
    oor.review_comment_title IS NOT NULL              AS has_comment_title,
    oor.review_comment_message IS NOT NULL            AS has_comment_message
FROM silver.olist_order_reviews AS oor
INNER JOIN silver.olist_orders AS oo
    ON oor.order_id = oo.order_id
LEFT JOIN gold.dim_customers AS dc
    ON oo.customer_id = dc.customer_id
LEFT JOIN gold.dim_dates AS dd_review
    ON oor.review_creation_date = dd_review.full_date;