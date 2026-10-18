# Dataset Inventory

The warehouse loads six supplied CSV extracts. CRM/ERP labels identify dataset domains rather than live system connections. Records are used for this sales analysis example; the repository does not establish source-system ownership, consent, or a production extraction agreement.

Field definitions appear in the [source/Silver catalog](../docs/source_data_catalog.md). The loader expects a header row, comma-separated fields, and the checked-in column order. Files use CRLF line endings and include a final record terminator. Normalizing final line terminators does not change field values.

| File | Data records | Columns | Bytes |
|---|---:|---:|---:|
| [cust_info.csv](source_crm/cust_info.csv) | 18,494 | 7 | 855,397 |
| [prd_info.csv](source_crm/prd_info.csv) | 397 | 7 | 26,934 |
| [sales_details.csv](source_crm/sales_details.csv) | 60,398 | 9 | 3,588,116 |
| [CUST_AZ12.csv](source_erp/CUST_AZ12.csv) | 18,484 | 3 | 561,551 |
| [LOC_A101.csv](source_erp/LOC_A101.csv) | 18,484 | 2 | 402,669 |
| [PX_CAT_G1V2.csv](source_erp/PX_CAT_G1V2.csv) | 37 | 4 | 1,171 |

Counts exclude headers. Customer files contain duplicate/missing identifiers and sales files contain date/amount issues intentionally handled or reported by the warehouse. Source files remain separate from cleaned database output. Do not infer that all profile values represent verified real individuals or that this project supplies additional rights in the underlying dataset.
