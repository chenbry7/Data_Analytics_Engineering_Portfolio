# Processing sequence: Verify input provenance; reconstruct matched promax covariance;
# compare paired bootstrap starts using the ML discrepancy;
# export intervals and fit diagnostics without claiming global optimality.
"""FA diagnostics: matched promax covariance and paired-start bootstrap."""
import json, hashlib, warnings
from pathlib import Path
import numpy as np
import pandas as pd
from factor_analyzer import FactorAnalyzer
from factor_analyzer.rotator import Rotator
from threadpoolctl import threadpool_limits
from analyze_latent import CORE, align
warnings.filterwarnings('ignore', category=FutureWarning)

def fit(x, smc):
    """Fit one initialization and evaluate its ML discrepancy and residuals."""
    with warnings.catch_warnings(record=True) as caught:
        model = FactorAnalyzer(n_factors=3, method='ml', rotation='varimax', use_smc=smc).fit(x)
    # Reconstruct fitted covariance before comparing initialization objectives.
    L = model.loadings_
    u = model.get_uniquenesses()
    R = model.corr_
    S = L @ L.T + np.diag(u)
    sign, logdet = np.linalg.slogdet(S)
    sr, lr = np.linalg.slogdet(R)
    if sign <= 0 or sr <= 0:
        raise ValueError('Nonpositive covariance determinant')
    objective = logdet + np.trace(np.linalg.solve(S, R)) - lr - len(CORE)
    residual = (R - S)[np.triu_indices(len(CORE), 1)]
    return (model, {'objective': float(objective), 'rms': float(np.sqrt(np.mean(residual ** 2))), 'near_bound': bool((u <= 0.006).any()), 'warnings': ' | '.join((str(w.message) for w in caught if not issubclass(w.category, FutureWarning)))})

def main(input_file=None, output_dir=None, prior_file=None, report_file=None):
    """Compare two FA starts per resample and verify promax covariance ordering."""
    # Require explicit inputs so diagnostics cannot silently use an older sample.
    if any((v is None for v in [input_file, output_dir, prior_file, report_file])):
        raise ValueError('Run 04_audio_analysis.py with RUN_ADVANCED_ANALYSIS=True')
    OUT = Path(output_dir)
    OUT.mkdir(exist_ok=True, parents=True)
    file = Path(input_file)
    # Verify the selected dimension and fingerprint from the preceding analysis.
    prior = json.loads(Path(prior_file).read_text())
    if prior['selected_k_permutation'] != 3:
        raise ValueError('This diagnostic compares 3-factor models; review selected dimension before using it')
    assert hashlib.sha256(file.read_bytes()).hexdigest() == prior['sample_sha256']
    x = pd.read_csv(file)[CORE].to_numpy()
    # Establish reference loadings and an independently rotated promax solution.
    ref, _ = fit(x, True)
    unrot = FactorAnalyzer(n_factors=3, method='ml', rotation=None).fit(x)
    rot = Rotator(method='promax')
    pattern = rot.fit_transform(unrot.loadings_)
    phi = rot.phi_
    common = pattern @ phi @ pattern.T
    invariance = float(np.max(np.abs(common - unrot.loadings_ @ unrot.loadings_.T)))
    assert invariance < 1e-08
    pro = FactorAnalyzer(n_factors=3, method='ml', rotation='promax').fit(x)
    # Recover correctly ordered phi using the correspondingly ordered structure matrix.
    phi_matched = np.linalg.lstsq(pro.loadings_, pro.structure_, rcond=None)[0]
    assert np.allclose(phi_matched, phi_matched.T)
    assert np.allclose(pro.loadings_ @ phi_matched @ pro.loadings_.T, common, atol=1e-08)
    off = (pro.corr_ - common)[np.triu_indices(9, 1)]
    # Export the matched pattern and factor-correlation matrices.
    pd.DataFrame(pattern, index=CORE, columns=['F1', 'F2', 'F3']).to_csv(OUT / 'promax_pattern_matched.csv', index_label='feature')
    pd.DataFrame(phi, index=['F1', 'F2', 'F3'], columns=['F1', 'F2', 'F3']).to_csv(OUT / 'promax_phi_matched.csv')
    # Fit both starts to the same resample and align both to reference factors.
    rows = []
    selected = []
    original = []
    rng = np.random.default_rng(5437)
    for b in range(200):
        xb = x[rng.integers(len(x), size=len(x))]
        candidates = []
        for smc in [True, False]:
            model, stat = fit(xb, smc)
            L, corr = align(ref.loadings_, model.loadings_)
            stat.update(replicate=b + 1, use_smc=smc, min_matching_correlation=float(corr.min()))
            rows.append(stat)
            candidates.append((L, stat))
        original.append(candidates[0][0])
        selected.append(min(candidates, key=lambda item: item[1]['objective'])[0])
        if (b + 1) % 25 == 0:
            print('Paired bootstrap', b + 1, '/ 200', flush=True)
    # Export all 400 fits and paired loading intervals for both selection rules.
    frame = pd.DataFrame(rows)
    frame.to_csv(OUT / 'bootstrap_fit_diagnostics.csv', index=False)
    for name, values in [('default_start', original), ('best_of_two_starts', selected)]:
        values = np.asarray(values)
        pd.DataFrame([{'feature': CORE[i], 'factor': j + 1, 'reference_loading': ref.loadings_[i, j], 'p025': np.quantile(values[:, i, j], 0.025), 'p975': np.quantile(values[:, i, j], 0.975)} for i in range(9) for j in range(3)]).to_csv(OUT / f'{name}_intervals.csv', index=False)
    # Summarize within-resample objective differences and remaining limitations.
    paired = frame.pivot(index='replicate', columns='use_smc', values='objective')
    report = {'sample_sha256': prior['sample_sha256'], 'replicates': 200, 'seed': 5437, 'promax_common_covariance_invariance_error': invariance, 'promax_rms_corrected': float(np.sqrt(np.mean(off ** 2))), 'promax_rms_previously_reported': prior['fa_specification_checks'][2]['offdiag_rms'], 'phi_order_mismatch_max_abs': float(np.max(np.abs(phi_matched - pro.phi_))), 'alternative_start_better_by_over_1e_6': int((paired[True] - paired[False] > 1e-06).sum()), 'default_start_better_by_over_1e_6': int((paired[False] - paired[True] > 1e-06).sum()), 'fit_warning_count': int(frame.warnings.ne('').sum()), 'default_near_bound_count': int(frame[frame.use_smc].near_bound.sum()), 'default_matching_below_095': int((frame[frame.use_smc].min_matching_correlation < 0.95).sum()), 'limits': ['Two starts are a sensitivity check, not guaranteed global optimum.', 'Different seed from Step4; compare starts within this paired run.', 'Boundary and factor identification limitations remain.']}
    Path(report_file).write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))
if __name__ == '__main__':
    raise SystemExit('Run 04_audio_analysis.py with RUN_ADVANCED_ANALYSIS=True instead.')
