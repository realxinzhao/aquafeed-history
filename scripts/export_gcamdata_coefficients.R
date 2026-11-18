# Locate the project without hard-coded machine-specific paths.
.af_root <- local({
  arguments <- commandArgs(trailingOnly = FALSE)
  command_file <- sub("^--file=", "", grep("^--file=", arguments, value = TRUE))
  source_files <- vapply(sys.frames(), function(frame) {
    value <- frame$ofile
    if (is.null(value)) "" else as.character(value)[1L]
  }, character(1))
  paths <- c(command_file, source_files[nzchar(source_files)])
  candidates <- unique(c(getwd(), dirname(paths)))
  found <- NULL
  for (start in candidates) {
    location <- normalizePath(start, winslash = "/", mustWork = FALSE)
    for (step in seq_len(20)) {
      if (file.exists(file.path(location, "AquafeedHistory.Rproj"))) { found <- location; break }
      parent <- dirname(location)
      if (identical(parent, location)) break
      location <- parent
    }
    if (!is.null(found)) break
  }
  if (is.null(found)) stop("Open AquafeedHistory.Rproj or run from the project directory", call. = FALSE)
  found
})
source(file.path(.af_root, "R/load.R"), local = TRUE)
af_load(.af_root)

# Builds only the source-evidence table and the species-year coefficient CSV.
# No production input is read.
sys.source(file.path(.af_root,"config/default.R"),envir=environment())
raw <- af_stage1_sources(.af_root,file.path(config$output_dir,"01_sources"))
coefficients <- af_stage2_coefficients(.af_root,config)
if(isTRUE(config$run_tests)) af_checks_v06(.af_root,raw,coefficients,NULL,config)
message("Wrote ",file.path(config$output_dir,"02_coefficients/aquaculture_feed_coefficients_species_year.csv"))
