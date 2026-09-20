# Architecture and Data Model

## Design

This architecture demonstrates batch data engineering for analytical use: ingestion, normalized transformations, model-result integration and reporting contracts. Statistical analysis is the downstream consumer; quality and lineage controls support every stage.

The database `Spotify` separates raw ingestion, validated entities and reporting outputs. Processing is manual and sequential for a single current snapshot. Layer table counts differ because each layer has a different responsibility.

Bronze preserves source records. Silver normalizes tracks, genres and memberships and records quality decisions. Gold combines reporting views with two physical tables for Python-computed PCA scores and model provenance.

Field-level definitions, SQL types, lineage and usage contracts are maintained in the [Data Catalog](DATA_CATALOG.md).

## Database objects

| Layer | Object | Type | Grain and purpose |
|---|---|---|---|
| Bronze | source_info | Table | One current source fingerprint, filename, row count and load time |
| Bronze | raw_track | Table | One original CSV record, with raw text and record number |
| Silver | track | Table | One unique track with typed attributes and analysis flags |
| Silver | genre | Table | One genre |
| Silver | track_genre | Table | One unique track–genre relationship |
| Silver | source_mapping | Table | One source record mapped to its canonical record and cleaned membership |
| Silver | popularity_summary | Table | One track's observed popularity range and conflict flag |
| Silver | source_info | Table | One successfully cleaned source snapshot |
| Silver | quality_results | Table | One quality-rule result with severity and affected count |
| Silver | rejected_records | Table | One blocking source record and rejection reason |
| Gold | pca_scores | Table | One eligible track with three PCA scores |
| Gold | analysis_info | Table | One model snapshot with sample provenance and fitted metadata |
| Gold | SongAnalysis | View | One song with features, popularity and available PCA scores |
| Gold | GenreSongDetail | View | One membership with reporting attributes and fractional weight |
| Gold | GenreSummary | View | One genre's aggregates |
| Gold | DataQuality | View | Current full-snapshot quality outcomes |
| Gold | SourceSummary | View | Matching source, cleaning and analysis metadata |

## Transformation contracts

1. Python validates CSV headers and row widths, fingerprints the source and imports raw text in a transaction.
2. SQL converts fields, applies blocking rules, separates entities and preserves every source record's lineage.
3. Python reads unique, positive-duration Silver tracks. It exports the analysis sample, computes models and checks that scores still correspond to current Silver before write-back.
4. Gold views join Silver attributes with model results. Matching source fingerprints prevent stale outputs after an incomplete refresh.
5. Acceptance SQL checks source reconciliation, PCA coverage, join cardinality and metric benchmarks.

FA/ICA scores and diagnostics remain local outputs; PCA scores are persisted for reporting. Source load time is not a Spotify observation timestamp.

## Reporting model

The first Power BI report imports `gold.GenreSongDetail` as `GenreSongs`. It uses distinct-track measures and per-track feature averages to avoid overcounting across genre selections. Source and quality tables are designed to remain disconnected and labeled as full-snapshot information. This intentionally small model requires no main-table relationships; the normalized entity relationships remain in Silver.

## Repository layout

```text
Project_2_Spotify_Audio_Features_Analysis/
├── 01_create_layers.sql ... 06_checks.sql  # Supported entry files
├── research/                              # Helpers invoked by Step 04
├── reports/                               # Findings, validation and compact evidence
├── powerbi/                               # Report, previews, model documentation and measures
├── outputs/                               # Generated results; excluded from Git
├── spotify_data.csv                       # Supplied input
├── spotify_README.pdf                     # Supplied source documentation
```

## Operational boundary

Import replaces the current snapshot and invalidates derived data. Cleaning invalidates previous PCA output. Model write-back is transactional, while partially written local files may remain after failures. Do not run stages concurrently or refresh Power BI mid-run.

The design does not provide immutable run history, scheduled orchestration, concurrent writers or validated production access controls. These are potential extensions rather than completed capabilities.

## Repository artifact responsibilities

The six numbered files are the execution entry points. Research modules are invoked by Step 04; they do not add manual execution stages.

| Artifact | Responsibility |
|---|---|
| `spotify_data.csv`, `spotify_README.pdf` | Source snapshot and original supplied documentation |
| `01_create_layers.sql` | Create the dedicated database, schemas and physical tables |
| `02_import_csv.py` | Validate and load raw records with source fingerprint and row reconciliation |
| `03_clean_silver.sql` | Build typed entities, memberships, quality results and record lineage |
| `04_audio_analysis.py` | Read eligible Silver tracks; compute PCA, call research helpers, write scores and produce current-run outputs |
| `05_gold_views.sql` | Expose song, membership, genre, quality and provenance views |
| `06_checks.sql` | Check readiness, reconciliation, score coverage and original-snapshot benchmarks |
| `research/feature_contract.py` | Define the shared ordered feature list and project root |
| `research/analyze_latent.py` | Parallel analysis, FA/ICA, bootstrap intervals and initialization checks |
| `research/diagnose_fa.py` | Matched promax covariance and paired-start FA bootstrap diagnostics |
| `reports/ANALYSIS_REPORT.md` | Curated findings and statistical limitations from the reviewed run |
| `reports/VALIDATION.md` | Evidence index and boundaries of SQL, local and Power BI review |
| `reports/evidence/analysis_metadata.json` | Fitted scaler/PCA parameters, versions and source/sample hashes |
| `reports/evidence/run_status.json` | Completion, advanced-analysis and SQL-write-back status |
| `reports/evidence/local_validation.json` | Recorded numerical validation outcomes |
| `reports/evidence/research_report.json` | FA/ICA, dimension selection and initial-bootstrap findings |
| `reports/evidence/diagnostic_report.json` | Paired-start and matched-covariance results |
| `reports/evidence/fa_paired_bootstrap_intervals.csv` | Best-of-two-start loading intervals from the paired diagnostic run |
| `powerbi/Spotify_Audio_Analytics.pbix` | Saved three-page report and embedded model |
| `powerbi/measures.dax` | Reusable distinct-track counts and feature-average definitions |
| `powerbi/expected_checks.json` | Reference selections and expected metrics; null represents BLANK |
| `powerbi/theme.json` | Base presentation theme; visual overrides are allowed |
| `powerbi/README.md` | Report pages, model contract and review scope |
| `powerbi/screenshots/catalog-overview.png` | Catalog Overview preview |
| `powerbi/screenshots/genre-song-explorer.png` | Genre & Song Explorer preview |
| `powerbi/screenshots/data-quality-methodology.png` | Data Quality & Methodology preview |
| `DATA_CATALOG.md` | Object/field definitions, grains, keys and lineage |
| `QUALITY_RULES.md` | Cleaning, exception and aggregation policy |
| `ARCHITECTURE.md`, `README.md` | Technical design and public project entry point |
| `requirements.txt`, `requirements-latent.txt` | Pinned base and full-analysis dependencies |
| `.gitignore` | Exclude generated outputs, local environments and caches |

Step 04 writes a current-run report to `outputs/ANALYSIS_REPORT.md`; it does not overwrite the curated report or accepted evidence under `reports/`. The compact accepted interval CSV corresponds to generated `outputs/fa_diagnostics/best_of_two_starts_intervals.csv`. Fresh runs require evidence review before replacing public findings.

The supplied PDF refers to an original filename `dataset.csv`; this repository intentionally uses `spotify_data.csv`. Its example code is source documentation, not an additional pipeline entry point.
