# Source System Analysis

## Business Context and Ownership

The business process is sales ordering and fulfillment. CRM provides customer profiles, product records, and sales details. ERP provides additional customer attributes, locations, and product categories. These labels describe dataset domains; this repository connects to supplied files rather than operational CRM/ERP services.

Bryan Chen maintains the warehouse implementation and documentation. Production data owners, source-system experts, extraction contacts, and service-level agreements are not specified by the supplied files. No source-system interviews are claimed.

## Source Interface and File Scope

| Source | File | Analytical role | Bronze / Silver object |
|---|---|---|---|
| CRM | `cust_info.csv` | Customer identity and profile | `crm_cust_info` |
| CRM | `prd_info.csv` | Product attributes and dated versions | `crm_prd_info` |
| CRM | `sales_details.csv` | Sales source records | `crm_sales_details` |
| ERP | `CUST_AZ12.csv` | Birthdate and gender enrichment | `erp_cust_az12` |
| ERP | `LOC_A101.csv` | Customer country | `erp_loc_a101` |
| ERP | `PX_CAT_G1V2.csv` | Product category hierarchy | `erp_px_cat_g1v2` |

The integration interface is CSV files in `datasets/source_crm/` and `datasets/source_erp/`. There are no configured APIs, Kafka topics, direct database extracts, or change feeds. CSV headers and physical field definitions are in the [source catalog](source_data_catalog.md).

## Extraction and Loading Contract

| Question | Current answer |
|---|---|
| Full or incremental? | Complete supplied file sets; full Bronze and Silver refresh |
| Batch or streaming? | Manually executed batch procedures |
| Historical scope? | Only the records in supplied files; previous file versions are not archived by the loader |
| Expected size? | Checked-in file profile below; no guaranteed future extract size |
| Volume limits? | No configured row threshold or scalability benchmark; server capacity must be evaluated for larger inputs |
| Impact on live source systems? | No live extraction occurs; the project loads files |
| Authentication? | SQL Server authentication is configured by the operator; local verification used Windows integrated authentication |
| File authorization? | The SQL Server service account must be able to read the configured server-side file location |
| Secrets? | No API tokens, SSH keys, VPN settings, or passwords are needed by the file interface; credentials must not be committed |
| Refresh schedule? | On demand; no automated schedule or freshness SLA |

## Checked-in File Profile

Counts exclude the CSV header and were measured from the repository files. They describe the file snapshot, not guaranteed loaded-table counts.

| File | Data records | Bytes |
|---|---:|---:|
| `datasets/source_crm/cust_info.csv` | 18,494 | 855,397 |
| `datasets/source_crm/prd_info.csv` | 397 | 26,934 |
| `datasets/source_crm/sales_details.csv` | 60,398 | 3,588,116 |
| `datasets/source_erp/CUST_AZ12.csv` | 18,484 | 561,551 |
| `datasets/source_erp/LOC_A101.csv` | 18,484 | 402,669 |
| `datasets/source_erp/PX_CAT_G1V2.csv` | 37 | 1,171 |

## Source Review Checklist

Before using a different extract, confirm delimiter, encoding, header order, null representation, date format, candidate key behavior, and embedded delimiter handling. Inspect whether source key normalization creates collisions. Confirm whether absence from a later file means deletion or incomplete extraction; the current full-refresh loader does not distinguish these cases.

Product history exists as dated source records, but that does not establish complete customer or product change history. Validate date boundaries before attempting historical analysis. Treat personal profile fields such as birthdates as data requiring appropriate access control in a real deployment.
