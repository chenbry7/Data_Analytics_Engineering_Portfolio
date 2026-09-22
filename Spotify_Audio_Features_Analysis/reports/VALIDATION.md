# Validation and Execution Evidence

Reviewed run: **14 September 2026**. The numerical pipeline is validated for the supplied snapshot. The included Power BI report received a separate configuration and screenshot review on 19–20 September 2026. A file-consistency audit, saved-model reconciliation and direct read-only SQL acceptance check were completed on 22 September 2026.

## Evidence sources

- [Analysis metadata](evidence/analysis_metadata.json): source/sample fingerprints, feature contract, scaler parameters, component axes and versions.
- [Run status](evidence/run_status.json): completed run with SQL write-back and advanced analysis enabled.
- [Local validation](evidence/local_validation.json): hash checks, score alignment, finite values, PCA recomputation and paired-bootstrap coverage.
- [Research report](evidence/research_report.json): parallel analysis, FA/ICA diagnostics and limitations.
- [Paired-start diagnostics](evidence/diagnostic_report.json) and [bootstrap intervals](evidence/fa_paired_bootstrap_intervals.csv).

These compact files are retained independently of the ignored outputs directory. They are results of the reviewed run; subsequent executions generate new local outputs and require a new evidence review.

## Local checks

| Check | Result |
|---|---|
| Original-source and exported-sample fingerprints | Match across model outputs |
| Eligible sample | 89,740 unique track IDs |
| PCA, FA and ICA scores | Same ordered IDs; finite numeric values |
| PCA recomputation from stored parameters | Matches saved scores |
| Paired bootstrap coverage | 400 fits across 200 resamples |
| Promax common-covariance invariance | Maximum error approximately 9.99e-16 |

## SQL acceptance

SSMS execution screenshots reviewed for this run show Step 06 PASS and successful completion at **2026-09-14 17:28:39 -04:00**. The displayed results reconcile 114,000 source records, 89,741 catalog tracks, 113,550 memberships, 114 genres and 89,740 PCA-scored tracks. Required-value rules pass; warning counts and metric benchmarks match the analysis report.

The historical execution statement above is based on operator-provided screenshots, which are not included here. On 22 September 2026, the read-only [06_checks.sql](../06_checks.sql) was independently rerun against the current local database and passed. Current source/sample fingerprints agree with the retained evidence; snapshot counts and metric benchmarks also agree. Runtime timestamps in the report describe the later database load/model write, not the date of the original evidence review.

## Interpretation and display notes

The latest report screenshot displays the tempo warning as 50-250 BPM. The SQL description uses the same ASCII range for reproducible display. FA boundary and uncertainty limitations are documented in the analysis report. There is no production orchestration, concurrency or access-control acceptance claim.

## Power BI review

The [PBIX](../powerbi/Spotify_Audio_Analytics.pbix) and [three supplied previews](../powerbi/README.md) are included. Read-only report-definition inspection confirms Page 2's `include_primary = 1` filter, track-ID scatter grouping with Maximum coordinates, a WARN-only quality chart, a quality table without totals and a percentage-formatted PCA variance card. Screenshot values reconcile with the documented global and acoustic benchmarks at displayed precision.

The preview images were supplied by the report author; they are not independently rendered exports. The subsequent offline audit decoded all three business tables and 15 measures. Membership keys, numeric fields and PCA scores match SQL; all 89,740 score rows also reconstruct from the retained scaler/component parameters. Text differences in song, album and artist labels are limited to letter case, while track IDs match exactly. The imported quality descriptions include the saved Power Query correction of the historical tempo-range encoding; the checked-in SQL already emits ASCII 50-250. Source timestamps agree at displayed precision. The business tables are disconnected, and the measure formulas match `powerbi/measures.dax`. Offline inspection does not execute interactive DAX. The project author has subsequently confirmed successful Power BI Desktop refresh and full interactive acceptance. This closes the previously outstanding refresh and interaction acceptance items; the runtime result is author-confirmed rather than an independently rerun audit.
