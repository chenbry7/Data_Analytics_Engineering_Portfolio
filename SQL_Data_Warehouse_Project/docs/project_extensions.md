# Independent Project Extensions

The project uses a SQL Server Bronze/Silver/Gold architecture with reliability improvements, a consolidated data quality scorecard, and business analysis using CTEs, aggregations, and window functions.

## 1. Reliability Improvements

| Change | Reason | Implementation |
|---|---|---|
| Rerunnable Gold view definitions | View creation must start a batch; repeated deployment should update definitions | Script 10 uses `CREATE OR ALTER VIEW` with `GO` between views |
| Propagate Bronze loading errors | A printed error alone can allow the caller to continue into Silver | Script 03 rethrows the original error with `THROW` |
| Calendar-aware date conversion | Eight digits do not guarantee a valid or plausible date | Script 07 uses `TRY_CONVERT` with ISO style 112 for order, shipping, and due dates |
| Type-correct Silver date checks | Silver date columns are already `DATE`, not integers | Script 08 reports missing dates directly |

Source sales dates must be valid calendar dates within the inclusive project window 1900-01-01 through 2050-01-01. Invalid, missing, or out-of-range dates become null and remain visible in the quality summary. The bounds are a documented policy for this historical dataset, not a universal date-validation rule. This policy does not silently invent replacement dates. It does not repair invalid text rejected earlier by typed Bronze ingestion.

Full refreshes still overwrite existing rows and are not protected by atomic publication across tables. `THROW` stops dependent execution but does not roll back earlier loads. The existing sales amount repair policy is retained and checked rather than redesigned.

## 2. Data Quality Scorecard

Run [13_data_quality_summary.sql](../scripts/13_data_quality_summary.sql) after loading the warehouse and defining Gold views. It returns a single result set with layer, rule, issue count, and status:

- **PASS:** the rule found no issues.
- **REVIEW:** source dates are invalid/missing, or cleaned dates remain incomplete.
- **FAIL:** a model, relationship, amount, or minimum-input requirement is violated.

Checks cover duplicate customer IDs, duplicate Gold business keys, missing keys, invalid date sequences, inconsistent sales amounts, unmatched products/customers, and fact row-count reconciliation. Group-based checks count duplicate key groups; other checks count affected rows unless their label states otherwise. Rules can overlap, so their counts must not be summed into a total rejected-row count.

The summary is a manual diagnostic, not a pipeline gate. Resolve FAIL results before interpreting analytical output. PASS applies only to the listed rules and is not proof of complete data quality. Empty sales input is explicitly flagged.

## 3. Sales Analysis

Run [14_sales_analysis.sql](../scripts/14_sales_analysis.sql) after reviewing the scorecard. The script returns four result sets:

| Report | Business question | Key SQL techniques |
|---|---|---|
| Monthly sales | How do revenue, volume, and average order value change over observed months? | Date grouping, CTEs, `LAG`, safe division |
| Category contribution | Which current categories contribute the most revenue? | Dimension joins, `DENSE_RANK`, window totals |
| Repeat purchasing | What proportion of observed buyers placed two or more distinct orders? | Customer aggregation, conditional aggregation |
| Coverage | Which missing fields limit the analysis? | Null-aware counts |

### Metric Definitions

- Revenue is the sum of stored `sales_amount`; currency is unspecified. It is not profit.
- Order count uses distinct order numbers rather than sales line counts. Category order counts are not additive when an order contains multiple categories.
- Average order value is revenue divided by distinct orders within the same monthly scope. Missing order numbers must be investigated before relying on this metric.
- Monthly change compares the previous **observed** month. Missing calendar months are not filled with zeros. The output includes the comparison month so gaps remain visible.
- Revenue share is category revenue divided by revenue across all displayed categories. Weighted unit price is revenue divided by units, not the unweighted average of line prices.
- Repeat-buyer percentage uses resolved customers with at least one non-null order number as its denominator. Two lines in the same order do not constitute repeat purchasing. The measure describes the supplied observation period, not lifetime loyalty or cohort retention.
- Undated sales are excluded from the monthly report but retained in category analysis. Coverage output discloses missing dates and keys.
- Product categories reflect current Gold product attributes, including for historical sales. Unmatched products remain in an explicit unknown category.

### Interpreting Results

Inspect revenue alongside units and weighted prices before attributing growth to demand. Compare category revenue share with volume to distinguish high-value categories from high-volume categories. Interpret repeat purchasing within the available date range; customers observed for shorter periods have less opportunity to return. Numerical findings should be recorded only after executing the reports against a validated warehouse.

## Execution and Validation

Use SQL Server 2017 or later and SSMS or sqlcmd. SQL Server 2017 is required by existing `TRIM` expressions. `GO` is a client batch separator.

For an existing warehouse, redefine procedures with scripts 03 and 07, execute script 09 to refresh, and run script 10 to define the views. Script 09 refreshes Bronze itself; script 04 is not needed in the same refresh sequence. Loading replaces existing Bronze/Silver data. The source paths in script 03 must be accessible to the SQL Server service.

Then run scripts 13 and 14. The [focused regression checks](../tests/extension_checks.sql) use table variables to check invalid calendar dates, distinct-order repeat purchasing, and average order value without modifying warehouse data. A failed assertion raises an error. [Warehouse assertions](../tests/warehouse_checks.sql) additionally reconcile populated layers; see [test instructions](../tests/README.md).

## Verified Results

See [Sales Analysis Findings](analysis_findings.md) for the executed report snapshot, interpretation, and verification limits.

## Scope

The project uses full loads, view-based Gold objects, and recalculated `ROW_NUMBER()` keys. Persistent dimensions, historical tracking, incremental processing, orchestration platforms, and automated publication gates are outside these extensions.
