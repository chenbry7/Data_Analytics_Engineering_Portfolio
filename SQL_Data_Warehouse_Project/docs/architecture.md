# Warehouse Architecture and Data Model

This SQL Server project integrates CRM and ERP sales data through Bronze, Silver, and Gold schemas. The design separates source ingestion, data preparation, and analytical access. The diagrams describe the implemented SQL; planned capabilities are identified separately. Mermaid diagrams render directly in this document on GitHub.

## Architecture

Six CSV files feed six Bronze tables. Stored procedures refresh Bronze and Silver in batches. Gold exposes two dimension views and one fact view. Business intelligence integration is a planned extension.

```mermaid
flowchart LR
  CSV[CRM + ERP: six CSV files] -->|BULK INSERT| B[Bronze: six tables]
  B -->|silver.load_silver| S[Silver: six cleaned tables]
  S --> G[Gold: three analytical views]
  G --> Q[SQL analysis]
  G -. proposed .-> BI[BI dashboard]
```


## Data Lineage

The customer dimension combines CRM customer profiles with ERP demographics and locations. The product dimension combines current CRM product records with ERP categories. The sales fact view resolves customer and product keys through the dimension views.

The diagram shows source-to-target lineage and the dimension lookups used by the fact view.

```mermaid
flowchart LR
  F0["CRM / cust_info.csv"] --> B0["bronze.crm_cust_info"] --> S0["silver.crm_cust_info"]
  F1["CRM / prd_info.csv"] --> B1["bronze.crm_prd_info"] --> S1["silver.crm_prd_info"]
  F2["CRM / sales_details.csv"] --> B2["bronze.crm_sales_details"] --> S2["silver.crm_sales_details"]
  F3["ERP / CUST_AZ12.csv"] --> B3["bronze.erp_cust_az12"] --> S3["silver.erp_cust_az12"]
  F4["ERP / LOC_A101.csv"] --> B4["bronze.erp_loc_a101"] --> S4["silver.erp_loc_a101"]
  F5["ERP / PX_CAT_G1V2.csv"] --> B5["bronze.erp_px_cat_g1v2"] --> S5["silver.erp_px_cat_g1v2"]
  S0 --> C[gold.dim_customers]
  S3 --> C
  S4 --> C
  S1 --> P[gold.dim_products]
  S5 --> P
  S2 --> F[gold.fact_sales]
  C -->|customer_id lookup| F
  P -->|product_number lookup| F
```


## Integration and Key Standardization

Gold joins operate on cleaned Silver records. The first five characters of the original product key form `cat_id`, with hyphens replaced by underscores. Characters from position seven onward form the product business key. ERP customer identifiers are standardized by removing the `NAS` prefix or hyphens, depending on the source.

CRM gender values take precedence unless classified as `n/a`; ERP supplies the fallback value.

```mermaid
flowchart LR
  SD[silver.crm_sales_details] -->|sls_cust_id = cst_id| CI[silver.crm_cust_info]
  SD -->|sls_prd_key = prd_key| PI[silver.crm_prd_info]
  CI -->|cst_key = cid| CA[silver.erp_cust_az12]
  CI -->|cst_key = cid| LA[silver.erp_loc_a101]
  PI -->|cat_id = id| PC[silver.erp_px_cat_g1v2]
```


## Logical Star Schema

The sales mart consists of three views. Relationships represent intended logical cardinality, rather than enforced primary or foreign key constraints. Dimension business-key uniqueness and unmatched fact records require validation.

The fact grain is one Silver sales source record. `order_number` identifies an order, not a unique line. Uniqueness of an order-product combination must be established before using it as a line identifier.

```mermaid
erDiagram
  DIM_CUSTOMERS ||--o{ FACT_SALES : "customer_key (logical)"
  DIM_PRODUCTS ||--o{ FACT_SALES : "product_key (logical)"
  DIM_CUSTOMERS {
    bigint customer_key
    int customer_id
    nvarchar customer_number
    nvarchar first_name
    nvarchar last_name
    nvarchar country
    nvarchar marital_status
    nvarchar gender
    date birthdate
    date create_date
  }
  DIM_PRODUCTS {
    bigint product_key
    int product_id
    nvarchar product_number
    nvarchar product_name
    nvarchar category_id
    nvarchar category
    nvarchar subcategory
    nvarchar maintenance
    int cost
    nvarchar product_line
    date start_date
  }
  FACT_SALES {
    nvarchar order_number
    bigint product_key
    bigint customer_key
    date order_date
    date shipping_date
    date due_date
    int sales_amount
    int quantity
    int price
  }
```


## Layer Responsibilities

Bronze uses typed landing tables and full refreshes. It preserves source-shaped records, but does not retain arbitrary raw bytes or previous file snapshots. Silver standardizes values, derives product validity dates, and adds load timestamps. Gold integrates the cleaned records for analysis.

Deriving product end dates in Silver does not provide historical dimension tracking in Gold: the product view selects only current records.

```mermaid
flowchart LR
  B["Bronze | 6 typed tables | full load | source landing"] --> S["Silver | 6 tables | full load | cleaning + metadata"]
  S --> G["Gold | 3 views | no load | integration + analytical model"]
```


## Execution and Validation

Database setup, procedure definition, data refresh, and analytical view creation are separate operations. `09_ETL_procedure_scripts.sql` loads both layers. `04_load_tables_bronze.sql` is an optional Bronze-only operation and is not required for the normal combined refresh. Quality scripts return results for manual inspection, including the consolidated scorecard in script 13. Script 14 provides sales analysis.

`10_gold_layer.sql` uses rerunnable view definitions in separate batches. Bronze errors propagate to the caller, and invalid sales dates become null during Silver conversion. See [project extensions](project_extensions.md) for the scorecard, analytical queries, and focused regression checks.

```mermaid
flowchart TD
  A[01 reset learning database] --> B[02 + 05 define tables]
  B --> C[03 + 07 define loaders]
  C --> D[09 refresh Bronze then Silver]
  D --> E[10 create or alter Gold views]
  E --> F[13 inspect quality scorecard]
  F --> G[Run warehouse assertions and investigate issues]
  G --> H[14 sales analysis]
  D -. optional detail .-> I[06 + 08 + 11 + 12 diagnostics]
```


## Modeling Decisions and Limitations

- `ROW_NUMBER()` produces `bigint` keys that are recalculated from the underlying data. These are not persisted identifiers and should not be stored externally as stable references.
- Customer deduplication retains the latest creation date per `cst_id`. Equal dates do not have a deterministic tie-breaker.
- Gold products are restricted to `prd_end_dt IS NULL`. Historical sales therefore use current product attributes. A missing current product can leave the fact product key null because the fact uses a left join.
- The product view exposes `maintenance`, as documented in the [data catalog](data_catalog.md).
- Monetary fields currently use `int`. Currency and rounding policy are not defined. Current product cost is insufficient to establish historical transaction profit.
- Diagram cardinalities describe the intended model; runtime validation results are not included.

## Implementation References

| Component | Source |
|---|---|
| Bronze ingestion | [03_bronze_procedure.sql](../scripts/03_bronze_procedure.sql) |
| Silver structure | [05_empty_tables_silver.sql](../scripts/05_empty_tables_silver.sql) |
| Silver transformations | [07_bronze_trans_to_silver.sql](../scripts/07_bronze_trans_to_silver.sql) |
| Refresh sequence | [09_ETL_procedure_scripts.sql](../scripts/09_ETL_procedure_scripts.sql) |
| Analytical model | [10_gold_layer.sql](../scripts/10_gold_layer.sql) |
| Gold validation | [12_gold_data_quality.sql](../scripts/12_gold_data_quality.sql) |

Mermaid diagrams are maintained directly in this document. Update the relevant diagram whenever the implemented architecture or relationships change.

See the [documentation index](README.md) for design concepts, source analysis, layer workflows, and analytical patterns.
