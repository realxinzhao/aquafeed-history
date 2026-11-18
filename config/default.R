# The coefficient CSV is the main product; production is only an application check.
config <- list(
  year_start = 1973L,
  year_end = 2023L,
  coverage_policy = "expanded", # "original" reproduces v0.6.1 pending-item behavior.
  early_policy = "hold", # Explicit 1995 endpoint hold before 1995; "blank" also supported.
  use_recent_fishoil = TRUE, # 2021 Skretting total fish oil for salmon/shrimp/tilapia; company->global proxy.
  use_recent_nonmarine = TRUE, # Conditional ratios transition from generic 2015 to company 2021.
  production_file = "data/raw/production/history_1973_2022_species.csv",
  species_reference_file = "data/raw/production/species_2021.csv",
  run_demand_checks = TRUE,
  write_allocated_rows = FALSE, # Optional large audit; cell weights always written.
  run_global_mix_sensitivity = FALSE, # Not applicable to actual species-resolved history.
  run_2021_reference_check = TRUE, # Separate check only; never used as historical species weights.
  output_dir = "outputs",
  gcamdata_formats = c("csv", "csv.gz"), # Compact six-column inputs with GCAM comment headers.
  run_tests = TRUE
)
