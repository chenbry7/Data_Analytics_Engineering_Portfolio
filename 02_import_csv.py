"""STEP 2 — edit the settings below, then Run Python File in VS Code.
Replaces this dedicated database's imported snapshot and clears derived outputs.
"""
from pathlib import Path
import csv
import hashlib
import io
import pyodbc
# EDIT THESE SETTINGS. No JSON file, command-line arguments or password required.
# Example: r"localhost\SQLEXPRESS"
SERVER = r'localhost\SQLEXPRESS'
# Must match Step 1.
DATABASE = 'Spotify'
CSV_PATH = Path(__file__).resolve().parent / 'spotify_data.csv'
DRIVER = 'ODBC Driver 18 for SQL Server'
# Local development/self-signed certificate only.
TRUST_SERVER_CERTIFICATE = 'yes'
COLUMNS = [
    'track_id',
    'artists',
    'album_name',
    'track_name',
    'popularity',
    'duration_ms',
    'explicit',
    'danceability',
    'energy',
    'key',
    'loudness',
    'mode',
    'speechiness',
    'acousticness',
    'instrumentalness',
    'liveness',
    'valence',
    'tempo',
    'time_signature',
    'track_genre',
]

def connection():
    """Connect with Windows authentication and explicit transaction control."""
    # Reject a database name that does not match the dedicated schema created in Step 1.
    if DATABASE != 'Spotify':
        raise ValueError('Use the dedicated database created in Step 1')
    # Stop with an actionable message when the configured ODBC driver is unavailable.
    if DRIVER not in pyodbc.drivers():
        raise RuntimeError('Install Microsoft ODBC Driver 18 for SQL Server first')

    # Escape ODBC connection-string values before constructing the Windows-authenticated connection.
    def quote(s):
        return '{' + str(s).replace('}', '}}') + '}'
    return pyodbc.connect(f'DRIVER={quote(DRIVER)};SERVER={quote(SERVER)};DATABASE={quote(DATABASE)};Trusted_Connection=yes;Encrypt=yes;TrustServerCertificate={TRUST_SERVER_CERTIFICATE}', autocommit=False, timeout=15)

def main():
    """Validate the source, replace Bronze atomically, and reconcile the load."""
    # Step 2.1: fingerprint the exact source bytes before parsing any values.
    content = CSV_PATH.read_bytes()
    # Compute the source fingerprint used to trace this exact CSV snapshot through the pipeline.
    source_hash = hashlib.sha256(content).hexdigest()
    # Parse CSV records without converting or cleaning the original field values.
    reader = csv.DictReader(io.StringIO(content.decode('utf-8-sig'), newline=''))
    # Step 2.2: reject unexpected headers or malformed records before database changes.
    fields = reader.fieldnames or []
    # Reject missing or repeated headers before any database records are changed.
    if len(fields) != len(set(fields)) or set(COLUMNS) - set(fields):
        raise ValueError('Missing or duplicate CSV headers')
    # Permit only the documented optional export-index column beyond the source contract.
    if set(fields) - set(COLUMNS) not in (set(), {''}, {'Unnamed: 0'}):
        raise ValueError('Unexpected CSV columns: review source schema')
    # Materialize source records so input validation finishes before snapshot replacement.
    rows = list(reader)
    # Reject an empty file or rows with a different field count from the header.
    if not rows or any((None in r or None in r.values() for r in rows)):
        raise ValueError('Empty source or malformed CSV record width')
    # Step 2.3: open the dedicated database after source validation succeeds.
    con = connection()
    try:
        # Step 2.4: replace generated records in foreign-key order within one transaction.
        con.execute('SET XACT_ABORT ON; SET NOCOUNT ON;')
        # One transaction: if import fails, rollback restores the prior snapshot.
        # Clear prior generated tables in foreign-key dependency order inside the import transaction.
        for table in ['gold.pca_scores', 'gold.analysis_info', 'silver.source_mapping', 'silver.track_genre', 'silver.popularity_summary', 'silver.track', 'silver.genre', 'silver.source_info', 'silver.rejected_records', 'silver.quality_results', 'bronze.raw_track', 'bronze.source_info']:
            con.execute('DELETE FROM ' + table)
        # Build a parameterized INSERT for raw fields, export index and original record number.
        sql = 'INSERT bronze.raw_track(source_record_number,source_export_index,' + ','.join(('[' + c + ']' for c in COLUMNS)) + ') VALUES(' + ','.join(('?' for _ in range(len(COLUMNS) + 2))) + ')'
        # Step 2.5: insert parameterized batches while preserving raw text and row lineage.
        cur = con.cursor()
        # Standard executemany preserves nvarchar(max) strings without fixed-buffer truncation.
        # Load the next 1,000 raw records while keeping the entire snapshot uncommitted.
        for offset in range(0, len(rows), 1000):
            # Attach one-based source record numbers and preserve the optional original export index.
            values = [(i + 1, r.get('', r.get('Unnamed: 0')), *[r[c] for c in COLUMNS]) for i, r in enumerate(rows[offset:offset + 1000], offset)]
            # Insert this batch into bronze.raw_track using bound parameters.
            cur.executemany(sql, values)
            print(f'Imported {min(offset + 1000, len(rows)):,} / {len(rows):,} rows (pending commit)', flush=True)
        # Release the batch cursor before reconciling the completed raw import.
        cur.close()
        # Step 2.6: reconcile the record count and persist provenance before committing.
        count = con.execute('SELECT COUNT(*) FROM bronze.raw_track').fetchone()[0]
        # Abort if the database row count differs from the parsed CSV record count.
        if count != len(rows):
            raise RuntimeError('Bronze row count mismatch')
        # Write the filename, hash and verified row count into bronze.source_info.
        con.execute('INSERT bronze.source_info(id,source_filename,source_sha256,row_count) VALUES(1,?,?,?)', CSV_PATH.name, source_hash, count)
        # Commit the complete Bronze snapshot only after reconciliation succeeds.
        con.commit()
        print(f'STEP 2 COMPLETE: {count:,} rows committed. Source SHA-256: {source_hash}')
        print('Next: run 03_clean_silver.sql in SSMS. Prior Silver/PCA outputs were cleared.')
    # Step 2.7: restore the previous snapshot if any database operation fails.
    except Exception:
        # Undo every pending replacement or insert after an import failure.
        con.rollback()
        print('IMPORT FAILED: transaction rolled back; no partial new snapshot committed.')
        raise
    # Release the database connection after either success or failure.
    finally:
        con.close()
if __name__ == '__main__':
    main()
