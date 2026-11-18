# v0.5.1-R — source-note regression fix

Date: 2026-11-16. Scientific baseline remains v0.4.

## Diagnosis

The supplied `R_test_results.csv` contains 84 checks: 83 PASS and one FAIL.
The failing check is `Source harmonization rebuilt from raw tables`, and its
only differing column is `harmonization_note`. All numeric coefficient and
2021 species/aggregate comparisons in that report passed.

`af_prepare_sources()` in `R/sources.R` assigned a generic source-priority note
to all 278 selected rows. The frozen v0.4 baseline has a different warning on
10 Tacon2015 rows for `Other freshwater & diadromous fishes`, 2000-2009.
The R translation inadvertently erased that warning. This is not a user input
or Windows configuration problem.

## Fix

Restore the original category-specific warning for those ten rows. No source
numbers, scientific assumptions, grouping rules, recipe shares, calculation
formulas, reference fixtures, or test tolerances are changed. The full archive
also updates the version string in `R/io.R` from `0.5-R` to `0.5.1-R`.
The functional fix for an existing checkout requires only `R/sources.R`.

## Apply to an existing project

Replace the existing `R/sources.R` with the supplied corrected `sources.R`.
Do not place it in the project root. Preserve any user configuration or data
changes; replacing the whole project is unnecessary.

Open `AquafeedHistory.Rproj`, then run in the R console:

```r
source("scripts/run_tests.R")
source("run_all.R")
```

The first command reloads the project functions and executes the existing
84-check suite. The second rebuilds generated tables and outputs with the
restored note. A passing suite should report `84 R checks passed.` This is an
expected result, not an observed patched-R result in the preparation environment.

## Verification and its limit

An independent reconstruction of the selection and note rules reproduced the
10 original note mismatches and verified zero remaining note mismatches across
all 278 selected rows after the correction. Source inputs, mappings, reference
fixtures and test code were checked for byte identity. See
`validation/metadata_fix_static_audit.csv` and `validation/metadata_fix_rows.csv`.

No R interpreter is available in the preparation environment; the patched R
suite has not been executed here. `validation/user_v0_5_R_test_results.csv` is
the user-supplied **pre-fix** runtime report, not a passing post-fix report.
The reported numeric difference of about 4.1e-9 tonnes in the failed source-table
comparison is below its existing absolute tolerance of 1e-6 tonnes; it is not
the reason the comparison failed. The character metadata mismatch was exact.
