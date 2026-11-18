# Aquafeed history: coefficients for GCAM

A reproducible R project estimating commercial aquafeed ingredients per tonne of
aquaculture output. The default dataset covers **731 species/item codes × 1973–2023
= 37,281 rows**, with one coefficient per species and year and no regional dimension.
Species inherit literature group estimates or documented assumptions; these are not
731 independently measured feeding histories.

## Generate the GCAM inputs

Clone this repository and open `AquafeedHistory.Rproj`, then run:

```r
source("scripts/export_gcamdata_coefficients.R")
```

Or, from a terminal:

```sh
Rscript scripts/export_gcamdata_coefficients.R
```

This command builds source evidence and coefficients without reading production data.
It writes all three products:

| File | Purpose |
|---|---|
| `outputs/gcamdata/aquaculture_feed_coefficients_species_year.csv` | Compact GCAM input with comment metadata and six columns. |
| `outputs/gcamdata/aquaculture_feed_coefficients_species_year.csv.gz` | The same compact input, gzip-compressed, with its own matching filename header. |
| `outputs/02_coefficients/aquaculture_feed_coefficients_species_year.csv` | Full coefficient table, including eFCR, commercial-feed shares, mapping and assumption flags. |

The compact files contain, in order:

```text
species_code, year, FeedCrops_per_t_output, fishmeal_per_t_output,
fishoil_per_t_output, OtherFeed_per_t_output
```

Both compact formats include `File`, `Title`, `Units`, `Description`, `Data source`,
`Date of CSV last update`, and `Column types: cinnnn` comment headers, then ordinary
CSV column names. Missing values remain blank; documented zero inputs remain zero.
Rerunning replaces the files. The date records export time, not the source observation
year. Copy **one format** into the appropriate gcamdata input directory; retain the
full coefficient/provenance tables with any archived dataset release.

`export_to_gcamdata.R` remains a compatibility entry point to this integrated workflow.
It now rebuilds coefficients and writes to `outputs/gcamdata/`, rather than requiring
a previously generated CSV or writing a separate gzip file in the repository root.
All calculation and export code uses base R; no package installation or API access
is needed to run it.

In [config/default.R](config/default.R), `gcamdata_formats = c("csv", "csv.gz")`
is the default. Select `"csv"` or `"csv.gz"` for one format; `character()` disables
only the compact exports. The full coefficient table is always written. The same
exporter is also called by `run_all.R`.

## Use the coefficients

For each species and year:

```text
effective ingredient coefficient = commercial_feed_share × efcr × ingredient_share
ingredient demand                 = aquaculture output × effective coefficient
```

Use the four `_per_t_output` columns directly. **Do not multiply by eFCR or the
commercial-feed share again.** Their sum is total commercial-feed input per tonne
of output. For GCAM technologies/regions, aggregate ingredient demand and production,
then divide; do not take an unweighted average of species coefficients.

`FeedCrops` is crop-derived ingredient mass. Fishmeal and fish oil are processed
ingredient tonnes, including the origins represented by the selected sources;
they are not wet reduction-fish equivalents. `OtherFeed` includes terrestrial animal
ingredients, additives and unallocated/specialty components. No common moisture
normalization or primary-input processing conversion is applied. Direct wet feed,
farm-made supplementary feeds and hatchery inputs are outside this account.

See [Methods, sources and validation](docs/METHODS.md) for source roles, equations,
historical assumptions, interpretation and GCAM aggregation. Detailed coverage
choices are in [Coverage assumptions](docs/COVERAGE_ASSUMPTIONS.md); the complete
bibliography is in the [source register](data/raw/literature/source_register.csv).

## Reproduce demand and validation

```r
source("run_all.R")
```

Or `Rscript run_all.R`. This applies the coefficients to the supplied **87,156-row
species production panel for 1973–2022**. It preserves each year's observed species
mix. Although coefficients include 2023, no 2023 production is supplied or invented.

Key results are written to `outputs/03_demand_checks/`: global and country demand,
country-technology demand, `benchmark_comparison.csv`, `core_vs_expanded_global.csv`,
and coverage contribution audits. Runtime checks are in
`validation/R_test_results.csv`; configuration, input/code checksums and session
information are in `outputs/run_info/`.

| Year | Original 12-group subtotal | Tacon et al. (2026) | Relative difference | Added coverage | Expanded estimate |
|---|---:|---:|---:|---:|---:|
| 2021 | 63.486 Mt | 63.600 Mt | −0.179% | 5.498 Mt | 68.984 Mt |
| 2022 | 66.510 Mt | 66.740 Mt | −0.345% | 5.967 Mt | 72.476 Mt |

The Tacon comparison uses the original subtotal because its parameters help construct
that estimate. It is a **source-consistency check**, not independent validation of
the additional assumptions or ingredient recipes. Expanded estimates exceed the
fixed-vintage Alltech totals by 33.9%/37.0%; the methods guide also reports the China
CFIA comparison and explains the unresolved boundaries.

Default `coverage_policy = "expanded"` fills 140 positive and six zero assignments
using documented assumptions; `"original"` retains the earlier incomplete scope.
Default `early_policy = "hold"` carries 1995 parameters back to 1973; `"blank"`
leaves early fed coefficients missing. Complete numerical coverage does not imply
complete empirical evidence or all-external-feed accounting. Low/high estimates vary
only the coverage extensions, not every source of uncertainty.

Native R execution and regression status are documented in
[validation/EXECUTION_STATUS.md](validation/EXECUTION_STATUS.md). The GitHub workflow
runs the pipeline on Ubuntu and Windows. It also checks the compact exports for
metadata, numerical round trips, gzip validity and safe repeat execution.

## Toward publication

[Publication priorities](docs/PUBLICATION_ROADMAP.md) identifies the next research
steps: evidence-quality summaries, targeted farming-system checks, stronger historical
and ingredient evidence, independent validation with matched boundaries, and broader
uncertainty analysis. It also covers citation, licensing and an archived release.
The existing coefficient assumptions are not recalibrated by the export/documentation
integration; see [integration notes](docs/EXPORT_INTEGRATION.md) for the changes.
