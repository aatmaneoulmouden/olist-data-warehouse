# Source System Analysis

## Project

**Olist Data Warehouse**

---

# Overview

The Olist E-commerce Dataset is a collection of CSV files representing different business entities within an e-commerce marketplace. Each CSV file models a specific operational process, such as customers, orders, products, sellers, payments, reviews, and geolocation data.

Before designing the data warehouse, it is essential to understand:

* The purpose of each source file
* Primary and foreign keys
* Relationships between entities
* Business processes represented by the data
* The grain (level of detail) of each dataset
* How each source contributes to the Bronze, Silver, and Gold layers

This analysis serves as the foundation for designing the Medallion Architecture and the final dimensional model.

---

# Source System Overview

The Olist dataset models the following business workflow:

```text
Customer
    │
    ▼
Places Order
    │
    ▼
Order Contains Products
    │
    ▼
Seller Ships Products
    │
    ▼
Customer Makes Payment
    │
    ▼
Customer Leaves Review
```

---

# Source Files

---

## 1. Customers

**File**

```text
olist_customers_dataset.csv
```

### Purpose

Stores customer information and location details.

### Primary Key

```text
customer_id
```

### Important Columns

| Column                     | Description                                            |
| -------------------------- | ------------------------------------------------------ |
| `customer_id`              | Customer identifier used by the order system.          |
| `customer_unique_id`       | Permanent identifier representing the actual customer. |
| `customer_zip_code_prefix` | Customer ZIP code prefix.                              |
| `customer_city`            | Customer city.                                         |
| `customer_state`           | Customer state.                                        |

### Notes

* The same customer may have multiple `customer_id` values across different orders.
* `customer_unique_id` identifies the actual customer.

### Gold Destination

```text
dim_customers
```

---

## 2. Orders

**File**

```text
olist_orders_dataset.csv
```

### Purpose

Contains order-level information.

### Primary Key

```text
order_id
```

### Foreign Keys

| Column        | References |
| ------------- | ---------- |
| `customer_id` | Customers  |

### Important Columns

| Column                          | Description                                                                   |
| ------------------------------- | ----------------------------------------------------------------------------- |
| `order_status`                  | Current status of the order (e.g., delivered, shipped, canceled, processing). |
| `order_purchase_timestamp`      | Date and time when the customer placed the order.                             |
| `order_approved_at`             | Date and time when the payment for the order was approved.                    |
| `order_delivered_customer_date` | Date and time when the order was successfully delivered to the customer.      |
| `order_estimated_delivery_date` | Estimated delivery date promised to the customer when the order was placed.   |

### Notes

This table represents only the **order header** and contains general information about each order. It does **not** contain product-level sales details. Product-level information is stored in the `olist_order_items_dataset.csv` table.

### Gold Destination

Used as a supporting source to enrich fact tables (including `fact_sales`, `fact_payments`, and `fact_reviews`) with order dates, status, and lifecycle information.

---

## 3. Order Items

**File**

```text
olist_order_items_dataset.csv
```

### Purpose

Contains every product purchased within an order.

### Business Grain

> One row represents one product sold in one order.

### Composite Key

```text
(order_id, order_item_id)
```

### Foreign Keys

| Column       | References |
| ------------ | ---------- |
| `order_id`   | Orders     |
| `product_id` | Products   |
| `seller_id`  | Sellers    |

### Measures

* `price`
* `freight_value`

### Gold Destination

```text
fact_sales
```

---

## 4. Products

**File**

```text
olist_products_dataset.csv
```

### Purpose

Contains product information.

### Primary Key

```text
product_id
```

### Foreign Keys

| Column                  | References                   |
| ----------------------- | ---------------------------- |
| `product_category_name` | Product Category Translation |

### Important Columns

| Column                  | Description                            |
| ----------------------- | -------------------------------------- |
| `product_category_name` | Category to which the product belongs. |
| `product_weight_g`      | Weight of the product in grams.        |
| `product_length_cm`     | Length of the product in centimeters.  |
| `product_height_cm`     | Height of the product in centimeters.  |
| `product_width_cm`      | Width of the product in centimeters.   |

### Gold Destination

```text
dim_products
```

---

## 5. Product Category Translation

**File**

```text
product_category_name_translation.csv
```

### Purpose

Translates Portuguese product category names into English.

### Primary Key

```text
product_category_name
```

### Notes

* Used to improve readability in analytics.
* Merged into the Product dimension during the Gold transformation.

### Gold Destination

Merged into:

```text
dim_products
```

---

## 6. Sellers

**File**

```text
olist_sellers_dataset.csv
```

### Purpose

Contains seller information.

### Primary Key

```text
seller_id
```

### Important Columns

| Column                   | Description                                                 |
| ------------------------ | ----------------------------------------------------------- |
| `seller_zip_code_prefix` | ZIP code prefix of the seller's business location.          |
| `seller_city`            | City where the seller is located.                           |
| `seller_state`           | Brazilian state (abbreviation) where the seller is located. |

### Gold Destination

```text
dim_sellers
```

---

## 7. Payments

**File**

```text
olist_order_payments_dataset.csv
```

### Purpose

Contains payment information for each order.

### Foreign Keys

| Column     | References |
| ---------- | ---------- |
| `order_id` | Orders     |

### Important Columns

| Column                 | Description                                                                           |
| ---------------------- | ------------------------------------------------------------------------------------- |
| `payment_type`         | Payment method used by the customer (e.g., credit card, debit card, voucher, boleto). |
| `payment_installments` | Number of installments selected by the customer.                                      |
| `payment_value`        | Amount paid using the specified payment method.                                       |

### Notes

An order may have multiple payment records.

Example:

* Credit Card
* Voucher

for the same order.

### Gold Destination

```text
fact_payments
```

---

## 8. Reviews

**File**

```text
olist_order_reviews_dataset.csv
```

### Purpose

Contains customer review information.

### Primary Key

```text
review_id
```

### Foreign Keys

| Column     | References |
| ---------- | ---------- |
| `order_id` | Orders     |

### Important Columns

| Column                    | Description                                                                   |
| ------------------------- | ----------------------------------------------------------------------------- |
| `review_score`            | Customer rating of the order, ranging from **1** (lowest) to **5** (highest). |
| `review_creation_date`    | Date when the customer submitted the review.                                  |
| `review_answer_timestamp` | Date and time when the review became available in the Olist system.           |

### Notes

Reviews are recorded at the **order level**, not the product level. If an order contains multiple products, the dataset does not indicate which specific product the review refers to.

### Gold Destination

```text
fact_reviews
```

---

## 9. Geolocation

**File**

```text
olist_geolocation_dataset.csv
```

### Purpose

Stores geographic information for Brazilian ZIP code prefixes.

### Important Columns

| Column                        | Description                                                       |
| ----------------------------- | ----------------------------------------------------------------- |
| `geolocation_zip_code_prefix` | ZIP code prefix (CEP) representing a geographic region in Brazil. |
| `geolocation_city`            | City associated with the ZIP code prefix.                         |
| `geolocation_state`           | Brazilian state associated with the ZIP code prefix.              |
| `geolocation_lat`             | Latitude coordinate of the ZIP code prefix.                       |
| `geolocation_lng`             | Longitude coordinate of the ZIP code prefix.                      |

### Relationships

Joined using:

```text
customer_zip_code_prefix
```

and

```text
seller_zip_code_prefix
```

### Notes

* This dataset contains many duplicate ZIP code prefixes because multiple latitude/longitude points may exist within the same postal region.
* Duplicates will be resolved in the Silver layer.
* During the Gold transformation, the cleaned geographic attributes (city, state, latitude, and longitude) will be incorporated into the Customer and Seller dimensions rather than creating a separate Geolocation dimension.

### Gold Destination

Merged into:

```text
dim_customers
dim_sellers
```

---

# Source System Relationships

```text
Customers
    │
    │ customer_id
    ▼
Orders
    │
    │ order_id
    ▼
Order Items
    │
    ├────────► Products
    │
    └────────► Sellers

Orders
    │
    ├────────► Payments
    │
    └────────► Reviews

Customers
    │
    └────────► Geolocation

Sellers
    │
    └────────► Geolocation

Products
    │
    └────────► Category Translation
```

---

# Business Grain

Understanding the grain (level of detail) of each source table is essential for designing the data warehouse.

| Source Table | Business Grain                                                         |
| ------------ | ---------------------------------------------------------------------- |
| Customers    | One row per customer record                                            |
| Orders       | One row per order                                                      |
| Order Items  | One row per product within an order                                    |
| Products     | One row per product                                                    |
| Sellers      | One row per seller                                                     |
| Payments     | One row per payment transaction                                        |
| Reviews      | One row per review                                                     |
| Geolocation  | One row per geographic location (contains duplicate ZIP code prefixes) |

---

# Business Entities

A **business entity** is a person, place, thing, or event that is important to the business and about which data is stored.

The Olist source system contains the following business entities:

| Business Entity  | Description                                                         |
| ---------------- | ------------------------------------------------------------------- |
| Customer         | A person who purchases products through the Olist marketplace.      |
| Order            | A purchase transaction containing general order information.        |
| Order Item       | An individual product purchased within an order.                    |
| Product          | An item available for sale.                                         |
| Seller           | A merchant selling products through the marketplace.                |
| Payment          | Payment information associated with an order.                       |
| Review           | Customer feedback submitted after receiving an order.               |
| Geolocation      | Geographic information associated with Brazilian ZIP code prefixes. |
| Product Category | Translation of product categories from Portuguese to English.       |

> **Note:** These entities represent the operational source system. During the ETL process, they will be transformed into an analytical model optimized for reporting and business intelligence.

---

# Gold Layer Mapping

| Source Table                 | Gold Object                                   |
| ---------------------------- | --------------------------------------------- |
| Customers                    | `dim_customers`                               |
| Sellers                      | `dim_sellers`                                 |
| Products                     | `dim_products`                                |
| Product Category Translation | Merged into `dim_products`                    |
| Geolocation                  | Merged into `dim_customers` and `dim_sellers` |
| Orders                       | Supporting source for fact tables             |
| Order Items                  | `fact_sales`                                  |
| Payments                     | `fact_payments`                               |
| Reviews                      | `fact_reviews`                                |

---

# Summary

The Olist dataset follows a transactional e-commerce model where customers place orders containing one or more products sold by sellers. Orders are associated with payments and customer reviews, while products are categorized using translated category names. Geographic information is provided through ZIP code prefixes.

This source system analysis provides the foundation for designing the Bronze, Silver, and Gold layers of the PostgreSQL data warehouse. The operational source entities will be transformed into a dimensional model following a Star Schema, where dimensions describe business entities and fact tables capture key business events such as sales, payments, and customer reviews.
