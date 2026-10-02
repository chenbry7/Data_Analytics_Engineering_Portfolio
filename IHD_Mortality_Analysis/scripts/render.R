# Run from project root: Rscript --vanilla scripts/render.R [--pdf]
args <- commandArgs(trailingOnly=TRUE)
if (dir.exists(".local-r-library")) .libPaths(c(normalizePath(".local-r-library"), .libPaths()))
stopifnot(file.exists("Code_public.Rmd"))
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
writeLines(c("HTML render succeeded in a clean R process.",
             "All 12 plotted endpoint pairs and percentage changes agree with the independent audit (tolerance 0.0001).",
             paste("Pandoc:", as.character(rmarkdown::pandoc_version())),
             capture.output(sessionInfo())), "R_RENDER_VALIDATION.txt")
if ("--pdf" %in% args) {
  rmarkdown::render("Code_public.Rmd", output_format="pdf_document",
                    output_file="Report_public.pdf", envir=new.env(parent=globalenv()))
}
