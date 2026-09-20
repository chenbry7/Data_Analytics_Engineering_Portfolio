-- Step 3.1: verify Bronze readiness and convert raw values into a temporary stage.
-- Step 3.2: identify blocking value and stable-attribute conflicts.
-- Step 3.3: persist rejected-row evidence and invalidate readiness on failure.
-- Step 3.4: rebuild normalized Silver entities and source lineage atomically.
-- Step 3.5: record warnings, reconcile row counts and mark Silver ready.

-- STEP 3: SSMS. Run only after STEP 2 commits Bronze.
-- Rebuilding Silver clears prior PCA output; run STEP 4 afterwards.
USE Spotify;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
-- This is a manual, single-user workflow. Do not run import/clean/analysis concurrently.
-- Acceptance condition: Run Step 2 first.
IF NOT EXISTS(SELECT 1 FROM bronze.source_info) THROW 51000,'Run Step 2 first',1;
-- Acceptance condition: Bronze source count mismatch.
IF (SELECT COUNT(*) FROM bronze.raw_track)<>(SELECT row_count FROM bronze.source_info WHERE id=1) THROW 51000,'Bronze source count mismatch',1;
-- Discard the previous session-local conversion stage before rebuilding it.
IF OBJECT_ID('tempdb..#stage') IS NOT NULL DROP TABLE #stage;
-- Discard the previous session-local rejected-record list.
IF OBJECT_ID('tempdb..#invalid') IS NOT NULL DROP TABLE #invalid;
-- Discard the previous session-local stable-attribute conflict list.
IF OBJECT_ID('tempdb..#conflicts') IS NOT NULL DROP TABLE #conflicts;
-- Create #stage: convert raw text to typed values while retaining source record numbers.
SELECT source_record_number,
TRY_CONVERT(nvarchar(100),NULLIF([track_id],N'')) COLLATE Latin1_General_100_BIN2 AS [track_id],
CONVERT(nvarchar(1000),NULLIF(LTRIM(RTRIM([artists])),N'')) COLLATE Latin1_General_100_BIN2 AS [artists],
CONVERT(nvarchar(1000),NULLIF(LTRIM(RTRIM([album_name])),N'')) COLLATE Latin1_General_100_BIN2 AS [album_name],
CONVERT(nvarchar(1000),NULLIF(LTRIM(RTRIM([track_name])),N'')) COLLATE Latin1_General_100_BIN2 AS [track_name],
TRY_CONVERT(int,NULLIF([popularity],N'')) AS [popularity],
TRY_CONVERT(bigint,NULLIF([duration_ms],N'')) AS [duration_ms],
CASE LOWER([explicit]) WHEN N'true' THEN CONVERT(bit,1) WHEN N'false' THEN CONVERT(bit,0) END AS [explicit],
TRY_CONVERT(float,NULLIF([danceability],N'')) AS [danceability],
TRY_CONVERT(float,NULLIF([energy],N'')) AS [energy],
TRY_CONVERT(int,NULLIF([key],N'')) AS [key],
TRY_CONVERT(float,NULLIF([loudness],N'')) AS [loudness],
TRY_CONVERT(int,NULLIF([mode],N'')) AS [mode],
TRY_CONVERT(float,NULLIF([speechiness],N'')) AS [speechiness],
TRY_CONVERT(float,NULLIF([acousticness],N'')) AS [acousticness],
TRY_CONVERT(float,NULLIF([instrumentalness],N'')) AS [instrumentalness],
TRY_CONVERT(float,NULLIF([liveness],N'')) AS [liveness],
TRY_CONVERT(float,NULLIF([valence],N'')) AS [valence],
TRY_CONVERT(float,NULLIF([tempo],N'')) AS [tempo],
TRY_CONVERT(int,NULLIF([time_signature],N'')) AS [time_signature],
TRY_CONVERT(nvarchar(100),NULLIF([track_genre],N'')) COLLATE Latin1_General_100_BIN2 AS [track_genre]
INTO #stage FROM bronze.raw_track;
-- Create #invalid: identify missing values, conversion failures, excessive lengths and hard-range violations.
SELECT s.source_record_number,CONVERT(nvarchar(1000),N'Invalid required value, length, type, key or hard numeric range; inspect Bronze') AS reason INTO #invalid
FROM #stage s JOIN bronze.raw_track r ON r.source_record_number=s.source_record_number
WHERE (s.[track_id] IS NULL)
    OR (s.[popularity] IS NULL)
    OR (s.[duration_ms] IS NULL)
    OR (s.[explicit] IS NULL)
    OR (s.[danceability] IS NULL)
    OR (s.[energy] IS NULL)
    OR (s.[key] IS NULL)
    OR (s.[loudness] IS NULL)
    OR (s.[mode] IS NULL)
    OR (s.[speechiness] IS NULL)
    OR (s.[acousticness] IS NULL)
    OR (s.[instrumentalness] IS NULL)
    OR (s.[liveness] IS NULL)
    OR (s.[valence] IS NULL)
    OR (s.[tempo] IS NULL)
    OR (s.[time_signature] IS NULL)
    OR (s.[track_genre] IS NULL)
    OR (NULLIF(LTRIM(RTRIM(s.[track_id])),N'') IS NULL
    OR DATALENGTH(r.[track_id])>200
    OR DATALENGTH(r.[track_id])<>DATALENGTH(LTRIM(RTRIM(r.[track_id]))))
    OR (NULLIF(LTRIM(RTRIM(s.[track_genre])),N'') IS NULL
    OR DATALENGTH(r.[track_genre])>200
    OR DATALENGTH(r.[track_genre])<>DATALENGTH(LTRIM(RTRIM(r.[track_genre]))))
    OR (DATALENGTH(r.[artists])>2000)
    OR (DATALENGTH(r.[album_name])>2000)
    OR (DATALENGTH(r.[track_name])>2000)
    OR (s.[danceability] NOT BETWEEN 0 AND 1)
    OR (s.[energy] NOT BETWEEN 0 AND 1)
    OR (s.[speechiness] NOT BETWEEN 0 AND 1)
    OR (s.[acousticness] NOT BETWEEN 0 AND 1)
    OR (s.[instrumentalness] NOT BETWEEN 0 AND 1)
    OR (s.[liveness] NOT BETWEEN 0 AND 1)
    OR (s.[valence] NOT BETWEEN 0 AND 1)
    OR (s.popularity NOT BETWEEN 0 AND 100)
    OR (s.duration_ms<0)
    OR (s.tempo<0);
-- Create #conflicts: identify song IDs with more than one set of stable attributes.
SELECT track_id INTO #conflicts
FROM (SELECT DISTINCT [track_id],[artists],[album_name],[track_name],[duration_ms],[explicit],[danceability],[energy],[key],[loudness],[mode],[speechiness],[acousticness],[instrumentalness],[liveness],[valence],[tempo],[time_signature]
FROM #stage) t
GROUP BY track_id HAVING COUNT(*)>1;
-- Add conflicting source rows to #invalid without duplicating already rejected rows.
INSERT #invalid SELECT s.source_record_number,N'Same track ID has conflicting stable attributes'
FROM #stage s JOIN #conflicts c ON c.track_id=s.track_id
WHERE NOT EXISTS(SELECT 1 FROM #invalid i WHERE i.source_record_number=s.source_record_number);
-- On blocking errors, save diagnostic evidence and stop before rebuilding cleaned entities.
IF EXISTS(SELECT 1 FROM #invalid)
BEGIN
 -- Start an atomic transaction for the following writes.
 BEGIN TRAN;
 -- Clear silver.rejected_records so this transaction does not mix old and new derived records.
 DELETE FROM silver.rejected_records;
 -- Clear silver.quality_results so this transaction does not mix old and new derived records.
 DELETE FROM silver.quality_results;
-- Populate silver.rejected_records: Preserve source record numbers and reasons for blocking validation errors.
 INSERT silver.rejected_records SELECT * FROM #invalid;
-- Record the blocking_source_errors quality rule and its affected-record count.
 INSERT silver.quality_results SELECT 'blocking_source_errors','ERROR',COUNT(*),'source_record','Fix source data; no successful Silver rebuild' FROM #invalid;
 -- Remove readiness marker so existing Gold views do not expose stale results.
 -- Clear silver.source_info so this transaction does not mix old and new derived records.
 DELETE FROM silver.source_info;
 -- Commit all writes in this transaction together.
 COMMIT;
 SELECT * FROM silver.rejected_records;
 THROW 51000,'Quality checks failed; inspect silver.rejected_records and corresponding Bronze rows',1;
END;
BEGIN TRY
 -- Start an atomic transaction for the following writes.
 BEGIN TRAN;
 -- Clear gold.pca_scores so this transaction does not mix old and new derived records.
 DELETE FROM gold.pca_scores;
 -- Clear gold.analysis_info so this transaction does not mix old and new derived records.
 DELETE FROM gold.analysis_info;
 -- Clear silver.source_mapping so this transaction does not mix old and new derived records.
 DELETE FROM silver.source_mapping;
 -- Clear silver.track_genre so this transaction does not mix old and new derived records.
 DELETE FROM silver.track_genre;
 -- Clear silver.popularity_summary so this transaction does not mix old and new derived records.
 DELETE FROM silver.popularity_summary;
 -- Clear silver.track so this transaction does not mix old and new derived records.
 DELETE FROM silver.track;
 -- Clear silver.genre so this transaction does not mix old and new derived records.
 DELETE FROM silver.genre;
 -- Clear silver.source_info so this transaction does not mix old and new derived records.
 DELETE FROM silver.source_info;
 -- Clear silver.rejected_records so this transaction does not mix old and new derived records.
 DELETE FROM silver.rejected_records;
 -- Clear silver.quality_results so this transaction does not mix old and new derived records.
 DELETE FROM silver.quality_results;
-- Populate silver.track: Store one cleaned row per song, with typed audio features and analysis eligibility flags.
 INSERT silver.track([track_id],[artists],[album_name],[track_name],[duration_ms],[explicit],[danceability],[energy],[key],[loudness],[mode],[speechiness],[acousticness],[instrumentalness],[liveness],[valence],[tempo],[time_signature],metadata_missing,include_primary,tempo_warning,loudness_warning)
SELECT DISTINCT [track_id],[artists],[album_name],[track_name],[duration_ms],[explicit],[danceability],[energy],[key],[loudness],[mode],[speechiness],[acousticness],[instrumentalness],[liveness],[valence],[tempo],[time_signature],CASE WHEN artists IS NULL
    OR album_name IS NULL
    OR track_name IS NULL THEN 1 ELSE 0 END,CASE WHEN duration_ms>0 THEN 1 ELSE 0 END,CASE WHEN tempo BETWEEN 50 AND 250 THEN 0 ELSE 1 END,CASE WHEN loudness BETWEEN -60 AND 0 THEN 0 ELSE 1 END
FROM #stage;
-- Populate silver.genre: Store the distinct genre vocabulary without repeating song attributes.
 INSERT silver.genre SELECT DISTINCT track_genre FROM #stage;
-- Populate silver.track_genre: Store one unique song/genre relationship; retain songs belonging to multiple genres.
 INSERT silver.track_genre SELECT DISTINCT track_id,track_genre FROM #stage;
-- Choose the earliest source record as the canonical reference for each duplicate group.
 ;WITH numbered AS (SELECT *,MIN(source_record_number) OVER(PARTITION BY [track_id],[artists],[album_name],[track_name],[popularity],[duration_ms],[explicit],[danceability],[energy],[key],[loudness],[mode],[speechiness],[acousticness],[instrumentalness],[liveness],[valence],[tempo],[time_signature],[track_genre]) AS canonical
FROM #stage)
-- Populate silver.source_mapping: Map every source record to its canonical record and cleaned song/genre relationship.
 INSERT silver.source_mapping SELECT source_record_number,canonical,track_id,track_genre,popularity,CASE WHEN canonical=source_record_number THEN 0 ELSE 1 END FROM numbered;
-- Populate silver.popularity_summary: Store each song's popularity range, distinct observation count and conflict indicator.
 INSERT silver.popularity_summary
SELECT track_id,MIN(popularity),MAX(popularity),COUNT(DISTINCT popularity),CASE WHEN COUNT(DISTINCT popularity)>1 THEN 1 ELSE 0 END
FROM #stage
GROUP BY track_id;
-- Record the redundant_records quality rule and its affected-record count.
 INSERT silver.quality_results
SELECT 'redundant_records','WARN',SUM(CONVERT(int,is_duplicate)),'source_record','Business duplicates retain canonical source references'
FROM silver.source_mapping;
-- Record the popularity_conflicts quality rule and its affected-record count.
 INSERT silver.quality_results
SELECT 'popularity_conflicts','WARN',SUM(CONVERT(int,has_conflict)),'track','Retain all observations; no latest value without timestamps'
FROM silver.popularity_summary;
-- Record the metadata_missing quality rule and its affected-record count.
 INSERT silver.quality_results SELECT 'metadata_missing','WARN',SUM(CONVERT(int,metadata_missing)),'track','Display metadata blank; source preserved in Bronze' FROM silver.track;
-- Record the excluded_duration quality rule and its affected-record count.
 INSERT silver.quality_results SELECT 'excluded_duration','WARN',COUNT(*),'track','Zero duration excluded from primary audio analysis' FROM silver.track WHERE include_primary=0;
-- Record the tempo_typical_range quality rule and its affected-record count.
 INSERT silver.quality_results SELECT 'tempo_typical_range','WARN',SUM(CONVERT(int,tempo_warning)),'track','Outside typical 50-250 BPM; warning only' FROM silver.track;
-- Record the loudness_typical_range quality rule and its affected-record count.
 INSERT silver.quality_results SELECT 'loudness_typical_range','WARN',SUM(CONVERT(int,loudness_warning)),'track','Outside approximate -60 to 0 dB; warning only' FROM silver.track;
-- Record the required_values quality rule and its affected-record count.
 INSERT silver.quality_results VALUES('required_values','PASS',0,'source_record','Required keys, conversions and hard ranges passed');
-- Acceptance condition: Source mapping count mismatch.
 IF (SELECT COUNT(*) FROM silver.source_mapping)<>(SELECT row_count FROM bronze.source_info WHERE id=1) THROW 51000,'Source mapping count mismatch',1;
-- Populate silver.source_info: Record the source fingerprint and timestamp of the successful Silver rebuild.
 INSERT silver.source_info(id,source_sha256) SELECT 1,source_sha256 FROM bronze.source_info WHERE id=1;
 -- Commit all writes in this transaction together.
 COMMIT;
END TRY BEGIN CATCH
 -- Restore the previous committed state if the rebuild failed.
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
-- Display the completed quality-rule results for review.
SELECT * FROM silver.quality_results;
-- Display catalog and eligible-analysis counts at the song grain.
SELECT COUNT(*) AS unique_tracks,SUM(CONVERT(int,include_primary)) AS analysis_tracks FROM silver.track;
SELECT 'STEP 3 complete: run 04_audio_analysis.py in VS Code' AS next_step;
GO
