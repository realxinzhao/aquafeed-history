# Aquafeed history: coefficients for GCAM

**[Read the documentation website](https://realxinzhao.github.io/aquafeed-history/)**
— getting started, methods, source register, assumptions and validation.

This reproducible R project estimates commercial aquafeed ingredients per tonne of
aquaculture output. Its full species-year table contains **778 species/item codes ×
1973–2024 = 40,456 rows**, with no regional coefficient dimension. Species inherit
literature-group estimates or documented assumptions; these are not 778 independently
measured feeding histories.

The default production input is
[`GCAMFAOSTAT_FISHPROD_Aquaculture_BySpecies.csv.gz`](data/raw/production/GCAMFAOSTAT_FISHPROD_Aquaculture_BySpecies.csv.gz):
FAO FISHSTAT data processed by **gcamfaostat**, release 2026.1.0. It contains 92,128
records, 770 production codes, 220 reporting areas, and years 1973–2024. The applied
crosswalk retains 8 legacy-only codes. The 2024 feed estimate holds the finalized 2023
coefficient vector forward; it is an assumption-based estimate, not a 2024 literature
coefficient estimate.

The project preserves previously assigned coefficients and fills 146 earlier pending
items through 140 positive proxies and 6 documented zero assumptions. Those assumptions
are not new measurements, and the original 12-group subtotal is not rescaled.

## Run in RStudio

Open `AquafeedHistory.Rproj` and run:

```r
source("scripts/export_gcamdata_coefficients.R")
```

Or, from a terminal:

```sh
Rscript scripts/export_gcamdata_coefficients.R
```

This command builds source evidence and coefficients and reads the configured production
file to extend the applied species roster. It does not calculate historical demand.
It writes the full coefficient table and two compact GCAM inputs:

| File | Purpose |
|---|---|
| `outputs/gcamdata/GCAMFAOSTAT_FeedCoef_Aquaculture_BySpecies.csv` | Compact GCAM input with comment metadata and six columns. |
| `outputs/gcamdata/GCAMFAOSTAT_FeedCoef_Aquaculture_BySpecies.csv.gz` | The same compact input, gzip-compressed, with its own matching filename header. |
| `outputs/02_coefficients/GCAMFAOSTAT_FeedCoef_Aquaculture_BySpecies.csv` | Full coefficient table, including eFCR, commercial-feed shares, mapping and assumption flags. |

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

Or `Rscript run_all.R`. This applies the coefficients to the supplied **92,128-row
species production panel for 1973–2024**. It preserves each year's observed species mix.
For 2024, all applicable coefficients are held at their 2023 values.

Key results are written to `outputs/03_demand_checks/`: global and country demand,
country-technology demand, `benchmark_comparison.csv`, `core_vs_expanded_global.csv`,
and coverage contribution audits. Runtime checks are in
`validation/R_test_results.csv`; configuration, input/code checksums and session
information are in `outputs/run_info/`.

The applied crosswalk is extended from production data on each run. New codes inherit a
feed group only when all existing entries for their exact ISSCAAP group agree; otherwise
they remain `UNESTIMATED`. Of the 47 new codes, 24 inherit a feed-group proxy, 14 inherit
a `NONFED` assumption, and 9 remain unestimated. Generated rows are flagged `AUTO:` and
low confidence in `outputs/02_coefficients/species_mapping_applied.csv`. Ambiguous
production stays visible; it is not silently set to zero.

The production panel is species-resolved, so each year's observed species mix is used;
there is no 2021 species-mixture approximation. The retired 1973–2022 source was removed
from the current project; prior release checksums and archive documentation are retained.

| Year | Tacon-comparable subtotal | Added coverage | Expanded estimate | FeedCrops | Fishmeal | Fish oil | OtherFeed |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2021 | 63.629 Mt | 5.384 Mt | 69.012 Mt | 50.878 Mt | 4.389 Mt | 0.992 Mt | 12.753 Mt |
| 2022 | 66.768 Mt | 5.850 Mt | 72.619 Mt | 53.554 Mt | 4.640 Mt | 1.030 Mt | 13.395 Mt |
| 2023 | 69.606 Mt | 6.534 Mt | 76.140 Mt | 56.073 Mt | 4.924 Mt | 1.066 Mt | 14.078 Mt |
| 2024 | 72.252 Mt | 6.831 Mt | 79.083 Mt | 58.273 Mt | 5.121 Mt | 1.091 Mt | 14.598 Mt |

The Tacon comparison uses the original subtotal because its parameters help construct
that estimate. It is a source-consistency check, not independent validation of added
assumptions. The 2024 estimate uses held 2023 coefficients and has no independent 2024
feed benchmark in this project.

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

## Additional method notes

OtherFeed keeps terrestrial animal ingredients, micronutrients, unallocated ingredients,
and, in new specialty recipes, non-crop algae/mineral components. Fresh seaweed fed directly,
wet baitfish, farm-made supplementary feeds, fertilizer and hatchery live feed remain outside
this commercial-compound-feed account. They are **not assigned fabricated meal equivalents**.

## Editable coverage assumptions

`data/mappings/coverage_assumption_groups.csv` contains every positive 2021 anchor,
its low/high sensitivity, trend and recipe donors, source IDs, rationale and caveats.
`data/mappings/coverage_species_overrides.csv` lists all 146 earlier coverage adjustments.
The curated seed crosswalk is preserved. New production codes are added to the applied
crosswalk only through the exact-ISSCAAP consensus rule; ambiguous codes remain
`UNESTIMATED` rather than being assigned zero.

Example: C01 Indian major carps (catla, rohu, mrigal) uses assumed e=2.0, p=0.25,
so the **effective** coefficient is 0.5 t/t at 2021. The 0.5 is not a pure eFCR.
FAO 578 supports positive feeding and a range of system FCRs, but **does not measure
this global p or this 0.5 coefficient**. The recipe is a stated crop-dominant assumption.
See `docs/COVERAGE_ASSUMPTIONS.md` for the full anchor table and evidence limits.

The literature check adds 14 references to the source register, including FAO 578,
FAO 567, turtle/frog feeding studies, SEAFDEC abalone research, sea-cucumber feeding,
pearl/oyster guidance and code-identity sources. Some references support pathway
existence, not quantitative global coefficients. Weak analogies are labelled explicitly.

### Historical rules

The original source hierarchy, annual eFCR/p values and ingredient trajectories are unchanged.
For most new groups, relative time changes are borrowed from a named original donor:

```
e(t) = e_anchor * donor_e(t) / donor_e(2021)
p(t) = min(1, (effective_anchor / e_anchor) * donor_p(t) / donor_p(2021))
a(t) = e(t) * p(t)
```

Two related-group transfers copy the donor p/e directly (Prussian-carp and trout-like proxies).
Fixed assumed recipes are constant over time; borrowed recipes follow the donor's annual
composition. These are constructed histories, not observations. Source-year fields for
extension rows identify the **2021 assumption anchor**, not the date of a measurement.

Default `early_policy = "hold"` extends 1995 values backward. `"blank"` leaves pre-1995
fed coefficients missing, so complete coverage is not claimed under that alternative.
2023/2024 biological studies support plausibility retrospectively, **not 1970s adoption**.

### Sensitivity

Low/high columns bound the **combined effective coefficient** for new groups. They are
not confidence intervals or independently estimated p/e distributions. Original coefficients
are held fixed. Ingredients scale in the same proportions: recipe uncertainty is not spanned.
`commercial_feed_low_t` and `_high_t` sum these scenarios. Do not compare the range to a
statistical confidence interval for all global aquafeed uncertainty.

Set `coverage_policy = "original"` to retain the v0.6.1 pending-item behavior and totals.
Set `"expanded"` (default) for the documented additions. Editable assumptions are not fitted
to Tacon or Alltech totals. Numeric regression fixtures are skipped when scientific inputs
change, but structural/mass-balance tests continue to run.

## Results from the updated production input

Mt of commercial-feed ingredients from the executed pipeline. 2024 applies the 2023
coefficient vector to 2024 production; no independent 2024 feed benchmark is available here.

| Year | Tacon-comparable subtotal | Added coverage | Expanded total | FeedCrops | Fishmeal | Fish oil | OtherFeed |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2021 | 63.629 | 5.384 | 69.012 | 50.878 | 4.389 | 0.992 | 12.753 |
| 2022 | 66.768 | 5.850 | 72.619 | 53.554 | 4.640 | 1.030 | 13.395 |
| 2023 | 69.606 | 6.534 | 76.140 | 56.073 | 4.924 | 1.066 | 14.078 |
| 2024 | 72.252 | 6.831 | 79.083 | 58.273 | 5.121 | 1.091 | 14.598 |

Values for 2021–2023 differ from the prior run because the production series has been revised.
The comparable subtotal retains its original 12-group scope; the automatically mapped new
species are kept in the added-coverage component.

### Coverage is not evidence quality

`excluded_output_t` remains zero, but ambiguous new species are not forced into a feed group.
In 2024, `unestimated_output_t` is **26,783 tonnes** (9 new codes); this production remains
visible in the unestimated outputs and contributes no fabricated feed coefficient.

- `complete_feed_estimate`: numerical coverage of the current commercial-feed account.
- `complete_all_external_feed_estimate`: explicitly FALSE; noncompound pathways unresolved.
- `assumption_covered_output_t`: production brought into numeric coverage by this release.
- `assumed_zero_output_t`: output assigned an explicit `NONFED` convention, including new
  unique-ISSCAAP automatic mappings.
- `non_live_product_output_t`: reported pearl/shell product mass.
- `live_output_t`: reported production less pearl/shell products; prevents using products
  as an animal-live-output denominator. Other historical product/basis issues remain flagged.
- `coverage_layer` and `coverage_assumption_id`: identify each proxy in the main CSV.

Zero pearl/shell commercial grow-out input does not assert zero hatchery feed or zero whole-life-cycle
resource use. HXP inherits the existing silver/bighead convention; YMX is an identified bivalve.
KUE is corrected to **Actinopyga echinites**, per the EC code register; the supplied conflicting
name "Deep-water redfish" is preserved in `species_name_original` and the identity audit.

## Benchmark interpretation

`benchmark_comparison.csv` compares Tacon2026 against `tacon_comparable_feed_t`, not
against the expanded total. Its separate `expanded_commercial_feed_t` column retains the
latter for context. Alltech/CFIA comparisons still use the expanded commercial total, but
are neither calibration constraints nor independent validation of these proxies.
Adding assumed positive inputs can correct an omission; it does not prove the expanded
estimate is closer to truth. Bounds and source-quality flags remain important.

## Principal output paths

```
outputs/01_sources/literature_source_estimates.csv
outputs/01_sources/coverage_literature_evidence.csv
outputs/02_coefficients/GCAMFAOSTAT_FeedCoef_Aquaculture_BySpecies.csv
outputs/02_coefficients/coefficient_provenance_group_year.csv
outputs/02_coefficients/species_mapping_applied.csv
outputs/gcamdata/GCAMFAOSTAT_FeedCoef_Aquaculture_BySpecies.csv.gz
outputs/03_demand_checks/core_vs_expanded_global.csv
outputs/03_demand_checks/global_feed_demand.csv
outputs/03_demand_checks/country_feed_demand.csv
outputs/03_demand_checks/country_technology_feed_demand.csv
outputs/03_demand_checks/coverage_extension_by_group_year.csv
outputs/03_demand_checks/coverage_extension_by_species_year.csv
outputs/03_demand_checks/coverage_mapping_audit_2021_2024.csv
```

The coverage audit is regenerated for 2021–2024 when present; group/species-year
contribution tables are regenerated for all supplied years. Regional aggregation to the
32 GCAM regions remains in gcamdata using the authoritative country mapping.

## Execution and regression status

The updated pipeline was run in R 4.6.0, and **75 native-R checks passed**. This verifies the
pipeline’s structural, conservation, mapping, 2023-to-2024 hold, and export round-trip checks;
it does not independently validate the 2024 feed estimate. The 2024 estimate uses the
documented 2023 hold-forward assumption.

Run `source("run_all.R")` locally. It rebuilds tables and executes the expanded R tests,
writing `validation/R_test_results.csv`. New fixtures are in `tests/reference/v0.7`.
Previously populated species coefficients and the original coefficient fixtures are tested
through 2023 against earlier references. Demand regressions for the former production file
are not applied to the revised FishStat series. Tests do not require the expanded total to
equal Tacon. Windows/Linux GitHub Actions are configured but not executed here.

Review diffs when updating an existing checkout; never overwrite local config or `.git`
blindly. Full copyrighted PDFs, credentials and user environment files are not included.
Original sources and data retain their use conditions; do not assume public redistribution
rights merely because a project is reproducible.
