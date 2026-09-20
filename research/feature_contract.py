"""Shared paths and ordered audio features for the statistical analysis modules."""
from pathlib import Path

# Resolve the project root independently of the current terminal directory.
ROOT = Path(__file__).resolve().parents[1]

# Preserve this feature order when fitting, exporting and comparing model matrices.
CORE = ['danceability', 'energy', 'loudness', 'speechiness', 'acousticness', 'instrumentalness', 'liveness', 'valence', 'tempo']
