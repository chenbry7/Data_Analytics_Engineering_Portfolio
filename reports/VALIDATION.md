# Validation and Execution Evidence

Reviewed run: **14 September 2026**. The numerical pipeline is validated for the supplied snapshot. The included Power BI report received a separate configuration and screenshot review on 19–20 September 2026.

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

This SQL acceptance statement is based on reviewed operator-provided screenshots; it is not an independently executed database query in the review environment. The screenshots are not included in this evidence directory. The read-only [06_checks.sql](../06_checks.sql) script is the reproducible acceptance entry point.

## Known limitations

The latest report screenshot displays the tempo warning as 50-250 BPM. The SQL description uses the same ASCII range for reproducible display. FA boundary and uncertainty limitations are documented in the analysis report. There is no production orchestration, concurrency or access-control acceptance claim.

## Power BI review

The [PBIX](../powerbi/Spotify_Audio_Analytics.pbix) and [three supplied previews](../powerbi/README.md) are included. Read-only report-definition inspection confirms Page 2's `include_primary = 1` filter, track-ID scatter grouping with Maximum coordinates, a WARN-only quality chart, a quality table without totals and a percentage-formatted PCA variance card. Screenshot values reconcile with the documented global and acoustic benchmarks at displayed precision.

The preview images were supplied by the report author; they are not independently rendered exports. Binary model DAX/relationships, live refresh and full multi-genre/song interaction testing were not independently executed. The pop/pop-film benchmark remains a runtime acceptance case. Report configuration review is not a substitute for those checks.
