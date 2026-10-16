# SQL standardization validation — 16 October 2026

The four SQL files were standardized for readable statements, consistent indentation,
explicit aliases and purpose comments. Seven default-space `LTRIM(RTRIM(...))`
expressions were replaced by equivalent `TRIM(...)` expressions. Other business rules,
identifiers, output columns and source literals were preserved.

- Setup and Gold view definitions executed successfully; final acceptance checks passed.
- Silver was rebuilt inside an outer transaction. Bidirectional set comparisons covered
  track, genre, membership, source mapping, popularity, quality and rejection results.
  These tables have enforced keys, so their compared rows do not conceal duplicate multiplicities.
- One known historical difference was explicitly accounted for in the temporary expected
  quality table: the database retains an incorrectly encoded tempo-range label, while both
  the pre-review and current SQL emit `50-250`. No live quality row was changed by this test.
- The outer transaction was rolled back. PCA scores and analysis/source provenance matched
  their pre-test snapshots afterward; 89,740 PCA rows remained intact.
- Final counts: 114,000 source records, 89,741 catalog tracks, 113,550 memberships and 114 genres.
- Python model fitting and Power BI Desktop were not rerun.

The first comparison exposed the historical label difference. The retained Silver log is
the successful rerun with that single expected-text normalization. Logs are decoded from
the SQL client output encoding into UTF-8 for publication.

## Captured outputs

- [spotify-setup.txt](spotify-setup.txt)
- [spotify-silver.txt](spotify-silver.txt)
- [spotify-gold.txt](spotify-gold.txt)
- [spotify-checks.txt](spotify-checks.txt)

[File fingerprints](manifest.json) identify the SQL and logs reviewed in this run.
