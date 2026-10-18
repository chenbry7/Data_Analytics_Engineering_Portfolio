# SQL Script Index

Each numbered script has a defined role. The numbering identifies files; it is not the recommended execution order. Follow the [first-run sequence](../README.md#first-run) for setup and the [operating workflow](../docs/development_workflow.md) for refreshes.

| Script | Role | Purpose | Effect |
|---|---|---|---|
| [01_create_database_and_schema.sql](01_create_database_and_schema.sql) | Initial setup | Drops and recreates the learning database; creates three schemas | DDL; destructive reset |
| [02_empty_tables_bronze.sql](02_empty_tables_bronze.sql) | Initial setup | Recreates the six Bronze tables | DDL; replaces tables |
| [03_bronze_procedure.sql](03_bronze_procedure.sql) | Definition deployment | Creates or alters the configured Bronze loader | Procedure definition |
| [04_load_tables_bronze.sql](04_load_tables_bronze.sql) | Optional source inspection | Executes the Bronze loader alone | Replaces Bronze data |
| [05_empty_tables_silver.sql](05_empty_tables_silver.sql) | Initial setup | Recreates the six Silver tables | DDL; replaces tables |
| [06_bronze_data_quality.sql](06_bronze_data_quality.sql) | Source diagnostics | Inspects source keys, codes, dates, amounts, and relationships | Read-only |
| [07_bronze_trans_to_silver.sql](07_bronze_trans_to_silver.sql) | Definition deployment | Creates or alters the Silver transformation procedure | Procedure definition |
| [08_silver_data_quality.sql](08_silver_data_quality.sql) | Cleaned-data diagnostics | Inspects cleaned Silver records and relationships | Read-only |
| [09_ETL_procedure_scripts.sql](09_ETL_procedure_scripts.sql) | Recurring refresh | Loads Bronze, then Silver | Replaces Bronze and Silver data |
| [10_gold_layer.sql](10_gold_layer.sql) | Definition deployment | Creates or alters customer, product, and sales views | View definitions |
| [11_gold_data_integration.sql](11_gold_data_integration.sql) | Integration diagnostics | Inspects CRM/ERP gender precedence | Read-only |
| [12_gold_data_quality.sql](12_gold_data_quality.sql) | Model diagnostics | Inspects dimensions and unresolved fact relationships | Read-only |
| [13_data_quality_summary.sql](13_data_quality_summary.sql) | Quality reporting | Returns issue counts with PASS, REVIEW, or FAIL status | Read-only |
| [14_sales_analysis.sql](14_sales_analysis.sql) | Business reporting | Returns monthly, category, repeat-buyer, and coverage results | Read-only |

Scripts 03 and 07 define loaders without executing them. Script 09 invokes both loaders; script 04 is unnecessary in that same refresh sequence. Script 10 deploys views rather than loading Gold tables. All numbered scripts explicitly select the DataWarehouse database; script 01 also uses master for database reset.

Run the [warehouse assertions](../tests/warehouse_checks.sql) after loading and creating the views. The [focused regression checks](../tests/extension_checks.sql) use table variables and do not require loaded warehouse records. [Verified execution results](../docs/validation.md) document the supplied dataset and remaining limitations.
