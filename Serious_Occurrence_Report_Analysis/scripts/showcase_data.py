"""Reproduce fictional SSIS inputs or reconcile their complete Gold projections.

Python 3 standard library only. No production source or service is used.
"""
import argparse
import calendar
from collections import Counter, defaultdict
import csv
from datetime import date, datetime, timedelta
import hashlib
import io
import json
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'data' / 'showcase'
SEED = 20260921
MONTH_COUNTS = [26, 31, 28, 35, 30, 38, 42, 36, 45, 39, 34, 36]

def read_csv(path):
    with path.open(encoding='cp1252', newline='') as stream:
        reader = csv.DictReader(stream)
        rows = list(reader)
        assert all(None not in row and None not in row.values() for row in rows)
        return reader.fieldnames, rows

def encode_csv(headers, rows):
    stream = io.StringIO(newline='')
    writer = csv.DictWriter(stream, fieldnames=headers, lineterminator='\r\n')
    writer.writeheader()
    writer.writerows(rows)
    return stream.getvalue().encode('cp1252')

def generate():
    rng = random.Random(SEED)
    sh, _ = read_csv(ROOT / 'data/synthetic/SO_status.csv')
    ch, _ = read_csv(ROOT / 'data/synthetic/SO_category.csv')
    statuses, categories = [], []
    sequence = 0
    for month_index, count in enumerate(MONTH_COUNTS):
        year, month = (2025, month_index + 9) if month_index < 4 else (2026, month_index - 3)
        for _ in range(count):
            sequence += 1
            site = rng.choices(range(1, 7), weights=[6, 5, 4, 3, 3, 2])[0]
            occurred = datetime(year, month, rng.randint(1, calendar.monthrange(year, month)[1]), rng.randint(0, 20), rng.choice([0, 15, 30, 45]))
            delay = rng.choices([0, 1, 2, 3, 5, 7], weights=[38, 31, 16, 8, 5, 2])[0]
            submitted = occurred + timedelta(days=delay, hours=1)
            updated = submitted + timedelta(days=rng.randint(0, 4))
            status = rng.choices(['Open', 'Closed', 'Under Review'], weights=[2, 6, 2])[0]
            media = 'Y' if rng.random() < .13 else 'N'
            level = str(rng.choice([1, 2]))
            sor_id = f'SYN-E{sequence:05d}'
            common = {'Site ID': f'SYN-SITE-{site:02d}', 'Site name': f'Synthetic Site {chr(64 + site)}',
                      'Relates to individual placed at non-funded non-licensed OPR?': 'N',
                      'SOR ID': sor_id, 'Status': status, 'SOR Level': level, 'Media attention': media}
            event = dict.fromkeys(sh, '')
            event.update(common)
            for label, stamp in [('Serious Occurrence', occurred), ('Report Submission', submitted)]:
                event['Date of ' + label] = stamp.date().isoformat()
                event['Time of ' + label] = stamp.time().isoformat()
            event.update({'Last Update Date': updated.date().isoformat(), 'Last Update Time': updated.time().isoformat()})
            records = []
            n = 0 if sequence % 23 == 0 else rng.choices([1, 2, 3, 4], weights=[3, 4, 2, 1])[0]
            participant = rng.randint(1, 120)
            selected_categories = rng.sample(range(8), n)
            for j, cat in enumerate(selected_categories):
                # The same fictional ID can recur in another category or event.
                p = participant if j < 2 else rng.randint(1, 120)
                missing_id = sequence % 37 == 0 and j == 0
                dob = None if p % 11 == 0 or missing_id else date(2003 + p % 21, 1 + p % 12, 1 + p % 27)
                age = '' if dob is None else str(occurred.year - dob.year - ((occurred.month, occurred.day) < (dob.month, dob.day)))
                row = dict.fromkeys(ch, '')
                row.update(common)
                row.update({'Date and Time of Serious Occurrence': occurred.isoformat(),
                            'Date and Time of Report Submission': submitted.isoformat(),
                            'Last Update Date and Time': updated.isoformat(),
                            'Category': 'Synthetic Category ' + chr(65 + cat),
                            'Sub Category': f'Synthetic Subcategory {chr(65 + cat)}{1 + sequence % 2}',
                            'Category Level': level, 'Location': 'Synthetic location ' + str(1 + sequence % 3),
                            'Client ID': '' if missing_id else f'SYN-P{p:04d}',
                            'Client DOB': '' if dob is None else dob.isoformat(),
                            'Client age (At time of SO)': age,
                            'Program': 'Synthetic Program ' + chr(65 + p % 4)})
                # Optional legal/notification attributes are intentionally unspecified.
                records.append(row)
            event['# of individuals'] = str(len({r['Client ID'] for r in records if r['Client ID']}) + sum(not r['Client ID'] for r in records))
            event['# of unique non-client individuals (associated to specific COVID 19 SORs)'] = '0'
            event['# of unique categories'] = str(len({r['Category'] for r in records}))
            statuses.append(event)
            categories.extend(records)
    return sh, statuses, ch, categories

def projections(statuses, categories):
    events, details = [], []
    for r in statuses:
        events.append(dict(sor_id=r['SOR ID'], site_id=r['Site ID'], site_name=r['Site name'],
            sor_status=r['Status'], sor_level=r['SOR Level'], media_attention={'Y':'Yes', 'N':'No'}[r['Media attention']],
            date_serious_occur=r['Date of Serious Occurrence'], time_serious_occur=r['Time of Serious Occurrence'],
            date_report_submit=r['Date of Report Submission'], time_report_submit=r['Time of Report Submission'],
            last_update_date=r['Last Update Date'], last_update_time=r['Last Update Time'],
            num_individuals=int(r['# of individuals']),
            num_unique_individuals=int(r['# of unique non-client individuals (associated to specific COVID 19 SORs)']),
            num_unique_categories=int(r['# of unique categories']),
            month_start=r['Date of Serious Occurrence'][:7]+'-01', year_month=r['Date of Serious Occurrence'][:7],
            report_delay_days=(date.fromisoformat(r['Date of Report Submission'])-date.fromisoformat(r['Date of Serious Occurrence'])).days))
    for r in categories:
        age = int(r['Client age (At time of SO)']) if r['Client age (At time of SO)'] else None
        group = 6 if age is None else 1 if age < 5 else 2 if age < 10 else 3 if age < 15 else 4 if age < 18 else 5
        row = dict(sor_id=r['SOR ID'], category=r['Category'], sub_category=r['Sub Category'], category_type=r['Type'] or 'n/a',
            claim=r['Claim'] or 'n/a', client_role=r['Role'] or 'n/a', category_level=r['Category Level'],
            occurrence_location=r['Location'], client_id=r['Client ID'] or None, client_age=age,
            age_group=['0-4','5-9','10-14','15-17','18+','Unknown'][group-1], age_group_order=group,
            guardian_status=r['Legal Guardian Status'] or 'n/a', program=r['Program'], provider_notification=r['Service Provider Notifications'] or 'n/a')
        for name in ['coroner','ombudsman','parent_guardian','local_health','placing_agency','police','other_ministry','emergency_DS','other']:
            row['notification_'+name] = 'n/a'
        details.append(row)
    return events, details

def verify_source(statuses, categories):
    by_id = {r['SOR ID']: r for r in statuses}
    assert len(by_id) == len(statuses) == 420
    assert len({r['Site ID'] for r in statuses}) == 6
    assert len({r['Category'] for r in categories}) == 8
    assert len({r['Program'] for r in categories}) == 4
    assert list(sorted(Counter(r['Date of Serious Occurrence'][:7] for r in statuses).values())) == sorted(MONTH_COUNTS)
    grouped = defaultdict(list)
    births = {}
    for r in categories:
        s = by_id[r['SOR ID']]
        grouped[r['SOR ID']].append(r)
        for field in ['Site ID','Site name','Status','SOR Level','Media attention']:
            assert r[field] == s[field], (r['SOR ID'], field)
        for field, datefield, timefield in [('Date and Time of Serious Occurrence','Date of Serious Occurrence','Time of Serious Occurrence'),('Date and Time of Report Submission','Date of Report Submission','Time of Report Submission'),('Last Update Date and Time','Last Update Date','Last Update Time')]:
            assert r[field] == s[datefield]+'T'+s[timefield]
        if r['Client ID']:
            assert births.setdefault(r['Client ID'], r['Client DOB']) == r['Client DOB']
        if r['Client DOB']:
            dob, occurrence = date.fromisoformat(r['Client DOB']), date.fromisoformat(s['Date of Serious Occurrence'])
            assert int(r['Client age (At time of SO)']) == occurrence.year-dob.year-((occurrence.month,occurrence.day)<(dob.month,dob.day))
    for key, r in by_id.items():
        rows = grouped[key]
        assert int(r['# of unique categories']) == len({c['Category'] for c in rows})
        assert int(r['# of individuals']) == len({c['Client ID'] for c in rows if c['Client ID']}) + sum(not c['Client ID'] for c in rows)
    e, c = projections(statuses, categories)
    assert len({x['age_group'] for x in c}) == 6
    return e, c

def summary(events, details):
    media = sum(e['media_attention']=='Yes' for e in events)
    return {'events':len(events), 'category_records':len(details), 'events_with_categories':len({c['sor_id'] for c in details}),
            'known_participants':len({c['client_id'] for c in details if c['client_id']}),
            'sites':len({e['site_id'] for e in events}), 'categories':len({c['category'] for c in details}),
            'programs':len({c['program'] for c in details}), 'media_events':media,
            'media_attention_rate':media/len(events), 'avg_report_delay_days':sum(e['report_delay_days'] for e in events)/len(events),
            'unknown_age_records':sum(c['client_age'] is None for c in details), 'missing_id_records':sum(c['client_id'] is None for c in details),
            'monthly_events':dict(sorted(Counter(e['year_month'] for e in events).items()))}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--generate', action='store_true')
    parser.add_argument('--gold-json', type=Path)
    args = parser.parse_args()
    if args.generate:
        sh, statuses, ch, categories = generate()
        verify_source(statuses, categories)
        OUT.mkdir(parents=True, exist_ok=True)
        for name, headers, rows in [('SO_status.csv',sh,statuses),('SO_category.csv',ch,categories)]:
            (OUT/name).write_bytes(encode_csv(headers,rows))
    sh, statuses = read_csv(OUT/'SO_status.csv')
    ch, categories = read_csv(OUT/'SO_category.csv')
    assert sh == read_csv(ROOT/'data/synthetic/SO_status.csv')[0]
    assert ch == read_csv(ROOT/'data/synthetic/SO_category.csv')[0]
    events, details = verify_source(statuses, categories)
    result = summary(events, details)
    if args.gold_json:
        actual = json.loads(args.gold_json.read_text(encoding='utf-8-sig'))
        canonical = lambda rows: Counter(json.dumps(r,sort_keys=True) for r in rows)
        assert canonical(actual['events']) == canonical(events), 'Gold event fields differ from CSV projection'
        assert canonical(actual['categories']) == canonical(details), 'Gold category fields differ from CSV projection'
        assert actual['counts'] == {'bronze_events':len(statuses),'bronze_categories':len(categories),'silver_events':len(statuses),'silver_categories':len(categories)}
        print('PASS: every Gold field and record matches CSV expectations; Bronze/Silver counts reconcile.')
    result['csv_sha256'] = {name:hashlib.sha256((OUT/name).read_bytes()).hexdigest() for name in ['SO_status.csv','SO_category.csv']}
    if args.generate:
        (OUT/'expected_metrics.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    else:
        assert result == json.loads((OUT/'expected_metrics.json').read_text()), 'Showcase metrics/hash manifest differs'
    print(json.dumps(result,indent=2))

if __name__ == '__main__':
    main()
