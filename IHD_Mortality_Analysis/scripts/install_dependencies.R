# Run from the project root. Only missing packages are installed, locally.
dir.create(".local-r-library", showWarnings=FALSE)
.libPaths(c(normalizePath(".local-r-library"), .libPaths()))
packages <- c("ggplot2", "readr", "dplyr", "tidyr", "stringr", "scales", "ggrepel", "knitr", "rmarkdown")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly=TRUE)]
minimum <- c(ggplot2="3.4.0", dplyr="1.0.0")
outdated <- names(minimum)[vapply(names(minimum), function(p) {
  requireNamespace(p, quietly=TRUE) && packageVersion(p) < package_version(minimum[[p]])
}, logical(1))]
missing <- union(missing, outdated)
if (length(missing)) install.packages(missing, lib=".local-r-library", repos="https://cloud.r-project.org")
if (!all(vapply(packages, requireNamespace, logical(1), quietly=TRUE))) stop("Dependency installation incomplete")
message("All required R packages are available")
