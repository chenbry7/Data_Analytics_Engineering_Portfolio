"""Validate the frozen course extract; optionally compare with a local source CSV.

Usage: python scripts/validate_data.py [path/to/hcd_sdr.csv]
Uses only Python's standard library. Does not render or validate R execution.
"""
import csv
import hashlib
import itertools
import json
import math
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
COUNTRIES = ['canada', 'england and wales', 'japan', 'united states']
SEX = ['total', 'males', 'females']
AGES = ['total', '0-14', '15-39', '40-64', '65 and above']
FIELDS = ['country', 'year', 'sex', 'cause', 'age_group', 'sdr_per_million']

def read(path):
    with Path(path).open(encoding='utf-8-sig', newline='') as f:
        reader = csv.DictReader(f)
        assert reader.fieldnames == FIELDS, reader.fieldnames
        return [{k: v.strip().lower() if k in ['country', 'sex', 'age_group']
                 else v.strip().upper() if k == 'cause' else v.strip()
                 for k, v in r.items()} for r in reader]

def key(r):
    return tuple(r[k] for k in FIELDS[:-1])

def main():
    path = ROOT / 'hcd_sdr_filtered.csv'
    rows = read(path)
    assert len({key(r) for r in rows}) == len(rows), 'Duplicate observational keys'
    assert all(math.isfinite(float(r['sdr_per_million'])) and
               float(r['sdr_per_million']) >= 0 for r in rows), 'Invalid rates'
    assert set(r['country'] for r in rows) == set(COUNTRIES)
    assert set(r['sex'] for r in rows) == set(SEX)
    assert set(r['age_group'] for r in rows) == set(AGES)
    assert set(r['cause'] for r in rows) == {'I033'}
    lookup = {key(r): float(r['sdr_per_million']) for r in rows}
    expected = set(itertools.product(COUNTRIES, map(str, range(2001, 2022)), SEX, ['I033'], AGES))
    observed = {key(r) for r in rows if 2001 <= int(r['year']) <= 2021}
    assert observed == expected, 'Incomplete 2001-2021 grid'
    audit = {'extract_rows': len(rows), 'analysis_rows': len(observed),
             'missing_or_duplicate_keys': 0, 'nonfinite_or_negative_rates': 0,
             'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
             'coverage': {c: [min(int(r['year']) for r in rows if r['country'] == c),
                               max(int(r['year']) for r in rows if r['country'] == c)] for c in COUNTRIES}}
    if len(sys.argv) > 1:
        source_path = Path(sys.argv[1])
        source = read(source_path)
        subset = [r for r in source if r['country'] in COUNTRIES and r['cause'] == 'I033']
        source_lookup = {key(r): float(r['sdr_per_million']) for r in subset}
        assert source_lookup.keys() == lookup.keys()
        differences = [abs(source_lookup[k] - lookup[k]) for k in lookup]
        assert all(math.isclose(source_lookup[k], lookup[k], rel_tol=0, abs_tol=1e-8)
                   for k in lookup), 'Rate mismatch exceeds serialization tolerance'
        assert len(subset) == len(rows)
        audit['source_comparison'] = {'rows': len(source), 'matching_subset_rows': len(subset),
                                     'sha256': hashlib.sha256(source_path.read_bytes()).hexdigest(),
                                     'max_absolute_difference': max(differences),
                                     'absolute_tolerance': 1e-8,
                                     'result': 'All keys match; rates agree within floating-point serialization tolerance'}
    endpoints = []
    for c, sex in itertools.product(COUNTRIES, SEX):
        a, b = [lookup[(c, str(y), sex, 'I033', 'total')] for y in [2001, 2021]]
        endpoints.append({'country': c, 'sex': sex, 'rate_2001': a, 'rate_2021': b,
                          'percent_change': round(100 * (b/a-1), 4)})
    for c in COUNTRIES:
        gap = [lookup[(c, str(y), 'males', 'I033', 'total')] -
               lookup[(c, str(y), 'females', 'I033', 'total')] for y in [2001, 2021]]
        assert gap[1] < gap[0]
        audit.setdefault('sex_gap', {})[c] = {'2001': gap[0], '2021': gap[1],
                                             'percent_change': 100*(gap[1]/gap[0]-1)}
    # Frozen labels transcribed from original Report.pdf (Figures 1-5).
    # Changed downloads are deliberately reported as needing narrative review.
    original_percent = {
        'canada': [-54.4, -53.5, -58.1],
        'england and wales': [-60.5, -58.2, -66.6],
        'japan': [-44.0, -37.7, -54.7],
        'united states': [-51.3, -48.1, -57.2]}
    original_age = {
        'canada': [0, 0, 16, 14, 661, 413, 9871, 4298],
        'england and wales': [1, 0, 22, 17, 902, 503, 11449, 4252],
        'japan': [0, 0, 17, 8, 253, 193, 3070, 1633],
        'united states': [1, 1, 37, 27, 1037, 692, 12610, 5802]}
    original_overall = {'canada': [2151.1, 980.9], 'england and wales': [2541.7, 1002.9],
                        'japan': [688.5, 385.8], 'united states': [2817.7, 1371.8]}
    label_matches = []
    for c in COUNTRIES:
        label_matches.extend(round(r['percent_change'], 1) == original_percent[c][SEX.index(r['sex'])]
                             for r in endpoints if r['country'] == c)
        rates = [round(lookup[(c, str(y), 'total', 'I033', age)])
                 for age in AGES[1:] for y in [2001, 2021]]
        label_matches.extend(a == b for a, b in zip(rates, original_age[c]))
        label_matches.extend(round(lookup[(c, str(y), 'total', 'I033', 'total')], 1) == b
                             for y, b in zip([2001, 2021], original_overall[c]))
        label_matches.append(all(lookup[(c, str(y), 'males', 'I033', 'total')] >
                                 lookup[(c, str(y), 'females', 'I033', 'total')]
                                 for y in range(2001, 2022)))
    label_matches.extend(round(audit['sex_gap'][c]['percent_change'], 1) == b
                         for c, b in zip(COUNTRIES, [-47.8, -49.1, -15.8, -34.5]))
    audit['original_report_check'] = {'all_labels_and_male_higher_checks_match': all(label_matches),
                                     'checks': len(label_matches),
                                     'warning': None if all(label_matches) else 'Data changed: revise original charts and public narrative'}
    audit['scope'] = 'Data checks and independent arithmetic only; no R execution'
    (ROOT / 'validation_results.json').write_text(json.dumps(audit, indent=2)+'\n', encoding='utf-8')
    with (ROOT / 'endpoint_summary.csv').open('w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=endpoints[0].keys()); w.writeheader(); w.writerows(endpoints)
    print(json.dumps(audit, indent=2))

if __name__ == '__main__':
    main()
