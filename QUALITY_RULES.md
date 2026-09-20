# Data Quality, Lineage and Metric Definitions

## Role in the project

These controls support the project's primary data engineering and analysis workflow. They establish source traceability, explicit data grains, reproducible cleaning decisions and reliable report metrics. Their scope is practical data quality and provenance, not a complete enterprise governance program.

## Rules

- Preserve original strings in Bronze. Metadata edge spaces are trimmed in Silver; blank metadata becomes NULL. IDs are case-sensitive and must not have edge spaces.
- Required key/type/range errors and conflicting stable attributes block cleaning. Rejected record numbers point back to Bronze.
- Within the declared numeric precision, identical normalized business records map to the first source record. That canonical row is not a latest-value claim.
- A song may have multiple genres. The unique song key is track_id; the relationship key is track_id + track_genre.
- Popularity retains each source observation. The summary records min, max, distinct count and a conflict flag; no timestamps means no verified latest popularity.
- Positive duration defines the primary sample. Zero tempo stays in the primary sample. Typical tempo/loudness ranges are warnings, not hard physical validity claims.
- Extra key/mode/time_signature fields are retained as integer codes without inventing undocumented meanings.
- Model scores must match the current eligible Silver track IDs and feature values before SQL write-back.

## Report metrics

- Catalog Songs: distinct track IDs in the selected genre memberships.
- Analysis Songs: same selection, restricted to include_primary=1.
- Feature means: average once per eligible selected track ID, not once per membership.
- Genre counts overlap. Their sum is the membership count, not the catalog total.
- Fractional weight 1/genre_count is an explicit allocation convention; it does not measure platform market share.
- Global source and quality views are labelled full snapshot and do not recalculate under song filters.

## Re-execution and limitations

One local snapshot, manual sequential execution. Import transactionally replaces source and derived data. Cleaning replaces Silver and invalidates prior PCA. Analysis replaces the matching model output. Failed import/write-back rolls back the SQL changes; partial local files can still exist and are marked failed.

No multi-batch history, production orchestration, release pointer, account-role testing or concurrency guarantee is claimed. Those remain potential engineering extensions. Bronze/Silver/Gold naming describes data responsibilities rather than production readiness.

The source guide's license/provenance assertions remain unverified outside this project. No listening-history data or user identities exist; do not invent privacy classifications or recommendation-performance claims.
