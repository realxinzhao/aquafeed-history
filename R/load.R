# Load the project functions into the caller's environment. Not an R package install.
af_load <- function(root = ".") {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  environment <- parent.frame()
  modules <- c("io.R", "sources.R", "coefficients.R", "cli.R", "export.R", "gcamdata.R", "coverage.R", "demand_history.R", "checks_v06.R")
  for (module in modules) sys.source(file.path(root, "R", module), envir = environment)
  invisible(root)
}
