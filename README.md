# Data Analytics & Engineering Portfolio

**SQL Server · Python · SSIS · Power BI · DAX · Statistical Analysis**

Projects demonstrating how raw data becomes validated, interpretable reporting through data pipelines, quality checks, statistical analysis, visual explanations and Power BI dashboards.

Each project includes source code, reproduction instructions, validation evidence and visual previews.

## Featured Projects

| Project | Focus | Key Results |
|---|---|---|
| [Serious Occurrence Reporting](Serious_Occurrence_Report_Analysis/README.md) | Internship-derived SSIS pipeline, data quality and operational reporting | Transactional Silver refresh; 19 SQL tests and 5 SSIS checks passed; four-page Power BI report |
| [Spotify Analytics](Spotify_Audio_Features_Analysis/README.md) | Python/SQL pipeline, audio-feature analysis and catalog reporting | 114,000 records processed into 89,741 unique tracks; PCA and complementary diagnostics; three-page Power BI report |
| [NBA Player Role Map](NBA_player_Role_Map/README.md) | Python statistical analysis, standardized PCA and player-role visualization | 421 players and 18 features; two components explain 73.82% of variance; reproducible notebook and multivariate diagnostics |

## 1. Serious Occurrence Reporting

**SSIS · SQL Server · T-SQL · PowerShell · Power BI**

An internship-derived project that transforms event-status and category exports through Bronze, Silver and Gold layers for reporting.

The original workflow was implemented and deployed during the internship. This public version adds subsequent engineering enhancements and a reproducible synthetic dataset.

### Key Features

- **Data validation:** checks event-key uniqueness, required identifiers, category-to-event references, date formats and nonnegative quantities.
- **Failure recovery:** refreshes both Silver tables in one transaction, preserving the previous published snapshot if validation or loading fails.
- **Reporting accuracy:** separates event and category records to prevent repeated classifications from inflating event counts or average reporting delays.
- **Automated verification:** passes 19 SQL acceptance tests and 5 SSIS checks, including invalid-input rejection and rollback after a mid-write failure.
- **Power BI reporting:** four pages cover event volume, categories and participants, reporting timeliness, and decomposition analysis.

**Data confidentiality:** original operational data and the internship report are not published because of sensitivity and confidentiality requirements. The public demonstration uses independently generated fictional records: **420 events and 855 category records across 12 months and six sites**. These are demonstration values, not organizational results.

[Project Documentation](Serious_Occurrence_Report_Analysis/README.md) · [Validation](Serious_Occurrence_Report_Analysis/docs/VALIDATION.md) · [Power BI Report](Serious_Occurrence_Report_Analysis/powerbi/SOR_analysis.pbix)

![Serious Occurrence Reporting Overview](Serious_Occurrence_Report_Analysis/powerbi/screenshots/overview.png)

## 2. Spotify Analytics

**Python · SQL Server · pandas · scikit-learn · Power BI**

A batch analytics project combining a Bronze–Silver–Gold data pipeline with statistical exploration of audio features and reporting across overlapping genres.

### Key Features

- **Data processing:** transforms **114,000 source records into 89,741 unique tracks**, retaining track–genre relationships across 114 genres.
- **Quality and traceability:** identifies **450 redundant records** and **720 tracks with conflicting popularity observations**, preserving evidence and source lineage.
- **Statistical analysis:** applies PCA to nine audio features; the first three components explain **61.88% of variance**. Factor analysis, ICA and bootstrap diagnostics provide complementary checks.
- **Model integration:** writes analytical scores back to SQL Server with track identifiers and sample reconciliation.
- **Power BI reporting:** three pages explore the catalog, genres and songs, and data quality; DAX measures account for overlapping genre memberships.

PCA describes variation in audio features. It does not establish recommendation performance or causal relationships, and the analysis documents the limitations of its complementary methods.

[Project Documentation](Spotify_Audio_Features_Analysis/README.md) · [Analysis Findings](Spotify_Audio_Features_Analysis/reports/ANALYSIS_REPORT.md) · [Power BI Report](Spotify_Audio_Features_Analysis/powerbi/Spotify_Audio_Analytics.pbix)

![Spotify Catalog Overview](Spotify_Audio_Features_Analysis/powerbi/screenshots/catalog-overview.png)

## 3. NBA Player Role Map

**Python · pandas · NumPy · scikit-learn · SciPy · Matplotlib**

A statistical analysis of 2023–24 NBA per-game player profiles that uses standardized PCA to summarize offensive involvement and interior-versus-perimeter playing style.

### Key Features

- **Data preparation:** filters **572 source players to 421 eligible players** using at least 10 games played and 10 minutes per game, then selects 18 core statistics.
- **Dimension reduction:** the first two principal components explain **73.82% of standardized variance**, providing a compact map of player profiles.
- **Interpretable results:** uses variable–component correlations and labeled score extremes to explain offensive involvement and interior-versus-perimeter style.
- **Statistical diagnostics:** examines multivariate normality and Mahalanobis distances, identifying **23 exploratory extreme profiles** while retaining all eligible players.
- **Reproducibility:** includes the source CSV, an executed notebook, pinned dependencies, a fresh-kernel runner, and independent numerical checks.

The role map is descriptive. Player positions are not ability rankings, causal effects or performance predictions; the documentation explains selection, percentage encoding and diagnostic limitations.

[Project Documentation](NBA_player_Role_Map/README.md) · [Analysis Notebook](NBA_player_Role_Map/NBA_code.ipynb) · [Written Report](NBA_player_Role_Map/NBA_report.pdf)

![NBA Player Role Map](NBA_player_Role_Map/figures/Fig3_scores_PC1_PC2_labeled.png)

## Skills Demonstrated

| Area | Implementation Examples |
|---|---|
| Data Engineering | Python and SSIS ingestion, layered SQL transformations, transactional snapshot loading |
| Data Quality | Key constraints, validation rules, source fingerprints, reconciliation and failure tests |
| Data Modeling | Separate event/category and track/genre grains; explicit relationships and aggregation rules |
| Data Analysis | Exploratory analysis, PCA, FA, ICA, player-role interpretation and multivariate diagnostics |
| Business Intelligence | Power BI data models, DAX measures, filtering and interactive report pages |
| Reproducibility | Execution scripts, documented dependencies, test fixtures and validation evidence |

## Explore or Reproduce

1. Open a project README for its objectives, architecture and results.
2. View project previews and reports: Power BI dashboards for SOR and Spotify, or the role map, notebook and PDF for NBA.
3. Follow the project-specific setup instructions to reproduce its pipeline or statistical analysis.

For SOR and Spotify, the saved Power BI reports contain imported data. Refreshing them requires the corresponding SQL Server database and connection configuration.

Pipeline and analysis execution are documented within each project. The NBA notebook was run from start to finish in a fresh kernel, with independent checks of feature scaling, PCA loadings and Mahalanobis distances. The project author has confirmed successful Power BI Desktop refresh and full interactive acceptance for both reports. Data provenance, usage conditions and project-specific limitations are described in the respective READMEs.
