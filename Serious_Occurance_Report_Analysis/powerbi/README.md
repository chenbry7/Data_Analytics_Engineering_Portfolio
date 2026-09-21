# Power BI report

[SOR_analysis.pbix](SOR_analysis.pbix) contains four completed pages and an imported synthetic dataset. Opening the saved report and refreshing it are separate operations. Refresh connects to `.\SQLEXPRESS`, database `SOR_Portfolio_Test`; run the root showcase loader first if the database currently contains the small test fixture.

## Model

| One side | Many side | Configuration |
|---|---|---|
| Calendar[Date] | Events[date_serious_occur] | Active, single direction |
| Events[sor_id] | Categories[sor_id] | Active, single direction |

Events imports `gold.fact_events` (420 rows, 18 columns); Categories imports `gold.fact_categories` (855 rows, 24 columns). Calendar has 365 unique days, September 2025–August 2026. The PBIX also contains hidden automatic date tables for other date columns; the report trends and date/month slicers use the explicit Calendar table.

`YearMonth` sorts by `MonthStart`; `age_group` sorts by `age_group_order`. Date, YearMonth and site slicers have synchronization groups on the first three pages. Category/program slicers are local to page 2. The decomposition page is a separate exploration page without these visible synchronized slicers.

## Metric contract

| Measure | Meaning | Unfiltered showcase |
|---|---|---:|
| Event Count | Number of event rows | 420 |
| Category Records | Actual classification records | 855 |
| Events with Categories | Distinct event IDs in visible classification records | 402 |
| Known Participants | Distinct nonblank participant IDs | 119 |
| Site Count | Distinct nonblank event site IDs | 6 |
| Media Event Count | Events with media_attention = Yes | 53 |
| Media Attention Rate | Media events / events | 12.62% |
| Avg Report Delay Days | Mean calendar-day delay per event | 1.23 |

The [DAX measures](MEASURES.dax) match the report formulas. [Calendar DAX](CALENDAR.dax) matches the saved calculated table.

Distinct event/category branches overlap. Participants can cross age groups during the year. Do not sum these group counts as if they were mutually exclusive. The event detail table uses only Events fields, including its event ID. No SLA threshold is implied by reporting delay.

## Report pages

| Page | Purpose |
|---|---|
| Overview | Event volume, participants, media attention, monthly trend, status and site comparisons |
| Categories & Participants | Category event counts, site/category matrix, participant age groups and programs |
| Reporting Timeliness & Detail | Event-average delay by site and month, with event-level detail |
| Decomposition Tree | Distinct events with categories explored by category, age, program, site and status |

## Usage notes

Date-range and YearMonth selections intersect. Clear both when returning to the full snapshot. The site/category matrix supports horizontal scrolling. Decomposition category branches overlap; their counts are not additive. The category-B example contains 115 events: 67 Closed, 24 Open and 24 Under Review.

The saved data, report definitions and screenshots have been checked. Live refresh and exhaustive interactive testing are outside the recorded validation scope. See [validation evidence](../docs/VALIDATION.md).
