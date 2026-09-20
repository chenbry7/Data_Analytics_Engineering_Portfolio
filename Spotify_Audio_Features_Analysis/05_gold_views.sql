-- Step 5.1: expose one-row-per-song analysis with current-source readiness checks.
-- Step 5.2: expose song/genre memberships and genre summaries at explicit grains.
-- Step 5.3: expose full-snapshot quality and source metadata for reporting.

-- STEP 5: SSMS. Create report views after Step 4.
USE Spotify;
GO
-- Create a one-row-per-song view combining features, popularity and optional PCA scores.
-- Require matching Bronze, Silver and model provenance to prevent stale reporting.
CREATE OR ALTER VIEW gold.SongAnalysis AS
SELECT t.track_id,t.artists,t.album_name,t.track_name,
 COALESCE(t.track_name,N'Unknown track') AS track_name_display,
 COALESCE(t.artists,N'Unknown artist') AS artists_display,
 t.duration_ms,t.duration_ms/60000.0 AS duration_minutes,CONVERT(int,t.explicit) AS explicit,
 t.danceability,t.energy,t.loudness,t.speechiness,t.acousticness,t.instrumentalness,t.liveness,t.valence,t.tempo,
 t.[key],t.mode,t.time_signature,
 CONVERT(int,t.metadata_missing) AS metadata_missing,
 CONVERT(int,t.include_primary) AS include_primary,
 CONVERT(int,t.tempo_warning) AS tempo_warning,
 CONVERT(int,t.loudness_warning) AS loudness_warning,
 p.popularity_min,p.popularity_max,p.distinct_values AS popularity_distinct_values,
 CONVERT(int,p.has_conflict) AS popularity_conflict,
 CASE WHEN p.has_conflict=0 THEN p.popularity_min END AS popularity_unambiguous,
 s.PC1,s.PC2,s.PC3,g.genre_count
FROM silver.track t
-- Attach one popularity summary per song without choosing an unsupported latest observation.
JOIN silver.popularity_summary p ON p.track_id=t.track_id
JOIN (SELECT track_id,COUNT(*) AS genre_count FROM silver.track_genre GROUP BY track_id) g ON g.track_id=t.track_id
-- Keep excluded catalog songs visible even though they do not receive PCA scores.
LEFT JOIN gold.pca_scores s ON s.track_id=t.track_id
CROSS JOIN silver.source_info si
JOIN bronze.source_info bi ON bi.source_sha256=si.source_sha256
JOIN gold.analysis_info ai ON ai.source_sha256=si.source_sha256
WHERE si.id=1 AND bi.id=1 AND ai.id=1;
GO
-- Create one row per song/genre membership for Power BI filtering.
-- Allocate each song a weight of 1 / genre_count for additive catalog equivalents.
CREATE OR ALTER VIEW gold.GenreSongDetail AS
SELECT b.track_genre,s.*,1.0/s.genre_count AS fractional_catalog_weight
FROM gold.SongAnalysis s JOIN silver.track_genre b ON b.track_id=s.track_id;
GO
-- Aggregate song/genre memberships into one row per genre.
-- Calculate audio averages only for eligible songs; retain catalog and quality counts.
CREATE OR ALTER VIEW gold.GenreSummary AS
SELECT track_genre,COUNT(*) AS catalog_track_count,SUM(include_primary) AS analysis_track_count,
 AVG(CASE WHEN include_primary=1 THEN energy END) AS analysis_mean_energy,
 AVG(CASE WHEN include_primary=1 THEN danceability END) AS analysis_mean_danceability,
 AVG(CASE WHEN include_primary=1 THEN acousticness END) AS analysis_mean_acousticness,
 AVG(CASE WHEN include_primary=1 THEN valence END) AS analysis_mean_valence,
 AVG(CASE WHEN include_primary=1 THEN duration_minutes END) AS analysis_mean_duration_minutes,
 SUM(popularity_conflict) AS popularity_conflict_count,SUM(metadata_missing) AS metadata_missing_count,
 SUM(fractional_catalog_weight) AS fractional_catalog_equivalents
FROM gold.GenreSongDetail GROUP BY track_genre;
GO
-- Expose rule outcomes for the current cleaned snapshot, independent of report filters.
CREATE OR ALTER VIEW gold.DataQuality AS
SELECT q.rule_code,q.severity,q.affected_count,q.grain,q.description
FROM silver.quality_results q
CROSS JOIN silver.source_info si JOIN bronze.source_info bi ON bi.source_sha256=si.source_sha256
WHERE si.id=1 AND bi.id=1;
GO
-- Expose one matching source/model snapshot with catalog counts and analysis metadata.
CREATE OR ALTER VIEW gold.SourceSummary AS
SELECT b.source_filename,b.source_sha256,b.row_count AS source_record_count,b.loaded_utc,
 s.cleaned_utc,a.analyzed_utc,a.sample_count AS analysis_track_count,a.explained_variance_first3,
 (SELECT COUNT(*) FROM silver.track) AS catalog_track_count,
 (SELECT COUNT(*) FROM silver.track_genre) AS track_genre_pair_count,
 (SELECT COUNT(*) FROM silver.genre) AS genre_count
FROM bronze.source_info b JOIN silver.source_info s ON s.source_sha256=b.source_sha256
JOIN gold.analysis_info a ON a.source_sha256=b.source_sha256
WHERE b.id=1 AND s.id=1 AND a.id=1;
GO
-- Preview the ready source/model snapshot.
SELECT * FROM gold.SourceSummary;
-- Preview ten genre aggregates before running final acceptance checks.
SELECT TOP(10) * FROM gold.GenreSummary ORDER BY track_genre;
SELECT 'STEP 5 complete: run 06_checks.sql, then connect Power BI to Gold views' AS next_step;
GO
