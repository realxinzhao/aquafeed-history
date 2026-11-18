# v0.6.1 — species-resolved historical input

- Replaced the old aggregate production input with the exact new updated1.csv upload.
- Default demand now joins actual species and year; no fixed 2021 mixture is applied.
- Expanded the crosswalk from 547 to 731 codes with 184 explicit documented assignments.
  Existing numerical coefficients and all prior source-group assignments are preserved.
- 103 new codes use existing fed-group proxies, 42 use the existing nonfed convention,
  and 39 remain unestimated. Names and taxonomic identities are not fabricated.
- Rebuilt the 37,281-row species-year CSV and all historical demand/benchmark outputs.
- Updated regression fixtures for the new input; retained the old numerical group-series
  fixture. Added explicit tests for original mapping preservation, direct species use,
  missing species keys, and rejection of unseen codes.
- Remove obsolete mixture/sensitivity files on rerun so outputs cannot silently mix runs.
- Keep ingredients as reported; no moisture, wet-fish, or primary-crop conversion.
- R execution still requires a local run. Independent application checks are separately
  labelled and must not be read as a passed native-R test suite.

Open AquafeedHistory.Rproj and run source("run_all.R"). To build only the coefficient
products, run source("scripts/export_gcamdata_coefficients.R"). Extract into a fresh
folder first; copy reviewed changes into an existing Git checkout without deleting .git.
