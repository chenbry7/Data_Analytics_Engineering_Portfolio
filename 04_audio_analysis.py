"""STEP 4 — Run directly in VS Code. Reads cleaned SQL data and writes PCA back.
Optional CSV/offline mode and full FA/ICA research are controlled by settings below.
"""
from pathlib import Path
import hashlib
import json
import sys
from datetime import datetime, timezone
import numpy as np
import pandas as pd
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
from threadpoolctl import threadpool_limits
# EDIT SETTINGS HERE. Keep server/database consistent with Step 2.
SERVER = r'localhost\SQLEXPRESS'
DATABASE = 'Spotify'
DRIVER = 'ODBC Driver 18 for SQL Server'
# Local development/self-signed certificate only.
TRUST_SERVER_CERTIFICATE = 'yes'
# "sql" or "csv" (CSV previously exported by this script).
INPUT_MODE = 'sql'
# False permits offline CSV analysis; SQL Gold won't update.
WRITE_RESULTS_TO_SQL = True
# True adds parallel analysis, FA/ICA and paired FA diagnostics.
RUN_ADVANCED_ANALYSIS = True
ROOT = Path(__file__).resolve().parent
OUTPUT = ROOT / 'outputs'
CLEAN_CSV = OUTPUT / 'clean_audio_features.csv'
CORE = [
    'danceability',
    'energy',
    'loudness',
    'speechiness',
    'acousticness',
    'instrumentalness',
    'liveness',
    'valence',
    'tempo',
]

def connection():
    """Connect to the same dedicated database used by the import step."""
    import pyodbc
    # Require the dedicated database shared by the numbered SQL scripts.
    if DATABASE != 'Spotify':
        raise ValueError('Database must match Step 1')
    # Check that the configured Microsoft ODBC driver is installed.
    if DRIVER not in pyodbc.drivers():
        raise RuntimeError('Install configured Microsoft ODBC driver')

    # Escape connection-string values without embedding credentials.
    def quote(s):
        return '{' + str(s).replace('}', '}}') + '}'
    return pyodbc.connect(f'DRIVER={quote(DRIVER)};SERVER={quote(SERVER)};DATABASE={quote(DATABASE)};Trusted_Connection=yes;Encrypt=yes;TrustServerCertificate={TRUST_SERVER_CERTIFICATE}', autocommit=False, timeout=15)

def sql_sample(con):
    """Return ordered eligible Silver tracks and the current source fingerprint."""
    cur = con.cursor()
    # Read the Silver fingerprint only when it matches the current Bronze snapshot.
    state = cur.execute('SELECT s.source_sha256 FROM silver.source_info s JOIN bronze.source_info b ON b.source_sha256=s.source_sha256 WHERE s.id=1').fetchone()
    # Stop if cleaning has not completed for the current imported source.
    if state is None:
        raise RuntimeError('Silver not ready for current source: run Step 3 first')
    # Read eligible songs in a stable track-ID order for score alignment and reproducibility.
    cur.execute('SELECT track_id,' + ','.join(CORE) + ' FROM silver.track WHERE include_primary=1 ORDER BY track_id')
    # Convert fetched Silver records into a labeled analysis DataFrame.
    frame = pd.DataFrame.from_records(cur.fetchall(), columns=[c[0] for c in cur.description])
    cur.close()
    return (frame, str(state[0]))

def main():
    """Analyze Silver or its verified export, then optionally publish keyed PCA scores."""
    # Step 4.1: validate the selected local execution mode and start a status record.
    if INPUT_MODE not in ['sql', 'csv']:
        raise ValueError('INPUT_MODE must be sql or csv')
    OUTPUT.mkdir(exist_ok=True)
    # Write the run status so incomplete or historical outputs are not mistaken for new results.
    (OUTPUT / 'run_status.json').write_text(json.dumps({'status': 'running', 'started_utc': datetime.now(timezone.utc).isoformat()}), encoding='utf-8')
    con = None
    try:
        # Connect only when SQL input or SQL score write-back is requested.
        if INPUT_MODE == 'sql' or WRITE_RESULTS_TO_SQL:
            con = connection()
        # Step 4.2: load eligible Silver data or verify the previously exported CSV.
        if INPUT_MODE == 'sql':
            # Load cleaned eligible songs and their verified source fingerprint from Silver.
            data, source_hash = sql_sample(con)
            # Serialize the exact analysis sample for reproducible local CSV re-use.
            sample = data.to_csv(index=False, lineterminator='\n').encode('utf-8')
            # Create clean_audio_features.csv from the Silver sample used in this run.
            CLEAN_CSV.write_bytes(sample)
            # Fingerprint the analysis sample independently of the original raw source.
            sample_hash = hashlib.sha256(sample).hexdigest()
            # Create sample_manifest.json linking the exported sample to its source snapshot.
            (OUTPUT / 'sample_manifest.json').write_text(json.dumps({'source_sha256': source_hash, 'sample_sha256': sample_hash, 'rows': len(data)}, indent=2), encoding='utf-8')
        else:
            # Read the previously exported clean sample without consulting a different CSV.
            sample = CLEAN_CSV.read_bytes()
            # Fingerprint the analysis sample independently of the original raw source.
            sample_hash = hashlib.sha256(sample).hexdigest()
            # Load the sample manifest that records the expected source and sample hashes.
            manifest = json.loads((OUTPUT / 'sample_manifest.json').read_text(encoding='utf-8'))
            # Reject a modified CSV whose bytes no longer match its provenance manifest.
            if manifest['sample_sha256'] != sample_hash:
                raise ValueError('Exported sample changed; re-export from Silver rather than mixing provenance')
            source_hash = manifest['source_sha256']
            # Parse the verified exported sample for the same downstream analysis steps.
            data = pd.read_csv(CLEAN_CSV)
        # Step 4.3: require unique song IDs and finite, varying model inputs.
        x = data[CORE].to_numpy(dtype=float)
        # Reject duplicate song IDs, insufficient rows, non-finite features or constant columns.
        if len(data) < 10 or not data.track_id.is_unique or (not np.isfinite(x).all()) or (x.std(axis=0) == 0).any():
            raise ValueError('Invalid analysis sample: unique IDs, finite varying features and at least ten rows required')
        # Step 4.4: standardize all nine features and fit deterministic full-SVD PCA.
        with threadpool_limits(limits=1):
            # Create the standardization transform so differently scaled features are comparable.
            scaler = StandardScaler()
            # Fit feature means/scales and transform the nine features to standardized values.
            z = scaler.fit_transform(x)
            # Create full-SVD PCA for a deterministic decomposition of the standardized sample.
            model = PCA(svd_solver='full')
            # Fit PCA and calculate component scores for every eligible song.
            scores = model.fit_transform(z)
        # Step 4.5: orient axes consistently and verify full-component reconstruction.
        for i in range(len(CORE)):
            # Reverse an axis and its scores together when its largest absolute loading is negative.
            if model.components_[i, np.argmax(np.abs(model.components_[i]))] < 0:
                model.components_[i] *= -1
                scores[:, i] *= -1
        # Verify that all retained PCA components reconstruct the standardized matrix.
        if not np.allclose(scores @ model.components_ + model.mean_, z, atol=1e-09):
            raise RuntimeError('PCA reconstruction check failed')
        # Create the three-component score table that will be linked to Gold by track_id.
        result = pd.DataFrame(scores[:, :3], columns=['PC1', 'PC2', 'PC3'])
        # Attach song identifiers in the same order as the fitted analysis sample.
        result.insert(0, 'track_id', data.track_id)
        # Create pca_scores.csv with one keyed row per eligible song.
        result.to_csv(OUTPUT / 'pca_scores.csv', index=False)
        # Create feature_summary.csv containing descriptive statistics for the nine inputs.
        data[CORE].describe().T.to_csv(OUTPUT / 'feature_summary.csv', index_label='feature')
        # Assemble source hashes, scaler parameters, component axes and explained variance.
        metadata = {
            'source_sha256': source_hash,
            'sample_sha256': sample_hash,
            'sample_rows': len(data),
            'features': CORE,
            'mean': scaler.mean_.tolist(),
            'scale': scaler.scale_.tolist(),
            'axes': model.components_.tolist(),
            'explained_variance_ratio': model.explained_variance_ratio_.tolist(),
            'rule': 'Positive-duration songs; zero tempo retained. Three display PCs follow prior exploratory evidence.',
            'analysis_utc': datetime.now(timezone.utc).isoformat(),
        }
        from importlib.metadata import version
        # Record installed numerical-library versions for reproducibility.
        metadata['versions'] = {p: version(p) for p in ['numpy', 'pandas', 'scikit-learn']}
        # Initialize the optional advanced-analysis result separately from the main PCA output.
        research_report = None
        # Step 4.6: optionally retain parallel analysis, FA/ICA and bootstrap diagnostics.
        if RUN_ADVANCED_ANALYSIS:
            # Make the bundled research modules importable without another manual entry point.
            sys.path.insert(0, str(ROOT / 'research'))
            from analyze_latent import main as latent
            from diagnose_fa import main as diagnose
            # Choose the local output folder for advanced statistical evidence.
            research_dir = OUTPUT / 'research'
            research_dir.mkdir(exist_ok=True)
            with threadpool_limits(limits=1):
                # Run parallel analysis, FA, ICA and bootstrap diagnostics on the same exported Silver sample.
                latent(input_file=CLEAN_CSV, output_dir=research_dir, report_file=research_dir / 'research_report.json', provenance={'implementation': 'sqlserver_simple', 'source_sha256': source_hash})
                # Read the advanced analysis results for inclusion in the current run report.
                research_report = json.loads((research_dir / 'research_report.json').read_text())
                # Run the paired-start diagnostic only when the selected model has three factors.
                if research_report['selected_k_permutation'] == 3:
                    # Generate matched promax and paired-bootstrap evidence under outputs/fa_diagnostics.
                    diagnose(input_file=CLEAN_CSV, output_dir=OUTPUT / 'fa_diagnostics', prior_file=research_dir / 'research_report.json', report_file=OUTPUT / 'fa_diagnostics/diagnostic_report.json')
                else:
                    print('FA paired diagnostic skipped: it targets three factors; review new selected dimension.')
        # Step 4.7: recheck Silver identity, replace scores and verify SQL round-trip values.
        if WRITE_RESULTS_TO_SQL:
            # Reject stale/changed CSV or concurrent changes instead of overwriting with mismatched scores.
            # Reload Silver immediately before write-back to detect a changed analysis input.
            current, current_hash = sql_sample(con)
            # Reject stale scores if source identity, ordered song IDs or feature values changed.
            if current_hash != source_hash or not current.track_id.equals(data.track_id) or (not np.allclose(current[CORE].to_numpy(dtype=float), x, rtol=1e-12, atol=1e-12)):
                raise RuntimeError('Analysis input no longer matches Silver; do not run stages concurrently')
            con.execute('SET XACT_ABORT ON;')
            # Remove prior PCA score rows inside the replacement transaction.
            con.execute('DELETE FROM gold.pca_scores')
            # Remove prior model metadata so it can be replaced with matching provenance.
            con.execute('DELETE FROM gold.analysis_info')
            cur = con.cursor()
            cur.fast_executemany = True
            # Convert keyed PCA scores into parameter tuples for SQL insertion.
            values = [(str(t), float(a), float(b), float(c)) for t, a, b, c in result.itertuples(index=False, name=None)]
            # Write score rows in batches of 2,000 while retaining transaction-level rollback.
            for offset in range(0, len(values), 2000):
                # Populate gold.pca_scores with the three scores for each eligible song.
                cur.executemany('INSERT gold.pca_scores(track_id,PC1,PC2,PC3) VALUES(?,?,?,?)', values[offset:offset + 2000])
            # Read persisted scores back in track-ID order before committing.
            cur.execute('SELECT track_id,PC1,PC2,PC3 FROM gold.pca_scores ORDER BY track_id')
            # Build the SQL round-trip comparison table from the inserted score rows.
            check = pd.DataFrame.from_records(cur.fetchall(), columns=['track_id', 'PC1', 'PC2', 'PC3'])
            cur.close()
            # Require matching IDs and numerically consistent scores after SQL insertion.
            if not check.track_id.equals(result.track_id) or not np.allclose(check.iloc[:, 1:], result.iloc[:, 1:], atol=1e-10):
                raise RuntimeError('SQL PCA round-trip mismatch')
            # Populate gold.analysis_info with sample provenance and reproducibility metadata.
            con.execute('INSERT gold.analysis_info(id,source_sha256,sample_sha256,sample_count,explained_variance_first3,metadata_json) VALUES(1,?,?,?,?,?)', source_hash, sample_hash, len(data), float(model.explained_variance_ratio_[:3].sum()), json.dumps(metadata))
            # Commit the matched PCA scores and model metadata together.
            con.commit()
        # Step 4.8: save reproducibility metadata, an English report and completion status.
        # Create analysis_metadata.json containing the fitted transformation and source details.
        (OUTPUT / 'analysis_metadata.json').write_text(json.dumps(metadata, indent=2) + '\n', encoding='utf-8')
        # Compose the English execution report from this run rather than historical reference values.
        lines = [
            '# Current analysis result',
            '',
            f'Songs analyzed: {len(data):,}',
            f'First three PCA components explain {model.explained_variance_ratio_[:3].sum() * 100:.4f}% of standardized variance.',
            f'SQL score write-back: {WRITE_RESULTS_TO_SQL}',
            f'Advanced FA/ICA executed in this run: {RUN_ADVANCED_ANALYSIS}',
            '',
            'This report describes this completed run. Dashboard acceptance is a separate step.',
            'Input: positive-duration unique track IDs; zero tempo retained. No latest popularity or recommendation accuracy is inferred.',
        ]
        # Append available advanced-analysis findings and interpretation limits to the report.
        if research_report:
            lines += ['', f"Parallel-analysis selected dimension: {research_report['selected_k_permutation']}.", f"FA near-boundary features: {research_report['fa_near_bound_features']}.", 'Inspect research JSON, bootstrap intervals and warnings before interpreting factor stability.']
        # Create the English ANALYSIS_REPORT.md for the current analysis run.
        (OUTPUT / 'ANALYSIS_REPORT.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
        # Write the run status so incomplete or historical outputs are not mistaken for new results.
        (OUTPUT / 'run_status.json').write_text(json.dumps({'status': 'completed', 'sql_write_back': WRITE_RESULTS_TO_SQL, 'advanced_analysis': RUN_ADVANCED_ANALYSIS}, indent=2), encoding='utf-8')
        print(f'STEP 4 COMPLETE: {len(data):,} songs. Outputs: {OUTPUT}')
        print('Next: run 05_gold_views.sql and 06_checks.sql in SSMS.' if WRITE_RESULTS_TO_SQL else 'Offline results only. Gold SQL has not been updated.')
    # Step 4.9: roll back uncommitted writes and mark partial local output as failed.
    except Exception:
        if con is not None:
            # Roll back pending SQL changes when an analysis or write-back operation fails.
            con.rollback()
        # Write the run status so incomplete or historical outputs are not mistaken for new results.
        (OUTPUT / 'run_status.json').write_text(json.dumps({'status': 'failed', 'note': 'Partial local files may exist; do not treat them as a completed run.'}), encoding='utf-8')
        raise
    # Always release the database connection, including after an error.
    # Close the database connection even when execution exits through an exception.
    finally:
        if con is not None:
            con.close()
if __name__ == '__main__':
    main()
