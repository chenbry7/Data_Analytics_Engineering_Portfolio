# Run from project root: Rscript --vanilla scripts/render.R
# Invalidate the previous success record before starting a new render/check cycle.
# A failed execution must not leave an older PASS record appearing current.
validation_log <- "R_RENDER_VALIDATION.txt"
if (file.exists(validation_log) && !file.remove(validation_log)) {
  stop("Cannot clear the previous validation record")
}
started_utc <- format(Sys.time(), tz="UTC", format="%Y-%m-%dT%H:%M:%SZ")
args <- commandArgs(trailingOnly=TRUE)
if (length(args)) stop("This project renders HTML only; no arguments are needed")
if (dir.exists(".local-r-library")) .libPaths(c(normalizePath(".local-r-library"), .libPaths()))
required <- c("Code_public.Rmd", "hcd_sdr_filtered.csv", "endpoint_summary.csv", "validation_results.json")
if (!all(file.exists(required))) stop("Run from the project root; required analysis/audit files are missing")
if (!requireNamespace("rmarkdown", quietly=TRUE)) stop("Run scripts/install_dependencies.R first")
if (!rmarkdown::pandoc_available()) stop("Pandoc unavailable: knit from RStudio or set RSTUDIO_PANDOC to its Pandoc folder")
audit_lines <- readLines("validation_results.json", warn=FALSE)
audit <- paste(audit_lines, collapse="\n")
md5_line <- grep('"md5":', audit_lines, value=TRUE)
if (length(md5_line)!=1L) stop("Refresh the independent data audit with python scripts/validate_data.py")
audited_md5 <- sub('.*"md5": "([a-f0-9]{32})".*', '\\1', md5_line)
if (!identical(unname(tools::md5sum("hcd_sdr_filtered.csv")), audited_md5)) {
  stop("CSV changed since the last independent audit; run python scripts/validate_data.py before rendering")
}
if (!grepl('"all_labels_and_male_higher_checks_match": true', audit, fixed=TRUE)) {
  stop("Frozen-report checks did not pass. Run scripts/validate_data.py and reconcile the narrative with the data")
}
analysis <- new.env(parent=globalenv())
rmarkdown::render("Code_public.Rmd", output_format="html_document",
                  output_file="Report_public.html", envir=analysis)
# Compare actual R plot inputs with the independent Python endpoint audit.
reference <- readr::read_csv("endpoint_summary.csv", show_col_types=FALSE)
actual <- dplyr::bind_rows(
  dplyr::transmute(analysis$ends, country, sex="total", rate_2001=rate_start,
                   rate_2021=rate_end, percent_change=pct),
  dplyr::transmute(analysis$db_dat, country, sex, rate_2001=y2001,
                   rate_2021=y2021, percent_change=pct*100))
checked <- dplyr::inner_join(actual, reference, by=c("country","sex"), suffix=c("_r","_audit"))
stopifnot(nrow(checked)==12L)
for (column in c("rate_2001","rate_2021","percent_change")) {
  stopifnot(all(abs(checked[[paste0(column,"_r")]] - checked[[paste0(column,"_audit")]]) < 0.0001))
}
# Check every plotted observation, not only the annotated endpoints.
check_table <- function(actual, expected, keys, value="rate", tolerance=1e-8) {
  stopifnot(!anyDuplicated(actual[keys]), !anyDuplicated(expected[keys]), nrow(actual)==nrow(expected))
  joined <- dplyr::inner_join(actual, expected, by=keys, suffix=c("_plot","_source"))
  stopifnot(nrow(joined)==nrow(expected),
            all(is.finite(joined[[paste0(value,"_plot")]])),
            all(abs(joined[[paste0(value,"_plot")]]-joined[[paste0(value,"_source")]]) < tolerance))
}
source <- analysis$dat
overall <- dplyr::transmute(dplyr::filter(source, sex=="total", age_group=="total"), country, year, rate=sdr_per_million)
check_table(analysis$fig1_dat, overall, c("country","year"))
sex_rates <- dplyr::transmute(dplyr::filter(source, sex %in% c("males","females"), age_group=="total"), country, year, sex, rate=sdr_per_million)
plotted_sex <- dplyr::transmute(analysis$fig2_long, country, year, sex=sex_lab, rate)
check_table(plotted_sex, sex_rates, c("country","year","sex"))
male <- dplyr::rename(dplyr::select(dplyr::filter(sex_rates, sex=="males"), -sex), male=rate)
female <- dplyr::rename(dplyr::select(dplyr::filter(sex_rates, sex=="females"), -sex), female=rate)
gap <- dplyr::mutate(dplyr::inner_join(male, female, by=c("country","year")), rate=male-female)
check_table(dplyr::mutate(analysis$gap_df, rate=diff), gap, c("country","year"))
age_source <- dplyr::transmute(dplyr::filter(source, sex=="total", age_group!="total", year %in% c(2001,2021)),
                             country, year, age_group, rate=sdr_per_million)
age_actual <- analysis$figB
age_actual$country <- names(analysis$country_lab)[match(age_actual$country, unname(analysis$country_lab))]
age_actual$year <- as.integer(as.character(age_actual$year))
age_actual$age_group <- names(analysis$age_labels)[match(age_actual$age_bin, unname(analysis$age_labels))]
check_table(age_actual, age_source, c("country","year","age_group"))
sex_labels <- dplyr::transmute(analysis$rng, country, sex=sex_lab, rate_2001=y0, rate_2021=y1, percent_change=pct*100)
check_table(sex_labels, dplyr::filter(reference, sex!="total"), c("country","sex"), "percent_change", 0.0001)
# Publish evidence only after rendering and all numerical assertions succeed.
# Relative artifact names keep this public record free of personal filesystem paths.
artifacts <- c("Code_public.Rmd", "scripts/render.R", "scripts/validate_data.py",
               "hcd_sdr_filtered.csv", "validation_results.json", "endpoint_summary.csv",
               "Report_public.html", "figures/overall-trend.png", "figures/sex-trends.png",
               "figures/sex-gap.png", "figures/endpoint-comparison.png", "figures/age-band-rates.png")
stopifnot(all(file.exists(artifacts)))
fingerprints <- tools::md5sum(artifacts)
writeLines(c("IHD Mortality Analysis: successful rendering and validation",
             paste("Started UTC:", started_utc),
             paste("Completed UTC:", format(Sys.time(), tz="UTC", format="%Y-%m-%dT%H:%M:%SZ")),
             "Command: Rscript --vanilla scripts/render.R",
             "HTML render succeeded in a clean R process.",
             "All 12 plotted endpoint pairs and percentage changes agree with the independent audit (tolerance 0.0001).",
             "All 84 overall, 168 sex-specific, 84 sex-gap and 32 age-band plotted observations match the source CSV (tolerance 1e-8).",
             "All eight sex-trend percentage annotations match the independent audit (tolerance 0.0001).",
             paste("Pandoc:", as.character(rmarkdown::pandoc_version())),
             "",
             "Artifact MD5 fingerprints (file identity, not a security signature):",
             paste(names(fingerprints), unname(fingerprints), sep="  "),
             "",
             "R session:",
             capture.output(sessionInfo())), validation_log)
message("PASS: public validation record saved to ", validation_log)
