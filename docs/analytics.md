# Analytics Documentation

## Overview

The Gold layer provides business-ready datasets that support analytical reporting and decision-making. This document describes each analytical report developed for the Olist Data Warehouse, including its business purpose, implementation approach, and expected insights.

# 1. Customer Analysis

## Business Objective

Understand customer behavior, purchasing patterns, and customer value.

## Business Questions

- How many customers have placed orders?
- How many are repeat customers?
- What is the average customer lifetime value?
- Which customers generate the most revenue?
- How frequently do customers purchase?

## Business Value

This analysis helps businesses:

- Identify high-value customers.
- Measure customer retention.
- Understand customer purchasing behavior.
- Support loyalty and marketing strategies.

## Grain

One row per customer (depending on the specific query).

## Gold Objects Used

- `gold.fact_sales`
- `gold.dim_customers`
- `gold.dim_dates`

## SQL Techniques

- Aggregations
- Window functions
- Common Table Expressions (CTEs)
- Ranking functions
- Date calculations
- Conditional logic

## Expected Output

Examples include:

- Customer summary KPIs
- Customer segmentation
- Customer lifetime value
- Purchase frequency
- Top customers by revenue

## Business Interpretation

The results identify the organization's most valuable customers, purchasing habits, and opportunities to improve customer retention and marketing effectiveness.

# 2. Product Analysis

## Business Objective

Evaluate product sales performance and identify high-performing and underperforming products.

## Business Questions

- Which products generate the highest revenue?
- Which products sell the most units?
- Which categories perform best?
- Which products have declining sales?

## Business Value

This analysis supports:

- Inventory planning
- Product portfolio optimization
- Pricing decisions
- Category management

## Grain

One row per product.

## Gold Objects Used

- `gold.fact_sales`
- `gold.dim_products`
- `gold.dim_dates`

## SQL Techniques

- Aggregations
- Window functions
- Ranking
- Time-series analysis
- CTEs

## Expected Output

Examples include:

- Product sales summary
- Product rankings
- Category performance
- Sales trends
- Year-over-year comparisons

## Business Interpretation

The analysis highlights products driving revenue, identifies slow-moving products, and supports inventory and merchandising decisions.

# 3. Sales Analysis

## Business Objective

Measure overall sales performance and identify sales trends over time.

## Business Questions

- How much revenue has been generated?
- How are sales changing over time?
- What are the seasonal sales patterns?
- How does revenue compare year over year?

## Business Value

This analysis helps management:

- Monitor business performance.
- Forecast future sales.
- Identify seasonality.
- Measure growth.

## Grain

Varies by analysis:

- Overall summary
- Monthly
- Yearly
- Daily

## Gold Objects Used

- `gold.fact_sales`
- `gold.dim_dates`

## SQL Techniques

- Aggregations
- Window functions
- Running totals
- Year-over-year calculations
- Month-over-month calculations
- Date functions

## Expected Output

Examples include:

- Sales KPIs
- Monthly revenue
- Year-over-year growth
- Month-over-month growth
- Sales trends
- Cumulative revenue

## Business Interpretation

Provides a comprehensive view of revenue performance and long-term business growth.

# 4. Order Analysis

## Business Objective

Evaluate order fulfillment efficiency and order performance.

## Business Questions

- How many orders were completed?
- What percentage of orders were delivered?
- How long does delivery take?
- How are orders distributed by value?

## Business Value

Supports:

- Logistics optimization
- Supply chain monitoring
- Delivery performance measurement
- Customer experience improvement

## Grain

Varies by analysis:

- One row per order
- Monthly summaries
- Delivery groups

## Gold Objects Used

- `gold.fact_sales`
- `gold.dim_dates`

## SQL Techniques

- Aggregations
- CASE expressions
- Conditional aggregation
- Date calculations
- Window functions

## Expected Output

Examples include:

- Order KPIs
- Delivery metrics
- Order status distribution
- Delivery time distribution
- Order value distribution

## Business Interpretation

Helps evaluate operational efficiency, delivery performance, and order fulfillment quality.

# 5. Payment Analysis

## Business Objective

Analyze customer payment behavior and payment processing trends.

## Business Questions

- Which payment methods are most popular?
- What is the average payment amount?
- How frequently are installments used?
- How much revenue has been collected?

## Business Value

Supports:

- Payment strategy
- Financial reporting
- Customer payment behavior analysis
- Revenue monitoring

## Grain

Varies by analysis:

- One row per payment transaction
- Monthly summaries
- Payment type

## Gold Objects Used

- `gold.fact_payments`
- `gold.dim_dates`

## SQL Techniques

- Aggregations
- Conditional aggregation
- Window functions
- CASE expressions

## Expected Output

Examples include:

- Payment KPIs
- Payment method distribution
- Installment analysis
- Payment trends

## Business Interpretation

Provides insight into customer payment preferences and financial transaction patterns.

# 6. Customer Satisfaction Analysis

## Business Objective

Measure customer satisfaction using review scores and identify factors affecting customer experience.

## Business Questions

- What is the average customer review score?
- How many positive and negative reviews exist?
- How has customer satisfaction changed over time?
- Which product categories receive the highest ratings?

## Business Value

Supports:

- Customer experience initiatives
- Product quality evaluation
- Category performance assessment
- Service improvement

## Grain

Varies by analysis:

- One row per review
- Monthly summaries
- Product category

## Gold Objects Used

- `gold.fact_reviews`
- `gold.fact_sales`
- `gold.dim_products`
- `gold.dim_dates`

## SQL Techniques

- Aggregations
- Conditional aggregation
- CTEs
- Joins
- Date analysis

## Expected Output

Examples include:

- Review KPIs
- Review score distribution
- Satisfaction trends
- Product category ratings

## Business Interpretation

Identifies strengths and weaknesses in customer experience and helps prioritize product and service improvements.

# 7. KPI Summary

## Business Objective

Provide a consolidated executive dashboard of the most important business metrics.

## Business Questions

- What is the current business performance?
- What are the primary operational KPIs?
- How healthy is the business overall?

## Business Value

Provides executives with a single view of overall business performance for quick decision-making.

## Grain

Single summarized dataset containing one row per KPI.

## Gold Objects Used

- `gold.fact_sales`
- `gold.fact_payments`
- `gold.fact_reviews`
- `gold.dim_customers`
- `gold.dim_dates`

## SQL Techniques

- UNION ALL
- Aggregations
- Conditional aggregation
- Date calculations
- Common Table Expressions (CTEs)

## Expected Output

Examples include:

- Total Revenue
- Total Orders
- Total Customers
- Average Order Value
- Delivered Order Rate
- Average Delivery Days
- Total Amount Paid
- Average Payment Value
- Average Review Score
- Positive Review Rate

## Business Interpretation

The KPI Summary provides an executive-level snapshot of sales performance, operational efficiency, financial activity, and customer satisfaction. It serves as a high-level dashboard for monitoring overall business health and identifying areas that require further investigation.