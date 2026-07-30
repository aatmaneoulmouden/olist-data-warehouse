/*
===============================================================================
Script: 02_product_analysis.sql

Purpose:
    Analyzes product sales volume, revenue contribution, pricing, category
    performance, and monthly sales trends.

Description:
    - Summarizes sales volume and revenue by product.
    - Identifies the highest-revenue products.
    - Identifies the highest-selling products by unit volume.
    - Evaluates product-category performance.
    - Calculates the average selling price of each product.
    - Tracks monthly product sales and ranks products within each month.

Phase:
    Phase 9 – Analytics and Reporting
===============================================================================
*/

/*==============================================================================
Product sales and revenue summary
==============================================================================*/

SELECT
    dp.product_id,
    COUNT(*)                           AS total_units_sold,
    ROUND(SUM(t.sales_amount), 2)      AS total_revenue
FROM gold.fact_sales AS t
JOIN gold.dim_products AS dp
    ON t.product_key = dp.product_key
GROUP BY
    dp.product_id
ORDER BY
    total_revenue DESC;


/*==============================================================================
Top 10 products by revenue
==============================================================================*/

WITH product_revenue AS (
    SELECT
        dp.product_id,
        SUM(t.sales_amount) AS total_revenue
    FROM gold.fact_sales AS t
    JOIN gold.dim_products AS dp
        ON t.product_key = dp.product_key
    GROUP BY
        dp.product_id
),
ranked_products AS (
    SELECT
        pr.product_id,
        pr.total_revenue,
        DENSE_RANK() OVER (
            ORDER BY pr.total_revenue DESC
        ) AS revenue_rank
    FROM product_revenue AS pr
)
SELECT
    rp.product_id,
    ROUND(rp.total_revenue, 2) AS total_revenue,
    rp.revenue_rank
FROM ranked_products AS rp
WHERE rp.revenue_rank <= 10
ORDER BY
    rp.revenue_rank,
    rp.product_id;


/*==============================================================================
Top 10 products by sales volume
==============================================================================*/

WITH product_sales_volume AS (
    SELECT
        dp.product_id,
        COUNT(*) AS total_units_sold
    FROM gold.fact_sales AS t
    JOIN gold.dim_products AS dp
        ON t.product_key = dp.product_key
    GROUP BY
        dp.product_id
),
ranked_products AS (
    SELECT
        psv.product_id,
        psv.total_units_sold,
        DENSE_RANK() OVER (
            ORDER BY psv.total_units_sold DESC
        ) AS sales_volume_rank
    FROM product_sales_volume AS psv
)
SELECT
    rp.product_id,
    rp.total_units_sold,
    rp.sales_volume_rank
FROM ranked_products AS rp
WHERE rp.sales_volume_rank <= 10
ORDER BY
    rp.sales_volume_rank,
    rp.product_id;


/*==============================================================================
Product category performance
==============================================================================*/

SELECT
    COALESCE(dp.product_category_name, 'N/A') AS category,
    COUNT(DISTINCT dp.product_id)             AS total_products,
    COUNT(*)                                  AS total_units_sold,
    COUNT(DISTINCT t.order_id)                AS total_orders,
    ROUND(SUM(t.sales_amount), 2)             AS total_revenue
FROM gold.fact_sales AS t
JOIN gold.dim_products AS dp
    ON t.product_key = dp.product_key
GROUP BY
    COALESCE(dp.product_category_name, 'N/A')
ORDER BY
    total_revenue DESC;


/*==============================================================================
Average selling price by product
==============================================================================*/

SELECT
    dp.product_id,
    ROUND(
        SUM(t.sales_amount)
            / NULLIF(COUNT(*), 0),
        2
    ) AS avg_selling_price
FROM gold.fact_sales AS t
JOIN gold.dim_products AS dp
    ON t.product_key = dp.product_key
GROUP BY
    dp.product_id
ORDER BY
    avg_selling_price DESC;


/*==============================================================================
Product sales trend by month
==============================================================================*/

SELECT
    dd.year,
    dd.month,
    dp.product_id,
    COUNT(*)                              AS total_units_sold,
    ROUND(SUM(t.sales_amount), 2)         AS total_revenue,
    ROW_NUMBER() OVER (
        PARTITION BY
            dd.year,
            dd.month
        ORDER BY
            COUNT(*) DESC,
            SUM(t.sales_amount) DESC,
            dp.product_id
    ) AS monthly_product_rank
FROM gold.fact_sales AS t
JOIN gold.dim_products AS dp
    ON t.product_key = dp.product_key
JOIN gold.dim_dates AS dd
    ON t.purchase_date_key = dd.date_key
GROUP BY
    dd.year,
    dd.month,
    dp.product_id
ORDER BY
    dd.year,
    dd.month,
    monthly_product_rank;