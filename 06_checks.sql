-- Step 6.1: verify readiness, quality status and source-to-Silver reconciliation.
-- Step 6.2: validate PCA coverage and Gold join cardinality.
-- Step 6.3: apply original-snapshot benchmarks only when its hash matches.
-- Step 6.4: return acceptance evidence and deduplicated metric examples.

-- STEP 6: SSMS validation. These checks do not modify data.
USE Spotify;
GO
SET NOCOUNT ON;
-- Acceptance condition: No ready source; run Steps 2-5 in order.
IF (SELECT COUNT(*) FROM gold.SourceSummary)<>1 THROW 51000,'No ready source; run Steps 2-5 in order',1;
-- Acceptance condition: Quality errors remain.
IF EXISTS(SELECT 1 FROM silver.quality_results WHERE severity='ERROR') THROW 51000,'Quality errors remain',1;
-- Acceptance condition: Bronze count mismatch.
IF (SELECT COUNT(*) FROM bronze.raw_track)<>(SELECT row_count FROM bronze.source_info WHERE id=1) THROW 51000,'Bronze count mismatch',1;
-- Acceptance condition: Lost source lineage records.
IF (SELECT COUNT(*) FROM silver.source_mapping)<>(SELECT COUNT(*) FROM bronze.raw_track) THROW 51000,'Lost source lineage records',1;
-- Acceptance condition: PCA coverage mismatch.
IF (SELECT COUNT(*) FROM gold.pca_scores)<>(SELECT COUNT(*) FROM silver.track WHERE include_primary=1) THROW 51000,'PCA coverage mismatch',1;
-- Acceptance condition: Excluded song has PCA score.
IF EXISTS(SELECT 1 FROM gold.pca_scores p JOIN silver.track t ON t.track_id=p.track_id WHERE t.include_primary=0) THROW 51000,'Excluded song has PCA score',1;
-- Acceptance condition: Gold song count mismatch.
IF (SELECT COUNT(*) FROM gold.SongAnalysis)<>(SELECT COUNT(*) FROM silver.track) THROW 51000,'Gold song count mismatch',1;
-- Acceptance condition: Gold join multiplied memberships.
IF (SELECT COUNT(*) FROM gold.GenreSongDetail)<>(SELECT COUNT(*) FROM silver.track_genre) THROW 51000,'Gold join multiplied memberships',1;
-- Acceptance condition: Fractional counts do not reconcile.
IF ABS((SELECT SUM(fractional_catalog_equivalents) FROM gold.GenreSummary)-(SELECT COUNT(*) FROM silver.track))>0.1 THROW 51000,'Fractional counts do not reconcile',1;
-- Only apply historical exact reference counts to the supplied original file.
IF (SELECT source_sha256 FROM bronze.source_info WHERE id=1)='b202fa49909b2d5cef71a04b1d21243cfeb36414535f2ca9272aa646721177bd'
BEGIN
-- Acceptance condition: Expected 114000 source records.
 IF (SELECT COUNT(*) FROM bronze.raw_track)<>114000 THROW 51000,'Expected 114000 source records',1;
-- Acceptance condition: Expected 89741 unique tracks.
 IF (SELECT COUNT(*) FROM silver.track)<>89741 THROW 51000,'Expected 89741 unique tracks',1;
-- Acceptance condition: Expected 113550 memberships.
 IF (SELECT COUNT(*) FROM silver.track_genre)<>113550 THROW 51000,'Expected 113550 memberships',1;
-- Acceptance condition: Expected 450 redundant source rows.
 IF (SELECT SUM(CONVERT(int,is_duplicate)) FROM silver.source_mapping)<>450 THROW 51000,'Expected 450 redundant source rows',1;
-- Acceptance condition: Expected 720 popularity conflicts.
 IF (SELECT SUM(CONVERT(int,has_conflict)) FROM silver.popularity_summary)<>720 THROW 51000,'Expected 720 popularity conflicts',1;
-- Acceptance condition: Expected 89740 eligible tracks.
 IF (SELECT COUNT(*) FROM gold.pca_scores)<>89740 THROW 51000,'Expected 89740 eligible tracks',1;
END;
SELECT 'PASS: source, quality, lineage, PCA and Gold checks' AS result;
SELECT * FROM gold.SourceSummary;
SELECT * FROM gold.DataQuality;
SELECT AVG(energy) AS mean_energy,AVG(danceability) AS mean_danceability,AVG(duration_minutes) AS mean_duration_minutes
FROM gold.SongAnalysis WHERE include_primary=1;
-- Cross-genre selection: deduplicate songs before averaging.
SELECT COUNT(*) AS unique_selected_songs,AVG(energy) AS mean_energy
FROM gold.SongAnalysis s
WHERE include_primary=1 AND EXISTS(SELECT 1 FROM silver.track_genre g WHERE g.track_id=s.track_id AND g.track_genre IN ('pop','pop-film'));
GO
