# Data provenance and reuse

## Frozen course extract

The included `hcd_sdr_filtered.csv` contains 1,965 records for four countries and cause I033. It was already present; its contents have not been replaced. The source comparison used the read-only course file `Rstudio/sta313/A2/Formal/hcd_sdr.csv` in the parent course repository (660,915 records). All 1,965 observation keys match after case normalization; the maximum numeric difference is 3.64e-12 per million, consistent with floating-point CSV serialization. The other full source at `Rstudio/sta313/hcd_sdr.csv` has the same row count and schema, but was not used as the authoritative comparison file.

The analysis selects 2001-2021, leaving a complete 1,260-row grid: 4 countries × 21 years × 3 sex categories × 5 age categories. No extra data or imputation is needed.

| Country in CSV | Extract coverage |
| --- | --- |
| canada | 2000-2022 |
| england and wales | 2001-2022 |
| japan | 1981-2021 |
| united states | 1979-2023 |

| Field | Meaning |
| --- | --- |
| country | National population; England and Wales is one combined population |
| year | Calendar year |
| sex | `males`, `females`, `total` (both sexes) |
| cause | `I033`, identified as ischaemic heart disease by the course report; a cause-list identifier, not literal ICD-10 code I33 |
| age_group | `total`, `0-14`, `15-39`, `40-64`, `65 and above` |
| sdr_per_million | Standardized deaths per million; rate, not number of deaths |

`sex=total, age_group=total` is the supplied overall SDR. Sex comparisons retain `age_group=total`. Age-band comparisons retain `sex=total` and use each supplied band separately. No rates are added to derive totals. The original report and local formal Rmd describe the standard as European Standard Population 2013, but the CSV alone cannot establish this: HCD supplies both 1976 and 2013 series. Confirm the original export and codebook before treating the standard and I033 mapping as fully verified provenance. The acquisition date and original download filenames are unknown. This is a frozen course snapshot, not a download of current HCD estimates.

## Source and license

Source attribution: Human Cause of Deaths data series (HCD). Human Mortality Database. Max Planck Institute for Demographic Research (Germany), University of California, Berkeley (USA), and French Institute for Demographic Studies (France). Available at [mortality.org](https://www.mortality.org/).

The [HMD user agreement](https://www.mortality.org/Data/UserAgreement), checked 1 October 2026, distinguishes HMD-constructed estimates (CC BY 4.0) from provider input data, which retain their providers' licenses. It recommends referring users to HMD for current downloads. The [HCD explanatory notes](https://www.mortality.org/File/GetDocument/hcd/docs/HCD_Method_Explanatory_Notes.pdf) describe reconstructed series, aggregated age-band SDRs, and the two European standards. These public documents support the methodology and reuse distinction; they do not establish which standard was downloaded for this local CSV.

The project includes the frozen `hcd_sdr_filtered.csv` to reproduce the published figures. It was filtered to the four countries and I033, with lowercase country, sex and age labels; no additional numerical transformation was applied in this public edition. The file appears to contain constructed SDR estimates, for which HMD states a [CC BY 4.0 license](https://creativecommons.org/licenses/by/4.0/). Its original download provenance remains incomplete, so inclusion does not independently confirm the exact series or its license status. The original acquisition date, download filenames, codebook and standard remain to be documented; no download date has been invented. Do not apply a blanket repository license to provider input data or to the collaborators' report without their agreement.

## Obtaining and preparing alternative data

The included CSV is ready for the supplied analysis. The following steps are optional and are intended for replacing or updating the extract.

1. Obtain HCD constructed standardized death-rate output from [HCD](https://www.mortality.org/Data/HCD), following its access terms. Select the intermediate cause list containing I033 and the 2013 European standard only after confirming the original course export. Record download date, country filenames, series and standard.
2. Prepare a UTF-8 combined CSV with exactly the six columns shown above and rates per million. If an export uses another unit, document and perform the conversion explicitly. Native HCD formats may require reshaping; the helper below expects the already combined course schema and does not guess units or cause mappings.
3. From this project directory run `Rscript --vanilla scripts/prepare_data.R path/to/combined_hcd_sdr.csv`. This filters the four countries and I033 and writes `hcd_sdr_filtered.csv`, refusing to overwrite a different existing file. Keep the official metadata with your own data preparation records.
4. Run `python scripts/validate_data.py` and then render the Rmd. New official releases can differ from the frozen course data; update findings and audit records together rather than expecting the published endpoints to remain unchanged.

Data checks are reproducible without R using the standard-library Python audit. Optional source comparison: `python scripts/validate_data.py path/to/combined_hcd_sdr.csv`. The audit writes `validation_results.json` and `endpoint_summary.csv`.
