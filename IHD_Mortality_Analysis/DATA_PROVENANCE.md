# Data provenance and reuse

## Frozen course extract

The included `hcd_sdr_filtered.csv` is a frozen course extract containing 1,965 records for four countries and cause I033. Its values were compared with the full course source: all observation keys match, and rates agree within 1e-8 per million (maximum difference 3.64e-12, consistent with floating-point CSV serialization).

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

`sex=total, age_group=total` is the supplied overall SDR. Sex comparisons retain `age_group=total`. Age-band comparisons retain `sex=total` and use each supplied band separately. No rates are added to derive totals. Following the original report and local formal Rmd, this project uses the European Standard Population 2013 designation and the course identification of I033 as IHD. These designations come from the course documentation; the CSV does not encode the standard or include a cause codebook. HCD provides both 1976 and 2013 standards, so the designation is not an assumed default. The original download date and filenames were not recorded in the available materials. This is a frozen course snapshot, rather than a download of current HCD estimates.

## Source and license

Source attribution: Human Cause of Deaths data series (HCD). Human Mortality Database. Max Planck Institute for Demographic Research (Germany), University of California, Berkeley (USA), and French Institute for Demographic Studies (France). Available at [mortality.org](https://www.mortality.org/).

The [HMD user agreement](https://www.mortality.org/Data/UserAgreement), checked 1 October 2026, distinguishes HMD-constructed estimates (CC BY 4.0) from provider input data, which retain their providers' licenses. It recommends referring users to HMD for current downloads. The [HCD explanatory notes](https://www.mortality.org/File/GetDocument/hcd/docs/HCD_Method_Explanatory_Notes.pdf) describe reconstructed series, aggregated age-band SDRs, and the two European standards. These public documents support the methodology and reuse distinction; they do not establish which standard was downloaded for this local CSV.

The project includes the frozen `hcd_sdr_filtered.csv` to reproduce the published figures. It was filtered to the four countries and I033, with lowercase country, sex and age labels; no additional numerical transformation was applied to the included extract. The supplied values are standardized death-rate estimates, rather than raw death counts. HMD licenses its constructed estimates under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/); attribution is provided above. The available course materials do not retain the original export metadata, so the exact downloaded output series cannot be independently certified. This source-data license statement does not grant a license to the collaborators' report or to third-party provider input data.

## Obtaining and preparing alternative data

The included CSV is ready for the supplied analysis. The following steps are optional and are intended for replacing or updating the extract.

1. Obtain HCD constructed standardized death-rate output from [HCD](https://www.mortality.org/Data/HCD), following its access terms. For an alternative extract corresponding to the course documentation, select the intermediate cause list containing I033 and the 2013 European standard; verify both against the metadata of your new download. Record download date, country filenames, series and standard.
2. Prepare a UTF-8 combined CSV with exactly the six columns shown above and rates per million. If an export uses another unit, document and perform the conversion explicitly. Native HCD formats may require reshaping; the helper below expects the already combined course schema and does not guess units or cause mappings.
3. From this project directory run `Rscript --vanilla scripts/prepare_data.R path/to/combined_hcd_sdr.csv`. This filters the four countries and I033 and writes `hcd_sdr_filtered.csv`, checking required fields, valid rates, unique keys and the complete 2001-2021 analysis grid before writing, and refusing to overwrite a different existing file. Keep the official metadata with your own data preparation records.
4. Run `python scripts/validate_data.py` and then render the Rmd. New official releases can differ from the frozen course data. The independent audit exits with an error if its frozen-report label checks fail; reconcile the findings and figures before publishing changed data. The render script checks that the CSV matches the latest audit checksum.

Data checks are reproducible without R using the standard-library Python audit. Optional source comparison: `python scripts/validate_data.py path/to/combined_hcd_sdr.csv`. The audit writes `validation_results.json` and `endpoint_summary.csv`.
