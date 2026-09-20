# Power BI Report

[Report file](Spotify_Audio_Analytics.pbix) · [DAX definitions](measures.dax) · [Metric benchmarks](expected_checks.json) · [Project overview](../README.md)

## Report pages

| Page | Visuals | Data scope |
|---|---|---|
| Catalog Overview | Catalog/analysis counts, mean energy and duration cards; genre count bars; energy/danceability comparison; feature-profile matrix; genre slicer | Selected genres; counts and averages deduplicate track IDs |
| Genre & Song Explorer | Genre/song slicers, selected-song and energy cards, song table, energy/danceability scatter, PC1/PC2 scatter | Page filter `include_primary = 1`; each scatter point is identified by `track_id` |
| Data Quality & Methodology | Snapshot counts, three-PC variance, warning chart, quality-rule table, provenance and methodology | Full-snapshot quality and source tables |

## Model and aggregation contract

| Report table | SQL view | Grain |
|---|---|---|
| GenreSongs | gold.GenreSongDetail | One track–genre membership |
| DataQuality | gold.DataQuality | One quality-rule result |
| SourceSummary | gold.SourceSummary | One current source/analysis snapshot |

The intended reporting model keeps the source and quality tables disconnected from genre/song selections. Normalized relationships remain in SQL Silver; the main reporting view already joins song attributes and PCA scores.

`Catalog Songs` counts distinct `track_id` values. `Analysis Songs` retains only eligible tracks. Feature means average each eligible selected track once, rather than averaging membership rows. For an empty selection, `Catalog Songs` and its derived counts return zero; `Genre Memberships` returns BLANK because its definition uses `COUNTROWS` directly. Feature means remain BLANK. JSON benchmarks represent BLANK as `null`. Song names are not unique identifiers. Scatter coordinates use Maximum at track-ID grain; genre is not a point-grouping field.

The quality chart filters `severity = WARN`. The rule table has no grand total because counts can overlap and mix source-record and track grains. `explained_variance_first3` is a fraction formatted as a percentage: 0.6187899 is approximately 61.88%. It describes three PCs, although the scatter displays only PC1 and PC2.

## Review scope

The included PBIX report definitions and supplied screenshots were reviewed. Page 2 eligibility filtering, scatter identifiers/aggregations, warning filtering, percentage formatting and removal of the quality total were confirmed. The report's compressed semantic model was not independently executed or fully decoded. This review does not certify all embedded DAX, relationships or refresh behavior.

Reference checks include 89,741 catalog songs, 89,740 eligible songs and mean energy 0.634458472 without filters. The pop/pop-film union benchmark is 1,768 distinct songs and mean energy 0.606568948. These are acceptance benchmarks, not a claim that every interaction was executed in Desktop. See [validation](../reports/VALIDATION.md).

## Opening and reproducing

The PBIX contains a saved data model for review in Power BI Desktop. Refresh requires an accessible `Spotify` SQL Server database, the Gold views and appropriate Windows credentials. The saved connection is a local development connection; reviewers must configure their own source to refresh. The pipeline is described in the [project quick start](../README.md#quick-start).

`measures.dax` contains separate measure definitions for reproducibility. `theme.json` is a base theme; individual visuals may override it. Screenshots are static report previews, not interactive embeds. No Power BI service publication or hosted-refresh setup is included.
