# Sales Analysis Findings

## Dataset and Validation Scope

The SQL reports were executed after a complete CSV-to-Gold refresh in an isolated SQL Server database on October 17, 2026. The fact view contained **60,398 sales records**, with dated orders spanning **December 29, 2010 to January 28, 2014**. These results describe the checked-in dataset and may change with replacement files.

The scorecard returned no FAIL results. Source and Silver date checks each identified **19 affected sales rows** for review; these rows have missing, invalid, or out-of-range dates. The Gold fact has **19 missing order dates**. The historical-date policy and full verification coverage are documented in [Verification Results](validation.md).

## 1. Revenue Is Concentrated in Bikes

| Current category | Revenue (source monetary units) | Revenue share | Units sold |
|---|---:|---:|---:|
| Bikes | 28,316,272 | 96.46% | 15,205 |
| Accessories | 700,262 | 2.39% | 36,112 |
| Clothing | 339,716 | 1.16% | 9,106 |

Bikes account for most of the **29,356,250** in total recorded revenue, while accessories have the highest unit volume. Revenue and volume therefore tell different stories: high accessory volume does not imply a comparable revenue contribution. Percentages may not sum to exactly 100% after rounding.

This is revenue, not profit. Product costs are current attributes and do not establish historical transaction margins. Categories also reflect the current product dimension.

## 2. Repeat Purchasing Describes the Observation Window

Of **18,484 observed buyers**, **6,865** placed at least two distinct orders, producing a repeat-buyer percentage of **37.14%**.

The calculation counts distinct orders rather than sales lines. It includes only customers with a resolved key and a non-null order number. It does not measure lifetime retention or compare acquisition cohorts; customers first observed near the end of the dataset have less opportunity to place another order.

## 3. Monthly Revenue Requires Coverage Context

December 2013 recorded **1,874,128** in revenue and **2,192 distinct orders**, compared with January 2014 revenue of **45,642** and **871 orders**. This difference should not be presented as proof of a business collapse. The dataset ends on January 28, 2014, and the SQL reports alone do not establish source completeness, product mix changes, or the cause of the difference.

The monthly report excludes the 19 undated sales rows. It compares each month with the previous observed month and exposes that comparison month explicitly. Missing months are not assumed to have zero sales.

## Reproduction and Verification

1. Run [the quality scorecard](../scripts/13_data_quality_summary.sql) against a populated warehouse and investigate FAIL results.
2. Run [the sales analysis](../scripts/14_sales_analysis.sql) to reproduce the four result sets.
3. Read [the metric definitions](project_extensions.md) before drawing business conclusions.

Focused regression checks, populated-warehouse assertions, a repeated full refresh, and repeated view deployment passed. A missing-file test confirmed that the Bronze error propagates and dependent Silver loading does not proceed. All execution used an isolated database. See [Verification Results](validation.md) for reconciled row counts, the tested engine version, and limitations.
