# Methods, sources and validation

## What the dataset represents

This project estimates **commercial compound-feed ingredients per tonne of aquaculture
output**. Its default export contains 731 FAO species/item codes for 1973–2023
(37,281 rows). Coefficients vary by species mapping and year; there is no regional
coefficient dimension. Most species inherit a broader feeding group's coefficients.
Consequently, this is a harmonized, assumption-completed dataset, not 731 independently
measured feeding histories.

The calculation is implemented in [R/gcamdata.R](../R/gcamdata.R),
[R/coefficients.R](../R/coefficients.R) and [R/coverage.R](../R/coverage.R).
The main audit trail is:

1. Curated literature CSVs in `data/raw/literature/` retain source values and locations.
2. `outputs/01_sources/literature_source_estimates.csv` collects the evidence, including
   missing fields and context-specific trial FCRs.
3. `outputs/02_coefficients/coefficient_provenance_group_year.csv` records selected
   sources, interpolation, proxies and assumptions. Its `coefficient_id` links to the
   full species-year CSV and applied species mapping in the same directory.
4. `outputs/03_demand_checks/` applies coefficients to production and reports coverage
   and benchmark comparisons. These comparisons do not calibrate the coefficients.

## Source roles

The complete bibliography, scope and source locations are in the
[source register](../data/raw/literature/source_register.csv). These are the principal
inputs to the current calculation:

| Source and location | Use in this project | Main qualification |
|---|---|---|
| [Tacon, Hasan and Metian (2011), FAO 564](https://www.fao.org/4/ba0002e/ba0002e.pdf), Tables 3 and 11; `FAO564_historical_anchors.csv` | 1995 commercial-feed share and eFCR; fishmeal/oil inclusion at 1995, 2000, 2005, 2007 and 2008. | Historical estimates; later projected columns are excluded from historical anchors. |
| [Tacon and Metian (2015)](https://doi.org/10.1080/23308249.2014.987209), Table 1; `Tacon2015_Table1_all_years.csv` | Annual commercial-feed shares and eFCR for 2000–2009. | Authors' group estimates, not a farm census; later overlapping years are superseded by Tacon 2026. |
| [Tacon et al. (2026)](https://doi.org/10.1080/23308249.2025.2568830), Table 3; `Tacon2026_Table3_all_years.csv` | Annual commercial-feed shares and eFCR for 2010–2023; original 12-group benchmark. | Provides feed-use parameters and totals, not a complete ingredient composition table. |
| [Naylor et al. (2021)](https://doi.org/10.1038/s41586-021-03308-6), Table 1; `Naylor2021_Table1_2017.csv` | 2017 meal inclusion, combining wild-fish and trimming meal; oil proxy where no selected total-oil endpoint exists. | The oil column is wild-fish oil. Missing trimming oil is unresolved, not established zero. Milkfish's blank trimming-meal entry is assumed zero in the filled calculation. |
| Tacon and Metian (2015), Figure 5; `Tacon2015_Figure5_profiles.csv` | Broad crop/terrestrial-animal/additive proportions within the nonmarine remainder. | Undated illustrative profiles. Shrimp labels sum to 90%; the missing 10% remains unallocated. |
| [Skretting Sustainability Report 2021](https://www.skretting.com/contentassets/d33f5d3f52444da29c4e577fe495410f/2021-ska-sustainability-report.pdf?v=4a3ae6), Table 15; `Skretting2021_Table15.csv` | Total fish-oil endpoints and conditional nonmarine proportions for salmon, marine shrimp and tilapia. | Company averages transferred globally by assumption. Marine protein includes more than fishmeal and is not substituted for the meal coefficient. |
| [Gephart et al. (2021)](https://doi.org/10.1038/s41586-021-03889-2), SI Table S5; FAO species/pearl-oyster guidance | Support for specified nonfed grow-out conventions. | Zero commercial grow-out input does not imply zero hatchery or whole-life-cycle inputs. |
| [Coverage evidence](../data/raw/literature/coverage_evidence.csv), including [FAO 578](https://www.fao.org/4/i3146e/i3146e.pdf), [FAO 567](https://www.fao.org/fishery/docs/DOCUMENT/aquaculture/aq2010_11/root/2011/ba0110e.pdf), turtle/frog trials and SEAFDEC abalone research | Support feeding pathways and plausible ranges for added groups. | Experimental or mixed-feed FCRs do not measure global commercial-feed adoption. Numerical global anchors remain explicit assumptions. |

[Aas et al. (2022)](https://doi.org/10.1016/j.aqrep.2022.101316), Norway's 2020 salmon
ingredient inventory, is retained for composition review; it does not create a Norway
override in the final species-year export. MacLeod/FAO 626, Shen and Cottrell are also
review evidence rather than additional independent annual observations. See
[SOURCE_AUDIT.md](SOURCE_AUDIT.md) for transcription-access and correction-audit limits.

## Coefficient construction

For species/group `s`, year `t`, and ingredient `i`, define:

- `e`: `efcr`, tonnes of commercial feed per tonne of output assigned to commercial
  feeding, conditional on that feeding pathway.
- `p`: `commercial_feed_share`, the fraction of total production assigned to commercial
  feed, stored as a proportion from zero to one.
- `s_i`: the ingredient's share of commercial-feed mass.

The exported quantities follow:

```text
commercial_feed_per_t_output = p × e
efcr_i                      = e × s_i
i_per_t_output              = p × e × s_i
```

The ingredient-specific `efcr_i` values are allocations of total eFCR, not separately
measured efficiencies. The four effective ingredient coefficients sum to
`commercial_feed_per_t_output`. For nonfed grow-out, effective coefficients are zero;
conditional eFCR is undefined and remains missing.

### Annualization and composition

The feed-parameter hierarchy is FAO 1995, Tacon 2015 for 2000–2009, then Tacon 2026
for 2010–2023. The code interpolates **p and e separately** between anchors. Default
`early_policy = "hold"` carries 1995 values backward to 1973; `"blank"` leaves early
fed coefficients missing. The older combined miscellaneous freshwater/diadromous
category supplies explicit proxies for the later separate groups.

Fishmeal inclusion interpolates between historical FAO and 2017 Naylor anchors,
then holds the 2017 endpoint. Oil follows that approach except for salmon, shrimp and
tilapia: their default total-oil series connects FAO 2008 directly to Skretting 2021,
then holds 2021. Other groups retain the stated wild-oil-as-total limitation.

After meal and oil are assigned, their complement is allocated using conditional
nonmarine ratios:

```text
nonmarine ingredient share = (1 − meal share − oil share) × conditional ratio
```

Generic ratios come from the illustrative Figure 5 profiles. For the three selected
Skretting groups, ratios transition linearly from the generic profile at 2015 to the
company profile at 2021. Choosing those transition years and transferring company
formulations are assumptions. This construction ensures mass balance; it does not
turn the resulting crop shares into observations.

The histories therefore combine changing adoption, efficiency and composition. For
example, the Chinese-fed-carp group changes from `p = 0.20, e = 2.0` in 1995 to
`p = 0.63, e = 1.7` in 2023: effective feed rises from 0.400 to 1.071 t/t despite
the lower conditional eFCR. These values are traceable in the
[group-year reference table](../tests/reference/v0.7/expected_group_year.csv).

### Filling coverage gaps

Default `coverage_policy = "expanded"` adds 140 positive species/item proxies in
23 assumption groups and six zero grow-out assignments. Previously populated
coefficients remain unchanged. The
[assumption table](../data/mappings/coverage_assumption_groups.csv) records each
2021 anchor, donor, recipe, sensitivity range and rationale; the
[override table](../data/mappings/coverage_species_overrides.csv) identifies every
affected item.

Most added groups scale their assumed 2021 e and p by a named donor's relative
historical changes, with p capped at one. Two related-group transfers copy donor
parameters directly. Recipes are fixed assumptions or annual donor recipes. For
example, Indian major carps use assumed `e = 2.0` and `p = 0.25` in 2021, giving
0.5 t/t. Feeding literature supports a positive pathway but does not establish
that global adoption rate. See [COVERAGE_ASSUMPTIONS.md](COVERAGE_ASSUMPTIONS.md).

## Applying the output in GCAM

The six-column files in `outputs/gcamdata/` contain `species_code`, `year`, and
`FeedCrops_per_t_output`, `fishmeal_per_t_output`, `fishoil_per_t_output`,
`OtherFeed_per_t_output`. Both `.csv` and `.csv.gz` carry GCAM comment metadata.
Keep the full table and provenance sidecar when distributing this compact export.

Join on **species code and year**, then calculate `ingredient demand = production ×
ingredient_per_t_output`. Do not multiply by e or p again. For a GCAM region and
technology, sum ingredient demands across its species/countries and divide by the
same mapped production total to obtain a production-weighted coefficient. A simple
average of species coefficients does not conserve feed demand. Treat zero-production
denominators explicitly; never silently convert unknown coefficients to zero.

`FeedCrops` includes crop-derived protein, starch and oils. `OtherFeed` includes
terrestrial animal ingredients, additives and unallocated components; specialty
assumptions can also include non-crop algae/minerals. It is not a bucket for missing
species or direct wet feed. Farm-made feeds, baitfish, fresh seaweed, fertilizers and
hatchery feeds remain outside this commercial-compound-feed account.

Mass is at the **ingredient/feed stage as reported**, with no common moisture
normalization. Fishmeal plus oil may be aggregated for a GCAM composite, but those
tonnes are not wet reduction-fish tonnes; whole-fish/trimming origins and processing
yields require separate accounting. Likewise, crop ingredients are not primary-crop
equivalents. Pricing, trade and processing conversions belong downstream.

## Validation and its interpretation

The supplied production panel covers 1973–2022. Although coefficients extend through
2023, there is no 2023 production application or verified 2023 model total. The
following values are recorded in the
[v0.7 reference results](../tests/reference/v0.7/expected_global_demand.csv) and
[benchmark input](../data/raw/benchmarks/commercial_feed_benchmarks.csv), in Mt:

| Year | Original 12-group subtotal | Tacon total | Relative difference | Added assumptions | Expanded total |
|---|---:|---:|---:|---:|---:|
| 2021 | 63.486 | 63.600 | −0.179% | 5.498 | 68.984 |
| 2022 | 66.510 | 66.740 | −0.345% | 5.967 | 72.476 |

**Tacon comparison is a dependent consistency check:** the calculation uses its p/e
framework. Small differences can reflect production vintages, group assignments and
source rounding. Agreement checks implementation and scope; it does not independently
validate crop recipes, regional adoption or the additional assumptions. Compare
Tacon with `tacon_comparable_feed_t`, not the expanded total.

External checks use the expanded total. The fixed-vintage
[Alltech 2023 report](https://www.alltech.com/sites/default/files/2023-02/Alltech-Agri-Food-Outlook-2023-EN-v7.pdf)
reports 51.510/52.914 Mt for 2021/2022; model estimates are 33.9%/37.0% higher.
China estimates are 31.064/32.746 Mt versus CFIA factory-feed production of
22.930/25.260 Mt reproduced in USDA FAS report CH2023-0045 (linked in the benchmark
input). These differences require reconciliation of production versus use, reporting
coverage and feeding assumptions; they are not dismissed or automatically calibrated
away. Country coefficients currently inherit global species/group parameters.

Computational checks separately test unique keys, parameter bounds, mass balance,
production conservation, source records and reference-result regression.
`validation/R_test_results.csv` records an actual run; reference fixtures themselves
are not an execution log. Run `Rscript run_all.R` to regenerate comparisons and checks.

Finally, `complete_feed_estimate = TRUE` means numeric coverage under the selected
commercial-feed assumptions. It does not establish empirical coverage of every
feeding system; `complete_all_external_feed_estimate` remains false. Expanded-total
ranges of 64.623–75.074 Mt (2021) and 67.744–79.085 Mt (2022) vary only the added
effective coefficients, holding original coefficients and recipe proportions fixed.
They are sensitivity scenarios, not confidence intervals for total uncertainty.
