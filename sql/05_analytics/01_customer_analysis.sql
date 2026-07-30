/*
===============================================================================
Script: 01_customer_analysis.sql

Purpose:
    Analyzes customer distribution, purchasing behavior, revenue contribution,
    retention, acquisition trends, and average order frequency.

Description:
    - Calculates customer geographic distribution by state.
    - Summarizes orders, items, revenue, purchase dates, and customer lifespan.
    - Identifies the top 10 customers by total revenue.
    - Classifies customers as one-time or returning customers.
    - Calculates monthly new-customer acquisition.
    - Calculates the average number of orders per customer.

Phase:
    Phase 9 – Analytics and Reporting
===============================================================================
*/

/*==============================================================================
Customer geographic distribution
==============================================================================*/

SELECT
    dc.customer_state                                              AS state,
    COUNT(DISTINCT dc.customer_unique_id)                          AS total_customers,
    ROUND(
        COUNT(DISTINCT dc.customer_unique_id) * 100.0
            / NULLIF(
                SUM(COUNT(DISTINCT dc.customer_unique_id)) OVER (),
                0
            ),
        2
    )                                                              AS customer_percentage
FROM gold.dim_customers AS dc
WHERE dc.customer_unique_id IS NOT NULL
GROUP BY
    dc.customer_state
ORDER BY
    dc.customer_state;


/*==============================================================================
Customer order and revenue summary
==============================================================================*/

WITH customer_orders AS (
    SELECT
        dc.customer_unique_id,
        dc.customer_state,
        t.order_id,
        dd.full_date                              AS purchase_date,
        t.sales_amount + t.freight_amount         AS total_amount
    FROM gold.fact_sales AS t
    JOIN gold.dim_customers AS dc
        ON t.customer_key = dc.customer_key
    JOIN gold.dim_dates AS dd
        ON t.purchase_date_key = dd.date_key
)
SELECT
    co.customer_unique_id,
    co.customer_state,
    COUNT(DISTINCT co.order_id)                   AS total_orders,
    COUNT(*)                                      AS total_items,
    MIN(co.purchase_date)                         AS first_purchase_date,
    MAX(co.purchase_date)                         AS last_purchase_date,
    ROUND(SUM(co.total_amount), 2)                AS total_revenue,
    ROUND(
        SUM(co.total_amount)
            / NULLIF(COUNT(DISTINCT co.order_id), 0),
        2
    )                                             AS avg_order_value,
    MAX(co.purchase_date)
        - MIN(co.purchase_date)                   AS lifespan_in_days
FROM customer_orders AS co
GROUP BY
    co.customer_unique_id,
    co.customer_state
ORDER BY
    total_revenue DESC;


/*==============================================================================
Top 10 customers by revenue
==============================================================================*/

WITH customer_orders AS (
    SELECT
        dc.customer_unique_id,
        dc.customer_state,
        t.sales_amount + t.freight_amount AS total_amount
    FROM gold.fact_sales AS t
    JOIN gold.dim_customers AS dc
        ON t.customer_key = dc.customer_key
),
customer_revenue AS (
    SELECT
        co.customer_unique_id,
        co.customer_state,
        SUM(co.total_amount) AS total_revenue
    FROM customer_orders AS co
    GROUP BY
        co.customer_unique_id,
        co.customer_state
)
SELECT
    cr.customer_unique_id,
    cr.customer_state,
    ROUND(cr.total_revenue, 2) AS total_revenue,
    DENSE_RANK() OVER (
        ORDER BY cr.total_revenue DESC
    )                           AS revenue_rank
FROM customer_revenue AS cr
ORDER BY
    cr.total_revenue DESC
LIMIT 10;


/*==============================================================================
One-time versus returning customers
==============================================================================*/

WITH customer_orders AS (
    SELECT
        dc.customer_unique_id,
        t.order_id
    FROM gold.fact_sales AS t
    JOIN gold.dim_customers AS dc
        ON t.customer_key = dc.customer_key
),
customer_types AS (
    SELECT
        co.customer_unique_id,
        COUNT(DISTINCT co.order_id) AS total_orders,
        CASE
            WHEN COUNT(DISTINCT co.order_id) = 1
                THEN 'One-Time Customer'
            ELSE 'Returning Customer'
        END AS customer_type
    FROM customer_orders AS co
    GROUP BY
        co.customer_unique_id
)
SELECT
    ct.customer_type,
    COUNT(*) AS total_customers,
    ROUND(
        COUNT(*) * 100.0
            / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    )        AS customer_percentage
FROM customer_types AS ct
GROUP BY
    ct.customer_type
ORDER BY
    ct.customer_type;


/*==============================================================================
New customers by month
==============================================================================*/

WITH customer_first_purchase AS (
    SELECT
        dc.customer_unique_id,
        MIN(dd.full_date) AS first_purchase_date
    FROM gold.fact_sales AS t
    JOIN gold.dim_customers AS dc
        ON t.customer_key = dc.customer_key
    JOIN gold.dim_dates AS dd
        ON t.purchase_date_key = dd.date_key
    GROUP BY
        dc.customer_unique_id
)
SELECT
    DATE_TRUNC('month', cfp.first_purchase_date)::date AS acquisition_month,
    COUNT(*)                                           AS new_customers
FROM customer_first_purchase AS cfp
GROUP BY
    DATE_TRUNC('month', cfp.first_purchase_date)
ORDER BY
    acquisition_month;


/*==============================================================================
Average orders per customer
==============================================================================*/

SELECT
    ROUND(
        COUNT(DISTINCT t.order_id)::numeric
            / NULLIF(COUNT(DISTINCT dc.customer_unique_id), 0),
        2
    ) AS avg_orders_per_customer
FROM gold.fact_sales AS t
JOIN gold.dim_customers AS dc
    ON t.customer_key = dc.customer_key;