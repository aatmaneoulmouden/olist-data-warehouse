# Silver Layer

## Purpose and Design Principles

The Silver layer transforms raw Bronze data into trusted, standardized, and validated operational data that serves as the foundation for the Gold layer.

Unlike the Bronze layer, which preserves data exactly as received, the Silver layer improves data quality by applying deterministic data cleansing, data standardization, and data validation while preserving the original business meaning and source-system identifiers.

Silver data is stored in physical PostgreSQL tables and remains organized around the original business entities rather than analytical models. This layer provides trusted operational data for downstream processing, including the creation of dimensional models, fact tables, dimension tables, and analytical views in the Gold layer.

The Silver layer does not perform data integration, data enrichment, dimensional modeling, analytical aggregations, KPI calculations, or other reporting-specific transformations. Those responsibilities belong to the Gold layer.

## Table Naming Convention

Silver tables follow the naming convention:

```text
silver.<source>_<entity>
```

Where:

- `silver` identifies the Medallion layer.
- `olist` identifies the source system.
- Table names remain consistent with their corresponding Bronze tables to simplify data lineage.
- Table names use lowercase letters and underscores.
- Plural nouns are used consistently across all tables.

## Silver Tables

Each Bronze table is transformed into a corresponding Silver table. The Silver layer preserves the same business entities while applying data cleansing, standardization, and validation.

| Silver Table                                  | Source Bronze Table                           |
|-----------------------------------------------|-----------------------------------------------|
| `silver.olist_customers`                      | `bronze.olist_customers`                      |
| `silver.olist_orders`                         | `bronze.olist_orders`                         |
| `silver.olist_order_items`                    | `bronze.olist_order_items`                    |
| `silver.olist_products`                       | `bronze.olist_products`                       |
| `silver.olist_sellers`                        | `bronze.olist_sellers`                        |
| `silver.olist_order_payments`                 | `bronze.olist_order_payments`                 |
| `silver.olist_order_reviews`                  | `bronze.olist_order_reviews`                  |
| `silver.olist_geolocations`                   | `bronze.olist_geolocations`                   |
| `silver.olist_product_category_translations`  | `bronze.olist_product_category_translations`  |

> **Note:** Each Silver table has a one-to-one relationship with its corresponding Bronze table. This design preserves clear data lineage while producing trusted, cleansed, and standardized operational datasets for downstream processing in the Gold layer.

## Transformation Strategy

The Silver layer transforms raw Bronze data through three sequential stages:

1. **Data Cleansing** – Correct objective data quality issues.
2. **Data Standardization** – Apply consistent formats and representations.
3. **Data Validation** – Verify that the transformed data satisfies the documented quality requirements.

Detailed rules for each stage are documented in the following sections.

## Data Cleansing Rules

The Silver layer applies deterministic data cleansing rules to improve data quality while preserving the original business meaning. Only objective corrections are performed. Data that cannot be corrected with confidence is preserved and documented.

### 1. Duplicate Records

Duplicate business records are identified using the documented business key for each entity. When duplicates exist, a single trusted record is retained.

| Table                         | Business Key                          | Rule                                  |
|-------------------------------|---------------------------------------|---------------------------------------|
| Customers                     | `customer_id`                         | Remove duplicate customer records.    |
| Orders                        | `order_id`                            | Remove duplicate orders.              |
| Order Items                   | (`order_id`, `order_item_id`)         | Remove duplicate order items.         |
| Payments                      | (`order_id`, `payment_sequential`)    | Remove duplicate payment records.     |
| Reviews                       | `review_id`                           | Remove duplicate reviews.             |
| Products                      | `product_id`                          | Remove duplicate products.            |
| Sellers                       | `seller_id`                           | Remove duplicate sellers.             |
| Product Category Translations | `product_category_name`               | Remove duplicate translations.        |
| Geolocations                  | `geolocation_zip_code_prefix`         | Remove duplicate ZIP codes.           |

> **Note:** The Silver **geolocations** table is designed with one record per ZIP code prefix to support a one-to-many relationship with both **customers** and **sellers**. Since a single ZIP code prefix can be associated with multiple latitude and longitude values in the source dataset, the `geolocation_lat` and `geolocation_lng` columns are intentionally excluded from the Silver layer. This prevents ambiguous joins and ensures that each customer or seller maps to a single, consistent location record. The original latitude and longitude values are preserved unchanged in the Bronze layer.

### 2. Invalid Values

Invalid values are corrected only when an objective correction can be applied.

| Column            | Cleansing Rule                                                                        |
|-------------------|---------------------------------------------------------------------------------------|
| Timestamp columns | Convert valid values to `TIMESTAMP`. Invalid timestamps are converted to `NULL`.      |
| Numeric columns   | Ensure values use the appropriate numeric data type.                                  |
| Review score      | Validate values fall within the expected range (1–5). Invalid values are documented.  |

### 3. Missing Values

Missing values are handled only when a safe replacement is supported by the business definition.

| Column                        | Rule                                                                  |
|-------------------------------|-----------------------------------------------------------------------|
| `product_name_lenght`         | Replace `NULL` with `0`.                                              |
| `product_description_lenght`  | Replace `NULL` with `0`.                                              |
| `product_photos_qty`          | Replace `NULL` with `0`.                                              |
| All other columns             | Preserve `NULL` values when the correct value cannot be determined.   |

### 4. Unwanted Whitespace

Leading and trailing whitespace is removed from all applicable text columns using `TRIM()`.

### 5. Data Type Conversion

Columns are converted to the appropriate PostgreSQL data type to support consistent processing.

| Column Type           | Target Type                               |
|-----------------------|-------------------------------------------|
| IDs                   | `VARCHAR(32)`                             |
| Date and time         | `TIMESTAMP`                               |
| ZIP code prefixes     | `VARCHAR(5)`                              |
| Numeric attributes    | Appropriate `INTEGER` or `NUMERIC` type   |
| Text attributes       | `VARCHAR(_)` where appropriate            |

### Cleansing Principles

- Preserve the original business meaning of the data.
- Apply only deterministic and repeatable transformations.
- Never guess missing or incorrect business values.
- Correct data only when an objective correction exists.
- Preserve and document anomalies that cannot be objectively corrected.

## Data Standardization Rules

The Silver layer applies data standardization rules to ensure that equivalent values are represented consistently across the dataset. These rules improve comparability, simplify joins and filtering, and reduce inconsistencies caused by differences in capitalization, formatting, or data representation.

| Table                         | Column                            | Standardization Rule |
|-------------------------------|-----------------------------------|---|
| Customers                     | `customer_zip_code_prefix`        | Convert to `VARCHAR(5)` and add leading zeros when necessary. |
| Customers                     | `customer_city`                   | Trim whitespace and apply consistent capitalization using `INITCAP()`. |
| Customers                     | `customer_state`                  | Trim whitespace and convert to uppercase. |
| Orders                        | `order_status`                    | Trim whitespace and convert to lowercase while preserving machine-friendly formats. |
| Order Payments                | `payment_type`                    | Trim whitespace and convert to lowercase while preserving machine-friendly formats. |
| Sellers                       | `seller_zip_code_prefix`          | Convert to `VARCHAR(5)` and add leading zeros when necessary. |
| Sellers                       | `seller_city`                     | Trim whitespace and apply consistent capitalization using `INITCAP()`. |
| Sellers                       | `seller_state`                    | Trim whitespace and convert to uppercase. |
| Geolocations                  | `geolocation_zip_code_prefix`     | Convert to `VARCHAR(5)` and add leading zeros when necessary. |
| Geolocations                  | `geolocation_city`                | Trim whitespace and apply consistent capitalization using `INITCAP()`. |
| Geolocations                  | `geolocation_state`               | Trim whitespace and convert to uppercase. |
| Products                      | `product_category_name`           | Trim whitespace and convert to lowercase while preserving machine-friendly formats. |
| Product Category Translations | `product_category_name`           | Trim whitespace and convert to lowercase while preserving machine-friendly formats. |
| Product Category Translations | `product_category_name_english`   | Trim whitespace and convert to lowercase while preserving machine-friendly formats. |

### Standardization Principles

- Apply the same formatting rule to equivalent columns across different tables.
- Preserve the original semantic meaning of each value.
- Use machine-friendly formats for categorical values.
- Store ZIP code prefixes as text rather than numeric values so leading zeros are preserved.
- Apply deterministic rules that produce the same result every time.
- Avoid translating, expanding, or interpreting values unless the transformation is supported by a documented business requirement.

## Data Validation Strategy

The Silver layer validates transformed data to ensure it meets defined data quality requirements before it is promoted to the Gold layer. Validation identifies records that violate expected quality standards and helps ensure the reliability of downstream analytical models.

### 1. Business Key Validation

Business key validation ensures that each business entity remains uniquely identifiable after the transformation process.

| Table         | Unique Columns                     |
|---------------|------------------------------------|
| Customers     | `customer_id`                      |
| Orders        | `order_id`                         |
| Order Items   | (`order_id`, `order_item_id`)      |
| Payments      | (`order_id`, `payment_sequential`) |
| Reviews       | `review_id`                        |
| Products      | `product_id`                       |
| Sellers       | `seller_id`                        |
| Geolocations  | `geolocation_zip_code_prefix`      |

### 2. Required Value Validation

Required value validation ensures that mandatory business attributes are populated.

| Table         | Required Columns                          |
|---------------|-------------------------------------------|
| Customers     | `customer_id`                             |
| Orders        | `order_id`, `customer_id`, `order_status` |
| Order Items   | `order_id`, `product_id`, `seller_id`     |
| Products      | `product_id`                              |
| Sellers       | `seller_id`                               |

### 3. Domain Validation

Domain validation ensures that values fall within their expected business domain.

| Column                    | Validation Rule                           |
|---------------------------|-------------------------------------------|
| `review_score`            | Must be between **1** and **5**.          |
| `payment_installments`    | Must be greater than or equal to **1**.   |
| `payment_value`           | Must be greater than or equal to **0**.   |
| `price`                   | Must be greater than or equal to **0**.   |
| `freight_value`           | Must be greater than or equal to **0**.   |

### 4. Referential Integrity Validation

Referential integrity validation ensures that relationships between business entities remain valid after the transformation process.

| Child Table   | Parent Table  | Validation Rule                                                       |
|---------------|---------------|-----------------------------------------------------------------------|
| Orders        | Customers     | Every order must reference an existing customer.                      |
| Order Items   | Orders        | Every order item must reference an existing order.                    |
| Order Items   | Products      | Every order item must reference an existing product.                  |
| Order Items   | Sellers       | Every order item must reference an existing seller.                   |
| Payments      | Orders        | Every payment must reference an existing order.                       |
| Reviews       | Orders        | Every review must reference an existing order.                        |
| Customers     | Geolocations  | Every customer ZIP code prefix must exist in the geolocation table.   |
| Sellers       | Geolocations  | Every seller ZIP code prefix must exist in the geolocation table.     |

### 5. Date Validation

Date validation ensures that timestamp values are valid and logically consistent where appropriate.

| Validation Rule                                                                                                                |
|--------------------------------------------------------------------------------------------------------------------------------|
| Verify that all timestamp values are valid and successfully converted to the `TIMESTAMP` data type.                            |
| Verify that delivery dates are not earlier than purchase dates.                                                                |
| Preserve and document timestamp anomalies that cannot be objectively corrected (for example, cancelled order inconsistencies). |

### Validation Principles

- Validate transformed data without altering its original business meaning.
- Apply deterministic and repeatable validation rules.
- Preserve and document anomalies that cannot be objectively corrected.
- Ensure only trusted and validated data is promoted to the Gold layer.

## Silver Table Structure and Constraints

The Silver layer stores cleansed, standardized, and validated operational data while preserving the business grain and source-system identifiers of each entity.

Silver tables use the original business keys, such as `order_id`, `customer_id`, `product_id`, and `seller_id`, as primary and foreign keys.

Before loading data into Silver, a pre-load validation is performed against the Bronze layer to identify issues that could violate Silver constraints, including duplicate business keys, missing required keys, invalid value ranges, and orphaned relationships.

During the Silver load, cleansing and standardization rules resolve objectively correctable issues. Database constraints then act as the final enforcement layer and prevent invalid records from being stored in Silver.

### Constraint Types

| Constraint    | Purpose                                                                                           |
|---------------|---------------------------------------------------------------------------------------------------|
| `PRIMARY KEY` | Uniquely identifies each record and automatically enforces both uniqueness and non-nullability.   |
| `FOREIGN KEY` | Ensures that a child record references an existing parent record.                                 |
| `NOT NULL`    | Prevents required attributes from containing missing values.                                      |
| `CHECK`       | Enforces valid domains, formats, and numeric ranges.                                              |
| `UNIQUE`      | Prevents duplicate values when a column is not used as the primary key.                           |

> A PostgreSQL primary key already includes both `UNIQUE` and `NOT NULL`. These constraints do not need to be declared separately on primary-key columns.

### Silver Table Constraints

#### Customers

**Business grain:** One record per customer order identity.

| Constraint Type   | Column                        | Rule                                                                          |
|-------------------|-------------------------------|-------------------------------------------------------------------------------|
| Primary Key       | `customer_id`                 | Must uniquely identify each customer record.                                  |
| Not Null          | `customer_unique_id`          | Must identify the underlying customer across multiple orders.                 |
| Not Null          | `customer_zip_code_prefix`    | Must contain the customer's ZIP code prefix.                                  |
| Foreign Key       | `customer_zip_code_prefix`    | Must reference an existing ZIP code prefix in `silver.olist_geolocations`.    |
| Check             | `customer_zip_code_prefix`    | Must contain exactly five numeric characters.                                 |
| Not Null          | `customer_city`               | Must contain the standardized customer city.                                  |
| Not Null          | `customer_state`              | Must contain the standardized two-character state code.                       |
| Check             | `customer_state`              | Must contain exactly two uppercase alphabetic characters.                     |

#### Orders

**Business grain:** One record per order.

| Constraint Type   | Column                        | Rule                                                              |
|-------------------|-------------------------------|-------------------------------------------------------------------|
| Primary Key       | `order_id`                    | Must uniquely identify each order.                                |
| Not Null          | `customer_id`                 | Every order must reference a customer.                            |
| Foreign Key       | `customer_id`                 | Must reference an existing customer in `silver.olist_customers`.  |
| Not Null          | `order_status`                | Every order must contain a standardized status.                   |
| Not Null          | `order_purchase_timestamp`    | Every order must contain a purchase timestamp.                    |
| Check             | `order_status`                | Must contain an accepted lowercase order-status value.            |

Recommended order-status domain:

```sql
CHECK
(
    order_status IN
    (
        'approved',
        'canceled',
        'created',
        'delivered',
        'invoiced',
        'processing',
        'shipped',
        'unavailable'
    )
)
```

> Timestamp sequencing should be validated through data-quality queries rather than enforced through database constraints. Canceled or incomplete orders may not follow the normal order lifecycle, and the source does not always provide enough information to objectively correct those anomalies.

#### Order Items

**Business grain:** One record per item within an order.

| Constraint Type   | Column                        | Rule                                                              |
|-------------------|-------------------------------|-------------------------------------------------------------------|
| Primary Key       | `order_id`, `order_item_id`   | Must uniquely identify each item within an order.                 |
| Foreign Key       | `order_id`                    | Must reference an existing order in `silver.olist_orders`.        |
| Check             | `order_item_id`               | Must be greater than zero.                                        |
| Not Null          | `product_id`                  | Every order item must reference a product.                        |
| Foreign Key       | `product_id`                  | Must reference an existing product in `silver.olist_products`.    |
| Not Null          | `seller_id`                   | Every order item must reference a seller.                         |
| Foreign Key       | `seller_id`                   | Must reference an existing seller in `silver.olist_sellers`.      |
| Not Null          | `shipping_limit_date`         | Every order item must contain a shipping-limit timestamp.         |
| Not Null          | `price`                       | Every order item must contain a price.                            |
| Check             | `price`                       | Must be greater than or equal to zero.                            |
| Not Null          | `freight_value`               | Every order item must contain a freight value.                    |
| Check             | `freight_value`               | Must be greater than or equal to zero.                            |

#### Products

**Business grain:** One record per product.

| Constraint Type   | Column                        | Rule                                                                                      |
|-------------------|-------------------------------|-------------------------------------------------------------------------------------------|
| Primary Key       | `product_id`                  | Must uniquely identify each product.                                                      |
| Foreign Key       | `product_category_name`       | Must reference an existing translation in `silver.olist_product_category_translations`.   |
| Check             | `product_name_lenght`         | Must be greater than or equal to zero.                                                    |
| Check             | `product_description_lenght`  | Must be greater than or equal to zero.                                                    |
| Check             | `product_photos_qty`          | Must be greater than or equal to zero.                                                    |
| Check             | `product_weight_g`            | Must be greater than or equal to zero when populated.                                     |
| Check             | `product_length_cm`           | Must be greater than or equal to zero when populated.                                     |
| Check             | `product_height_cm`           | Must be greater than or equal to zero when populated.                                     |
| Check             | `product_width_cm`            | Must be greater than or equal to zero when populated.                                     |

#### Sellers

**Business grain:** One record per seller.

| Constraint Type   | Column                    | Rule                                                                          |
|-------------------|---------------------------|-------------------------------------------------------------------------------|
| Primary Key       | `seller_id`               | Must uniquely identify each seller.                                           |
| Not Null          | `seller_zip_code_prefix`  | Must contain the seller's ZIP code prefix.                                    |
| Foreign Key       | `seller_zip_code_prefix`  | Must reference an existing ZIP code prefix in `silver.olist_geolocations`.    |
| Check             | `seller_zip_code_prefix`  | Must contain exactly five numeric characters.                                 |
| Not Null          | `seller_city`             | Must contain the standardized seller city.                                    |
| Not Null          | `seller_state`            | Must contain the standardized two-character state code.                       |
| Check             | `seller_state`            | Must contain exactly two uppercase alphabetic characters.                     |

#### Payments

**Business grain:** One payment transaction or installment sequence per order.

| Constraint Type   | Column                            | Rule                                                          |
|-------------------|-----------------------------------|---------------------------------------------------------------|
| Primary Key       | `order_id`, `payment_sequential`  | Must uniquely identify each payment record within an order.   |
| Foreign Key       | `order_id`                        | Must reference an existing order in `silver.olist_orders`.    |
| Check             | `payment_sequential`              | Must be greater than zero.                                    |
| Not Null          | `payment_type`                    | Must contain a standardized payment type.                     |
| Check             | `payment_type`                    | Must contain an accepted lowercase machine-friendly value.    |
| Not Null          | `payment_installments`            | Must contain the number of installments.                      |
| Check             | `payment_installments`            | Must be greater than or equal to one.                         |
| Not Null          | `payment_value`                   | Must contain the payment amount.                              |
| Check             | `payment_value`                   | Must be greater than or equal to zero.                        |

Recommended payment-type domain:

```sql
CHECK
(
    payment_type IN
    (
        'boleto',
        'credit_card',
        'debit_card',
        'not_defined',
        'voucher'
    )
)
```

#### Reviews

**Business grain:** One record per review.

| Constraint Type   | Column            | Rule                                                          |
|-------------------|-------------------|---------------------------------------------------------------|
| Primary Key       | `review_id`       | Must uniquely identify each review.                           |
| Not Null          | `order_id`        | Every review must reference an order.                         |
| Foreign Key       | `order_id`        | Must reference an existing order in `silver.olist_orders`.    |
| Not Null          | `review_score`    | Every review must contain a score.                            |
| Check             | `review_score`    | Must be between 1 and 5.                                      |

Review title, review message, answer timestamp, and creation timestamp may remain nullable because the source business process does not require every review to contain those values.

#### Geolocations

**Business grain:** One record per ZIP code prefix.

| Constraint Type   | Column                        | Rule                                                      |
|-------------------|-------------------------------|-----------------------------------------------------------|
| Primary Key       | `geolocation_zip_code_prefix` | Must uniquely identify each standardized ZIP code prefix. |
| Check             | `geolocation_zip_code_prefix` | Must contain exactly five numeric characters.             |
| Not Null          | `geolocation_city`            | Must contain the canonical standardized city.             |
| Not Null          | `geolocation_state`           | Must contain the standardized two-character state code.   |
| Check             | `geolocation_state`           | Must contain exactly two uppercase alphabetic characters. |

The Silver geolocation table intentionally excludes latitude and longitude because a single ZIP code prefix may contain multiple coordinate combinations in the Bronze data. Since customers and sellers reference only the ZIP code prefix, retaining multiple coordinate records would create ambiguous one-to-many joins.

#### Product Category Translations

**Business grain:** One record per Portuguese product category name.

| Constraint Type   | Column                            | Rule                                                  |
|-------------------|-----------------------------------|-------------------------------------------------------|
| Primary Key       | `product_category_name`           | Must uniquely identify each source product category.  |
| Not Null          | `product_category_name_english`   | Must contain the corresponding English category name. |

### Foreign-Key Load Order

Because Silver tables enforce foreign-key constraints, they must be loaded in dependency order.

```text
1. Geolocations
2. Customers
3. Sellers
4. Products
5. Product Category Translations
6. Orders
7. Order Items
8. Payments
9. Reviews
```

The exact order of independent tables may vary, but all parent tables must be loaded before their dependent child tables.

For example:

- Geolocations must be loaded before customers and sellers.
- Customers must be loaded before orders.
- Orders, products, and sellers must be loaded before order items.
- Orders must be loaded before payments and reviews.

### Constraint Enforcement Strategy

Silver constraints are not intended to replace data validation. They provide the final protection against invalid data.

The Silver loading process follows this sequence:

```text
Bronze data
    │
    ▼
Pre-load constraint validation
    │
    ▼
Data cleansing and standardization
    │
    ▼
Load into constrained Silver tables
    │
    ▼
Post-load data validation
    │
    ▼
Gold layer
```

#### Pre-load Validation

Before loading, the Bronze data is checked for conditions that could violate Silver constraints:

- Duplicate primary or composite business keys.
- `NULL` business keys.
- Missing required attributes.
- Invalid domain values.
- Invalid numeric ranges.
- Missing parent records.

#### Constraint Enforcement

During loading, PostgreSQL constraints prevent invalid records from being stored. A constraint violation should cause the load transaction to fail rather than silently produce an incomplete Silver table.

#### Post-load Validation

After loading, validation queries verify:

- Expected records were loaded.
- No duplicate business keys exist.
- Required values are present.
- Domain and range rules are satisfied.
- Referential relationships are complete.
- Standardization rules were correctly applied.
- Source-to-target row reconciliation is explainable.

## Silver Metadata Columns

Each Silver table includes metadata columns to support data lineage, auditing, and operational monitoring. These columns are managed by the data warehouse and are not part of the original source data.

| Column                | Data Type     | Description                                                                   |
|-----------------------|---------------|-------------------------------------------------------------------------------|
| `dwh_load_timestamp`  | `TIMESTAMP`   | Records the date and time when the record was loaded into the Silver layer.   |


## Load Strategy

The Silver layer uses a **full-load** strategy.

During each load, the target Silver tables are truncated and then reloaded from the Bronze layer using PostgreSQL `INSERT INTO ... SELECT` statements.

This strategy was selected because the Olist dataset is relatively small and static. Rebuilding the Silver layer during each execution is simple, reliable, and appropriate for this project.

The full-load approach also avoids unnecessary complexity such as change detection, merge logic, and incremental load tracking.

The Silver loading process follows this workflow:

```text
PRE-LOAD VALIDATION
        ↓
TRUNCATE SILVER TABLES
        ↓
TRANSFORM BRONZE DATA
        ↓
INSERT INTO SILVER TABLES
        ↓
POST-LOAD VALIDATION
        ↓
LOAD COMPLETE
```

## SQL Script Organization

Silver layer SQL scripts are organized into multiple files based on responsibility. This approach improves readability, maintainability, and scalability as the project grows.

Folder structure:

```text
sql/
└── 03_silver/
    ├── 01_ddl_silver.sql
    ├── 02_load_silver.sql
    └── 03_validate_silver.sql
```

| Script                    | Purpose                                                                                                              |
|---------------------------|----------------------------------------------------------------------------------------------------------------------|
| `01_ddl_silver.sql`       | Creates the Silver tables and applies the required primary key, foreign key, `NOT NULL`, and `CHECK` constraints.    |
| `02_load_silver.sql`      | Defines the Silver loading procedure using `INSERT INTO ... SELECT` statements to cleanse and standardize Bronze data. |
| `03_validate_silver.sql`  | Contains pre-load and post-load validation queries to verify constraints, data quality, referential integrity, and row counts. |

Numeric prefixes indicate the recommended execution order of the scripts.

## Summary

The Silver layer transforms the raw Bronze data into trusted operational datasets by applying data cleansing, data standardization, and data validation while preserving the original business entities and source-system identifiers.

This layer introduces relational integrity through primary keys, foreign keys, and database constraints, ensuring that downstream processes operate on consistent and reliable data.

The Silver layer serves as the foundation for the Gold layer, where the cleansed and validated operational data will be transformed into dimensional models, fact tables, dimension tables, and business-ready analytical datasets.