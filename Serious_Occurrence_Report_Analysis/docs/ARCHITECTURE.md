# Architecture

The internship workflow used SSIS and SQL Server to prepare Serious Occurrence Reporting exports for Power BI. This maintained portfolio version keeps the original full-snapshot workflow and source mappings, with clearly identified post-internship validation and reporting improvements.

1. SSIS imports the status and category CSV snapshots into Bronze.
2. `silver.load_all` validates both snapshots and normalizes strings, flags and typed values.
3. Both Silver tables are replaced in one transaction. A validation or write failure leaves the previous Silver snapshot intact.
4. `gold.fact_events` publishes one row per event; `gold.fact_categories` publishes one row per actual category record, retaining repeated participants.
5. Power BI uses an event-to-category relationship and a calendar related to the event occurrence date.

Bronze ingestion is outside the Silver transaction. Failed imports can leave partial Bronze data; the package calls Silver only after both imports succeed. Use one ingestion writer at a time. This demonstration does not implement incremental ingestion, concurrency orchestration or scheduling.

The checked-in DTSX contains connection placeholders. The runner configures a temporary copy for the marked demo database and removes it after execution. No production connection is required. The package is executed standalone with DTExec; this version does not claim an ISPAC/SSISDB deployment.

An event with no category remains visible in Events but creates no category row. Event reporting delay therefore gives each event equal weight. Category breakdowns count distinct event IDs or known participant IDs, depending on the question; those distinct counts are not additive across groups.
