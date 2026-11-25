# GCAM export and documentation integration

This update consolidates the root-level `export_to_gcamdata.R` implementation into
the standard coefficient workflow. `R/export.R` writes a six-column GCAM input as
both CSV and gzip, using a single open connection for each file's comment metadata
and data. Both `scripts/export_gcamdata_coefficients.R` and `run_all.R` call it through
stage 2. The root script forwards to the integrated workflow for compatibility.

The full coefficient CSV is `outputs/02_coefficients/GCAMFAOSTAT_FeedCoef_Aquaculture_BySpecies.csv`.
Compact exports are `outputs/gcamdata/GCAMFAOSTAT_FeedCoef_Aquaculture_BySpecies.csv`
and `.csv.gz`; both carry the GCAM column-type string `cinnnn`. The new
export has no `readr` or `dplyr` dependency. Comment headers describe the actual
project, ingredient mass basis, already-applied commercial-feed share and provenance.
Missing values remain blank, zero values remain zero, and reruns replace files.

New tests exercise schema/metadata, equivalence to the full table, compressed/plain
content, leading-zero and literal-NA codes, missing/zero coefficients, numeric
precision, gzip signature, repeat execution, single-format output and malformed
format/key/year rejection. They run with the existing numerical regression suite.

The README now points to two concise guides: [methods and validation](METHODS.md)
and [publication priorities](PUBLICATION_ROADMAP.md). The latter proposes future
research improvements; it does not imply those improvements have been implemented.

## Metadata corrections and unchanged numerical baseline

Three records in `data/raw/literature/source_register.csv` were corrected:

- `UserHistory2026` now describes the current FAO FISHSTAT 2026.1.0 species-resolved
  production data (1973–2024), processed by gcamfaostat, replacing the obsolete input
  path and ISSCAAP-mixture description.
- `UserProduction2021` now identifies the current reference-file path and its
  comparison-only role.
- `Naylor2021` now points to the correction-audit status already recorded in
  `SOURCE_AUDIT.md`; this does not claim a new audit of the April author correction.

The source-register checksum and the current production-input checksum are recorded in
`tests/reference/v0.7/scientific_input_md5.csv`. Existing literature-based numeric
fixtures remain active through 2023; the new production panel changes applied species
coverage and demand totals, not the underlying literature anchors.

## FISHSTAT production refresh — November 25, 2026

The default input is `data/raw/production/GCAMFAOSTAT_FISHPROD_Aquaculture_BySpecies.csv.gz`:
FAO FISHSTAT data processed by gcamfaostat, archive release 2026.1.0. The retired
`history_1973_2022_species.csv` file was removed from the active project. The applied
crosswalk now extends automatically from the production roster using exact-ISSCAAP
consensus; conflicting assignments remain unestimated. The 2024 coefficient vector
holds the finalized 2023 values. This refresh changes 2021–2023 production-based demand
totals and adds 2024 output, but does not revise the literature coefficient anchors.

## Export reproducibility

The header update date defaults to the local run date. To reproduce an archived
header exactly when re-exporting an existing in-memory full coefficient table, call
`af_export_gcamdata_coefficients(species, out, update_date = "YYYY-MM-DD")` with the
archive's actual date. Numerical data are unchanged by this metadata field. The
full pipeline records runtime/configuration/input information under `outputs/run_info/`.

The header follows the GCAM reader's `File`, `Title`, `Units` and `Column types`
requirements; see [GCAM's input reader](https://github.com/JGCRI/gcam-core/blob/master/input/gcamdata/R/utils.R).
No complete GCAM model run is implied by file-format and coefficient validation.
