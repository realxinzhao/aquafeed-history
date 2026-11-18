# Execution status — v0.6.1-R

Native R was not available during authoring; the current R code has not been run here.
No R_test_results.csv is supplied as a fabricated success log.

44 independent data/arithmetic checks passed. See independent_data_checks.csv.
Bundled coefficients preserve the prior v0.6 group-year numerical values; their new
species expansion and all demand results were calculated independently from the new
mapping and source input. The code to reproduce the project is native R, not Python.

Run Rscript run_all.R locally to rebuild and establish runtime success. The workflow
writes actual results and R_test_results.csv, and stops if any check fails. The Windows
and Linux CI workflow has not run for this update.
