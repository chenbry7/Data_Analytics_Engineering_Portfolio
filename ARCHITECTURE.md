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
