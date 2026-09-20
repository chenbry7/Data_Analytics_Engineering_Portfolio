-- Step 1.1: create the dedicated database if absent.
-- Step 1.2: create Bronze, Silver and Gold schemas.
-- Step 1.3: create raw, cleaned, lineage, quality and model-result tables.
-- Existing tables are preserved; this file does not migrate incompatible schemas.

-- STEP 1: SSMS. Run this complete file once; rerunning does not drop data.
-- A separate database avoids changing any previously deployed advanced version.
USE master;
GO
IF DB_ID('Spotify') IS NULL
 EXEC(N'CREATE DATABASE Spotify COLLATE Latin1_General_100_BIN2');
GO
USE Spotify;
GO
IF SCHEMA_ID('bronze') IS NULL EXEC(N'CREATE SCHEMA bronze AUTHORIZATION dbo');
GO
IF SCHEMA_ID('silver') IS NULL EXEC(N'CREATE SCHEMA silver AUTHORIZATION dbo');
GO
IF SCHEMA_ID('gold') IS NULL EXEC(N'CREATE SCHEMA gold AUTHORIZATION dbo');
GO
-- Create bronze.source_info.
-- Store one source snapshot fingerprint, filename, row count and import timestamp.
IF OBJECT_ID('bronze.source_info','U') IS NULL
BEGIN
    CREATE TABLE bronze.source_info (
        id int PRIMARY KEY CHECK(id=1),
        source_filename nvarchar(260) NOT NULL,
        source_sha256 char(64) NOT NULL,
        row_count int NOT NULL,
        loaded_utc datetime2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO
-- Create bronze.raw_track.
-- Preserve every CSV record as raw text, keyed by its original record number.
IF OBJECT_ID('bronze.raw_track','U') IS NULL
BEGIN
    CREATE TABLE bronze.raw_track (
        source_record_number int PRIMARY KEY,
        source_export_index nvarchar(100) NULL,
        [track_id] nvarchar(max) NULL,
        [artists] nvarchar(max) NULL,
        [album_name] nvarchar(max) NULL,
        [track_name] nvarchar(max) NULL,
        [popularity] nvarchar(max) NULL,
        [duration_ms] nvarchar(max) NULL,
        [explicit] nvarchar(max) NULL,
        [danceability] nvarchar(max) NULL,
        [energy] nvarchar(max) NULL,
        [key] nvarchar(max) NULL,
        [loudness] nvarchar(max) NULL,
        [mode] nvarchar(max) NULL,
        [speechiness] nvarchar(max) NULL,
        [acousticness] nvarchar(max) NULL,
        [instrumentalness] nvarchar(max) NULL,
        [liveness] nvarchar(max) NULL,
        [valence] nvarchar(max) NULL,
        [tempo] nvarchar(max) NULL,
        [time_signature] nvarchar(max) NULL,
        [track_genre] nvarchar(max) NULL
    );
END;
GO
-- Create silver.track.
-- Store one cleaned row per song, with typed audio features and analysis eligibility flags.
IF OBJECT_ID('silver.track','U') IS NULL
BEGIN
    CREATE TABLE silver.track (
        track_id nvarchar(100) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,
        [artists] nvarchar(1000) NULL,
        [album_name] nvarchar(1000) NULL,
        [track_name] nvarchar(1000) NULL,
        [duration_ms] bigint NOT NULL,
        [explicit] bit NOT NULL,
        [danceability] float NOT NULL,
        [energy] float NOT NULL,
        [key] int NOT NULL,
        [loudness] float NOT NULL,
        [mode] int NOT NULL,
        [speechiness] float NOT NULL,
        [acousticness] float NOT NULL,
        [instrumentalness] float NOT NULL,
        [liveness] float NOT NULL,
        [valence] float NOT NULL,
        [tempo] float NOT NULL,
        [time_signature] int NOT NULL,
        metadata_missing bit NOT NULL,
        include_primary bit NOT NULL,
        tempo_warning bit NOT NULL,
        loudness_warning bit NOT NULL
    );
END;
GO
-- Create silver.genre.
-- Store the distinct genre vocabulary without repeating song attributes.
IF OBJECT_ID('silver.genre','U') IS NULL
BEGIN
    CREATE TABLE silver.genre (
        track_genre nvarchar(100) COLLATE Latin1_General_100_BIN2 PRIMARY KEY
    );
END;
GO
-- Create silver.track_genre.
-- Store one unique song/genre relationship; retain songs belonging to multiple genres.
IF OBJECT_ID('silver.track_genre','U') IS NULL
BEGIN
    CREATE TABLE silver.track_genre (
        track_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES silver.track(track_id),
        track_genre nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES silver.genre(track_genre),
        PRIMARY KEY(track_id,track_genre)
    );
END;
GO
-- Create silver.source_mapping.
-- Map every source record to its canonical record and cleaned song/genre relationship.
IF OBJECT_ID('silver.source_mapping','U') IS NULL
BEGIN
    CREATE TABLE silver.source_mapping (
        source_record_number int PRIMARY KEY REFERENCES bronze.raw_track(source_record_number),
        canonical_record_number int NOT NULL REFERENCES bronze.raw_track(source_record_number),
        track_id nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
        track_genre nvarchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
        popularity int NOT NULL CHECK(popularity BETWEEN 0 AND 100),
        is_duplicate bit NOT NULL,
        FOREIGN KEY(track_id,track_genre) REFERENCES silver.track_genre(track_id,track_genre)
    );
END;
GO
-- Create silver.popularity_summary.
-- Store each song's popularity range, distinct observation count and conflict indicator.
IF OBJECT_ID('silver.popularity_summary','U') IS NULL
BEGIN
    CREATE TABLE silver.popularity_summary (
        track_id nvarchar(100) COLLATE Latin1_General_100_BIN2 PRIMARY KEY REFERENCES silver.track(track_id),
        popularity_min int NOT NULL,
        popularity_max int NOT NULL,
        distinct_values int NOT NULL,
        has_conflict bit NOT NULL
    );
END;
GO
-- Create silver.source_info.
-- Record the source fingerprint and timestamp of the successful Silver rebuild.
IF OBJECT_ID('silver.source_info','U') IS NULL
BEGIN
    CREATE TABLE silver.source_info (
        id int PRIMARY KEY CHECK(id=1),
        source_sha256 char(64) NOT NULL,
        cleaned_utc datetime2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO
-- Create silver.quality_results.
-- Store each validation rule, severity, affected count and measurement grain.
IF OBJECT_ID('silver.quality_results','U') IS NULL
BEGIN
    CREATE TABLE silver.quality_results (
        rule_code varchar(60) PRIMARY KEY,
        severity varchar(10) NOT NULL,
        affected_count int NOT NULL,
        grain varchar(20) NOT NULL,
        description nvarchar(1000) NOT NULL
    );
END;
GO
-- Create silver.rejected_records.
-- Preserve source record numbers and reasons for blocking validation errors.
IF OBJECT_ID('silver.rejected_records','U') IS NULL
BEGIN
    CREATE TABLE silver.rejected_records (
        source_record_number int PRIMARY KEY REFERENCES bronze.raw_track(source_record_number),
        reason nvarchar(1000) NOT NULL
    );
END;
GO
-- Create gold.pca_scores.
-- Store three PCA scores per eligible song, linked by track_id.
IF OBJECT_ID('gold.pca_scores','U') IS NULL
BEGIN
    CREATE TABLE gold.pca_scores (
        track_id nvarchar(100) COLLATE Latin1_General_100_BIN2 PRIMARY KEY REFERENCES silver.track(track_id),
        PC1 float NOT NULL,
        PC2 float NOT NULL,
        PC3 float NOT NULL
    );
END;
GO
-- Create gold.analysis_info.
-- Store model provenance, sample size, explained variance and reproducibility metadata.
IF OBJECT_ID('gold.analysis_info','U') IS NULL
BEGIN
    CREATE TABLE gold.analysis_info (
        id int PRIMARY KEY CHECK(id=1),
        source_sha256 char(64) NOT NULL,
        sample_sha256 char(64) NOT NULL,
        sample_count int NOT NULL,
        explained_variance_first3 float NOT NULL,
        metadata_json nvarchar(max) NOT NULL,
        analyzed_utc datetime2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO
SELECT 'STEP 1 complete: run 02_import_csv.py in VS Code' AS next_step;
