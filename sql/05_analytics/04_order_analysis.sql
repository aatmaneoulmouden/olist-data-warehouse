/*
===============================================================================
Script: 04_order_analysis.sql

Purpose:
    Analyzes order-level performance, fulfillment efficiency, and delivery metrics.

Description:
    - Summarizes overall order volume and key order KPIs.
    - Analyzes order distribution by status and order value.
    - Tracks order status trends over time.
    - Measures average order value and average items per order.
    - Evaluates delivery performance, including on-time delivery metrics.
    - Analyzes delivery-time distribution across predefined delivery ranges.

Phase:
    Phase 9 – Analytics and Reporting
===============================================================================
*/

/*==============================================================================
Orders summary
==============================================================================*/

SELECT
    'Total Orders' AS metric,
    COUNT(DISTINCT t.order_id)::numeric AS value
FROM gold.fact_sales AS t
UNION ALL
SELECT
    'Total Delivered Orders',
    COUNT(DISTINCT t.order_id)::numeric
FROM gold.fact_sales AS t
WHERE t.order_status = 'Delivered'
UNION ALL
SELECT
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
    'Total Canceled Orders',
    COUNT(DISTINCT t.order_id)::numeric
FROM gold.fact_sales AS t
WHERE t.order_status = 'Canceled'
UNION ALL
SELECT
    'Canceled Order Rate (%)',
    ROUND(
        COUNT(DISTINCT t.order_id) FILTER (
            WHERE t.order_status = 'Canceled'
        ) * 100.0
        /
        NULLIF(COUNT(DISTINCT t.order_id), 0),
        2
    )
FROM gold.fact_sales AS t
UNION ALL
SELECT
    'Average Items per Order',
    ROUND(
        COUNT(*)::numeric
            / NULLIF(COUNT(DISTINCT t.order_id), 0),
        2
    )
FROM gold.fact_sales AS t
UNION ALL
SELECT
    'Average Order Value',
    ROUND(
        SUM(t.sales_amount)
            / NULLIF(COUNT(DISTINCT t.order_id), 0),
        2
    )
FROM gold.fact_sales AS t
UNION ALL
SELECT
    'Single-Item Orders',
    COUNT(*)::numeric
FROM (
    SELECT
        t.order_id
    FROM gold.fact_sales AS t
    GROUP BY
        t.order_id
    HAVING COUNT(*) = 1
) AS single_item_orders
UNION ALL
SELECT
    'Multi-Item Orders',
    COUNT(*)::numeric
FROM (
    SELECT
        t.order_id
    FROM gold.fact_sales AS t
    GROUP BY
        t.order_id
    HAVING COUNT(*) > 1
) AS multi_item_orders;


/*==============================================================================
Orders by status
==============================================================================*/

SELECT
    t.order_status,
    COUNT(DISTINCT t.order_id) AS total_orders,
    ROUND(
        COUNT(DISTINCT t.order_id) * 100.0
        /
        NULLIF(
            SUM(COUNT(DISTINCT t.order_id)) OVER (),
            0
        ),
        2
    ) AS percentage_of_orders
FROM gold.fact_sales AS t
GROUP BY
    t.order_status
ORDER BY
    total_orders DESC;


/*==============================================================================
Order-status trend over time
==============================================================================*/

SELECT
    dd.year,
    dd.month,
    dd.month_name,
    t.order_status,
    COUNT(DISTINCT t.order_id) AS total_orders,
    ROUND(
        COUNT(DISTINCT t.order_id) * 100.0
        /
        NULLIF(
            SUM(COUNT(DISTINCT t.order_id)) OVER (
                PARTITION BY dd.year, dd.month
            ),
            0
        ),
        2
    ) AS percentage_of_monthly_orders
FROM gold.fact_sales AS t
JOIN gold.dim_dates AS dd
    ON t.purchase_date_key = dd.date_key
GROUP BY
    dd.year,
    dd.month,
    dd.month_name,
    t.order_status
ORDER BY
    dd.year,
    dd.month,
    total_orders DESC;


/*==============================================================================
Order value distribution
==============================================================================*/

WITH orders AS (
    SELECT
        t.order_id,
        SUM(t.sales_amount + t.freight_amount) AS order_value
    FROM gold.fact_sales AS t
    GROUP BY
        t.order_id
),
order_distributions AS (
    SELECT
        o.order_id,
        o.order_value,
        CASE
            WHEN o.order_value < 50 THEN 'Under $50'
            WHEN o.order_value < 100 THEN '$50–$99.99'
            WHEN o.order_value < 200 THEN '$100–$199.99'
            ELSE '$200 and Above'
        END AS order_value_range,
        CASE
            WHEN o.order_value < 50 THEN 1
            WHEN o.order_value < 100 THEN 2
            WHEN o.order_value < 200 THEN 3
            ELSE 4
        END AS range_order
    FROM orders AS o
)
SELECT
    od.order_value_range,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0
        /
        NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS percentage_of_orders
FROM order_distributions AS od
GROUP BY
    od.order_value_range,
    od.range_order
ORDER BY
    od.range_order;


/*==============================================================================
Delivery performance
==============================================================================*/

WITH delivery_metrics AS (
    SELECT DISTINCT
        t.order_id,
        dd_purchase.full_date                                  AS purchase_date,
        dd_customer_delivery.full_date                         AS delivery_date,
        dd_estimated_delivery.full_date                        AS estimated_delivery_date,
        dd_customer_delivery.full_date
            - dd_purchase.full_date                            AS delivery_days,
        dd_estimated_delivery.full_date
            - dd_purchase.full_date                            AS estimated_delivery_days,
        dd_customer_delivery.full_date
            - dd_estimated_delivery.full_date                  AS delivery_variance_days
    FROM gold.fact_sales AS t
    JOIN gold.dim_dates AS dd_purchase
        ON t.purchase_date_key = dd_purchase.date_key
    JOIN gold.dim_dates AS dd_customer_delivery
        ON t.customer_delivery_date_key = dd_customer_delivery.date_key
    JOIN gold.dim_dates AS dd_estimated_delivery
        ON t.estimated_delivery_date_key = dd_estimated_delivery.date_key
    WHERE t.order_status = 'Delivered'
)
SELECT
    'Average Delivery Days' AS metric,
    ROUND(AVG(dm.delivery_days), 2) AS value
FROM delivery_metrics AS dm

UNION ALL

SELECT
    'Average Estimated Delivery Days',
    ROUND(AVG(dm.estimated_delivery_days), 2)
FROM delivery_metrics AS dm

UNION ALL

SELECT
    'Average Days Early/Late',
    ROUND(AVG(dm.delivery_variance_days), 2)
FROM delivery_metrics AS dm

UNION ALL

SELECT
    'On-Time Orders',
    COUNT(*)::numeric
FROM delivery_metrics AS dm
WHERE dm.delivery_date <= dm.estimated_delivery_date

UNION ALL

SELECT
    'Late Orders',
    COUNT(*)::numeric
FROM delivery_metrics AS dm
WHERE dm.delivery_date > dm.estimated_delivery_date

UNION ALL

SELECT
    'On-Time Delivery Rate (%)',
    ROUND(
        COUNT(*) FILTER (
            WHERE dm.delivery_date <= dm.estimated_delivery_date
        ) * 100.0
        /
        NULLIF(COUNT(*), 0),
        2
    )
FROM delivery_metrics AS dm;


/*==============================================================================
Delivery-time distribution
==============================================================================*/

WITH delivered_orders AS (
    SELECT DISTINCT
        t.order_id,
        dd_purchase.full_date                                  AS purchase_date,
        dd_customer_delivery.full_date                         AS delivery_date,
        dd_customer_delivery.full_date - dd_purchase.full_date AS delivery_days
    FROM gold.fact_sales AS t
    JOIN gold.dim_dates AS dd_purchase
        ON t.purchase_date_key = dd_purchase.date_key
    JOIN gold.dim_dates AS dd_customer_delivery
        ON t.customer_delivery_date_key = dd_customer_delivery.date_key
    WHERE t.order_status = 'Delivered'
),
delivery_time_distribution AS (
    SELECT
        ddo.order_id,
        ddo.delivery_days,
        CASE
            WHEN ddo.delivery_days < 0 THEN 'Invalid Duration'
            WHEN ddo.delivery_days BETWEEN 0 AND 3 THEN '0–3 days'
            WHEN ddo.delivery_days BETWEEN 4 AND 7 THEN '4–7 days'
            WHEN ddo.delivery_days BETWEEN 8 AND 14 THEN '8–14 days'
            WHEN ddo.delivery_days BETWEEN 15 AND 30 THEN '15–30 days'
            ELSE 'More than 30 days'
        END AS delivery_group,
        CASE
            WHEN ddo.delivery_days < 0 THEN 0
            WHEN ddo.delivery_days BETWEEN 0 AND 3 THEN 1
            WHEN ddo.delivery_days BETWEEN 4 AND 7 THEN 2
            WHEN ddo.delivery_days BETWEEN 8 AND 14 THEN 3
            WHEN ddo.delivery_days BETWEEN 15 AND 30 THEN 4
            ELSE 5
        END AS delivery_group_order
    FROM delivered_orders AS ddo
)
SELECT
    dtd.delivery_group,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0
        /
        NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS delivered_orders_percentage
FROM delivery_time_distribution AS dtd
GROUP BY
    dtd.delivery_group,
    dtd.delivery_group_order
ORDER BY
    dtd.delivery_group_order;