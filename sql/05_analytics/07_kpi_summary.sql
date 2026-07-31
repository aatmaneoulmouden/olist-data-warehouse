/*
===============================================================================
Script: 07_kpi_summary.sql

Purpose:
    Provides a consolidated summary of the primary business KPIs across sales,
    orders, payments, and customer satisfaction.

Description:
    - Summarizes total revenue, orders, customers, and average order value.
    - Measures delivered-order performance and average delivery time.
    - Reports total and average customer payment values.
    - Reports average review scores and positive-review rates.
    - Produces a compact dataset suitable for executive dashboards and reports.

Phase:
    Phase 9 – Analytics and Reporting
===============================================================================
*/

WITH delivered_orders AS (
    -- Reduces the item-level sales fact to one row per delivered order.
    SELECT DISTINCT
        t.order_id,
        dd_purchase.full_date          AS purchase_date,
        dd_customer_delivery.full_date AS delivery_date
    FROM gold.fact_sales AS t
    JOIN gold.dim_dates AS dd_purchase
        ON t.purchase_date_key = dd_purchase.date_key
    JOIN gold.dim_dates AS dd_customer_delivery
        ON t.customer_delivery_date_key = dd_customer_delivery.date_key
    WHERE t.order_status = 'Delivered'
)
SELECT
    'Sales'             AS area,
    'Total Revenue ($)' AS metric,
    ROUND(SUM(t.sales_amount + t.freight_amount), 2) AS value
FROM gold.fact_sales AS t
UNION ALL
SELECT
    'Sales',
    'Total Orders',
    COUNT(DISTINCT t.order_id)::numeric
FROM gold.fact_sales AS t
UNION ALL
SELECT
    'Sales',
    'Total Customers',
    COUNT(DISTINCT dc.customer_unique_id)::numeric
FROM gold.fact_sales AS t
JOIN gold.dim_customers AS dc
    ON t.customer_key = dc.customer_key
UNION ALL
SELECT
    'Sales',
    'Avg Order Value ($)',
    ROUND(
        SUM(t.sales_amount + t.freight_amount)
            / NULLIF(COUNT(DISTINCT t.order_id), 0),
        2
    )
FROM gold.fact_sales AS t
UNION ALL
SELECT
    'Orders',
    'Delivered Order Rate (%)',
    ROUND(
        COUNT(DISTINCT t.order_id) FILTER (
            WHERE t.order_status = 'Delivered'
        ) * 100.0
        /
        NULLIF(COUNT(DISTINCT t.order_id), 0),
        2
    )
FROM gold.fact_sales AS t
UNION ALL
SELECT
    'Orders',
    'Average Delivery Days',
    ROUND(AVG(d.delivery_date - d.purchase_date), 2)
FROM delivered_orders AS d
UNION ALL
SELECT
    'Payments',
    'Total Amount Paid ($)',
    ROUND(SUM(fp.payment_value), 2)
FROM gold.fact_payments AS fp
UNION ALL
SELECT
    'Payments',
    'Average Payment Value ($)',
    ROUND(AVG(fp.payment_value), 2)
FROM gold.fact_payments AS fp
UNION ALL
SELECT
    'Customer Satisfaction',
    'Average Review Score',
    ROUND(AVG(fr.review_score), 2)
FROM gold.fact_reviews AS fr
UNION ALL
SELECT
    'Customer Satisfaction',
    'Positive Review Rate (%)',
    ROUND(
        COUNT(*) FILTER (
            WHERE fr.review_score BETWEEN 4 AND 5
        ) * 100.0
        /
        NULLIF(COUNT(*), 0),
        2
    )
FROM gold.fact_reviews AS fr;