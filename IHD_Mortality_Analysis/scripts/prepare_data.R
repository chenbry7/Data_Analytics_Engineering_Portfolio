# Input is a combined course-schema CSV, not a raw native HCD download.
args <- commandArgs(trailingOnly=TRUE)
if (length(args) != 1L) stop("Usage: Rscript --vanilla scripts/prepare_data.R input.csv")
dat <- readr::read_csv(args[1], show_col_types=FALSE)
fields <- c("country","year","sex","cause","age_group","sdr_per_million")
stopifnot(identical(names(dat), fields))
for (column in c("country","sex","age_group")) dat[[column]] <- tolower(trimws(dat[[column]]))
dat$cause <- toupper(trimws(dat$cause))
dat <- dat[dat$country %in% c("canada","england and wales","japan","united states") & dat$cause == "I033", ]
stopifnot(nrow(dat)>0, !anyDuplicated(dat[fields[1:5]]),
          all(is.finite(dat$sdr_per_million)), all(dat$sdr_per_million >= 0))
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
