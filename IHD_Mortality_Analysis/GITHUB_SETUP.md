# GitHub showcase setup

The publication folder contains a standalone project, with the README at its root.
It includes the executed HTML report, five R-generated figures, analysis source,
dependency/preparation scripts, the frozen analysis CSV, and validation records. It excludes the course
originals, local R library and earlier snapshot.

## Suggested repository details

- Name: `ihd-mortality-four-country-analysis`
- Description: `R and ggplot2 analysis of ischaemic heart disease mortality trends, sex gaps, and age-band rates in four countries, 2001-2021.`
- Topics: `r`, `ggplot2`, `rmarkdown`, `data-visualization`, `mortality`, `public-health`, `portfolio`
- Authors: Bryan Hao Yang Chen and Zhuoyang Li, jointly responsible for all original project steps.

## Upload the standalone project

1. Use the prepared `ihd-mortality-four-country-analysis` folder; an optional ZIP contains the same files.
2. Create a repository with the suggested name in your GitHub account. For a new empty repository, leave the automatic README, .gitignore and license choices unchecked: the package already supplies a README and .gitignore; rights in collaborative materials and source data are separate.
3. Upload or move the prepared project files and folders into the repository root. Upload the contents, not the ZIP itself. Confirm that `README.md`, `Code_public.Rmd`, `Report_public.html`, `figures/` and `scripts/` are at the top level. The dotfile `.gitignore` may need to be selected separately if your file browser hides it.
4. Add the description and topics in the repository's About section. The README presents three preview charts directly on GitHub. Readers can download `Report_public.html` and open it in a browser for the complete report.
5. Before setting visibility to public, review [data provenance](DATA_PROVENANCE.md) and the [publication checklist](PUBLICATION_CHECKLIST.md). The packaged analysis includes `hcd_sdr_filtered.csv` and can be rerun after installing the R dependencies. Original download date, standard and codebook confirmation remain documented uncertainties.

This repository presentation does not require a separate website. The report remains in HTML format; no PDF or TeX installation is required.

## Rebuild the package after changes

```sh
python scripts/export_public.py
```

The export script checks the allowlist, Markdown links and ZIP integrity. The standalone folder and optional archive are written under the ignored `github-release/` directory. Move the contents of the standalone folder into your GitHub checkout. The ZIP is a transfer copy, not a file to commit inside the repository.
