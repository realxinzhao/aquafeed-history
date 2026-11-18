# Aquafeed history — native R replication project

**Version 0.5.1-R · Scientific baseline: v0.4 · Prepared 16 November 2026**

Estimate commercial aquaculture-feed inputs from species-level production, retain a year dimension, and aggregate to the supplied GCAM technology mapping. The project contains the source transcriptions, production example, mappings, assumptions, native R code, expected-output fixtures, and a GitHub Actions validation workflow.

> **Runtime evidence and patch status:** the user's native-R v0.5 report contains **83 passing checks and one source-note mismatch**. v0.5.1 restores the missing category-specific note without changing scientific calculations, fixtures, or tolerances. The corrected note rule has been independently checked against all 278 selected source rows, but the patched project has **not been rerun in R in the preparation environment**, which still lacks an R interpreter. Run `source("scripts/run_tests.R")` locally. See `docs/FIX_v0.5.1.md`. No GitHub push was made as part of this fix.

## 1. Start in RStudio

Unzip this directory, then open **`AquafeedHistory.Rproj`**. In the R console:

```r
source("run_all.R")
```

Or, from a terminal in this directory:

```sh
Rscript run_all.R
```

The core calculation, validation, CSV export, HTML summary, and PNG coefficient plots use **base R only**. There is no Python runtime, `reticulate`, virtual environment, or subprocess invoking Python. R 4.1 or later is the intended minimum; the included CI workflow specifies R 4.5.0 on Linux and Windows. These are compatibility targets, not locally tested versions.

Defaults are in `config/default.R`. The default run processes the **bundled 2021 production data** under three scenarios and executes regression tests against the frozen v0.4 baseline. It does not invent production for other years.

### Optional Excel workbook

The workbook exporter is also R code, using `openxlsx`. This dependency is optional and does not affect the numerical calculation.

```r
# Install optional reporting tools and record the actual installed environment:
source("scripts/setup_optional_reports.R")

# Then set export_excel = TRUE in config/default.R and run:
source("run_all.R")
```

The setup script uses `renv` to create a real lockfile after installation. No fabricated or untested package-version lockfile is supplied. Review and commit the generated `renv.lock` and activation files. On another computer, use `renv::restore()` for that optional reporting environment. Without Excel, no package setup is needed.

## 2. What is replicated from source

The numerical path is:

```text
Curated literature transcriptions + explicit mapping/assumption tables
  -> select historical Tacon rows and exclude forecasts
  -> harmonize source feed groups and proxy mappings
  -> build annual p, eFCR, fishmeal/oil, and conditional recipe shares
  -> join species production by feed group and year
  -> calculate feed and ingredient quantities
  -> aggregate by country / water area / ISSCAAP / GCAM technology / year
  -> coverage audit, mass-balance checks, summaries, figures, optional Excel
```

**The reproducibility boundary is explicit.** PDF-to-table transcription and analyst taxonomy decisions are curated inputs. They are not represented as an automatic web scraper or automatic PDF extraction. Their source IDs, URLs, table/page locations, notes, and assumptions are retained. Full copyrighted PDFs are not redistributed in the project. A fresh clone can regenerate the analysis from the included tabular inputs without internet access.

Unlike the older pipeline, this port **rebuilds the selected Tacon history directly from the separately transcribed Tacon 2015 and 2026 tables**. It does not use the previous preassembled `historical_coefficients_2000_2023.csv` as a computational input. Likewise, the generic nonmarine proportions are rebuilt from the actual Figure 5 labels, not from already-calibrated Scenario H output shares. The Norway inventory is calculated from named raw categories rather than hard-coded ingredient totals.

The supplied crosswalk's `input_production_t` is a retained **2021 diagnostic only**. It is not used as a historical weight. Each input year's supplied species production is used directly. FAO reporting-area codes remain FAO codes: this project does not falsely relabel them ISO codes or invent a 32-region GCAM crosswalk.

## 3. Files and folders

```text
aquafeed-history/
  AquafeedHistory.Rproj
  run_all.R                       # single entry point
  config/default.R                # input, scenarios, early-year policy, reports
  R/
    io.R                          # stable CSV I/O, code preservation, manifests
    sources.R                     # raw-table selection / harmonization
    coefficients.R                # annual parameters and Norway override
    production.R                  # species calculation and year-aware aggregates
    reconciliation.R              # original/species production-coverage audit
    reports.R                     # scenario summary, PNGs, HTML, optional workbook
    validation.R                  # regression and input/edge-case checks
    cli.R, pipeline.R, load.R
  scripts/
    build_coefficients.R
    process_production.R
    run_tests.R
    setup_optional_reports.R
    publish_github.R              # explicit opt-in; private repositories only
  data/
    raw/literature/                # source transcriptions and source register
    raw/production/                # your unchanged 2021 source CSVs
    mappings/                     # species and GCAM crosswalks; recipe mapping
    processed/                    # rebuilt, Git-ignored
  docs/                           # methodology, assumptions, data dictionary, audits
  tests/reference/v0.4/            # immutable previous outputs, validation only
  validation/                     # input manifest and preparation/runtime status
  outputs/                        # generated results, Git-ignored
  .github/workflows/replicate.yml  # R rebuild/regression workflow
```

Raw tables and expected fixtures are versioned; generated results are ignored by Git. Source CSV bytes are preserved across Windows/Linux using `.gitattributes`, so source-file checksum checks are meaningful.

## 4. Scientific definitions retained

For reporting area `r`, species/item `s`, and year `t`, with assigned literature group `g(s)`:

```text
commercial_feed = production_live_weight * commercial_feed_share[g,t] * eFCR[g,t]
FeedCrops       = commercial_feed * crop_ingredient_share[g,t]
ReductionFish  = commercial_feed * (fishmeal_share[g,t] + fishoil_proxy_share[g,t])
OtherFeed      = commercial_feed - FeedCrops - ReductionFish
```

All quantities are tonnes. `FeedCrops` is processed crop-ingredient mass, **not primary crop equivalents**. `ReductionFish` is a **fishmeal-and-oil ingredient proxy**, not wet whole fish and not exclusively whole-fish-origin material. Some origin components remain unknown. No fourfold/25%-yield wet-fish conversion is applied.

The calculation covers commercial compound feeds, not all external feed, farm-made feed, or directly fed whole fish. The complement of “commercial-feed share” is not necessarily unfed. Do not apply that share twice if your technology's output is already restricted to commercially fed production.

Important inherited caveats are not repaired silently in a language port:

- 1975–1994 lacks calibrated coefficients. An explicit `blank` or `hold` decision is required; the default stops.
- Fish-oil definitions differ across the source vintages, and Naylor's unreported trimming-oil component remains missing.
- Nonmarine compositions include generic/company-to-global and temporal-transfer assumptions.
- The printed shrimp Figure 5 labels total 90%; the missing 10 percentage points remain unallocated.
- Unresolved species and feed pathways remain missing. Nonfed grow-out is a separate, explicit zero assumption.
- The previous positive-cell production omissions are audited, not filled or scaled.

See `docs/methodology_v0.4.md`, `docs/assumptions.csv`, and `data/raw/literature/source_register.csv` for the full scientific audit. This port is not a new literature review or a resolution of its outstanding correction/source-definition flags.

## 5. Historical production, 1975–2023

Provide a species-level CSV with these required columns:

```text
FAO_area_code, water_area_code, species_code, ISSCAAP, year, supply, measure, value
```

`supply` must be `Aquaculture`; `measure` must be `Q_tlw`. The `value` field is live-weight tonnes. Keep `water_area_code` as character so codes such as `04` retain their leading zeros. Additional descriptive columns are preserved. The uniqueness key is reporting area × water area × species × year × supply × measure.

Example, leaving unsupported early-year feed quantities blank:

```sh
Rscript run_all.R --input data/raw/production/species_1975_2023.csv --early-policy blank --output outputs/history
```

For an explicitly assumption-based completeness sensitivity:

```sh
Rscript run_all.R --input data/raw/production/species_1975_2023.csv --early-policy hold --output outputs/history_early_hold
```

The historical production file is **not bundled**; replace the example path with your actual file. New historical species codes stop the run for a crosswalk decision. `--allow-unmapped` instead retains their output with unestimated feed, never silently treating them as nonfed.

The pipeline never repeats 2021 production to manufacture a historical panel. Its source/aggregate coverage comparison under `input_audit_2021` is explicitly a **bundled 2021 input audit**, not a validation of future multi-year exports.

## 6. Output files

Each scenario directory contains:

- `species_feed_estimates.csv`: all source rows, mappings, quantities, coverage and provenance.
- `global_by_year.csv`, `country_technology_by_year.csv`, `technology_by_year.csv`, `feed_group_by_year.csv`, and `country_water_ISSCaap_by_year.csv`.
- `unestimated_records.csv` and `excluded_records.csv`, including headers when empty.
- `QA.csv`, `run_settings.csv`, `input_and_code_manifest.csv`, and `sessionInfo.txt`.

The root output directory also receives `scenario_comparison.csv`, `report.html`, coefficient plots, the 2021 coverage audit, and the optional `aquafeed_history.xlsx`. `complete_scope_feed_t` stays blank when relevant production has unestimated feed. Subtotals are explicitly labeled.

For a single scenario:

```sh
Rscript scripts/process_production.R --input data/raw/production/species_2021.csv --recipe recent_nonmarine --norway-override --output outputs/my_case
```

For interactive function-level use:

```r
source("R/load.R")
af_load(".")
coefficients <- af_build_coefficients(".")
run <- af_process_production(
  input = "data/raw/production/species_2021.csv",
  output = "outputs/interactive",
  coefficients = coefficients,
  recipe = "recent_nonmarine",
  norway_override = TRUE
)
run$summaries$global_by_year
```

## 7. Validation before analytical use

```sh
Rscript scripts/run_tests.R
```

The suite parses all R files, rebuilds coefficient tables, and compares **every legacy column** of the 588 annual coefficients, the strict/no-backcast series, the Norway override, the selected Tacon history, all 2,324 species records in each of three 2021 cases, and every level of aggregation against v0.4. It tests duplicate keys, capture input, wrong units, new taxa, taxonomy mismatches, missing/negative/nonfinite production, early-year policy, the 255 omitted positive production cells, and preservation of `NA` versus zero.

Synthetic multi-year tests are explicitly labeled as tests; they are not production estimates. Numerical comparisons use stated absolute/relative tolerances for floating-point differences. Boolean CSV spelling may differ (`TRUE/FALSE` in R versus `True/False` in Python); the tests compare logical meanings. Extra R provenance columns are allowed, but no legacy columns may disappear.

A successful run writes `validation/R_test_results.csv` and reports the actual number of passing checks. The supplied pre-fix report is retained as `validation/user_v0_5_R_test_results.csv` (83 PASS, one metadata FAIL). A complete post-fix native-R run is still required; no all-pass result is claimed here. The reference subtotal 63,486,260.242367 t was among the passing numerical checks in the user's pre-fix report.

Intentional source/method changes should be reviewed and versioned. Do not overwrite reference fixtures just to silence a failing test. Baseline tests always use the bundled production example even when the main run processes your historical file.

## 8. Put the project on your GitHub

Suggested destination: **`realxinzhao/aquafeed-history`**, **private**.

The current ChatGPT connection could inspect GitHub but could not create repositories or push files. The following steps therefore run on **your own computer**, not automatically from the analysis. No GitHub token belongs in a CSV, script, or chat message.

With Git and GitHub CLI installed, open the RStudio **Terminal** in this project:

```sh
gh auth login
git init -b main
git add .
git commit -m "Add source-documented native-R aquafeed history pipeline"
gh repo create realxinzhao/aquafeed-history --private --source=. --remote=origin --push
```

For a fresh folder only, an alternative R helper performs these operations after checking your authenticated account and refusing existing repositories:

```sh
Rscript scripts/publish_github.R --publish --repo realxinzhao/aquafeed-history
```

The helper does nothing without `--publish`; it never uploads as a side effect of running the analysis. If the name already exists, use a different repository name or follow your existing repository's normal Git workflow. Do not force-push.

After the first push, the supplied GitHub Actions workflow attempts the native R rebuild and tests on Windows and Linux. It has read-only repository permissions and does not deploy public pages. Its green status must be observed, not assumed. Source inputs are included in the private repository; review data rights before changing visibility or sharing externally.

## 9. Rights and documentation

No new open-source or open-data license is asserted on your behalf. `docs/DATA_AND_CODE_RIGHTS.md` explains the boundary. Full papers, secrets, R session state, and generated outputs are excluded from Git. References remain in the source register; sources reviewed but not applied retain that status.
