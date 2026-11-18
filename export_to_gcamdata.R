# Compatibility entry point. The integrated workflow builds the coefficients and
# exports both headed CSV and CSV.gz files under outputs/gcamdata/ by default.
.af_export_script <- local({
  arguments <- commandArgs(trailingOnly = FALSE)
  command_file <- sub("^--file=", "", grep("^--file=", arguments, value = TRUE))
  source_files <- vapply(sys.frames(), function(frame) {
    value <- frame$ofile
    if (is.null(value)) "" else as.character(value)[1L]
  }, character(1))
  candidates <- unique(c(getwd(), dirname(source_files[nzchar(source_files)]), dirname(command_file)))
  for (start in candidates) {
    location <- normalizePath(start, winslash = "/", mustWork = FALSE)
    for (step in seq_len(20)) {
      if (file.exists(file.path(location, "AquafeedHistory.Rproj")))
        return(file.path(location, "scripts/export_gcamdata_coefficients.R"))
      parent <- dirname(location)
      if (identical(parent, location)) break
      location <- parent
    }
  }
  stop("Open AquafeedHistory.Rproj or run from the project directory", call. = FALSE)
})
source(.af_export_script, local = TRUE)
