# SQL Validation

| File | Purpose | Requires warehouse data? |
|---|---|---|
| [extension_checks.sql](extension_checks.sql) | Isolated table-variable cases for date parsing, distinct-order repeat buyers, and average order value | No |
| [warehouse_checks.sql](warehouse_checks.sql) | Assertions for key integrity, relationships, sales row preservation, dates, amounts, and Gold/Silver revenue reconciliation | Yes |

Run the warehouse checks after loading data and deploying Gold views. Both scripts raise an error with THROW when an assertion fails. They do not modify warehouse tables. Missing source dates are review items reported by script 13, rather than silently treated as valid dates.

In SSMS, open and execute each file. For command-line validation, run from the project root and replace the server placeholder:

```powershell
sqlcmd -S "<server-or-instance>" -E -b -i "tests/extension_checks.sql"
sqlcmd -S "<server-or-instance>" -E -b -i "tests/warehouse_checks.sql"
```

The `-b` option returns an unsuccessful process exit code on SQL errors. `-E` uses Windows integrated authentication; choose authentication appropriate for the deployment. See [verification results](../docs/validation.md) for the tested dataset and limitations.
