# Synthetic showcase data

All records, identifiers, sites, categories and programs are fictional. These data are designed to demonstrate filtering, relationships and reporting metrics. Their distributions are chosen for illustration and do not describe the internship organization or its performance. Category A–H and program A–D are generic demo labels, not an official taxonomy.

## Coverage

| Attribute | Value |
|---|---:|
| Occurrence period | September 2025–August 2026 |
| Events | 420 |
| Category records | 855 |
| Events with categories | 402 |
| Events without categories | 18 |
| Known participants represented | 119 |
| Sites / categories / programs | 6 / 8 / 4 |
| Unknown-age category records | 81 |
| Category records with no participant ID | 11 |

Event volume varies by month, site, status and classification. The fictional participant pool has 120 possible IDs; 119 occur in this snapshot. Repeated IDs retain the same fictional birth date, and known ages are calculated at the event date. The same participant can appear in multiple events and categories. Missing age is not zero. Missing IDs are excluded from Known Participants.

For this dataset, `# of individuals` counts distinct identified participants plus anonymous participant records per event. `# of unique categories` counts the event's distinct category labels. The separate non-client quantity is zero throughout: no non-client population is modeled. Optional legal/notification fields are left unspecified. Statuses and levels are illustration choices, not inferred organizational rules. Monthly variation is synthetic, not a finding.

## Files and reproducibility

`SO_status.csv` and `SO_category.csv` retain the small fixture's exact headers and column order, Windows-1252 encoding and CRLF line endings. `expected_metrics.json` records CSV hashes and independently calculated reporting expectations. The original small dataset remains in [data/synthetic](../synthetic/README.md).

From the repository project folder, Python 3 standard library is sufficient to regenerate the CSVs deterministically with seed 20260921:

```powershell
python .\scripts\showcase_data.py --generate
```

Run without `--generate` to check the files and their manifest. Generation alone does not load SQL Server. After initial SQL setup, load and verify the showcase with:

```powershell
.\run_showcase.ps1 -Server '.\SQLEXPRESS'
```

The loader uses the existing SSIS package, then compares all 18 event fields and 24 category fields, preserving duplicate multiplicities, against expectations derived from the CSVs. Bronze and Silver row counts must reconcile. It leaves `SOR_Portfolio_Test` populated with the showcase for Power BI. Pass `-Python 'C:\path\to\python.exe'` when Python is not on PATH.

The small acceptance runners restore the small fixture. Run `run_showcase.ps1` afterward to restore the larger report dataset. Both datasets are fictional and use the same marked demo database; loading one replaces the other.

## Power BI expected values with no filters

| Measure | Display |
|---|---:|
| Event Count | 420 |
| Category Records | 855 |
| Events with Categories | 402 |
| Known Participants | 119 |
| Site Count | 6 |
| Media Event Count | 53 |
| Media Attention Rate | 12.6% |
| Avg Report Delay Days | 1.23 |

Use the existing [Power BI model and metric guide](../../powerbi/README.md). There are 12 populated occurrence months. Distinct participant/event breakdowns are not additive across categories. Unknown-age records are not the same metric as distinct participants in the Unknown group.
