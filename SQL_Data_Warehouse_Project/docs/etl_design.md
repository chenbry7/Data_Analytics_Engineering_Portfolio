# ETL Design

## End-to-End Processing

Extraction selects records from a source, transformation changes their representation or meaning, and loading writes them into a target. Here the provided files are already extracts: the repository implements their ingestion and subsequent SQL transformation, not live source extraction.

```mermaid
flowchart LR
  F[Supplied CSV extracts] -->|Load: BULK INSERT| B[Bronze tables]
  B -->|Read and transform| S[Silver tables]
  S -->|Integrate at query time| G[Gold views]
  G -->|Aggregate at query time| R[SQL reports]
```

The system mixes loading and transformation across boundaries. It should not be interpreted as a single monolithic ETL job or as a streaming pipeline. Script 09 invokes Bronze and then Silver; Gold view definitions are deployed separately.

## Method Choices

| Topic | Options | Current implementation |
|---|---|---|
| Extraction scope | Full extract or changed records | Supplied complete files; no incremental contract |
| Extraction direction | Pull by consumer or push by source | Files already supplied; no operational push/pull integration |
| Extraction technique | Query, file parsing, API, event stream, CDC, web extraction | File ingestion only |
| Processing mode | Batch or stream | Batch |
| Full load | Truncate/insert, replace target, or synchronize full snapshot | Truncate then insert |
| Incremental load | Append new records or update/insert changed keys with deletion rules | Not implemented |
| Dimension changes | Preserve original values, overwrite current values, or add dated versions | Current customer/product views; no persistent SCD mechanism |

SCD Type 0 retains original attributes; Type 1 overwrites attributes without retaining versions; Type 2 stores versions with validity boundaries. Current refreshed views provide a current-state analytical model, but they do not implement persisted Type 1 updates or Type 2 version management. Silver's derived product end dates are not sufficient to claim Gold SCD2.

## Implemented Transformation Matrix

| Target | Rule | Reason / limitation |
|---|---|---|
| `silver.crm_cust_info` | Exclude null `cst_id`; choose latest `cst_create_date` per ID using `ROW_NUMBER` | Deduplication; equal dates lack a deterministic tie-breaker |
| Customer names | `TRIM` first/last names | Remove surrounding whitespace |
| Marital status | S → Single, M → Married, otherwise n/a | Standardized categories |
| CRM gender | F → Female, M → Male, otherwise n/a | Standardized categories |
| `silver.crm_prd_info.cat_id` | First five source key characters; replace hyphen with underscore | Match ERP category identifiers |
| Product business key | Source key substring starting at position seven | Match sales product keys |
| Product cost | Null → 0 | Preserves the implemented policy; zero is not evidence of a known actual cost |
| Product line | M/R/S/T → Mountain/Road/Other Sales/Touring; otherwise n/a | Standardized categories |
| Product validity | Cast start date to DATE; derive end as next start minus one day using `LEAD` | Source product history representation; duplicate starts need review |
| Sales dates | `TRY_CONVERT(DATE, CONVERT(VARCHAR(10), value), 112)` | Invalid/missing dates or values outside 1900-01-01 through 2050-01-01 become null |
| Sales amount | If null, nonpositive, or inconsistent with quantity × absolute price, derive quantity × absolute price | Uses original fields; unresolved cases must remain visible in quality results |
| Unit price | If null or nonpositive, derive sales / `NULLIF(quantity,0)` | Integer arithmetic; zero quantity yields null; original inputs can conflict |
| ERP customer ID | Remove leading NAS when present | Align with CRM customer number |
| ERP birthdate | Future birthdate → null | Uses execution date as the comparison boundary |
| ERP gender | Normalize M/Male and F/Female; otherwise n/a | Comparison follows database collation; input is uppercased |
| ERP location ID | Remove hyphens | Align with CRM customer number |
| Country | DE → Germany; US/USA/United States → United States; blank/null → n/a; trim other values | Limited explicit normalization map |
| ERP category records | Copy id, category, subcategory, maintenance | No additional category cleanup in this procedure |
| All Silver tables | Default `dwh_create_date` on insert | Load timestamp, not a source history timestamp |
| Gold customers | Join CRM to ERP on normalized identifiers; prefer CRM gender unless n/a, otherwise ERP fallback | Customer enrichment; source null handling follows the implemented CASE |
| Gold products | Join category on cat_id=id; keep end date null | Current-product analytical attributes |
| Gold dimension keys | `ROW_NUMBER()` over documented order | BIGINT, recalculated, not durable |
| Gold sales | LEFT JOIN business keys to dimension views | Preserve unmatched source sales but expose null dimension keys; duplicates can multiply rows |

## Cleaning Techniques and Boundaries

The implementation includes deduplication, filtering, whitespace trimming, missing-value handling, invalid-value handling, type conversion, standardization, derived columns, and enrichment. It does not implement statistical outlier detection. A high sales value should not be removed merely because it is unusual; it needs a business rule and supporting evidence.

Aggregation is performed by analysis queries, not the core Gold fact view. Country/code standardization is distinct from relational normalization into additional tables. The project does not convert Silver to a normalized enterprise core.

## Error Handling and Validation

Bronze wraps ingestion in TRY/CATCH, prints diagnostic details, and rethrows the original error. Script 09 therefore stops on a Bronze failure rather than proceeding normally to Silver. Successful earlier loads are not automatically rolled back. Silver has no multi-table atomic publication mechanism.

The [quality scorecard](../scripts/13_data_quality_summary.sql) exposes source problems, incomplete cleaned dates, inconsistent amounts, key uniqueness, unmatched dimensions, and row-count reconciliation. It does not silently repair remaining issues or automatically block a report. [Focused regression checks](../tests/extension_checks.sql) cover calendar conversion and important analysis denominators.
