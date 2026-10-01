# Report verification and correction notes

The original nine-page report is preserved as an archival analysis. The table below compares its numerical claims with the final notebook executed on 2026-10-01. Read the small loading correction below alongside the PDF.

| Report claim | Executed result |
| --- | --- |
| 572 rows, 67 columns; filtered n=421 | Matches; zero missing rows removed |
| PC1 51.2%, PC2 22.6%, cumulative 73.8% | 51.1827%, 22.6323%, 73.8150% |
| Only two eigenvalues >1 | 9.2348, 4.0835; third 0.9192 |
| Mardia skewness 8640.68, kurtosis z=71.85 | 8640.6789, 71.8457 |
| chi-square cutoff 42.31, 23 flags | 42.312396, 23 flags |

## Small substantive correction

The original loadings use `components.T * sqrt(explained_variance)`. StandardScaler uses population variance while PCA eigenvalues use sample variance. Exact variable-score correlations require multiplying those original values by `sqrt((421-1)/421)` (0.99881165). Thus PTS 0.979 becomes 0.978, MIN 0.922 becomes 0.921 and OREB 0.867 becomes 0.866 to three decimals. All report loadings should be interpreted with this correction; authoritative corrected values are in outputs/loadings_PC1_PC2.csv. Scores, component directions, variance explained and diagnostic distances do not change. The original report is an archival result, accompanied by these correction notes rather than overwritten.

Full SVD and explicit sign anchors stabilize the intended positive-PC1 involvement / positive-PC2 interior interpretation. Survival functions avoid cancellation in tail probabilities (these extreme values still underflow). No data or players were deleted and no complex model was introduced.

The full covariance matrix is rank 18, but its condition number is about 113,852. Original Mahalanobis distances agree with an independent sample-covariance calculation. This verifies computation, not calibration: rounded near-dependent variables, in-sample distances and non-normal profiles limit chi-square inference. The original Mardia sample-covariance approximation is retained, explicitly labeled; no literal p=0 claim is made.
