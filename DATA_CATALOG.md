# Data Catalog

## Scope and authority

Database: **Spotify**. Implementation: local, sequential batch processing with one current snapshot. This catalog describes the maintained SQL tables, reporting views and their analytical use. It supports the project's data engineering and analysis workflow through explicit metadata and lineage; it is not a deployed catalog service.

Definitions are aligned with [01_create_layers.sql](01_create_layers.sql), [03_clean_silver.sql](03_clean_silver.sql), [04_audio_analysis.py](04_audio_analysis.py) and [05_gold_views.sql](05_gold_views.sql). SQL declarations are authoritative for physical types and constraints. View nullability below describes intended row behavior rather than SQL Server metadata inference. Audio-feature labels are source-provided; their upstream measurement algorithms are outside this implementation.

## Catalog conventions and navigation

This human-readable catalog follows common field-metadata conventions illustrated by [Frictionless Table Schema on GitHub](https://github.com/frictionlessdata/tableschema-js) and the [WPRDC data-dictionary guide](https://github.com/WPRDC/data-guide/blob/master/docs/data_dictionaries.md): stable field names, readable descriptions, types, permitted values, missing-value handling and keys. It is a Markdown project document, not a validated Frictionless JSON descriptor or a claim of compliance with a universal catalog format.

- [Nine audio features: plain-language guide](#nine-audio-features-plain-language-guide)
- [Source asset](#source-asset)
- [Object directory](#object-directory)
- [Physical table dictionary](#physical-table-dictionary)
- [Relationships and join contracts](#relationships-and-join-contracts)
- [Gold view dictionary](#gold-view-dictionary)
- [Quality-rule index](#quality-rule-index)
- [Lineage and analytical consumers](#lineage-and-analytical-consumers)
- [Refresh, retention and maintenance](#refresh-retention-and-maintenance)

## Nine audio features: plain-language guide

The following explanations paraphrase the supplied [Spotify dataset guide](spotify_README.pdf), pages 1-2. Its footer identifies it as AI-authored course documentation, not an official Spotify specification. Examples below are explanatory illustrations rather than observed sample records. The project's validation rules are documented separately from source interpretation hints.

### Meaning and interpretation

| Field name | Display label | Plain-language meaning | Lower values | Higher values |
|---|---|---|---|---|
| `danceability` | Danceability | How easy the track feels to dance to, based on its beat, rhythm and tempo. | Less suitable for dancing | More suitable for dancing |
| `energy` | Energy | How intense and active the track sounds. | Calmer or gentler | More intense or forceful |
| `loudness` | Average loudness | How loud the recording is on average across the track. | More negative: quieter | Closer to zero: louder |
| `speechiness` | Spoken-word presence | How much the recording sounds like spoken words rather than ordinary music or singing. | Less speech-like content | More speech-like content |
| `acousticness` | Acoustic character | How likely the recording is to have an acoustic sound. | Less likely to be acoustic | More likely to be acoustic |
| `instrumentalness` | Absence of vocals | How likely the track is to contain no vocals. | More likely to contain vocals | More likely to be instrumental |
| `liveness` | Live-performance cues | How strongly the recording suggests a live audience or performance setting. | Fewer live-performance cues | More live-performance cues |
| `valence` | Musical mood | How positive or cheerful the music sounds. | Sadder, darker or angrier-sounding | Happier or more cheerful-sounding |
| `tempo` | Beat speed | The estimated number of beats per minute in the track. | Slower beat | Faster beat |

### Units and reading notes

| Field name | Unit / scale | Reading note |
|---|---|---|
| `danceability` | 0 to 1; no unit | A higher score does not necessarily mean a faster song. |
| `energy` | 0 to 1; no unit | Energy describes overall intensity, not just volume or tempo. |
| `loudness` | Decibels (dB); typically -60 to 0 | For example, -5 dB is louder than -20 dB. The typical range is a warning range, not a hard cutoff. |
| `speechiness` | 0 to 1; no unit | The source guide suggests 0.33-0.66 may mix music and speech, and above 0.66 may be mostly spoken word. These are interpretation hints, not pipeline filters. |
| `acousticness` | 0 to 1; no unit | This is a model-derived confidence score, not the percentage of acoustic instruments in the track. |
| `instrumentalness` | 0 to 1; no unit | This is not the number of instruments or the percentage of time occupied by instruments. |
| `liveness` | 0 to 1; no unit | The source guide treats values above 0.8 as suggestive of a live performance; the score is not proof of a concert recording. |
| `valence` | 0 to 1; no unit | This describes the sound of the music, not lyrical sentiment or the actual mood of a listener. |
| `tempo` | Beats per minute (BPM); typically 50-250 | 120 BPM means about two beats per second. A stored zero is retained and flagged; it should not be interpreted as a normal slow tempo. |

### Storage, permitted values and missing data

| Property | Contract |
|---|---|
| Raw storage | The nine source fields are nullable nvarchar(max) strings in bronze.raw_track |
| Clean storage | All nine are float NOT NULL in silver.track; retained as numeric features in the Gold detail views |
| Hard bounds | Seven 0-1 features must lie within inclusive [0,1]; tempo must be nonnegative; loudness must be convertible to a numeric value |
| Typical-range warnings | Tempo outside [50,250] or loudness outside [-60,0] is flagged, not automatically removed |
| Missing or nonnumeric audio values | Block Silver cleaning; no zero-filling or mean imputation is applied |
| Valid zero values | Not treated as missing; zero tempo remains in the primary sample with a warning |
| Primary sample | Unique tracks with positive duration; this eligibility rule is separate from audio-feature interpretation |
| Model scaling | Step 04 standardizes the features before PCA; raw 0-1, dB and BPM values are not treated as interchangeable units |

A score of 0.8 is a feature score, not automatically an 80% probability. In particular, energy and valence are different: an intense track can still sound sad, and a cheerful track can be gentle. These explanatory contrasts are not new classification rules.

## Source asset

| Attribute | Value |
|---|---|
| Input | spotify_data.csv |
| Documentation | spotify_README.pdf |
| Format | CSV; raw values preserved as text in Bronze |
| Reviewed source records | 114,000 |
| Reviewed catalog | 89,741 tracks; 113,550 memberships; 114 genres |
| Reviewed primary sample | 89,740 positive-duration tracks |
| Source SHA-256 | b202fa49909b2d5cef71a04b1d21243cfeb36414535f2ca9272aa646721177bd |
| Acquisition | Supplied local dataset; no API ingestion or live refresh |
| Update policy | Manual full-snapshot replacement |
| Maintenance | Project maintainer; catalog updated with schema/metric changes |
| Access and distribution | Local Windows-authenticated SQL access; independent source licensing verification is not asserted |

This is catalog data, not listening history. Load/clean/model timestamps are pipeline events, not collection dates. The dataset does not support platform market-share or user-preference claims. Counts above describe the reviewed snapshot, not hard-coded requirements for arbitrary new data.

## Object directory

| Object | Type | Grain | Produced by |
|---|---|---|---|
| `bronze.source_info` | Table | One current imported snapshot | `02_import_csv.py` |
| `bronze.raw_track` | Table | One original CSV record, including duplicates | `02_import_csv.py` |
| `silver.track` | Table | One unique track ID | `03_clean_silver.sql` |
| `silver.genre` | Table | One distinct genre | `03_clean_silver.sql` |
| `silver.track_genre` | Table | One unique track–genre membership | `03_clean_silver.sql` |
| `silver.source_mapping` | Table | One source record with its canonical reference | `03_clean_silver.sql` |
| `silver.popularity_summary` | Table | One track with all-source popularity summary | `03_clean_silver.sql` |
| `silver.source_info` | Table | One successfully cleaned source snapshot | `03_clean_silver.sql` |
| `silver.quality_results` | Table | One quality rule outcome | `03_clean_silver.sql` |
| `silver.rejected_records` | Table | One source record rejected by blocking validation | `03_clean_silver.sql` |
| `gold.pca_scores` | Table | One eligible track with three PCA scores | `04_audio_analysis.py` |
| `gold.analysis_info` | Table | One current analysis snapshot | `04_audio_analysis.py` |
| `gold.SongAnalysis` | View | One catalog track | `05_gold_views.sql` |
| `gold.GenreSongDetail` | View | One track–genre membership | `05_gold_views.sql` |
| `gold.GenreSummary` | View | One genre | `05_gold_views.sql` |
| `gold.DataQuality` | View | One current quality-rule outcome | `05_gold_views.sql` |
| `gold.SourceSummary` | View | One matched source/analysis snapshot | `05_gold_views.sql` |

## Physical table dictionary

PK = primary key; FK = foreign key. Single-column primary keys are non-null even when NOT NULL is implicit. Numeric business bounds are mostly enforced by the Silver transformation, not by table-level CHECK constraints. Bronze deliberately allows nullable raw fields; required-field validation occurs in Step 03.

### bronze.source_info

Grain: One current imported snapshot.

| Field | SQL type | Nullable | Definition |
|---|---|---|---|
| `id` | `int` | No | Singleton record key; CHECK(id=1). At most one row, not a history table. |
| `source_filename` | `nvarchar(260)` | No | Imported source filename; not a remote data-source URL. |
| `source_sha256` | `char(64)` | No | SHA-256 of the exact original CSV bytes; 64 hexadecimal characters. |
| `row_count` | `int` | No | Number of parsed source records; not physical text lines. |
| `loaded_utc` | `datetime2` | No | Database UTC timestamp of source import; not a Spotify observation time. |

Declared key/default/check definitions:

```sql
id int PRIMARY KEY CHECK(id=1)
loaded_utc datetime2 NOT NULL DEFAULT SYSUTCDATETIME()
```

### bronze.raw_track

Grain: One original CSV record, including duplicates.

| Field | SQL type | Nullable | Definition |
|---|---|---|---|
| `source_record_number` | `int` | No | One-based parsed CSV record position, excluding the header. |
| `source_export_index` | `nvarchar(100)` | Yes | Optional original export-index value, retained as text; not a song identifier. |
| `track_id` | `nvarchar(max)` | Yes | Raw CSV text. Source track identifier; case-sensitive identity key. No automatic identifier-length semantics are assumed beyond the declared storage limit. Typed validation is applied in Silver. |
| `artists` | `nvarchar(max)` | Yes | Raw CSV text. Source artist metadata; retained as a single text field, not an artist dimension. Typed validation is applied in Silver. |
| `album_name` | `nvarchar(max)` | Yes | Raw CSV text. Source album name; not a unique album identifier. Typed validation is applied in Silver. |
| `track_name` | `nvarchar(max)` | Yes | Raw CSV text. Source track title; titles need not be unique. Typed validation is applied in Silver. |
| `popularity` | `nvarchar(max)` | Yes | Raw CSV text. Source popularity observation, validated as an integer from 0 to 100 in Silver; not a latest-value claim. Typed validation is applied in Silver. |
| `duration_ms` | `nvarchar(max)` | Yes | Raw CSV text. Source track duration in milliseconds; zero is retained in the catalog and excluded from primary analysis. Typed validation is applied in Silver. |
| `explicit` | `nvarchar(max)` | Yes | Raw CSV text. Source explicit-content flag; raw true/false text is converted to a bit in Silver. Typed validation is applied in Silver. |
| `danceability` | `nvarchar(max)` | Yes | Raw CSV text; converted and validated in Silver. How easy the track feels to dance to, based on its beat, rhythm and tempo. Unit/scale: 0 to 1; no unit. See the plain-language guide for interpretation and validation notes. |
| `energy` | `nvarchar(max)` | Yes | Raw CSV text; converted and validated in Silver. How intense and active the track sounds. Unit/scale: 0 to 1; no unit. See the plain-language guide for interpretation and validation notes. |
| `key` | `nvarchar(max)` | Yes | Raw CSV text. Source musical-key integer code; code meanings are not mapped by this implementation. Typed validation is applied in Silver. |
| `loudness` | `nvarchar(max)` | Yes | Raw CSV text; converted and validated in Silver. How loud the recording is on average across the track. Unit/scale: Decibels (dB); typically -60 to 0. See the plain-language guide for interpretation and validation notes. |
| `mode` | `nvarchar(max)` | Yes | Raw CSV text. Source mode integer code; retained without an additional categorical mapping. Typed validation is applied in Silver. |
| `speechiness` | `nvarchar(max)` | Yes | Raw CSV text; converted and validated in Silver. How much the recording sounds like spoken words rather than ordinary music or singing. Unit/scale: 0 to 1; no unit. See the plain-language guide for interpretation and validation notes. |
| `acousticness` | `nvarchar(max)` | Yes | Raw CSV text; converted and validated in Silver. How likely the recording is to have an acoustic sound. Unit/scale: 0 to 1; no unit. See the plain-language guide for interpretation and validation notes. |
| `instrumentalness` | `nvarchar(max)` | Yes | Raw CSV text; converted and validated in Silver. How likely the track is to contain no vocals. Unit/scale: 0 to 1; no unit. See the plain-language guide for interpretation and validation notes. |
| `liveness` | `nvarchar(max)` | Yes | Raw CSV text; converted and validated in Silver. How strongly the recording suggests a live audience or performance setting. Unit/scale: 0 to 1; no unit. See the plain-language guide for interpretation and validation notes. |
| `valence` | `nvarchar(max)` | Yes | Raw CSV text; converted and validated in Silver. How positive or cheerful the music sounds. Unit/scale: 0 to 1; no unit. See the plain-language guide for interpretation and validation notes. |
| `tempo` | `nvarchar(max)` | Yes | Raw CSV text; converted and validated in Silver. The estimated number of beats per minute in the track. Unit/scale: Beats per minute (BPM); typically 50-250. See the plain-language guide for interpretation and validation notes. |
| `time_signature` | `nvarchar(max)` | Yes | Raw CSV text. Source time-signature integer code; retained without inventing undocumented code meanings. Typed validation is applied in Silver. |
| `track_genre` | `nvarchar(max)` | Yes | Raw CSV text. Source genre label. A track may have more than one genre. Typed validation is applied in Silver. |

Declared key/default/check definitions:

```sql
source_record_number int PRIMARY KEY
```

### silver.track

Grain: One unique track ID.

| Field | SQL type | Nullable | Definition |
|---|---|---|---|
| `track_id` | `nvarchar(100)` | No | Source track identifier; case-sensitive identity key. No automatic identifier-length semantics are assumed beyond the declared storage limit. |
| `artists` | `nvarchar(1000)` | Yes | Source artist metadata; retained as a single text field, not an artist dimension. |
| `album_name` | `nvarchar(1000)` | Yes | Source album name; not a unique album identifier. |
| `track_name` | `nvarchar(1000)` | Yes | Source track title; titles need not be unique. |
| `duration_ms` | `bigint` | No | Source track duration in milliseconds; zero is retained in the catalog and excluded from primary analysis. |
| `explicit` | `bit` | No | Source explicit-content flag; raw true/false text is converted to a bit in Silver. |
| `danceability` | `float` | No | How easy the track feels to dance to, based on its beat, rhythm and tempo. Unit/scale: 0 to 1; no unit. See the plain-language guide for interpretation and validation notes. |
| `energy` | `float` | No | How intense and active the track sounds. Unit/scale: 0 to 1; no unit. See the plain-language guide for interpretation and validation notes. |
| `key` | `int` | No | Source musical-key integer code; code meanings are not mapped by this implementation. |
| `loudness` | `float` | No | How loud the recording is on average across the track. Unit/scale: Decibels (dB); typically -60 to 0. See the plain-language guide for interpretation and validation notes. |
| `mode` | `int` | No | Source mode integer code; retained without an additional categorical mapping. |
| `speechiness` | `float` | No | How much the recording sounds like spoken words rather than ordinary music or singing. Unit/scale: 0 to 1; no unit. See the plain-language guide for interpretation and validation notes. |
| `acousticness` | `float` | No | How likely the recording is to have an acoustic sound. Unit/scale: 0 to 1; no unit. See the plain-language guide for interpretation and validation notes. |
| `instrumentalness` | `float` | No | How likely the track is to contain no vocals. Unit/scale: 0 to 1; no unit. See the plain-language guide for interpretation and validation notes. |
| `liveness` | `float` | No | How strongly the recording suggests a live audience or performance setting. Unit/scale: 0 to 1; no unit. See the plain-language guide for interpretation and validation notes. |
| `valence` | `float` | No | How positive or cheerful the music sounds. Unit/scale: 0 to 1; no unit. See the plain-language guide for interpretation and validation notes. |
| `tempo` | `float` | No | The estimated number of beats per minute in the track. Unit/scale: Beats per minute (BPM); typically 50-250. See the plain-language guide for interpretation and validation notes. |
| `time_signature` | `int` | No | Source time-signature integer code; retained without inventing undocumented code meanings. |
| `metadata_missing` | `bit` | No | 1 when artists, album_name or track_name is NULL after trimming blank metadata; otherwise 0. |
| `include_primary` | `bit` | No | 1 when duration_ms > 0; otherwise 0. Defines the primary analysis sample. |
| `tempo_warning` | `bit` | No | 1 when tempo is outside inclusive [50,250]; otherwise 0. Warning only. |
| `loudness_warning` | `bit` | No | 1 when loudness is outside inclusive [-60,0]; otherwise 0. Warning only. |

Declared key/default/check definitions:

```sql
track_id nvarchar(100) COLLATE Latin1_General_100_BIN2 PRIMARY KEY
```

### silver.genre

Grain: One distinct genre.

| Field | SQL type | Nullable | Definition |
|---|---|---|---|
| `track_genre` | `nvarchar(100)` | No | Source genre label. A track may have more than one genre. |

Declared key/default/check definitions:

```sql
track_genre nvarchar(100) COLLATE Latin1_General_100_BIN2 PRIMARY KEY
```

### silver.track_genre

Grain: One unique track–genre membership.

| Field | SQL type | Nullable | Definition |
|---|---|---|---|
| `track_id` | `nvarchar(100)` | No | Source track identifier; case-sensitive identity key. No automatic identifier-length semantics are assumed beyond the declared storage limit. |
| `track_genre` | `nvarchar(100)` | No | Source genre label. A track may have more than one genre. |

Declared key/default/check definitions:

```sql
track_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES silver.track(track_id)
track_genre nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES silver.genre(track_genre)
PRIMARY KEY(track_id,track_genre)
```

### silver.source_mapping

Grain: One source record with its canonical reference.

| Field | SQL type | Nullable | Definition |
|---|---|---|---|
| `source_record_number` | `int` | No | One-based parsed CSV record position, excluding the header. |
| `canonical_record_number` | `int` | No | Smallest source record number in the identical normalized business-record group, including popularity and genre; not a latest record. |
| `track_id` | `nvarchar(100)` | No | Source track identifier; case-sensitive identity key. No automatic identifier-length semantics are assumed beyond the declared storage limit. |
| `track_genre` | `nvarchar(100)` | No | Source genre label. A track may have more than one genre. |
| `popularity` | `int` | No | Source popularity observation, validated as an integer from 0 to 100 in Silver; not a latest-value claim. |
| `is_duplicate` | `bit` | No | 1 when source_record_number differs from canonical_record_number; otherwise 0. |

Declared key/default/check definitions:

```sql
source_record_number int PRIMARY KEY REFERENCES bronze.raw_track(source_record_number)
canonical_record_number int NOT NULL REFERENCES bronze.raw_track(source_record_number)
popularity int NOT NULL CHECK(popularity BETWEEN 0 AND 100)
FOREIGN KEY(track_id,track_genre) REFERENCES silver.track_genre(track_id,track_genre)
```

### silver.popularity_summary

Grain: One track with all-source popularity summary.

| Field | SQL type | Nullable | Definition |
|---|---|---|---|
| `track_id` | `nvarchar(100)` | No | Source track identifier; case-sensitive identity key. No automatic identifier-length semantics are assumed beyond the declared storage limit. |
| `popularity_min` | `int` | No | Minimum observed popularity over all source records for this track. |
| `popularity_max` | `int` | No | Maximum observed popularity over all source records for this track. |
| `distinct_values` | `int` | No | Number of distinct observed popularity values for this track. |
| `has_conflict` | `bit` | No | 1 when distinct_values > 1; otherwise 0. |

Declared key/default/check definitions:

```sql
track_id nvarchar(100) COLLATE Latin1_General_100_BIN2 PRIMARY KEY REFERENCES silver.track(track_id)
```

### silver.source_info

Grain: One successfully cleaned source snapshot.

| Field | SQL type | Nullable | Definition |
|---|---|---|---|
| `id` | `int` | No | Singleton record key; CHECK(id=1). At most one row, not a history table. |
| `source_sha256` | `char(64)` | No | SHA-256 of the exact original CSV bytes; 64 hexadecimal characters. |
| `cleaned_utc` | `datetime2` | No | Database UTC timestamp marking a successfully populated Silver snapshot. |

Declared key/default/check definitions:

```sql
id int PRIMARY KEY CHECK(id=1)
cleaned_utc datetime2 NOT NULL DEFAULT SYSUTCDATETIME()
```

### silver.quality_results

Grain: One quality rule outcome.

| Field | SQL type | Nullable | Definition |
|---|---|---|---|
| `rule_code` | `varchar(60)` | No | Stable identifier of the quality rule. |
| `severity` | `varchar(10)` | No | Pipeline-emitted PASS, WARN or ERROR; stored as text, without a SQL enumeration constraint. |
| `affected_count` | `int` | No | Count at the declared grain; counts across rules may overlap. |
| `grain` | `varchar(20)` | No | Pipeline-emitted track or source_record; identifies the unit counted by this rule. |
| `description` | `nvarchar(1000)` | No | Human-readable rule explanation; not executable rule logic. |

Declared key/default/check definitions:

```sql
rule_code varchar(60) PRIMARY KEY
```

### silver.rejected_records

Grain: One source record rejected by blocking validation.

| Field | SQL type | Nullable | Definition |
|---|---|---|---|
| `source_record_number` | `int` | No | One-based parsed CSV record position, excluding the header. |
| `reason` | `nvarchar(1000)` | No | Blocking rejection explanation; join to Bronze using source_record_number for raw evidence. |

Declared key/default/check definitions:

```sql
source_record_number int PRIMARY KEY REFERENCES bronze.raw_track(source_record_number)
```

### gold.pca_scores

Grain: One eligible track with three PCA scores.

| Field | SQL type | Nullable | Definition |
|---|---|---|---|
| `track_id` | `nvarchar(100)` | No | Source track identifier; case-sensitive identity key. No automatic identifier-length semantics are assumed beyond the declared storage limit. |
| `PC1` | `float` | No | First PCA component score on standardized inputs; unitless, not bounded to [0,1]. |
| `PC2` | `float` | No | Second PCA component score on standardized inputs; unitless, not bounded to [0,1]. |
| `PC3` | `float` | No | Third PCA component score on standardized inputs; unitless, not bounded to [0,1]. |

Declared key/default/check definitions:

```sql
track_id nvarchar(100) COLLATE Latin1_General_100_BIN2 PRIMARY KEY REFERENCES silver.track(track_id)
```

### gold.analysis_info

Grain: One current analysis snapshot.

| Field | SQL type | Nullable | Definition |
|---|---|---|---|
| `id` | `int` | No | Singleton record key; CHECK(id=1). At most one row, not a history table. |
| `source_sha256` | `char(64)` | No | SHA-256 of the exact original CSV bytes; 64 hexadecimal characters. |
| `sample_sha256` | `char(64)` | No | SHA-256 of the exported clean analysis CSV bytes. |
| `sample_count` | `int` | No | Number of eligible unique tracks in this model run. |
| `explained_variance_first3` | `float` | No | Sum of the first three explained-variance ratios; stored as a fraction, not a percentage. |
| `metadata_json` | `nvarchar(max)` | No | Serialized model provenance, features, scaler parameters, axes, versions and analysis time; stored as nvarchar(max), without an ISJSON constraint. |
| `analyzed_utc` | `datetime2` | No | Database UTC timestamp when current analysis metadata is inserted; can follow the model-computation timestamp. |

Declared key/default/check definitions:

```sql
id int PRIMARY KEY CHECK(id=1)
analyzed_utc datetime2 NOT NULL DEFAULT SYSUTCDATETIME()
```

## Relationships and join contracts

| From | To | Relationship |
|---|---|---|
| silver.track_genre.track_id | silver.track.track_id | Many memberships to one track; FK enforced |
| silver.track_genre.track_genre | silver.genre.track_genre | Many memberships to one genre; FK enforced |
| silver.source_mapping.source_record_number | bronze.raw_track.source_record_number | At most one mapping per source record; FK enforced |
| silver.source_mapping.canonical_record_number | bronze.raw_track.source_record_number | Many records may reference one canonical source row; FK enforced |
| silver.source_mapping.(track_id, track_genre) | silver.track_genre.(track_id, track_genre) | Many source records to one membership; composite FK enforced |
| silver.popularity_summary.track_id | silver.track.track_id | At most one summary per track; FK enforced |
| silver.rejected_records.source_record_number | bronze.raw_track.source_record_number | At most one rejection record per source row; FK enforced |
| gold.pca_scores.track_id | silver.track.track_id | At most one score row per track; FK enforced; only eligible tracks populated |
| Snapshot source_sha256 fields | Matching source_sha256 fields | Equality join in reporting views; not an FK |

A successful pipeline populates every track's popularity summary and every source record's mapping. Those coverage conditions are transformation/acceptance contracts, not guarantees supplied by an FK alone.

## Gold view dictionary

### gold.SongAnalysis

Track grain. Fields inherited unchanged from silver.track: `track_id`, `artists`, `album_name`, `track_name`, `duration_ms`, the nine audio features, `key`, `mode` and `time_signature`. Their definitions/types are listed above. The following columns are derived, renamed or joined:

| Field | Result type | Definition / possible NULL |
|---|---|---|
| track_name_display | nvarchar(1000) | track_name or 'Unknown track'; non-null display value |
| artists_display | nvarchar(1000) | artists or 'Unknown artist'; non-null display value |
| duration_minutes | decimal(28,6) | duration_ms / 60000.0; non-null for returned tracks |
| explicit | int | Converted Silver bit, 0/1 |
| metadata_missing, include_primary, tempo_warning, loudness_warning | int | Converted Silver flags, 0/1 |
| popularity_min, popularity_max | int | Joined track-level popularity bounds |
| popularity_distinct_values | int | Renamed popularity_summary.distinct_values |
| popularity_conflict | int | Converted popularity_summary.has_conflict, 0/1 |
| popularity_unambiguous | int | popularity_min only when has_conflict=0; NULL otherwise |
| PC1, PC2, PC3 | float | Left-joined PCA scores; NULL for tracks without a score, including excluded tracks |
| genre_count | int | Count of the track's unique memberships across the complete snapshot |

Reporting requires matching Bronze, Silver and model source fingerprints. The view can return no rows after an incomplete refresh. A matching model hash alone is not a substitute for Step 06 score-coverage checks.

### gold.GenreSongDetail

Contains every SongAnalysis column, plus:

| Field | Result type | Definition |
|---|---|---|
| track_genre | nvarchar(100) | Genre from silver.track_genre; part of the logical view key |
| fractional_catalog_weight | decimal(14,12) | 1.0 / genre_count; allocation uses the track's full-snapshot membership count |

Logical unique key: (track_id, track_genre). Views do not declare a physical PK. Fractional weights sum approximately to the catalog count over all memberships; they are not distinct-song counts within a partial genre selection or market-share estimates.

### gold.GenreSummary

| Field | Result type | Definition |
|---|---|---|
| track_genre | nvarchar(100) | Grouping genre |
| catalog_track_count | int | Membership count within one genre, equal to unique tracks in that genre |
| analysis_track_count | int | Sum of include_primary within the genre |
| analysis_mean_energy | float | Eligible-track mean energy |
| analysis_mean_danceability | float | Eligible-track mean danceability |
| analysis_mean_acousticness | float | Eligible-track mean acousticness |
| analysis_mean_valence | float | Eligible-track mean valence |
| analysis_mean_duration_minutes | decimal(38,6) | Eligible-track mean duration in minutes |
| popularity_conflict_count | int | Sum of popularity-conflict flags |
| metadata_missing_count | int | Sum of missing-metadata flags |
| fractional_catalog_equivalents | decimal(38,12) | Sum of fractional membership weights |

Means are NULL when a genre has no eligible tracks. Genre-level counts overlap across genres. These SQL aggregates do not recompute under arbitrary Power BI song filters.

### gold.DataQuality

Exposes `rule_code`, `severity`, `affected_count`, `grain` and `description` unchanged from silver.quality_results, using the same types. It requires current Silver/Bronze provenance, but not completed model output. Blocking-error details may need direct inspection of Silver because the readiness marker is removed on failure.

### gold.SourceSummary

| Field | Result type | Origin |
|---|---|---|
| source_filename | nvarchar(260) | bronze.source_info.source_filename |
| source_sha256 | char(64) | bronze.source_info.source_sha256 |
| source_record_count | int | bronze.source_info.row_count |
| loaded_utc | datetime2 | bronze.source_info.loaded_utc |
| cleaned_utc | datetime2 | silver.source_info.cleaned_utc |
| analyzed_utc | datetime2 | gold.analysis_info.analyzed_utc |
| analysis_track_count | int | gold.analysis_info.sample_count |
| explained_variance_first3 | float | gold.analysis_info.explained_variance_first3 |
| catalog_track_count | int | COUNT(*) of silver.track |
| track_genre_pair_count | int | COUNT(*) of silver.track_genre |
| genre_count | int | COUNT(*) of silver.genre |

One row is expected only after source, cleaning and analysis fingerprints match. Scalar counts describe the full snapshot.

## Quality-rule index

| Rule code | Severity | Count grain | Action |
|---|---|---|---|
| blocking_source_errors | ERROR | source_record | Store rejected records, invalidate Silver readiness and stop |
| required_values | PASS | source_record | Record successful key/type/length/hard-range validation with zero affected rows |
| redundant_records | WARN | source_record | Retain mapping and canonical record reference |
| popularity_conflicts | WARN | track | Retain observed range; do not infer the latest value |
| metadata_missing | WARN | track | Retain track and expose display fallbacks |
| excluded_duration | WARN | track | Retain zero-duration catalog tracks but exclude from primary analysis |
| tempo_typical_range | WARN | track | Retain records outside [50,250] |
| loudness_typical_range | WARN | track | Retain records outside [-60,0] |

Full policy: [QUALITY_RULES.md](QUALITY_RULES.md). Rule counts can overlap. Stable-attribute conflicts exclude popularity/genre from the comparison and block cleaning; redundant-record grouping includes them. The report displays the tempo warning range as 50-250 BPM.

## Lineage and analytical consumers

```text
CSV bytes -> bronze.source_info.source_sha256
CSV record -> bronze.raw_track.source_record_number
           -> silver.source_mapping -> track / track_genre
                                    -> popularity_summary
silver.track WHERE include_primary=1
           -> clean_audio_features.csv + sample_manifest.json
           -> standardization + PCA -> gold.pca_scores / analysis_info
           -> FA / ICA / bootstrap -> local research outputs
gold.SongAnalysis -> gold.GenreSongDetail -> Power BI GenreSongs
```

Power BI imports GenreSongDetail as `GenreSongs`. DataQuality and SourceSummary provide disconnected full-snapshot panels in the reporting design. `[Catalog Songs]` counts distinct track IDs; feature means average each eligible selected track once. `popularity_unambiguous` must not be filled with zero for conflicting tracks. PCA scores are exploratory coordinates, not rankings or recommendation probabilities. DAX definitions: [measures.dax](powerbi/measures.dax). Report pages and aggregation contracts: [Power BI report](powerbi/README.md). Page 2 applies `include_primary = 1`; Page 3 displays full-snapshot rule results, filters the warning chart to `WARN`, and omits the rule-count total. `explained_variance_first3` is displayed as a percentage for all three components, not just the two plotted axes.

## Refresh, retention and maintenance

Step 02 replaces the current snapshot transactionally and clears derived SQL records. Step 03 rebuilds Silver and invalidates PCA. Step 04 writes matching scores/model metadata; Step 05 defines views; Step 06 validates coverage and reconciliation. Run stages sequentially and refresh Power BI only after successful acceptance. Reproduction entry point: [Quick start](README.md#quick-start).

The database does not retain immutable batch history. Local outputs may contain older files after a partial run; consult run_status.json. Compact accepted evidence is retained separately in reports/evidence. Update this catalog whenever schema, eligibility, metric definitions or output contracts change. SQL Server permission roles, automated stewardship workflows and retention enforcement are not implemented by this document.
