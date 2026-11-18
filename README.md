# Aquaculture feed coefficients for gcamdata — v0.7-R

## Main product

`outputs/02_coefficients/aquaculture_feed_coefficients_species_year.csv`

**731 species/item codes × 1973–2023 = 37,281 rows**, no regional coefficient dimension.
Separate FeedCrops, fishmeal, fish oil, OtherFeed. Do not convert meal/oil to wet fish or
crop ingredients to primary crops here. No moisture normalization or processing yields.
Feed tonnage is ingredient mass as reported; not verified dry matter for all sources.

This release preserves all previously assigned coefficients and fills **146 formerly
pending items**: **140 positive commercial-feed proxies** and **6 zero commercial
grow-out assumptions** (four pearl/shell products, HXP silver/bighead mixture, YMX bivalve).
The 140 positive items use **23 transparent assumption groups**. They are NOT 140 new
measurements. The original 12-group subtotal is never rescaled to absorb the extension.

## Run in RStudio

Unzip to a fresh folder and open `AquafeedHistory.Rproj`.

```r
# Source evidence and main coefficient file only (no production input needed):
source("scripts/export_gcamdata_coefficients.R")

# Or all three steps, including historical demand and checks:
source("run_all.R")
```

Command line: `Rscript run_all.R` or `Rscript run_all.R --coefficients-only`.
Configuration lives in `config/default.R`. All calculation code uses base R. No Python
runtime, package download or external API is required for replication.

## Three steps

1. `outputs/01_sources/literature_source_estimates.csv`: **463 raw source records**,
   including 21 added context-specific FCR/qualitative records. Raw trials and mash-feed
   FCRs are retained as `reported_fcr`, **not silently adopted as global commercial eFCR**.
   Source CSVs are curated transcriptions, not an automated PDF-extraction claim.
2. `outputs/02_coefficients/`: main species-year file, group-year provenance, and applied
   mapping. The original 612 group-year records plus 1,173 extension records give 1,785
   positive-fed group-year rows. Nonfed conventions are documented in the mapping/assumptions.
3. `outputs/03_demand_checks/`: production application, coverage, country and technology
   aggregates, source-scope benchmarks, and the contribution of the new assumptions.

The unchanged historical input has 87,156 observations, 731 codes, 214 FAO reporting
areas and years **1973–2022**. Coefficients include 2023 independently; no 2023 production
is invented. Regions use the same species-year coefficient, but their species mixtures differ.
No fixed 2021 species mixture is used for the default historical input.

## Numerical definitions

Let e = `efcr`, p = `commercial_feed_share`, s_i = ingredient share.

- `commercial_feed_per_t_output = p * e` applies to **total** species production.
- `efcr_FeedCrops`, `efcr_fishmeal`, `efcr_fishoil`, `efcr_OtherFeed` = e * s_i.
- `FeedCrops_per_t_output`, `fishmeal_per_t_output`, `fishoil_per_t_output`,
  `OtherFeed_per_t_output` = p * e * s_i.
- Ingredients sum to total commercial feed. Source-specific eFCRs are allocations,
  **not separately measured feeding efficiencies**.
- Apply `_per_t_output` fields directly to total live-weight production. Do not multiply
  p again. Conditional eFCR stays missing for nonfed grow-out; effective coefficients are zero.

OtherFeed keeps terrestrial animal ingredients, micronutrients, unallocated ingredients,
and, in new specialty recipes, non-crop algae/mineral components. Fresh seaweed fed directly,
wet baitfish, farm-made supplementary feeds, fertilizer and hatchery live feed remain outside
this commercial-compound-feed account. They are **not assigned fabricated meal equivalents**.

## Editable coverage assumptions

`data/mappings/coverage_assumption_groups.csv` contains every positive 2021 anchor,
its low/high sensitivity, trend and recipe donors, source IDs, rationale and caveats.
`data/mappings/coverage_species_overrides.csv` lists all 146 affected codes explicitly.
The underlying crosswalk and raw production are preserved. New unseen codes still require
an explicit mapping; there is no silent automatic universal fallback.

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

## Results from the unchanged production input

Mt of commercial-feed ingredients; independent precomputed calculation, **not an R execution log**.

| Year | Original subtotal | Added coverage | Expanded total | FeedCrops | Fishmeal | Fish oil | OtherFeed |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2021 | 63.486 | 5.498 | 68.984 | 50.871 | 4.381 | 0.992 | 12.740 |
| 2022 | 66.510 | 5.967 | 72.476 | 53.450 | 4.631 | 1.027 | 13.368 |

2021 extension-only sensitivity produces an expanded total of
**64.623–75.074 Mt**;
2022: **67.744–79.085 Mt**.
The original Tacon-comparable subtotal is unchanged in every historical year.

### Coverage is not evidence quality

Default `unestimated_output_t = 0` and `excluded_output_t = 0` for every supplied year.
This means complete **numeric coverage under the assumptions**, not that all species have
observed feed data or that all external feed pathways are covered.

- `complete_feed_estimate`: numerical coverage of the current commercial-feed account.
- `complete_all_external_feed_estimate`: explicitly FALSE; noncompound pathways unresolved.
- `assumption_covered_output_t`: production brought into numeric coverage by this release.
- `assumed_zero_output_t`: output covered through the six newly assumed-zero assignments.
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
outputs/02_coefficients/aquaculture_feed_coefficients_species_year.csv
outputs/02_coefficients/coefficient_provenance_group_year.csv
outputs/02_coefficients/species_mapping_applied.csv
outputs/03_demand_checks/core_vs_expanded_global.csv
outputs/03_demand_checks/global_feed_demand.csv
outputs/03_demand_checks/country_feed_demand.csv
outputs/03_demand_checks/country_technology_feed_demand.csv
outputs/03_demand_checks/coverage_extension_by_group_year.csv
outputs/03_demand_checks/coverage_extension_by_species_year.csv
outputs/03_demand_checks/coverage_mapping_audit_2021_2022.csv
```

The last audit is regenerated for 2021/2022 when present; the group/species-year
contribution tables are regenerated for all supplied years. Regional aggregation to the
32 GCAM regions remains in gcamdata using the authoritative country mapping.

## Execution and regression status

**R is not installed in the authoring environment. This revision has not been run in R.**
The native-R code and all scientific inputs are provided; bundled results were calculated
independently for cross-checking. **48 independent data/arithmetic checks passed.** Static
structure checks are also recorded; neither substitutes for native R execution.

Run `source("run_all.R")` locally. It rebuilds tables and executes the expanded R tests,
writing `validation/R_test_results.csv`. New fixtures are in `tests/reference/v0.7`.
Old populated species coefficients and the original subtotal are tested separately against
v0.6.1. Tests do not require the expanded total to equal Tacon. Windows/Linux GitHub Actions
are configured but not executed here.

The supplied files are a complete local project update, **not a live GitHub push**.
Review diffs when updating an existing checkout; never overwrite local config or `.git`
blindly. Full copyrighted PDFs, credentials and user environment files are not included.
Original sources and data retain their use conditions; do not assume public redistribution
rights merely because a project is reproducible.
