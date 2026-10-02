# Publication checklist

Review date: 1 October 2026. Scope: the 21-file standalone showcase project. This local audit did not push files, change repository visibility or deploy a website.

## Public file list

- `README.md`, `DATA_PROVENANCE.md`, `PUBLICATION_CHECKLIST.md`, `GITHUB_SETUP.md`, `.gitignore`
- `Code_public.Rmd` (analysis entry point)
- `hcd_sdr_filtered.csv` (included frozen analysis dataset)
- `Report_public.html` (successfully executed, self-contained public R Markdown report)
- `figures/overall-trend.png`, `figures/sex-trends.png`, `figures/endpoint-comparison.png`, `figures/sex-gap.png`, `figures/age-band-rates.png`
- `scripts/install_dependencies.R`, `scripts/render.R`, `scripts/prepare_data.R`, `scripts/validate_data.py`, `scripts/export_public.py`
- `validation_results.json`, `endpoint_summary.csv`, `R_RENDER_VALIDATION.txt`

Exclude from a new standalone public repository: archival `Code.Rmd`, archival `Report.pdf`, earlier `Report_public_snapshot.html`, `.local-r-library/`, raw source downloads, course drafts, teacher templates, local logs, inspection intermediates and personal metadata. Files on this exclusion list remain locally preserved. This checklist is a packaging instruction, not an automatic removal from existing Git history.

## Data and license

- [x] Read the complete Rmd and all nine pages of report text; inspect the five retained charts visually.
- [x] Compare the supplied CSV with the local formal full source: 1,965 corresponding records; identical keys; rates agree within 1e-8 absolute tolerance. Maximum difference 3.64e-12.
- [x] Confirm exact country, sex and age-band labels; cause is exclusively I033; units in the extract/report are SDR per million.
- [x] Verify official HCD explanatory notes and HMD user agreement; add links and institutional attribution in DATA_PROVENANCE.md.
- [x] Retain the original course report's I033 identification and European Standard Population 2013 designation; record their documentary basis in DATA_PROVENANCE.md.
- [x] Provide institutional source attribution and the official CC BY 4.0 terms for HMD-constructed estimates. Record the unavailable original download date/export metadata once in DATA_PROVENANCE.md, without inventing defaults or extending the data license to other materials.

## Privacy and authorship

- [x] Preserve Bryan Hao Yang Chen and Zhuoyang Li as collaborators.
- [x] Public analysis uses project-relative paths; no student numbers, personal email addresses or personal absolute paths found in public narrative/code/rendered report. Embedded third-party HTML libraries retain their original attribution notices. Data preparation accepts a user-provided input path rather than embedding one.
- [x] Preserve originals unchanged; exclude them from standalone packaging.
- [x] Bryan confirmed that both authors jointly completed all steps of the original project; the README and public report use that shared contribution statement.
- [x] Standalone folder and ZIP use an explicit 21-file allowlist, exclude all source-repository Git history, and check relative Markdown links and ZIP integrity. This export process does not create or publish a remote repository.
- [x] Re-check the included CSV: hash matches the verified extract; complete 1,260-row analysis grid and all 60 original-report checks pass. README links resolve to packaged files.
- [ ] Review actual GitHub visibility and repository contents when uploading.

## Arithmetic and analysis validation actually performed

- [x] Python standard-library audit executed against the frozen CSV and full formal source; outputs saved in `validation_results.json` and `endpoint_summary.csv`.
- [x] Complete 2001-2021 Cartesian grid: 1,260 observations, zero duplicate keys, zero missing/nonfinite/negative rates.
- [x] Independently verify all four overall endpoint values and changes, eight sex-specific endpoint changes, four absolute gap changes and 32 age-band endpoint labels against the original report.
- [x] Remove automatic installation and missing-value filling from public analysis; fail explicitly on invalid coverage.
- [x] Replace rate summation with selection of unique supplied observations.
- [x] Correct female/male percentage-change wording and distinguish proportional change from absolute-gap arithmetic.
- [x] Remove original Figure 6 and its death-share claims. Age-band rates cannot be converted into death-count composition by normalization.
- [x] Regenerate five figures from the executed public Rmd; visually inspect them and correct overlapping sex labels and endpoint annotation placement. Source and SDR units are explicit.
- [x] Public R-rendered HTML embeds its five figure images. The earlier static snapshot is retained locally as a superseded reading copy and excluded from the standalone package.

## Execution environment and completed checks

Independent validation and initial PDF preview extraction used the bundled Python runtime, the standard library, pypdf/pypdfium2 and Pillow. Final report and all five PNGs were generated by R Markdown / ggplot2. Missing ggrepel 0.9.8 was installed into the project-local `.local-r-library`; this binary library is excluded from publication.

- [x] Fresh R execution: Windows R registry identified an existing non-default R installation. The final public Rmd executed from the standalone folder successfully under R 4.6.1 using `Rscript --vanilla`. R was present but absent from PATH; the earlier default-location check was incomplete.
- [x] Render `Code_public.Rmd` using RStudio-bundled Pandoc. Final render completed without chunk warnings; actual session is recorded in `R_RENDER_VALIDATION.txt`. All five figures were visually reviewed. All 12 plotted endpoint pairs and percentage changes matched the independent Python audit within 0.0001. All 84 overall, 168 sex-specific, 84 sex-gap and 32 age-band observations matched the source CSV within 1e-8. All eight sex-trend percentage annotations matched the independent endpoint audit.
- [x] Keep HTML as the delivered report format, as requested by the author. The temporary PDF and browser-PDF helper were removed from the public package.
- [x] Update README and checklist to point to the actual R-rendered report. No numerical changes were required. The old snapshot remains only in the course archive and is neither linked nor packaged as a public deliverable.
- [x] Execute the optional data-preparation helper against the existing full local course source: produce a complete 1,965-row subset; preserve an equivalent existing extract; reject an incomplete grid; refuse to overwrite differing data. No new official data download was performed.
- [x] Test the independent Python validator with duplicate keys, a missing observation, a nonfinite rate and a changed endpoint; all are rejected.
- [x] Limit the Rmd and rendering script to HTML. Remove the unavailable old-snapshot reference; consolidate repeated country/palette/age-label definitions.
- [x] Check Markdown/HTML links, all five embedded images, README tree coverage, file hashes and ZIP allowlist. Export refuses unexpected leftover files rather than silently including them; its rejection was tested.
- [x] Test render safeguards: a CSV changed after auditing is rejected before producing a report; the removed PDF option is rejected.
- [x] Open the HTML offline in a browser: all five images load, all ten sections/contents links exist, contents navigation works, and the 390-pixel mobile layout has no page overflow. Inspect desktop/mobile screenshots and all five final PNGs.

## Recommended repository metadata

Name: `ihd-mortality-four-country-analysis`

Description: `R and ggplot2 analysis of ischaemic heart disease mortality trends, sex gaps, and age-band rates in four countries, 2001-2021.`
