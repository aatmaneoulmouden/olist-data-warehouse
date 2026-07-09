# Bronze Layer

The Bronze layer is responsible for storing raw source data exactly as received from the source CSV files. In this project, Bronze objects are implemented as physical PostgreSQL tables. No business transformations are applied during data ingestion. This layer preserves the original source data for auditing, troubleshooting, reprocessing, and comparison against later transformation layers.

## Table Naming Convention

Bronze tables follow the naming convention:

```text
bronze.<source>_<entity>
```

Where:

- `bronze` identifies the Medallion layer.
- `olist` identifies the source system.
- The table name closely matches the original source dataset.
- Table names use lowercase letters and underscores.
- Plural nouns are used consistently across all tables.
- The `_dataset` suffix from the source CSV filenames is omitted for readability.

### Naming Exception

The source file `product_category_name_translation.csv` is represented in the Bronze layer as:

`bronze.olist_product_category_translations`

This name was chosen to improve readability while preserving the meaning of the source dataset. The `_name_` portion was omitted because the table represents translations of product categories rather than category name values, and the `_dataset` suffix was removed as part of the standard naming convention.

## Bronze Tables

Each source CSV file is loaded into a corresponding Bronze table. The Bronze layer preserves the raw structure of the source data, with no business transformations applied during ingestion.

| Bronze Table                                  | Source File                               |
|-----------------------------------------------|-------------------------------------------|
| `bronze.olist_customers`                      | `olist_customers_dataset.csv`             |
| `bronze.olist_orders`                         | `olist_orders_dataset.csv`                |
| `bronze.olist_order_items`                    | `olist_order_items_dataset.csv`           |
| `bronze.olist_products`                       | `olist_products_dataset.csv`              |
| `bronze.olist_sellers`                        | `olist_sellers_dataset.csv`               |
| `bronze.olist_order_payments`                 | `olist_order_payments_dataset.csv`        |
| `bronze.olist_order_reviews`                  | `olist_order_reviews_dataset.csv`         |
| `bronze.olist_geolocations`                   | `olist_geolocation_dataset.csv`           |
| `bronze.olist_product_category_translations`  | `product_category_name_translation.csv`   |

> **Note:** Each Bronze table has a one-to-one relationship with its corresponding source CSV file. This design preserves the original source data and simplifies data ingestion, auditing, troubleshooting, and reprocessing.

## Bronze Table Structure and Data Types

Bronze tables preserve the same column structure as the source CSV files. No source columns are renamed, removed, merged, or transformed during ingestion.

The Bronze layer does not enforce primary keys, foreign keys, `NOT NULL` constraints, or business validation rules. This allows the raw data to be loaded exactly as received, even if it contains duplicate records, missing values, or referential integrity issues.

Data types are aligned with the source data and mapped to appropriate PostgreSQL data types. This ensures that the raw source values are stored efficiently without changing their business meaning. No business logic, data cleansing, validation, or standardization is performed in the Bronze layer. These transformations are handled in the Silver layer.

## Metadata Columns

Bronze tables include the following technical metadata column:

| Column                | Data Type     | Purpose                                                   |
|-----------------------|---------------|-----------------------------------------------------------|
| `dwh_load_timestamp`  | `TIMESTAMP`   | Records when the row was loaded into the Bronze layer.    |

Because the Bronze layer uses a **full-load** strategy, a `batch_id` is not required. Each load truncates and reloads the table, so multiple batches never coexist in the same Bronze table.

The `source_file_name` column is also not required for this project because each Bronze table maps directly to one known source CSV file, and the table naming convention clearly identifies the source dataset.

## Load Strategy

The Bronze layer uses a **full-load** strategy.

During each load, the target Bronze table is truncated and then reloaded from the corresponding source CSV file using PostgreSQL's native `COPY` command.

This strategy was selected because the Olist dataset is provided as complete CSV snapshots rather than incremental change files. Since the dataset is relatively small and static, reloading the full dataset is simple, reliable, and efficient for this project.

The full-load approach also avoids unnecessary complexity such as change detection, merge logic, and incremental load tracking. These techniques are more appropriate for production systems where source data changes frequently or where only new and updated records are received.

The Bronze loading process follows this workflow:

```text
TRUNCATE TABLE
        ↓
COPY CSV INTO BRONZE TABLE
        ↓
LOAD COMPLETE
```

## SQL Script Organization

Bronze layer SQL scripts are organized into multiple files based on responsibility. This approach improves readability, maintainability, and scalability as the project grows.

Folder structure:

```text
sql/
└── 02_bronze/
    ├── 01_ddl_bronze.sql
    ├── 02_load_bronze.sql
    └── 03_validate_bronze.sql
```

| Script                    | Purpose                                                                                           |
|---------------------------|---------------------------------------------------------------------------------------------------|
| `01_ddl_bronze.sql`       | Creates the Bronze tables.                                                                        |
| `02_load_bronze.sql`      | Defines the Bronze loading procedure using PostgreSQL's `COPY` command.                           |
| `03_validate_bronze.sql`  | Contains SQL validation queries to verify row counts, duplicate records, and basic load quality.  |

Numeric prefixes indicate the recommended execution order of the scripts.

## Summary

The Bronze layer serves as the raw data ingestion layer of the Olist Data Warehouse. It preserves the source data exactly as received by storing it in physical PostgreSQL tables with source-aligned data types and minimal technical metadata. No business transformations or data quality rules are applied in this layer. Data is loaded using a full-load strategy with PostgreSQL's native `COPY` command, providing a reliable foundation for downstream processing in the Silver and Gold layers.