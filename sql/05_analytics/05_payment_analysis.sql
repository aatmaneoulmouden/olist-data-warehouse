/*
===============================================================================
Script: 05_payment_analysis.sql

Purpose:
    Analyzes customer payment activity, payment methods, and installment behavior.

Description:
    - Summarizes overall payment activity and key payment KPIs.
    - Analyzes transaction volume and payment value by payment type.
    - Tracks payment-method usage over time.
    - Examines the distribution of payment installments.
    - Compares average payment values across payment methods.

Phase:
    Phase 9 – Analytics and Reporting
===============================================================================
*/

/*==============================================================================
Payment summary
==============================================================================*/

WITH payment_categories AS (
    SELECT
        fp.order_id,
        COUNT(*) AS payment_transaction_count,
        CASE
            WHEN COUNT(*) = 1 THEN 'Single-Payment Order'
            ELSE 'Multiple-Payment Order'
        END AS payment_category
    FROM gold.fact_payments AS fp
    GROUP BY
        fp.order_id
)
SELECT
    'Total Payment Transactions' AS metric,
    COUNT(*)                     AS value
FROM gold.fact_payments AS fp
UNION ALL
SELECT
    'Total Amount Paid ($)',
    SUM(fp.payment_value)
FROM gold.fact_payments AS fp
UNION ALL
SELECT
    'Total Paid Orders',
    COUNT(DISTINCT fp.order_id)
FROM gold.fact_payments AS fp
UNION ALL
SELECT
    'Avg Payment Value ($)',
    ROUND(AVG(fp.payment_value), 2)
FROM gold.fact_payments AS fp
UNION ALL
SELECT
    'Avg Paid Amount per Order ($)',
    ROUND(
        SUM(fp.payment_value)
            / NULLIF(COUNT(DISTINCT fp.order_id), 0),
        2
    )
FROM gold.fact_payments AS fp
UNION ALL
SELECT
    'Avg Payment Transactions per Order',
    AVG(tpo.total_transactions)::integer
FROM (
    SELECT
        fp.order_id,
        COUNT(*) AS total_transactions
    FROM gold.fact_payments AS fp
    GROUP BY
        fp.order_id
) AS tpo
UNION ALL
SELECT
    'Avg Installments',
    AVG(fp.payment_installments)::integer
FROM gold.fact_payments AS fp
UNION ALL
SELECT
    pc.payment_category,
    SUM(pc.payment_transaction_count)
FROM payment_categories AS pc
GROUP BY
    pc.payment_category;


/*==============================================================================
Payments by payment type
==============================================================================*/

SELECT
    fp.payment_type,
    COUNT(*)                         AS total_transactions,
    COUNT(DISTINCT fp.order_id)      AS total_orders,
    SUM(fp.payment_value)            AS total_payment_value,
    ROUND(
        COUNT(*) * 100.0
            / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_transactions,
    ROUND(
        SUM(fp.payment_value) * 100.0
            / SUM(SUM(fp.payment_value)) OVER (),
        2
    ) AS percentage_of_payment_value
FROM gold.fact_payments AS fp
GROUP BY
    fp.payment_type;


/*==============================================================================
Payment-type trend over time
==============================================================================*/

SELECT
    dd.year,
    dd.month,
    dd.month_name,
    fp.payment_type,
    COUNT(*)                    AS total_payment_transactions,
    COUNT(DISTINCT fp.order_id) AS total_orders,
    SUM(fp.payment_value)        AS total_payment_value,
    ROUND(
        SUM(fp.payment_value) * 100.0
            / SUM(SUM(fp.payment_value))
                OVER (PARTITION BY dd.year, dd.month),
        2
    ) AS monthly_contribution
FROM gold.fact_payments AS fp
JOIN gold.dim_dates AS dd
    ON fp.payment_date_key = dd.date_key
GROUP BY
    dd.year,
    dd.month,
    dd.month_name,
    fp.payment_type
ORDER BY
    dd.year,
    dd.month,
    fp.payment_type;


/*==============================================================================
Installment distribution
==============================================================================*/

WITH installments AS (
    SELECT DISTINCT
        fp.order_id,
        fp.payment_installments,
        CASE
            WHEN fp.payment_installments = 0 THEN 'No Installments'
            WHEN fp.payment_installments = 1 THEN '1 Installment'
            WHEN fp.payment_installments BETWEEN 2 AND 3 THEN '2–3 Installments'
            WHEN fp.payment_installments BETWEEN 4 AND 6 THEN '4–6 Installments'
            WHEN fp.payment_installments BETWEEN 7 AND 12 THEN '7–12 Installments'
            ELSE 'Over 12 Installments'
        END AS installment_category,
        CASE
            WHEN fp.payment_installments = 0 THEN 1
            WHEN fp.payment_installments = 1 THEN 2
            WHEN fp.payment_installments BETWEEN 2 AND 3 THEN 3
            WHEN fp.payment_installments BETWEEN 4 AND 6 THEN 4
            WHEN fp.payment_installments BETWEEN 7 AND 12 THEN 5
            ELSE 6
        END AS installment_category_order
    FROM gold.fact_payments AS fp
    GROUP BY
        fp.payment_installments,
        fp.order_id
)
SELECT
    i.installment_category,
    COUNT(*)                    AS total_transactions,
    COUNT(DISTINCT i.order_id)  AS total_orders,
    ROUND(
        COUNT(*) * 100.0
            / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_transactions
FROM installments AS i
GROUP BY
    i.installment_category,
    i.installment_category_order
ORDER BY
    i.installment_category_order;


/*==============================================================================
Average payment value by payment type
==============================================================================*/

SELECT
    fp.payment_type,
    COUNT(*)                 AS total_transactions,
    ROUND(AVG(fp.payment_value), 2) AS avg_payment_value
FROM gold.fact_payments AS fp
GROUP BY
    fp.payment_type;