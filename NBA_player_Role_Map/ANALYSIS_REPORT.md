# NBA Player Role Map: Analysis Report

**Bryan Chen · 2023–24 season · Revised portfolio report**

## Research question

Can correlated player statistics be summarized by a small number of interpretable dimensions? This exploratory analysis describes offensive involvement and interior-versus-perimeter profiles. It does not rank player ability, predict performance, or assign validated role classes.

## Data and preparation

The supplied NBA.com course snapshot contains 572 players and 67 columns. Requiring at least 10 games and 10 minutes per game leaves 421 players. The 18 selected per-game features cover playing time, scoring, shooting, rebounding, playmaking and defensive activity. No incomplete selected rows were removed. See [data provenance](DATA_SOURCE.md).

Each feature is centered and scaled with StandardScaler before full-SVD PCA. Signs are anchored so points have a positive PC1 loading and offensive rebounds have a positive PC2 loading. Sign choices affect presentation, not explained variance.

![Feature correlations](figures/Fig1_corr_heatmap_core18_annotated.png)

PTS and FGM correlate at 0.991; PTS and FGA at 0.985. Such redundancy motivates dimension reduction but also gives related scoring statistics repeated representation in the feature set.

## Dimension reduction

| Component | Explained variance | Interpretation |
|---|---:|---|
| PC1 | 51.1827% | Offensive involvement |
| PC2 | 22.6323% | Interior-versus-perimeter style |
| Combined | 73.8150% | Two-dimensional exploratory summary |

Only the first two eigenvalues exceed one (9.2348 and 4.0835; the third is 0.9192). This supports a compact descriptive display, not proof that basketball roles have exactly two underlying dimensions. About 26.19% of standardized variation remains outside the displayed map.

![Explained variance](figures/Fig2_scree_plot_v3.png)

## Corrected feature-component correlations

Loadings below are correlations between standardized features and component scores. With n=421, the computation is `components.T * sqrt(explained_variance * (n-1)/n)`, accounting for the population-variance convention in StandardScaler and sample-variance convention in PCA eigenvalues.

| Feature | PC1 | PC2 |
|---|---:|---:|
| MIN | 0.921 | -0.039 |
| PTS | 0.978 | -0.076 |
| FGM | 0.971 | 0.003 |
| FGA | 0.961 | -0.166 |
| FG_PCT | 0.166 | 0.729 |
| FG3M | 0.630 | -0.641 |
| FG3A | 0.638 | -0.649 |
| FG3_PCT | 0.179 | -0.616 |
| FTM | 0.893 | 0.038 |
| FTA | 0.886 | 0.127 |
| FT_PCT | 0.312 | -0.533 |
| OREB | 0.285 | 0.866 |
| DREB | 0.736 | 0.542 |
| REB | 0.643 | 0.687 |
| AST | 0.772 | -0.209 |
| STL | 0.669 | -0.078 |
| BLK | 0.347 | 0.653 |
| TOV | 0.894 | -0.008 |

PC1 combines scoring volume, playing time, free throws, assists and turnovers. It reflects offensive involvement, not the formal usage-rate statistic. PC2 contrasts interior rebounding, finishing and blocks against three-point emphasis.

## Player profiles

![Player role map](figures/Fig3_scores_PC1_PC2_labeled.png)

Rudy Gobert illustrates the interior-oriented side; Stephen Curry illustrates the perimeter-oriented side. Players close on this plot share a similar two-component projection, not necessarily identical full statistical profiles or interchangeable tactical roles. Selected labels illustrate extreme profiles rather than a comprehensive ranking. Exact axis extremes are retained in [PC1](outputs/extremes_PC1.csv) and [PC2](outputs/extremes_PC2.csv) tables.

## Diagnostics and sensitivity limits

Approximate Mardia diagnostics show pronounced departures from multivariate normality: skewness chi-square 8640.68 (1140 degrees of freedom) and kurtosis z=71.85, both p < 1e-16. PCA itself does not require normality; these diagnostics constrain distributional interpretations.

The chi-square(18) 0.999 reference threshold is 42.312396 and flags 23 profiles. All remain in the analysis. These are exploratory unusual combinations, not confirmed errors. The full covariance matrix has rank 18 but condition number approximately 113,852; redundancy and rounding can make Mahalanobis rankings sensitive. In-sample distances and non-normality also limit reference-threshold calibration.

Per-game statistics reflect playing time and team context and are not possession-adjusted. Recorded rounded FG3A is zero for 26 players and FTA for one; associated percentages cannot automatically be interpreted as measured shooting accuracy. This single-season study does not establish stability across seasons or eligibility thresholds.

## Conclusion

Two standardized components retain 73.82% of feature variance and provide an interpretable map of offensive involvement and interior/perimeter style. The result is a descriptive comparison tool, with important residual variation and diagnostic limitations. No classification accuracy, scouting impact or predictive performance is claimed.

## Reproducibility and report status

The [executed notebook](NBA_code.ipynb), [validation record](outputs/validation.json) and [corrected loading export](outputs/loadings_PC1_PC2.csv) are the numerical sources for this report. Run `verify_notebook.py` in the documented environment to reproduce the analysis; this written interpretation should be reviewed if the input snapshot changes.

This is the current portfolio report. Its feature-component correlations use the corrected finite-sample normalization; see [numerical verification](REPORT_VERIFICATION.md). Authorship and assistance acknowledgments are recorded in the [project README](README.md#author-and-acknowledgments).
