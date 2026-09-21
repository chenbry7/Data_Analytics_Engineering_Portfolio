# Data contract

The included files are fictional examples with the original status (21 columns) and category (56 columns) source structure. Keep CSV headers and column order. The SSIS sources use Windows-1252 and CRLF. Both files represent full snapshots and must be nonempty; an individual event may have no category records.

| Field class | Rule |
|---|---|
| Event key | Trimmed `sor_id` required in both files; unique in status; category IDs must exist in status |
| Participant key | May repeat within and across events; never used as a unique category key |
| Date | `YYYY-MM-DD` |
| Time | `HH:mm:ss` |
| Timestamp | `YYYY-MM-DDTHH:mm:ss` or the same with a space; no fractional seconds/time zone |
| Age and quantities | Nonnegative whole numbers within SQL INT range |
| Optional typed value | NULL, blank or n/a becomes SQL NULL |
| Flags | Original Y/N normalization to Yes/No, with n/a fallback |
| Date consistency | Occurrence cannot follow the relevant submission/update date |

The complete snapshot is rejected on a rule violation; records are not silently removed or deduplicated. Identifier comparison follows the database collation. These format constraints are explicit demonstration choices, not claims about an unavailable original export.

Silver preserves the 77-column source-aligned schema, with 60 mapped columns. The 17 originally unpopulated fields remain unpopulated: status `categories`; category `YOTIS`, `DSCIS`, `cont_for_youth`, `customary_care`, `office_guardian_trustee`, `other`, `YP_factors`, `OC`, `OD`, `SC`, `SD`, `PB`, `PD`, `EM`, `ES`, `CP`. They are excluded from Gold.

Gold exposes 18 event fields and 24 category fields. `report_delay_days` is the number of calendar-day boundaries between occurrence and submission, not elapsed 24-hour periods. Missing dates produce NULL. Unknown age is a separate group; age groups use the age supplied on each category record. No response-time SLA or overdue rule is invented.

Known Participants excludes blank IDs and counts distinct IDs visible in the current category context. It cannot count unidentified people or establish identity beyond the supplied ID. Source summary quantities are retained for reference, not substituted for these detail-based metrics.

## Demonstration datasets

The small acceptance fixture is in `data/synthetic`; the larger report dataset is in `data/showcase`. Both obey the same source contract. The showcase uses generic fictional category/program labels, with generation choices and reporting expectations documented in [its README](../data/showcase/README.md). No schema or Gold model change is required.
