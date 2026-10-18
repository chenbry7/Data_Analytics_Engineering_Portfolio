# Naming Conventions

## General Rules

Warehouse schemas, tables, views, procedures, and columns use English snake_case names. Source CSV filenames retain their supplied spelling and case. SQL examples qualify warehouse objects with their schema.

## Schemas and Objects

| Object | Pattern | Project examples |
|---|---|---|
| Landing/preparation table | `<source>_<entity>` | `bronze.crm_cust_info`, `silver.erp_cust_az12` |
| Dimension view | `dim_<plural_entity>` | `gold.dim_customers`, `gold.dim_products` |
| Fact view | `fact_<process>` | `gold.fact_sales` |
| Loading procedure | `<layer>.load_<layer>` | `bronze.load_bronze`, `silver.load_silver` |

The source prefix is `crm` or `erp`. The entity part follows the supplied file's domain name, normalized to lowercase; it is not necessarily an exact case-sensitive filename copy. Gold names describe business entities instead of source-system file names. No `gold.load_gold` procedure exists because Gold objects are views.

## Columns

| Role | Convention | Examples |
|---|---|---|
| Source fields | Retain recognizable source prefixes in Bronze/Silver | `cst_id`, `prd_key`, `sls_order_dt` |
| Gold business attributes | Clear analytical names | `first_name`, `product_number`, `sales_amount` |
| Generated dimension keys | Singular entity plus `_key` | `customer_key`, `product_key` |
| Source identifiers | Explicit identifier or business number | `customer_id`, `customer_number`, `product_id`, `product_number` |
| Warehouse metadata | `dwh_` prefix | `dwh_create_date` |

The `_key` suffix identifies the analytical key role, not an enforced primary key. Current generated keys are calculated BIGINT values. `dwh_create_date` is a load timestamp; `create_date` is the customer creation date from CRM.

## Scripts and Reports

Numbered SQL scripts describe setup, load, inspection, or analysis responsibilities. Scripts 13 and 14 are read-only reports, not stored report tables. Documentation uses descriptive English filenames. The [catalog](data_catalog.md) is authoritative for the actual Gold output names, including `maintenance`.
