# Input is a combined course-schema CSV, not a raw native HCD download.
args <- commandArgs(trailingOnly=TRUE)
if (length(args) != 1L) stop("Usage: Rscript --vanilla scripts/prepare_data.R input.csv")
if (dir.exists(".local-r-library")) .libPaths(c(normalizePath(".local-r-library"), .libPaths()))
if (!requireNamespace("readr", quietly=TRUE)) stop("Run scripts/install_dependencies.R first")
dat <- readr::read_csv(args[1], show_col_types=FALSE)
fields <- c("country","year","sex","cause","age_group","sdr_per_million")
stopifnot(identical(names(dat), fields))
for (column in c("country","sex","age_group")) dat[[column]] <- tolower(trimws(dat[[column]]))
dat$cause <- toupper(trimws(dat$cause))
dat <- dat[dat$country %in% c("canada","england and wales","japan","united states") & dat$cause == "I033", ]
stopifnot(nrow(dat)>0, !anyDuplicated(dat[fields[1:5]]),
          !anyNA(dat),
          all(dat$sex %in% c("total","males","females")),
          all(dat$age_group %in% c("total","0-14","15-39","40-64","65 and above")),
          all(dat$year == as.integer(dat$year)),
          all(is.finite(dat$sdr_per_million)), all(dat$sdr_per_million >= 0))
expected <- expand.grid(country=c("canada","england and wales","japan","united states"),
                        year=2001:2021, sex=c("total","males","females"), cause="I033",
                        age_group=c("total","0-14","15-39","40-64","65 and above"),
                        stringsAsFactors=FALSE)
analysis <- dat[dat$year >= 2001 & dat$year <= 2021, ]
make_key <- function(x) do.call(paste, c(as.list(x[fields[1:5]]), sep="|"))
if (!setequal(make_key(analysis), make_key(expected))) stop("Input lacks a complete 2001-2021 analysis grid; nothing was written")
target <- "hcd_sdr_filtered.csv"
if (file.exists(target)) {
  existing <- readr::read_csv(target, show_col_types=FALSE)
  ord <- function(x) do.call(order, as.list(x[fields[1:5]]))
  a <- as.data.frame(existing[ord(existing), ]); rownames(a) <- NULL
  b <- as.data.frame(dat[ord(dat), ]); rownames(b) <- NULL
  if (!isTRUE(all.equal(a,b,tolerance=1e-8))) stop("Existing extract differs; review/version it before replacing")
  message("Existing extract agrees; left unchanged")
} else {
  readr::write_csv(dat, target)
}
