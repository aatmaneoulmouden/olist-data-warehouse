/*
===============================================================================
Script: 06_customer_satisfaction_analysis.sql

Purpose:
    Analyzes customer satisfaction using review scores and review activity.

Description:
    - Summarizes overall review activity and customer satisfaction KPIs.
    - Analyzes the distribution of customer review scores.
    - Tracks average customer satisfaction over time.
    - Compares customer satisfaction across product categories.

Phase:
    Phase 9 – Analytics and Reporting
===============================================================================
*/


/*==============================================================================
Customer satisfaction summary
==============================================================================*/

SELECT
    'Total Reviews' AS metric,
    COUNT(*)::numeric AS value
FROM gold.fact_reviews AS fr
UNION ALL
SELECT
    'Average Review Score',
    ROUND(AVG(fr.review_score), 2)
FROM gold.fact_reviews AS fr
UNION ALL
SELECT
    'Highest Review Score',
    MAX(fr.review_score)::numeric
FROM gold.fact_reviews AS fr
UNION ALL
SELECT
    'Lowest Review Score',
    MIN(fr.review_score)::numeric
FROM gold.fact_reviews AS fr
UNION ALL
SELECT
    '5-Star Reviews',
    COUNT(*)::numeric
FROM gold.fact_reviews AS fr
WHERE fr.review_score = 5
UNION ALL
SELECT
    '1-Star Reviews',
    COUNT(*)::numeric
FROM gold.fact_reviews AS fr
WHERE fr.review_score = 1
UNION ALL
SELECT
    'Positive Review Rate (4–5 Stars)',
    ROUND(
        COUNT(*) FILTER (
            WHERE fr.review_score BETWEEN 4 AND 5
        ) * 100.0
        /
        NULLIF(COUNT(*), 0),
        2
    )
FROM gold.fact_reviews AS fr
UNION ALL
SELECT
    'Negative Review Rate (1–2 Stars)',
    ROUND(
        COUNT(*) FILTER (
            WHERE fr.review_score BETWEEN 1 AND 2
        ) * 100.0
        /
        NULLIF(COUNT(*), 0),
        2
    )
FROM gold.fact_reviews AS fr;


/*==============================================================================
Review rating distribution
==============================================================================*/

SELECT
    fr.review_score,
    COUNT(*) AS total_reviews,
    ROUND(
        COUNT(*) * 100.0
        /
        NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS percentage_of_reviews
FROM gold.fact_reviews AS fr
GROUP BY
    fr.review_score
ORDER BY
    fr.review_score;


/*==============================================================================
Customer satisfaction trend over time
==============================================================================*/

SELECT
    dd.year,
    dd.month,
    dd.month_name,
    ROUND(AVG(fr.review_score), 2) AS avg_review_score,
    COUNT(*) AS total_reviews
FROM gold.fact_reviews AS fr
JOIN gold.dim_dates AS dd
    ON fr.review_creation_date_key = dd.date_key
GROUP BY
    dd.year,
    dd.month,
    dd.month_name
ORDER BY
    dd.year,
    dd.month;


/*==============================================================================
Customer satisfaction by product category
==============================================================================*/

WITH review_categories AS (
    SELECT DISTINCT
        fr.review_id,
        fr.review_score,
        dp.product_category_name
    FROM gold.fact_reviews AS fr
    JOIN gold.fact_sales AS t
        ON fr.order_id = t.order_id
    JOIN gold.dim_products AS dp
        ON t.product_key = dp.product_key
    WHERE dp.product_category_name IS NOT NULL
)
SELECT
    rc.product_category_name,
    ROUND(AVG(rc.review_score), 2) AS avg_review_score,
    COUNT(DISTINCT rc.review_id) AS total_reviews
FROM review_categories AS rc
GROUP BY
    rc.product_category_name
ORDER BY
    avg_review_score DESC,
    total_reviews DESC;