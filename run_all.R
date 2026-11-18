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

cli_options <- af_cli(commandArgs(trailingOnly = TRUE),
  value_flags=c("input","output","early-policy","config"),
  boolean_flags=c("coefficients-only","skip-tests","help"))
if(isTRUE(cli_options$help)) {
  cat("Rscript run_all.R [--coefficients-only] [--input FILE] [--output DIR]\n",
      "                 [--early-policy hold|blank] [--skip-tests] [--config FILE]\n")
} else {
  config_path <- if(is.null(cli_options$config)) file.path(.af_root,"config/default.R") else af_path(.af_root,cli_options$config)
  config_environment <- new.env(parent=baseenv());sys.source(config_path,envir=config_environment)
  config<-config_environment$config
  if(!is.null(cli_options$input)) config$production_file<-cli_options$input
  if(!is.null(cli_options$output)) config$output_dir<-cli_options$output
  if(!is.null(cli_options[["early-policy"]])) config$early_policy<-cli_options[["early-policy"]]
  if(isTRUE(cli_options[["coefficients-only"]])) config$run_demand_checks<-FALSE
  if(isTRUE(cli_options[["skip-tests"]])) config$run_tests<-FALSE
  message("Step 1: preserve source values and within-source products")
  raw <- af_stage1_sources(.af_root,file.path(config$output_dir,"01_sources"))
  message("Step 2: build documented annual coefficients and species CSV")
  coefficients <- af_stage2_coefficients(.af_root,config)
  demand <- NULL
  if(isTRUE(config$run_demand_checks)) {
    message("Step 3: calculate demand and compare benchmarks (no automatic fitting)")
    demand <- af_stage3_check_demand(.af_root,coefficients,config)
  }
  if(isTRUE(config$run_tests)) af_checks_v06(.af_root,raw,coefficients,demand,config)
  af_manifest(.af_root,file.path(.af_root,config$output_dir,"run_info"),
    if(isTRUE(config$run_demand_checks)) af_path(.af_root,config$production_file) else character(),
    list(coverage_policy=af_coverage_policy(config),early_policy=config$early_policy,year_start=config$year_start,year_end=config$year_end,
      use_recent_fishoil=config$use_recent_fishoil,use_recent_nonmarine=config$use_recent_nonmarine,
      gcamdata_formats=names(coefficients$gcamdata_files),
      ran_demand_checks=config$run_demand_checks),
    extra_files=c(file.path(.af_root,"config/default.R"),file.path(.af_root,"data/raw/benchmarks/commercial_feed_benchmarks.csv"),
                  if(isTRUE(config$run_demand_checks)) af_path(.af_root,config$species_reference_file) else character()))
  message("Main output: ",file.path(config$output_dir,"02_coefficients/aquaculture_feed_coefficients_species_year.csv"))
  for(path in coefficients$gcamdata_files) message("GCAM input: ",path)
}
