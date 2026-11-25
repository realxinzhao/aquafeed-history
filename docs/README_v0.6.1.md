# Aquaculture feed coefficients for gcamdata — v0.6.1-R

## Main product

**`outputs/02_coefficients/aquaculture_feed_coefficients_species_year.csv`**

One row per **species/item code × year**, without a region dimension. Default coverage:
**731 species/item codes × 1973–2023 = 37,281 rows**. These are mostly assignments from
12 literature feed groups, not 731 independently measured feeding efficiencies.

The repository has three steps. Production calculations are application checks; they
are not required to build the main coefficient CSV and do not fit the coefficients.

| Step | Inputs | Output |
|---|---|---|
| 1. Preserve source evidence | Curated literature CSV transcriptions | `outputs/01_sources/literature_source_estimates.csv` (442 records, including explicitly labelled projections and undated profiles) |
| 2. Fill and map | Source evidence, documented selection/interpolation rules, species crosswalk | Main species–year coefficient CSV, 612-row group–year provenance table, applied species mapping |
| 3. Check application | Production, coefficients, independent published feed benchmarks | Country/year and global demand estimates, coverage, benchmark differences; direct species history by default |

No moisture adjustment, dry-matter normalization, wet-fish/reduction yield, primary-crop
conversion or embodied-feed conversion is applied. Fishmeal and fish oil remain separate.
The intended output measure is tonnes of commercial feed ingredients per tonne live-weight
production. Tacon does not supply a sufficiently explicit moisture specification to call
these coefficients verified dry-matter coefficients.

## Run in RStudio

Open `AquafeedHistory.Rproj`. All calculations use base R; no Python runtime is required.

```r
# Main deliverable only: steps 1 and 2. Does not read production data.
source("scripts/export_gcamdata_coefficients.R")

# Or all three steps, including historical application and tests:
source("run_all.R")
```

The terminal equivalents are:

```sh
Rscript run_all.R --coefficients-only
Rscript run_all.R
Rscript scripts/run_tests.R
```

Change settings in `config/default.R`; paths are relative to the project. An alternative
production file can be supplied without editing code:

```sh
Rscript run_all.R --input path/to/production.csv --early-policy blank --output outputs/strict
```

`early-policy hold` is the explicit default completeness assumption: use 1995 coefficients
before 1995. `blank` leaves the unsupported early values missing. Neither policy creates
observed evidence before 1995. The old `--no-plots`/Excel flags are retired: this release
is deliberately CSV-focused.

## What the columns mean

Let `p = commercial_feed_share`, `e = efcr`, and `s_i` be the ingredient mass share.

- `efcr = e`: commercial feed per tonne **commercially fed** live output.
- `commercial_feed_share = p`: fraction of total production using commercial feed.
- `commercial_feed_per_t_output = p * e`: commercial feed per tonne **total** live output.
- `FeedCrops_share`, `fishmeal_share`, `fishoil_share`, `OtherFeed_share`: selected estimated recipe; sums to one where estimated.
- `efcr_FeedCrops`, `efcr_fishmeal`, `efcr_fishoil`, `efcr_OtherFeed = e * s_i`: source-specific input coefficients conditional on commercially fed output.
- `FeedCrops_per_t_output`, `fishmeal_per_t_output`, `fishoil_per_t_output`, `OtherFeed_per_t_output = p * e * s_i`: source inputs per tonne of total production.

The component eFCR columns are allocations of total eFCR, **not independent conversion
efficiencies**. Use the effective `_per_t_output` fields with total aquaculture production;
do not multiply by the commercial-feed share a second time. Within the commercially fed
technology alone, use the conditional `efcr_*` fields.

`OtherFeed` retains terrestrial animal ingredients, additives, and genuinely unallocated
mass. It is not relabelled as crops. `fishmeal + fishoil` can subsequently be combined into
ReductionFish, but that total includes any trimming-derived material in the selected
recipe and is not a whole-wet-fish input.

See [`docs/data_dictionary.csv`](docs/data_dictionary.csv). Each modeled species-year row
has `coefficient_id` linking to `coefficient_provenance_group_year.csv`, with source IDs,
source-year brackets, fill methods, scope warnings and assumption-register references.
Sources resolve through `data/raw/literature/source_register.csv`.

## Step 1: raw source evidence

Raw CSVs in `data/raw/literature` are curated numerical transcriptions, with source URLs,
table/page locations, source geography and evidence status. The program does not claim
to automatically extract or interpret PDFs. Full papers are not redistributed.

The raw evidence table preserves unknown values. In particular:

* Naylor 2017's oil column is **wild-fish oil**, so total oil stays missing in the raw table.
* Skretting's marine-protein category includes crustacean meal; it is not equated with fishmeal.
* Tacon Figure 5 is an **undated illustrative profile**, not an observed 2015 diet.
* The Figure 5 shrimp labels sum to 90%; 10% is retained as unallocated, not silently assigned to crops.
* Aas's Norway inventory is national composition evidence, not a global eFCR replacement.

Raw component eFCRs are calculated only where the **same source record** supplies both
eFCR and the ingredient share. This yields fishmeal/oil allocations for FAO and meal
allocations for Naylor. Crop-specific eFCRs generally require combining evidence across
sources; that construction belongs to step 2 and is labelled as such. Projections remain
visible in the raw table, but are not used as realized history.

## Step 2: annual filling rules

Total-feed coefficients use FAO 564 at 1995, separate linear interpolation of `p` and
`efcr` through 1999, Tacon 2015 for 2000–2009, and Tacon 2026 for 2010–2023. The newer
source takes priority in overlapping years. Selected group proxies are explicitly retained.

Fishmeal uses FAO 564 reference years 1995, 2000, 2005, 2007 and 2008, followed by
Naylor's 2017 wild-plus-trimming meal share; subsequent years hold the endpoint.

**Changes from v0.4/v0.5:**

1. For salmon, shrimp and tilapia, total fish oil now interpolates from FAO 2008 to
   Skretting 2021 total oil, without interpolating through Naylor's wild-only oil column.
   This is an explicit **company-to-global assumption**, not a new global observation.
2. Their nonmarine proportions transition from the generic profile at the assumed
   2015 transition point to Skretting's 2021 conditional nonmarine ratios, then hold.
   Earlier versions' recent-composition sensitivity applied the company ratios across
   all years. The new trajectory remains a constructed hybrid recipe.
3. Silver and bighead carp (`SVC`, `BIC`) receive zero commercial grow-out feed using
   Gephart 2021 Table S5. This does not imply zero natural food, fertilizer, or incidental
   pond inputs. Their conditional eFCR and p remain undefined.
4. The main export and processing now cover 1973–2023, with separate fishmeal and oil.

For other groups, the post-2008 fish-oil series still uses a wild-only oil proxy where no
better total-oil anchor is available. `fishoil_scope` exposes that unresolved limitation.
Unknown trimming oil is not claimed to be measured zero. The original Naylor milkfish
trimming-meal blank is kept raw; using its wild-meal endpoint as total in the filled series
is an explicit zero-additional-trimming proxy.

The audit retains unsupported species as `UNESTIMATED` (142 codes), not zero. Filling
years with bounded assumptions does not justify inventing a universal feed coefficient
for every taxon. `NONFED` has zero effective input but missing conditional eFCR; it is
not interchangeable with `UNESTIMATED` or `OUT_OF_SCOPE`.

All rules are in [`docs/assumptions.csv`](docs/assumptions.csv), with substantive limitations
and source review recorded in [`docs/SOURCE_AUDIT.md`](docs/SOURCE_AUDIT.md).

## Step 3: historical species-resolved production input in v0.6.1

The v0.6.1 release used the user upload
`AquacutureProductionAllYears_bySpecies_bycountry_tonnes_updated1.csv`, stored in that
release as `data/raw/production/history_1973_2022_species.csv`. It contained **87,156
observations, 731 species/item codes, 214 FAO reporting areas, 40 ISSCAAP groups, and
50 years (1973–2022)**. All records were labelled `Aquaculture` and `Q_tlw`; keys were
unique. These are historical facts about v0.6.1, not the current default input.

The old file was removed from the current working project on November 25, 2026. The
current default is `data/raw/production/GCAMFAOSTAT_FISHPROD_Aquaculture_BySpecies.csv.gz`,
FAO FISHSTAT data (release 2026.1.0) processed by gcamfaostat and covering 1973–2024.
This archived v0.6.1 document and its input checksum remain as historical references.

**Default demand calculations now use actual supplied species production in each year.**
The 2021 species-mixture approximation from v0.6 is not used. The old aggregate-history
file is no longer the default input and is not bundled in this release. The generic
aggregate-input fallback remains in the R code for other uses, but its global-mixture
sensitivity is disabled by default. Stale mixture output files are removed on rerun.

The earlier `species_2021.csv` remains an optional **separate consistency check only**
(`run_2021_reference_check` in the config). It does not supply historical composition
weights for the new input, and it is never added to the historical production file.

### Historical mapping extension

The earlier 547 item-code assignments and all group-year numerical coefficients are
unchanged. This release adds explicit crosswalk rows for 184 historical codes:

| New-code treatment | Number of codes |
|---|---:|
| Existing literature feed-group proxy | 103 |
| Existing nonfed commercial grow-out convention | 42 |
| Unestimated pathway, retained as missing | 39 |

The mapping decisions are listed individually in
`docs/historical_species_mapping_additions.csv` and summarized by assumption F21.
Assignments use the supplied ISSCAAP category and, for selected freshwater fish and
salmon/trout records, literal common-name labels. They are **documented proxies, not
184 new species-specific feeding measurements**. Missing names are not invented.
Names, source categories, years, record counts, and production exposure are retained
in the mapping audit. New carp memberships, charr, and miscellaneous diadromous
pathways without a supported assignment remain unestimated.

Subsequent unseen item codes or species/ISSCAAP conflicts stop processing for an
explicit mapping decision. Required input fields are `FAO_area_code`, `water_area_code`,
`ISSCAAP`, `year`, `value`, `supply= Aquaculture`, `measure= Q_tlw`, and `species_code`
for direct species processing. Capture input, missing keys, negative/non-finite
quantities, wrong units, duplicate records, and unsupported years are rejected.

Country outputs retain FAO reporting-area codes. A country-to-32-GCAM-region mapping
was not supplied; no macroregional mapping is invented. Aggregate in gcamdata using
your authoritative mapping.

## Updated application results (independent calculation)

The bundled results were recalculated from the new source file. They are comparison
fixtures for the R code, **not a claim of native R execution**. Values below are modeled
commercial-feed subtotals, in million tonnes of ingredients as reported.

| Year | Total | FeedCrops | Fishmeal | Fish oil | OtherFeed |
|---|---:|---:|---:|---:|---:|
| 2021 | 63.486 | 46.268 | 4.066 | 0.959 | 12.193 |
| 2022 | 66.510 | 48.446 | 4.289 | 0.991 | 12.784 |

The 2021 production total in this new input is **126.225744 Mt**; **12.040554 Mt**
has unestimated feed pathways, and 0.001891 Mt of pearls/shells is out of scope.
In 2022, production is **130.920761 Mt**, with **12.851054 Mt** unestimated and
0.002678 Mt out of scope. Partial feed totals are not full-coverage observations.
The input's 2021 species records reproduce the earlier supplied species-reference
calculation. They have not been scaled to the larger, earlier ISSCAAP aggregate file.

The updated totals differ from v0.6 because production coverage and actual historical
species composition replace the older aggregate input and fixed-mixture approximation.
No literature eFCR, commercial-feed share, or recipe was recalibrated for this update.

Tacon's modeled benchmarks remain internal consistency checks, not independent
validation. Relative to the retained Alltech benchmarks, the new global subtotals are
23.25% higher in 2021 and 25.69% higher in 2022. China-mainland estimates are 29.850 Mt
and 31.443 Mt, respectively, versus retained CFIA figures 22.93 and 25.26 Mt. These
differences are not erased through fitted coefficients. Benchmark citations and
accounting-scope notes remain in `data/raw/benchmarks/commercial_feed_benchmarks.csv`.

Main outputs in `outputs/03_demand_checks/` are:

- `global_feed_demand.csv`, `country_feed_demand.csv`, and technology aggregates;
- `benchmark_comparison.csv` and `production_input_audit.csv`;
- `unestimated_production_by_country_group_year.csv` and
  `unestimated_production_by_species_year.csv`;
- `species_2021_direct_check.csv`, the optional separate reference check.

No `historical_species_mix_assumptions.csv` is generated for the direct species input.

## Validation status and reproducibility

**Native R execution has not been performed in this authoring environment because R is
unavailable.** The project is native R and requires no Python runtime for replication.
The precomputed application outputs were generated separately using the unchanged
v0.6 group-year coefficient values, the expanded mapping, and the newly supplied
production file. They are independent application comparison targets, not R run logs.

**44 independent data and arithmetic checks passed**; see
`validation/independent_data_checks.csv`. These cover source-file integrity, keys,
all 731 item codes, preservation of all prior 547-code numerical coefficients, source
mass balances, production coverage partitions, regional/global aggregation, missing
values versus zeros, and the separate 2021 reference agreement. These do not prove
that all R functions execute correctly or validate the science independently.

Run `source("run_all.R")` locally to rebuild in R, run runtime tests, and write
`validation/R_test_results.csv`. The R tests keep the unchanged coefficient regression
in `tests/reference/v0.6/` and use the **new input's** demand fixtures in
`tests/reference/v0.6.1/`. No old historical-demand totals are used as new-input
expectations. Demand fixture comparisons apply only when the default configuration
and exact bundled input checksum match; structural and mass-balance checks still apply
to other valid inputs. Each run writes settings, R session information, and input/code
checksums to `outputs/run_info/`. GitHub Actions is configured but has not been run for
this release.

For a clean update, extract into a new folder and run there first; do not overwrite local
configuration or a `.git` directory blindly. To retain an existing Git checkout, review
and copy code/data/docs, inspect the diff, then commit normally. Obsolete old modules
and CLI flags were removed from this simplified release.

## GitHub and use conditions

This ZIP is the updated local repository package. It has **not been pushed**: the previously
proposed `realxinzhao/aquafeed-history` could not be resolved by the connected account.
The existing private-repository publishing helper remains optional; running the analysis
never publishes data. Sources, numerical transcriptions and user inputs retain their
respective ownership and use conditions. Full copyrighted papers and credentials are not
included. Review redistribution permissions before making a repository public.
