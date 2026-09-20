# Processing sequence: Read the verified Silver export; select dimensionality by parallel analysis;
# fit and align FA/ICA; quantify bootstrap and initialization sensitivity;
# export keyed scores, diagnostics and reproducibility metadata.
"""Reproducible song-level parallel analysis, ML FA, ICA and stability checks."""
import hashlib, json, warnings
from pathlib import Path
from importlib.metadata import version
import numpy as np
import pandas as pd
from scipy.optimize import linear_sum_assignment
from scipy.stats import kurtosis
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA, FastICA
from sklearn.exceptions import ConvergenceWarning
from factor_analyzer import FactorAnalyzer
from factor_analyzer.factor_analyzer import calculate_kmo, calculate_bartlett_sphericity
from threadpoolctl import threadpool_limits
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from feature_contract import CORE
warnings.filterwarnings('ignore', category=FutureWarning)

def fit_fa(x, k, rotation='varimax', bound=0.005):
    """Fit maximum-likelihood FA and retain diagnostic warnings."""
    with warnings.catch_warnings(record=True) as caught:
        warnings.simplefilter('always', UserWarning)
        model = FactorAnalyzer(n_factors=k, method='ml', rotation=rotation, bounds=(bound, 1)).fit(x)
    return (model, [str(w.message) for w in caught if not issubclass(w.category, FutureWarning)])

def align(ref, other):
    """Match component columns and signs before comparing fitted solutions."""
    corr = np.corrcoef(ref.T, other.T)[:ref.shape[1], ref.shape[1]:]
    a, b = linear_sum_assignment(-np.abs(corr))
    order = b[np.argsort(a)]
    signs = np.sign(corr[np.arange(len(order)), order])
    signs[signs == 0] = 1
    return (other[:, order] * signs, np.abs(corr[np.arange(len(order)), order]))

def main(input_file=None, output_dir=None, report_file=None, provenance=None):
    """Analyze the explicit Silver export and write reproducible research artifacts."""
    # Validate the caller contract before creating any output files.
    if input_file is None or output_dir is None or report_file is None:
        raise ValueError('Run 04_audio_analysis.py with RUN_ADVANCED_ANALYSIS=True')
    # Create only the explicit output directory supplied by Step 04 after validation.
    OUT = Path(output_dir)
    OUT.mkdir(parents=True, exist_ok=True)
    file = Path(input_file)
    # Load the same keyed sample used by the main PCA workflow.
    data = pd.read_csv(file)
    x = data[CORE].to_numpy()
    n, p = x.shape
    if not data.track_id.is_unique or not np.isfinite(x).all():
        raise ValueError('Invalid explicit research sample')
    audit = {'source_sha256': (provenance or {}).get('source_sha256')}
    # Standardize feature scales and seed parallel-analysis simulations.
    z = StandardScaler().fit_transform(x)
    rng = np.random.default_rng(437)
    observed = np.linalg.eigvalsh(np.corrcoef(z, rowvar=False))[::-1]
    null_normal = []
    null_perm = []
    # Estimate null eigenvalue distributions using normal and permuted samples.
    for i in range(200):
        normal = rng.normal(size=z.shape)
        perm = np.column_stack([rng.permutation(z[:, j]) for j in range(p)])
        null_normal.append(np.linalg.eigvalsh(np.corrcoef(normal, rowvar=False))[::-1])
        null_perm.append(np.linalg.eigvalsh(np.corrcoef(perm, rowvar=False))[::-1])
        if (i + 1) % 50 == 0:
            print('Parallel analysis', i + 1, flush=True)
    qn = np.quantile(null_normal, 0.95, axis=0)
    qp = np.quantile(null_perm, 0.95, axis=0)

    # Retain only consecutive leading eigenvalues above the null threshold.
    def leading(q):
        fail = np.flatnonzero(observed <= q)
        return int(fail[0]) if len(fail) else p
    k = leading(qp)
    if not 1 <= k < p:
        raise ValueError('Dimension selection requires review')
    pd.DataFrame({'component': range(1, p + 1), 'observed': observed, 'normal_p95': qn, 'permutation_p95': qp}).to_csv(OUT / 'parallel_analysis.csv', index=False)
    # Cross-check PCA variance ratios against correlation-matrix eigenvalues.
    pc = PCA().fit(z)
    assert np.allclose(pc.explained_variance_ratio_, observed / observed.sum())
    # Fit the primary FA model and quantify residual correlation and adequacy.
    fa, fa_warnings = fit_fa(x, k)
    L = fa.loadings_
    uni = fa.get_uniquenesses()
    R = np.corrcoef(x, rowvar=False)
    residual = R - (L @ L.T + np.diag(uni))
    off = residual[np.triu_indices(p, 1)]
    kmo = calculate_kmo(x)[1]
    bartlett = calculate_bartlett_sphericity(x)
    # Export loadings, uniqueness diagnostics and track-keyed factor scores.
    pd.DataFrame(L, index=CORE, columns=[f'F{i + 1}' for i in range(k)]).to_csv(OUT / 'fa_loadings.csv', index_label='feature')
    pd.DataFrame({'feature': CORE, 'communality': fa.get_communalities(), 'uniqueness': uni, 'near_lower_bound': uni <= 0.006}).to_csv(OUT / 'fa_diagnostics.csv', index=False)
    scores = pd.DataFrame(fa.transform(x), columns=[f'F{i + 1}' for i in range(k)])
    scores.insert(0, 'track_id', data.track_id)
    scores.to_csv(OUT / 'fa_scores.csv', index=False)
    # Compare uniqueness bounds and rotations without changing the primary model.
    specs = []
    for rotation, bound in [('varimax', 0.001), ('varimax', 0.01), ('promax', 0.005)]:
        model, notes = fit_fa(x, k, rotation, bound)
        aligned, corr = align(L, model.loadings_)
        # factor-analyzer 0.5.1 reorders pattern/structure but not phi.
        phi = np.linalg.lstsq(model.loadings_, model.structure_, rcond=None)[0] if model.phi_ is not None else np.eye(k)
        assert np.allclose(phi, phi.T, atol=1e-08)
        common = model.loadings_ @ phi @ model.loadings_.T
        rr = R - common
        values = rr[np.triu_indices(p, 1)]
        specs.append({'rotation': rotation, 'bound': bound, 'min_aligned_loading_correlation': float(corr.min()), 'offdiag_rms': float(np.sqrt(np.mean(values ** 2))), 'warnings': notes})
        pd.DataFrame(model.loadings_, index=CORE).to_csv(OUT / f'fa_{rotation}_{bound}_loadings.csv', index_label='feature')
    # Resample complete tracks and align factor loadings for interval estimates.
    boots = []
    boot_warnings = []
    near = 0
    for b in range(200):
        sample = x[rng.integers(n, size=n)]
        model, notes = fit_fa(sample, k)
        boot_warnings.extend(notes)
        near += int((model.get_uniquenesses() <= 0.006).any())
        boots.append(align(L, model.loadings_)[0])
        if (b + 1) % 50 == 0:
            print('Bootstrap', b + 1, flush=True)
    boots = np.asarray(boots)
    pd.DataFrame([{'feature': CORE[i], 'factor': j + 1, 'loading': L[i, j], 'p025': np.quantile(boots[:, i, j], 0.025), 'p975': np.quantile(boots[:, i, j], 0.975)} for i in range(p) for j in range(k)]).to_csv(OUT / 'fa_bootstrap_intervals.csv', index=False)
    # Evaluate ICA initialization stability across ten reproducible seeds.
    stability = []
    reference = None
    for seed in [437, 0, 1, 2, 3, 4, 5, 6, 7, 8]:
        with warnings.catch_warnings(record=True) as caught:
            warnings.simplefilter('always', ConvergenceWarning)
            model = FastICA(n_components=k, whiten='unit-variance', random_state=seed, max_iter=2000, tol=0.0001)
            s = model.fit_transform(z)
        notes = [str(w.message) for w in caught]
        if reference is None:
            reference = model.mixing_
            table = pd.DataFrame(s, columns=[f'IC{i + 1}' for i in range(k)])
            table.insert(0, 'track_id', data.track_id)
            table.to_csv(OUT / 'ica_scores.csv', index=False)
            pd.DataFrame(reference, index=CORE).to_csv(OUT / 'ica_mixing.csv', index_label='feature')
            ic_kurt = kurtosis(s, axis=0).tolist()
        corr = align(reference, model.mixing_)[1]
        stability.append({'seed': seed, 'iterations': int(model.n_iter_), 'min_aligned_mixing_correlation': float(corr.min()), 'warnings': notes})
    # Assemble sample provenance, numerical diagnostics and interpretation limits.
    report = {'versions': {pkg: version(pkg) for pkg in ['numpy', 'pandas', 'scipy', 'scikit-learn', 'factor-analyzer', 'matplotlib']}, 'sample_rows': n, 'sample_sha256': hashlib.sha256(file.read_bytes()).hexdigest(), 'source_sha256': audit['source_sha256'], 'seed': 437, 'parallel_repetitions': 200, 'selected_k_permutation': k, 'selected_k_normal': leading(qn), 'kmo': float(kmo), 'bartlett_chi2': float(bartlett[0]), 'bartlett_p': float(bartlett[1]), 'fa_offdiag_rms': float(np.sqrt(np.mean(off ** 2))), 'fa_max_abs_offdiag': float(np.max(np.abs(off))), 'fa_near_bound_features': [CORE[i] for i in range(p) if uni[i] <= 0.006], 'fa_warnings': fa_warnings, 'fa_specification_checks': specs, 'bootstrap_repetitions': 200, 'bootstrap_with_near_bound': near, 'bootstrap_warnings': sorted(set(boot_warnings)), 'ica_excess_kurtosis': ic_kurt, 'ica_seed_checks': stability, 'provenance': provenance, 'validation': ['PCA covariance comparison passed', 'Unique track IDs', '200 full-song bootstrap fits', 'Optimal permutation/sign alignment'], 'limits': ['Exploratory correlation-eigenvalue parallel analysis; not definitive factor count.', 'Bootstrap assumes independent tracks, not independent artists.', 'Boundary solutions limit FA interpretation.', 'ICA initialization stability is not external validity.']}
    # Re-read score exports to confirm ordered identifiers and finite values.
    for filename in ['fa_scores.csv', 'ica_scores.csv']:
        check = pd.read_csv(OUT / filename)
        assert check.track_id.equals(data.track_id) and np.isfinite(check.iloc[:, 1:]).all().all()
    Path(report_file).write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    # Render parallel-analysis and factor-loading summaries for the current run.
    fig, axes = plt.subplots(1, 2, figsize=(12, 4.8), layout='constrained')
    axes[0].plot(range(1, p + 1), observed, 'o-', label='Observed')
    axes[0].plot(range(1, p + 1), qp, 'o--', label='Permutation 95%')
    axes[0].set(title=f'Parallel analysis: retain {k}', xlabel='Component', ylabel='Correlation eigenvalue')
    axes[0].legend()
    im = axes[1].imshow(L, vmin=-1, vmax=1, cmap='coolwarm', aspect='auto')
    axes[1].set_yticks(range(p), CORE)
    axes[1].set_xticks(range(k), [f'F{i + 1}' for i in range(k)])
    axes[1].set_title('ML FA loadings (boundary caution)')
    for i in range(p):
        for j in range(k):
            axes[1].text(j, i, f'{L[i, j]:.2f}', ha='center', va='center', fontsize=8)
    fig.colorbar(im, ax=axes[1])
    fig.savefig(OUT / 'model_summary.png', dpi=160)
    plt.close(fig)
    print(json.dumps(report, indent=2), flush=True)
if __name__ == '__main__':
    raise SystemExit('Run 04_audio_analysis.py with RUN_ADVANCED_ANALYSIS=True instead.')
