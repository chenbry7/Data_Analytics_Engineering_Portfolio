# Acceptance run: 1 October 2026

A fresh local run of the checked-in synthetic demonstration completed successfully after correcting the project directory name.

| Stage | Result | Captured output |
|---|---|---|
| `run_demo.ps1` | 19 SQL acceptance tests passed, including mid-write rollback | [SQL output](sql-acceptance.txt) |
| `tests/03_ssis_acceptance.ps1` | 5 SSIS checks passed, including three expected failure cases | [SSIS output](ssis-acceptance.txt) |
| `run_showcase.ps1` | All Gold fields and record multiplicities matched; Bronze/Silver counts reconciled | [Showcase output](showcase-reconciliation.txt) |

The final database contains 420 events and 855 category records, ready for the saved report. The small acceptance fixture was restored to the larger showcase after testing.

## Execution

The scripts ran sequentially using Windows authentication against the marked local `SOR_Portfolio_Test` database and the SQL Express instance. DTExec reported version 17.0.1000.7. Commands were:

```powershell
.\run_demo.ps1 -Server '.\SQLEXPRESS'
.\tests\03_ssis_acceptance.ps1 -Server '.\SQLEXPRESS'
.\run_showcase.ps1 -Server '.\SQLEXPRESS' -Python '<local Python executable>'
```

The supplied logs contain the complete captured script output, normalized to UTF-8. SSIS runs use DTExec `/REPORTING E` (error reporting); the three expected-failure cases include their diagnostic messages, error codes and exit results, followed by assertions that the complete Silver snapshot was preserved. These expected DTSER_FAILURE results demonstrate successful rejection tests, not a failed acceptance suite. Only the personal temporary-directory prefix is replaced with `<TEMP>`; diagnostic content and timestamps are otherwise retained. No production data is included.

[manifest.json](manifest.json) identifies the tested code, source CSVs, saved report and captured logs with SHA-256 hashes. The report hash identifies the unchanged artifact; it does not mean Power BI Desktop was executed in this run.

## Scope

This run verifies SQL, SSIS and source-to-Gold reconciliation. It did not rerun Power BI Desktop refresh or interactions. Earlier report review and author-confirmed interactive acceptance remain documented in [Validation](../../VALIDATION.md).
