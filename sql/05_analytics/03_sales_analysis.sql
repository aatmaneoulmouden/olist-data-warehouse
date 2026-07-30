/*
===============================================================================
Script: 03_sales_analysis.sql

Purpose:
    Analyzes overall sales performance, revenue trends, growth rates,
    seasonality, average order value, and cumulative revenue.

Description:
    - Calculates high-level sales metrics.
    - Tracks monthly sales performance.
    - Calculates year-over-year and month-over-month growth.
    - Tracks average order value over time.
    - Analyzes sales by weekday and calendar month.
    - Calculates cumulative revenue over time.

Phase:
    Phase 9 – Analytics and Reporting
===============================================================================
*/

/*==============================================================================
Sales summary
==============================================================================*/

SELECT
    'Total Orders' AS metric,
    COUNT(DISTINCT t.order_id)::numeric AS value
FROM gold.fact_sales AS t
UNION ALL
SELECT
    'Total Items Sold',
    COUNT(*)::numeric
FROM gold.fact_sales AS t
UNION ALL
SELECT
    'Total Sales Revenue',
    ROUND(SUM(t.sales_amount), 2)
FROM gold.fact_sales AS t
UNION ALL
SELECT
    'Total Freight Revenue',
    ROUND(SUM(t.freight_amount), 2)
FROM gold.fact_sales AS t
UNION ALL
SELECT
    'Total Customer Amount',
    ROUND(SUM(t.sales_amount + t.freight_amount), 2)
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
    'Average Item Revenue',
    ROUND(
        SUM(t.sales_amount)
            / NULLIF(COUNT(*), 0),
        2
    )
FROM gold.fact_sales AS t;


/*==============================================================================
Sales trend over time
==============================================================================*/

SELECT
    dd.year,
    dd.month,
    dd.month_name,
    ROUND(SUM(t.sales_amount), 2)                    AS sales_revenue,
    ROUND(SUM(t.freight_amount), 2)                  AS freight_revenue,
    ROUND(SUM(t.sales_amount + t.freight_amount), 2) AS total_customer_amount,
    COUNT(DISTINCT t.order_id)                       AS total_orders,
    COUNT(*)                                         AS total_items_sold
FROM gold.fact_sales AS t
JOIN gold.dim_dates AS dd
    ON t.purchase_date_key = dd.date_key
GROUP BY
    dd.year,
    dd.month,
    dd.month_name
ORDER BY
    dd.year,
    dd.month;


/*==============================================================================
Year-over-Year (YoY) sales growth
==============================================================================*/

WITH yearly_revenue AS (
    SELECT
        dd.year,
        SUM(t.sales_amount + t.freight_amount) AS current_year_revenue
    FROM gold.fact_sales AS t
    JOIN gold.dim_dates AS dd
        ON t.purchase_date_key = dd.date_key
    GROUP BY
        dd.year
),
revenue_comparison AS (
    SELECT
        yr.year,
        yr.current_year_revenue,
        LAG(yr.current_year_revenue) OVER (
            ORDER BY yr.year
        ) AS previous_year_revenue
    FROM yearly_revenue AS yr
)
SELECT
    rc.year,
    ROUND(rc.current_year_revenue, 2)  AS current_year_revenue,
    ROUND(rc.previous_year_revenue, 2) AS previous_year_revenue,
    ROUND(
        rc.current_year_revenue - rc.previous_year_revenue,
        2
    ) AS revenue_difference,
    ROUND(
        (
            rc.current_year_revenue - rc.previous_year_revenue
        )
        / NULLIF(rc.previous_year_revenue, 0)
        * 100,
        2
    ) AS growth_pct
FROM revenue_comparison AS rc
ORDER BY
    rc.year;


/*==============================================================================
Month-over-Month (MoM) sales growth
==============================================================================*/

WITH monthly_revenue AS (
    SELECT
        dd.year,
        dd.month,
        dd.month_name,
        SUM(t.sales_amount + t.freight_amount) AS current_month_revenue
    FROM gold.fact_sales AS t
    JOIN gold.dim_dates AS dd
        ON t.purchase_date_key = dd.date_key
    GROUP BY
        dd.year,
        dd.month,
        dd.month_name
),
revenue_comparison AS (
    SELECT
        mr.year,
        mr.month,
        mr.month_name,
        mr.current_month_revenue,
        LAG(mr.current_month_revenue) OVER (
            ORDER BY
                mr.year,
                mr.month
        ) AS previous_month_revenue
    FROM monthly_revenue AS mr
)
SELECT
    rc.year,
    rc.month,
    rc.month_name,
    ROUND(rc.current_month_revenue, 2)  AS current_month_revenue,
    ROUND(rc.previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        rc.current_month_revenue - rc.previous_month_revenue,
        2
    ) AS revenue_difference,
    ROUND(
        (
            rc.current_month_revenue - rc.previous_month_revenue
        )
        / NULLIF(rc.previous_month_revenue, 0)
        * 100,
        2
    ) AS growth_pct
FROM revenue_comparison AS rc
ORDER BY
    rc.year,
    rc.month;


/*==============================================================================
Average order value over time
==============================================================================*/

SELECT
    dd.year,
    dd.month,
    dd.month_name,
    ROUND(
        SUM(t.sales_amount)
            / NULLIF(COUNT(DISTINCT t.order_id), 0),
        2
    ) AS avg_order_value
FROM gold.fact_sales AS t
JOIN gold.dim_dates AS dd
    ON t.purchase_date_key = dd.date_key
GROUP BY
    dd.year,
    dd.month,
    dd.month_name
ORDER BY
    dd.year,
    dd.month;


/*==============================================================================
Sales by day of week
==============================================================================*/

SELECT
    dd.day_of_week,
    dd.day_name AS weekday,
    COUNT(DISTINCT t.order_id)                       AS total_orders,
    COUNT(*)                                         AS total_items_sold,
    ROUND(SUM(t.sales_amount + t.freight_amount), 2) AS total_customer_amount
FROM gold.fact_sales AS t
JOIN gold.dim_dates AS dd
    ON t.purchase_date_key = dd.date_key
GROUP BY
    dd.day_of_week,
    dd.day_name
ORDER BY
    dd.day_of_week;


/*==============================================================================
Sales by month — seasonality
==============================================================================*/

SELECT
    dd.month,
    dd.month_name,
    COUNT(DISTINCT t.order_id)                       AS total_orders,
    COUNT(*)                                         AS total_items_sold,
    ROUND(SUM(t.sales_amount + t.freight_amount), 2) AS total_customer_amount
FROM gold.fact_sales AS t
JOIN gold.dim_dates AS dd
    ON t.purchase_date_key = dd.date_key
GROUP BY
    dd.month,
    dd.month_name
ORDER BY
    dd.month;


/*==============================================================================
Cumulative sales over time
==============================================================================*/

WITH monthly_revenue AS (
    SELECT
        dd.year,
        dd.month,
        dd.month_name,
        SUM(t.sales_amount + t.freight_amount) AS total_customer_amount
    FROM gold.fact_sales AS t
    JOIN gold.dim_dates AS dd
        ON t.purchase_date_key = dd.date_key
    GROUP BY
        dd.year,
        dd.month,
        dd.month_name
)
SELECT
    mr.year,
    mr.month,
    mr.month_name,
    ROUND(mr.total_customer_amount, 2) AS total_customer_amount,
    ROUND(
        SUM(mr.total_customer_amount) OVER (
            ORDER BY
                mr.year,
                mr.month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS cumulative_customer_amount
FROM monthly_revenue AS mr
ORDER BY
    mr.year,
    mr.month;