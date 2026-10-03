# Numerical Verification

The [analysis report](ANALYSIS_REPORT.md) summarizes the notebook executed in a fresh kernel on 2026-10-01. The [validation record](outputs/validation.json) retains the input fingerprint, environment and numerical checks.

| Verified quantity | Result |
| --- | --- |
| Source dimensions | 572 players, 67 columns |
| Eligible sample | 421 players; zero incomplete selected rows removed |
| Explained variance | PC1 51.1827%, PC2 22.6323%, cumulative 73.8150% |
| Leading eigenvalues | 9.2348, 4.0835; third 0.9192 |
| Approximate Mardia diagnostics | Skewness chi-square 8640.6789; kurtosis z 71.8457 |
| Exploratory distance threshold | Chi-square(18), 0.999 quantile: 42.312396 |
| Profiles above threshold | 23; all retained |

## Feature-component correlations

StandardScaler uses population variance while PCA eigenvalues use sample variance. With n=421, exact variable-score correlations are computed as `components.T * sqrt(explained_variance * (n-1)/n)`. Omitting the finite-sample factor would inflate their magnitude by approximately 0.12%.

The notebook verifies these values against directly calculated correlations. The [loading export](outputs/loadings_PC1_PC2.csv) and current report use the corrected values: PTS 0.978 and MIN 0.921 on PC1; OREB 0.866 on PC2. This normalization does not change scores or explained variance. Full SVD and explicit sign anchors provide a consistent positive-PC1 involvement / positive-PC2 interior interpretation.

## Diagnostic scope

The covariance matrix has rank 18 and condition number approximately 113,852. Mahalanobis distances agree with an independent sample-covariance calculation. This verifies computation, not calibration: rounded near-dependent variables, in-sample distances and non-normal profiles limit chi-square inference. Mardia tests are labeled as approximations. Survival functions avoid subtraction-related cancellation in tail probabilities; extreme probabilities can still underflow, so the report states p < 1e-16 rather than literal p=0.

The fresh-kernel execution procedure and dependency versions are documented in the [README](README.md#getting-started).
