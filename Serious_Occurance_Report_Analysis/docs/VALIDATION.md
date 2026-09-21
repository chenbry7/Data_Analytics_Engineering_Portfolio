# Validation

Validated on 21 September 2026 with SQL Server Express 17.0.1000.7, DTExec 17.0.1000.7 and MSOLEDBSQL19.1, using Windows authentication against the marked synthetic database `SOR_Portfolio_Test`.

## Executed checks

| Component | Evidence | Result |
|---|---|---|
| SQL | 19 acceptance tests | Passed |
| SSIS | 5 ingestion and failure checks | Passed |
| Showcase | All 18 Gold event fields and 24 Gold category fields compared with CSV-derived expectations | Matched |
| Layer counts | Bronze and Silver event/category counts compared with the loaded snapshots | Matched |
| Saved PBIX | 420 event rows and 855 category rows compared with the showcase projection | Matched |
| Report definitions | Source queries, 8 measures, core relationships, sorting, detail fields and slicer synchronization | Reviewed |
| Report previews | Four page screenshots compared with expected values | Reviewed |

## SQL and SSIS coverage

SQL tests cover normalization, optional NULLs, date/time precision, repeated refresh, unique event IDs, repeated participants, missing IDs, orphan categories, empty snapshots, invalid typed values and reversed dates. An injected constraint failure after Silver writes begin verifies rollback of both tables. Rejected batches are checked against complete serialized Silver snapshots, and tests check for leaked transactions.

SSIS checks compare CSV ingestion with the independently SQL-loaded fixture, reject malformed dates, duplicate event IDs and missing input files, and verify a successful final reload. Negative tests require the expected failure message and unchanged Silver data.

## Datasets and expected results

| Metric | Small acceptance fixture | Report showcase |
|---|---:|---:|
| Events | 3 | 420 |
| Category records | 4 | 855 |
| Events with categories | 2 | 402 |
| Known participants | 2 | 119 |
| Sites | 2 | 6 |
| Media-attention events | 1 | 53 |
| Average reporting delay, days | 0.666667 | 1.230952 |

The showcase covers September 2025–August 2026, eight categories and four programs. Source checks verify event references, cross-file attributes and timestamps, consistent fictional birth dates, age-at-event calculations and summary quantities. Comparisons preserve record multiplicity. CSV fingerprints and monthly expectations are in [expected_metrics.json](../data/showcase/expected_metrics.json).

## Power BI validation

The saved report's ZIP integrity passed. Embedded Events and Categories match the showcase projection; times are compared at the source's whole-second precision to accommodate floating-point decoder differences. Calendar contains 365 distinct dates. The two core relationships are active and single-direction; the event detail table uses Events fields and sorts occurrence date descending. Age groups follow their numeric order. Date, month and site slicers have matching synchronization groups across the first three pages.

Screenshot headline metrics, monthly event counts and the decomposition example agree with the data. Category B contains 115 events: 67 Closed, 24 Open and 24 Under Review. The site/category matrix requires horizontal scrolling for its full width.

Reviewed PBIX SHA-256: `af6068404414efa0263587728c914f66bcd9e250302524091f10ddba1f28bddd`.

## Reproduce

Run [the SQL suite](../run_demo.ps1), [the SSIS suite](../tests/03_ssis_acceptance.ps1), then [the showcase loader and reconciliation](../run_showcase.ps1). The final step leaves the larger dataset in the database. Requirements and commands are in the [project README](../README.md).

## Scope

Validation covers the supplied synthetic snapshots, local SQL/SSIS execution, saved PBIX data/configuration and report screenshots. Live Power BI refresh and exhaustive interactive tests were not executed as part of this validation. Scheduling, concurrent ingestion, compatibility with unavailable production exports and completeness of upstream business records are not established by these checks.
