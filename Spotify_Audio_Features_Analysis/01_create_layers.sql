/* ============================================================================
   Create Spotify Database and Layer Tables
-------------------------------------------------------------------------------
Script Purpose:
    Create the dedicated database, Bronze/Silver/Gold schemas, and tables for
    source records, cleaned entities, lineage, quality results and PCA output.

Execution Notes:
    Existing tables and data are preserved. This is setup, not schema migration.

Implementation Notes:
    Binary collation preserves exact identifier and source-value comparisons.
*/

USE master;
GO
IF DB_ID('Spotify') IS NULL
    EXEC (N'CREATE DATABASE Spotify COLLATE Latin1_General_100_BIN2');
GO
USE Spotify;
GO
IF SCHEMA_ID('bronze') IS NULL
    EXEC (N'CREATE SCHEMA bronze AUTHORIZATION dbo');
GO
IF SCHEMA_ID('silver') IS NULL
    EXEC (N'CREATE SCHEMA silver AUTHORIZATION dbo');
GO
IF SCHEMA_ID('gold') IS NULL
    EXEC (N'CREATE SCHEMA gold AUTHORIZATION dbo');
GO

-- ---------------------------------------------------------
-- Create bronze.source_info.
-- Store one source snapshot fingerprint, filename, row count and import timestamp.
IF OBJECT_ID('bronze.source_info', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.source_info (
        id INT PRIMARY KEY CHECK (id = 1),
        source_filename NVARCHAR(260) NOT NULL,
        source_sha256 CHAR(64) NOT NULL,
        row_count INT NOT NULL,
        loaded_utc DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO

-- ---------------------------------------------------------
-- Create bronze.raw_track.
-- Preserve every CSV record as raw text, keyed by its original record number.
IF OBJECT_ID('bronze.raw_track', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.raw_track (
        source_record_number INT PRIMARY KEY,
        source_export_index NVARCHAR(100) NULL,
        [track_id] NVARCHAR(MAX) NULL,
        [artists] NVARCHAR(MAX) NULL,
        [album_name] NVARCHAR(MAX) NULL,
        [track_name] NVARCHAR(MAX) NULL,
        [popularity] NVARCHAR(MAX) NULL,
        [duration_ms] NVARCHAR(MAX) NULL,
        [explicit] NVARCHAR(MAX) NULL,
        [danceability] NVARCHAR(MAX) NULL,
        [energy] NVARCHAR(MAX) NULL,
        [key] NVARCHAR(MAX) NULL,
        [loudness] NVARCHAR(MAX) NULL,
        [mode] NVARCHAR(MAX) NULL,
        [speechiness] NVARCHAR(MAX) NULL,
        [acousticness] NVARCHAR(MAX) NULL,
        [instrumentalness] NVARCHAR(MAX) NULL,
        [liveness] NVARCHAR(MAX) NULL,
        [valence] NVARCHAR(MAX) NULL,
        [tempo] NVARCHAR(MAX) NULL,
        [time_signature] NVARCHAR(MAX) NULL,
        [track_genre] NVARCHAR(MAX) NULL
    );
END;
GO

-- ---------------------------------------------------------
-- Create silver.track.
-- Store one cleaned row per song, with typed audio features and analysis eligibility flags.
IF OBJECT_ID('silver.track', 'U') IS NULL
BEGIN
    CREATE TABLE silver.track (
        track_id NVARCHAR(100) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,
        [artists] NVARCHAR(1000) NULL,
        [album_name] NVARCHAR(1000) NULL,
        [track_name] NVARCHAR(1000) NULL,
        [duration_ms] BIGINT NOT NULL,
        [explicit] BIT NOT NULL,
        [danceability] FLOAT NOT NULL,
        [energy] FLOAT NOT NULL,
        [key] INT NOT NULL,
        [loudness] FLOAT NOT NULL,
        [mode] INT NOT NULL,
        [speechiness] FLOAT NOT NULL,
        [acousticness] FLOAT NOT NULL,
        [instrumentalness] FLOAT NOT NULL,
        [liveness] FLOAT NOT NULL,
        [valence] FLOAT NOT NULL,
        [tempo] FLOAT NOT NULL,
        [time_signature] INT NOT NULL,
        metadata_missing BIT NOT NULL,
        include_primary BIT NOT NULL,
        tempo_warning BIT NOT NULL,
        loudness_warning BIT NOT NULL
    );
END;
GO

-- ---------------------------------------------------------
-- Create silver.genre.
-- Store the distinct genre vocabulary without repeating song attributes.
IF OBJECT_ID('silver.genre', 'U') IS NULL
BEGIN
    CREATE TABLE silver.genre (
        track_genre NVARCHAR(100) COLLATE Latin1_General_100_BIN2 PRIMARY KEY
    );
END;
GO

-- ---------------------------------------------------------
-- Create silver.track_genre.
-- Store one unique song/genre relationship; retain songs belonging to multiple genres.
IF OBJECT_ID('silver.track_genre', 'U') IS NULL
BEGIN
    CREATE TABLE silver.track_genre (
        track_id NVARCHAR(100) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES silver.track (track_id),
        track_genre NVARCHAR(100) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES silver.genre (track_genre),
        PRIMARY KEY (track_id, track_genre)
    );
END;
GO

-- ---------------------------------------------------------
-- Create silver.source_mapping.
-- Map every source record to its canonical record and cleaned song/genre relationship.
IF OBJECT_ID('silver.source_mapping', 'U') IS NULL
BEGIN
    CREATE TABLE silver.source_mapping (
        source_record_number INT PRIMARY KEY REFERENCES bronze.raw_track (source_record_number),
        canonical_record_number INT NOT NULL REFERENCES bronze.raw_track (source_record_number),
        track_id NVARCHAR(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
        track_genre NVARCHAR(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
        popularity INT NOT NULL CHECK (popularity BETWEEN 0 AND 100),
        is_duplicate BIT NOT NULL,
        FOREIGN KEY (track_id, track_genre) REFERENCES silver.track_genre (track_id, track_genre)
    );
END;
GO

-- ---------------------------------------------------------
-- Create silver.popularity_summary.
-- Store each song's popularity range, distinct observation count and conflict indicator.
IF OBJECT_ID('silver.popularity_summary', 'U') IS NULL
BEGIN
    CREATE TABLE silver.popularity_summary (
        track_id NVARCHAR(100) COLLATE Latin1_General_100_BIN2 PRIMARY KEY REFERENCES silver.track (track_id),
        popularity_min INT NOT NULL,
        popularity_max INT NOT NULL,
        distinct_values INT NOT NULL,
        has_conflict BIT NOT NULL
    );
END;
GO

-- ---------------------------------------------------------
-- Create silver.source_info.
-- Record the source fingerprint and timestamp of the successful Silver rebuild.
IF OBJECT_ID('silver.source_info', 'U') IS NULL
BEGIN
    CREATE TABLE silver.source_info (
        id INT PRIMARY KEY CHECK (id = 1),
        source_sha256 CHAR(64) NOT NULL,
        cleaned_utc DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO

-- ---------------------------------------------------------
-- Create silver.quality_results.
-- Store each validation rule, severity, affected count and measurement grain.
IF OBJECT_ID('silver.quality_results', 'U') IS NULL
BEGIN
    CREATE TABLE silver.quality_results (
        rule_code VARCHAR(60) PRIMARY KEY,
        severity VARCHAR(10) NOT NULL,
        affected_count INT NOT NULL,
        grain VARCHAR(20) NOT NULL,
        description NVARCHAR(1000) NOT NULL
    );
END;
GO

-- ---------------------------------------------------------
-- Create silver.rejected_records.
-- Preserve source record numbers and reasons for blocking validation errors.
IF OBJECT_ID('silver.rejected_records', 'U') IS NULL
BEGIN
    CREATE TABLE silver.rejected_records (
        source_record_number INT PRIMARY KEY REFERENCES bronze.raw_track (source_record_number),
        reason NVARCHAR(1000) NOT NULL
    );
END;
GO

-- ---------------------------------------------------------
-- Create gold.pca_scores.
-- Store three PCA scores per eligible song, linked by track_id.
IF OBJECT_ID('gold.pca_scores', 'U') IS NULL
BEGIN
    CREATE TABLE gold.pca_scores (
        track_id NVARCHAR(100) COLLATE Latin1_General_100_BIN2 PRIMARY KEY REFERENCES silver.track (track_id),
        PC1 FLOAT NOT NULL,
        PC2 FLOAT NOT NULL,
        PC3 FLOAT NOT NULL
    );
END;
GO

-- ---------------------------------------------------------
-- Create gold.analysis_info.
-- Store model provenance, sample size, explained variance and reproducibility metadata.
IF OBJECT_ID('gold.analysis_info', 'U') IS NULL
BEGIN
    CREATE TABLE gold.analysis_info (
        id INT PRIMARY KEY CHECK (id = 1),
        source_sha256 CHAR(64) NOT NULL,
        sample_sha256 CHAR(64) NOT NULL,
        sample_count INT NOT NULL,
        explained_variance_first3 FLOAT NOT NULL,
        metadata_json NVARCHAR(MAX) NOT NULL,
        analyzed_utc DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO
SELECT 'STEP 1 complete: run 02_import_csv.py in VS Code' AS next_step;
