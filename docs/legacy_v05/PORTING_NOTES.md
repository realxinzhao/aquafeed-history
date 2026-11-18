# Native R port — scope and audit

## Preserved scientific baseline

Scientific choices remain v0.4: published total-feed source hierarchy, linear parameter interpolation, optional early hold, historical marine proxies, reference and recent nonmarine cases, optional Norway salmon composition, ingredient-stage units, unknown origin components, and partial feed coverage. This delivery is a language/replication refactor, not a new fitted dataset.

## Python -> R responsibilities

| Previous component | R component |
|---|---|
| `build_coefficients.py` | `R/sources.R`, `R/coefficients.R`, `scripts/build_coefficients.R` |
| `process_production.py` | `R/production.R`, `scripts/process_production.R` |
| `tests/test_pipeline.py` | `R/validation.R`, `scripts/run_tests.R` |
| External workbook/figure creation | `R/reports.R` |
| Manual orchestration | `run_all.R`, `config/default.R`, `R/pipeline.R` |
| Coverage audit snapshots | `R/reconciliation.R` re-derives the audit from both supplied CSVs |

## Deliberate refactoring improvements

1. The selected historical Tacon table is rebuilt from the two raw extracted tables, not read as a preassembled source.
2. Broad nonmarine profiles are recomputed from the visible Figure 5 percentages and an explicit group-to-profile mapping. The figure's missing shrimp balance is retained as unallocated.
3. Norway inventory category totals are read by name; the krill subset is removed from fishmeal without double counting.
4. New provenance columns are attached to species calculations in addition to coefficient-table provenance.
5. Zero-row output files are written with headers, preventing stale previous-run files from masquerading as current results.
6. Missing/nonfinite production, fractional years and taxonomy mismatches fail explicitly. The input's leading-zero codes are preserved.
7. Run manifests use base R's MD5 checksum function for dependency-free identity checks, alongside the frozen SHA256+MD5 input manifest. They are not a cryptographic signing system.

## Reproducibility boundary

Raw production and curated literature transcriptions are included. Species identity decisions and broad recipe mappings remain editable/versioned analyst inputs. Neither PDF transcription nor acquisition of an unprovided 1975–2023 production file is automated. `source_register.csv` and the inherited 22 scientific assumptions remain authoritative for provenance and limitations.

## Execution limitations at handover

The preparation environment had no R executable; package installation and binary-download attempts failed. Native-R execution, numerical regression, Excel generation and CI have **not been observed**. A source-level static audit is stored separately and must not be confused with passing runtime tests. Previous Python outputs are isolated in `tests/reference/v0.4`, with no Python source code or interpreter required by the delivered workflow.

## Changing the science later

First obtain a passing native-R baseline. Then make source/mapping/assumption changes in a separate Git commit or branch. Review differences before updating the immutable fixtures or increasing the scientific version. Avoid combining an R migration with an unreviewed change in feed definitions or region-specific coefficients.

## v0.5.1-R follow-up

The user subsequently ran v0.5 in native R: 83 of 84 checks passed, including
all numerical regression comparisons. The single failure was a lost
category-specific `harmonization_note`, restored in v0.5.1-R. No numerical
behavior or test tolerance was changed. Patched native-R execution remains
unverified in the preparation environment. See `FIX_v0.5.1.md`.
