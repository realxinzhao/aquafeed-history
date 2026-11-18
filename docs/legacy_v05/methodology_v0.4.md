# Aquaculture feed coefficients: historical extension v0.4

**Prepared 16 November 2026. Coverage of coefficients: 1975–2023. Actual production run: 2021 only.**

This is a reproducible, source-documented **commercial compound-feed** estimation framework for GCAM. It is not a measured global feed-use panel and does not yet cover every feeding pathway. The 1975–1994 coefficients are an explicitly optional backcast. No historical production volumes were inferred from the supplied 2021 file.

## Main findings of the source audit

The previous v0.3 total-feed calculation already used **Tacon et al. (2026), Table 3**, for the 2021 commercial-feed share and eFCR. Tacon & Metian (2015) mainly supplied the **generic nonmarine ingredient ratios**. Its Figure 5 is not a 2021 survey. The previous marine composition used **Naylor et al. (2021), Table 1, whose data year is 2017**. The new framework preserves a reference case that exactly reproduces v0.3 while adding a temporal axis, older historical marine estimates, and separate newer composition sensitivities.

**FAO Technical Paper 564 (Tacon, Hasan & Metian, 2011)** is the most useful historical addition. Table 3 supplies commercial-feed shares and eFCR estimates beginning in 1995; Table 11 supplies group-level fishmeal and fish-oil inclusion estimates for 1995, 2000, 2005, 2007 and 2008. Its 2010/2015/2020 entries include projections and are not used as realized history. Table 10 also reports country-specific inclusion ranges, but these are not complete recipes and their midpoints cannot simply be normalized into a mass balance.

**Skretting's 2021 report, Table 15 (p.57)** provides company-reported full ingredient categories for salmon, shrimp, tilapia and seabass/seabream. It improves the provenance of recent nonmarine mix assumptions for the first three groups. A company portfolio is not a global production-weighted average; therefore these values are an explicit sensitivity, not an unquestioned replacement. The seabass/seabream profile is retained as a raw source but is not assigned to all marine finfish.

**Aas et al. (2022)** provide a near-complete Norwegian Atlantic-salmon feed-ingredient inventory for 2020. An optional national/species override transfers its composition shares to 2020–2023. Only 2020 is an inventory year; later years are a carry-forward assumption. Its marine-protein category includes 8,155 t of krill meal: this is removed from fishmeal and classified as OtherFeed. Its eFCR is not substituted for Tacon because ingredient-input/as-is/dry-feed and finished-feed boundaries differ.

**Gephart et al. (2021)** is valuable for empirical system/regional variation, but its studies published during 1995–2020 are not an annual time series. Publication dates must not be treated as farm measurement dates; replicated farms, imputed entries, pseudocounts and live-versus-edible-weight conversions require care before aggregation. **MacLeod et al. (2019/2020)** explicitly model regional FCRs and commercial/noncommercial rations. The FAO626 Table 4 regional coefficients are extracted here for review, not automatically mapped into GCAM regions. **Shen et al. (2024)** reuses MacLeod/Gephart feed information; it is not independent evidence for all coefficients. **Cottrell et al. (2025)** supplies explicitly hypothetical salmon diets, not observations for 2025 or an historical recipe panel. **Skretting2023** combines fish oil and algal oil, so its broad aquatic category cannot be copied directly into ReductionFish.

See `sources/source_register.csv` for every source, table/page, URL, data years, evidence type, role and limitations. Published raw rows, including unused projections, are retained separately from selected coefficients.

## Calculation and units

For reporting area r, species/item s and year t, with literature group g(s):

```
commercial_feed[r,s,t] = production_live[r,s,t] * commercial_share[g,t] * eFCR[g,t]
FeedCrops = commercial_feed * crop_ingredient_mass_share
ReductionFish = commercial_feed * (fishmeal_share + fishoil_proxy_share)
OtherFeed = commercial_feed - FeedCrops - ReductionFish
```

All quantities are tonnes. Production is the input's Q_tlw live weight. FeedCrops is **processed crop ingredient mass**, not whole-crop or primary-equivalent biomass. ReductionFish is **processed meal/oil mass**, not raw wet fish. No 25% yield or fourfold fish conversion is applied. Fishmeal and fish oil are retained separately internally. An upstream reduction sector must handle the joint-product yields without double counting and distinguish whole-fish from processing-byproduct sources.

Tacon does not specify a uniform moisture basis for all reported commercial-feed eFCRs. Do not relabel all coefficients as dry matter. Aas2022 reports 1.35 on an ingredient-as-is basis versus 1.25 on dry matter; its reported ingredient input also differs from feed traded. This update uses national composition fractions only, keeping the Tacon total-feed equation unchanged. Applying ingredient shares to total commercial-feed mass is a documented approximation without a separate milling/moisture loss model.

The coefficient `commercial_share * eFCR` is relative to **all output in the literature group**. It is not the FCR for a fed-only GCAM technology. Do not apply the share a second time to an output series already restricted to commercially fed production. Grow-out nonfed assumptions do not imply zero hatchery inputs.

## Annual coefficients: rules and evidence

| Period/component | Selected treatment | Interpretation |
|---|---|---|
| 1975–1994 | Optional hold of 1995 p/eFCR/FM/FO; separate blank version supplied | Backcast sensitivity, not calibrated history |
| 1995 | FAO564 Table3 p/eFCR and Table 11 marine inclusion | Published author estimates |
| 1996–1999 total feed | Linear p and eFCR interpolation from 1995 to Tacon2015's 2000 values | Constructed annualization |
| 2000–2009 total feed | Tacon2015 annual estimates | Published estimates, not direct observations |
| 2010–2023 total feed | Tacon2026 annual estimates | Preferred revised vintage |
| 1995–2008 marine mix | FAO564 anchor years; linear interpolation in intervening years | Estimates plus interpolation |
| 2009–2016 marine mix | Linear between 2008 and Naylor2017 | Definition caveat for fish oil |
| 2017 marine mix | Naylor2021 Table 1 | Published synthesis, data year 2017 |
| 2018–2023 marine mix | Hold 2017 shares | No invented modern downward trend |
| Nonmarine reference | Tacon2015 conditional ratios frozen over time | Explicit synthetic allocation |
| Recent nonmarine sensitivity | Skretting2021 conditional ratios for three groups; generic ratios otherwise | Company-to-global and temporal transfer |
| Norway salmon override | Aas2020 composition in 2020, held 2021–2023 | National observed mix plus carry-forward |

Interpolations operate on parameters, not on observed feed quantities; the product is recomputed. Nonmarine shares are conditional on the remaining mass after assigning FMFO, so both the total feed balance and marine trajectory are preserved. Annual source brackets, source IDs/URLs, evidence labels and early-backcast flags are included on each group-year row. There are **588 rows: 12 groups × 49 years**. Exactly 240 rows precede 1995. The no-early-backcast table leaves those numeric estimates blank; this does not make later proxies or interpolations into observations.

The earlier source's mixed freshwater/diadromous category cannot be perfectly divided retrospectively. The separate miscellaneous diadromous/sturgeon group uses an explicit earlier-group proxy before 2010 and an ODF/miscellaneous-freshwater marine-mix proxy. Source-vintage changes and changing species mixtures can create apparent coefficient changes; no automatic smoothing or monotonic improvement is imposed.

## Ingredient cases: what changes, what does not

`historical_reference` reproduces the previous 2021 synthetic H allocation. The marine amount is independently determined; the nonmarine balance is allocated to crops, land-animal ingredients, additives and unallocated material according to relative Figure 5 weights. The printed shrimp labels sum to 90%, not 100%; the missing 10 percentage points remain unallocated rather than being invented as crops.

`recent_nonmarine` changes only the relative nonmarine categories for salmon, marine shrimp and tilapia using the **2021** Skretting table. The raw reported profiles sum to approximately 100% because of rounding. Only their nonmarine conditional ratios are normalized. These are not copied as complete global diets, and their broad marine-protein category is not equated to fishmeal.

`--norway-override` adds the nationally supported 2020 composition for Norway (FAO reporting area 162), Atlantic salmon (SAL), in 2020–2023. The override is optional and does not affect total commercial feed. It includes both whole-fish and trimming fish oil and explicitly excludes krill from FMFO.

None of these constitutes a verified global crop-only total. The recent profiles reduce reliance on a generic 2015 diagram for selected groups, but uncertainties remain substantial for carps, catfishes and miscellaneous groups.

## Important limitations discovered in the review

**Fish oil is not fully harmonized.** Naylor Table 1 labels its oil column as oil from wild fish; it does not supply a separate trimming-oil quantity. The reference calculation, like v0.3, uses this as an oil-total proxy for compatibility. This can understate true total FMFO. Trimming-oil origins remain blank, never claimed as measured zero. The 2009–2016 oil interpolation therefore bridges definitions as an explicit approximation. National inventory overrides are better where available.

**Early crop/animal splits are weak.** FAO564's executive summary estimates land-animal byproducts below about 1% of global aquafeed around 2008. Applying the later generic Figure 5 or company 2021 nonmarine ratios backward can conflict with that aggregate evidence. The provided crop/animal trajectories are structural sensitivities, not validated early-period history. Use the total-feed and marine series with their flags; do not interpret a smooth crop line as observed substitution. An early regional-ration reconstruction is still needed for strong 1975–2008 land-use claims.

**Corrections review is incomplete.** Two Naylor2021 corrections were identified (10.1038/s41586-021-03508-0 and 10.1038/s41586-021-03736-4). Their full text could not be fetched. Values were checked against the accessible main-article copy, but correction reconciliation remains an explicit audit flag. Some web-PDF image renderings were unavailable; their parsed tables were used with arithmetic checks. FAO564 tables were also visually inspected.

**Regional coefficients are not identical in reality.** FAO626 Table 4 contains meaningful differences, but it describes broad regions/groups and a dry-feed definition. Adding its eFCRs blindly to global commercial-feed shares would create a new mixture of boundaries. The review-only regional table is a starting point for controlled overrides, not a fitted regional panel.

**Coverage remains partial.** Indian major carps outside the Chinese-fed-carp subset and other unsupported feed pathways remain unestimated, not nonfed. The existing 547-code crosswalk retains name/proxy flags. Additional historical codes are stopped by default and must be classified explicitly. A country’s annual species composition is taken from each year’s own supplied production, not from the 2021 mixture.

## 2021 demonstration and comparison

All three cases use the same 2021 production observations and the same total-feed coefficients. Values below are Mt, rounded for display; CSVs retain precision.

| Case | Commercial feed | FeedCrops | ReductionFish proxy | OtherFeed |
|---|---:|---:|---:|---:|
| Historical reference (reproduces v0.3) | 63.486 | 44.112 | 4.914 | 14.461 |
| Recent nonmarine sensitivity | 63.486 | 46.353 | 4.914 | 12.219 |
| Recent nonmarine + Norway composition | 63.486 | 46.556 | 4.995 | 11.935 |

These are modeled subtotals over the supplied coverage. Core production is 126.224 Mt; 20.249 Mt has unresolved feeding pathways. The previous finding that 255 positive aggregate-production cells were absent from the species file is unchanged. They are neither filled nor scaled. `complete_scope_feed_t` is blank for incomplete aggregates. Tacon's 63.60 Mt 2021 benchmark is not forced onto the data, and its 69.42 Mt 2023 benchmark is not used as a 2021 target.

## Major trends to interpret

The source series broadly show increased use of commercial diets, lower or flat eFCRs for many groups, and lower fishmeal inclusion. These changes can offset each other. For Chinese fed carp, the selected commercial share rises from 20% in 1995 to 63% in 2023 while eFCR moves 2.0 to 1.7; their product rises 0.40 to 1.071 t feed/t total group output. For tilapia the product rises 1.40 to 1.666, despite lower eFCR. For shrimp it falls 1.50 to 1.32, and for salmon 1.50 to 1.30. These reflect published group estimates and source-vintage changes, not a causal decomposition of farm technology.

A more comparable marine indicator is **fishmeal alone**, adding wild and trimming meal at the 2017 endpoint: carp 10%→1%, tilapia 10%→2%, shrimp 28%→10%, salmon 45%→12%, marine fish 50%→14% from 1995 to 2017. Fish-oil comparisons need the definition warning above. Aas2022 also notes a small increase in eFCR from 2016 to 2020, so do not impose automatic annual efficiency improvement.

An absolute increase in commercial-feed or crop demand cannot be calculated from coefficients alone. It also depends on the missing historical country/species production panel. The workbook trend display is a **coefficient plot**, not a fabricated 1975–2023 feed-consumption history.

## Reproduce and extend

Python 3.9+; only the standard library is required for the CSV pipeline.

```bash
python build_coefficients.py
python process_production.py --input inputs/species_2021.csv --output outputs/reference_2021
python process_production.py --recipe recent_nonmarine --output outputs/recent_nonmarine_2021
python process_production.py --recipe recent_nonmarine --norway-override --output outputs/recent_with_Norway_2021
python tests/test_pipeline.py
```

For an actual multi-year file with the same columns:

```bash
# Do not estimate pre-1995 feed until an early-history assumption is chosen:
python process_production.py --input my_species_history.csv --early-policy blank --output outputs/history
# Explicit endpoint-backcast sensitivity instead:
python process_production.py --input my_species_history.csv --early-policy hold --output outputs/history_early_hold
```

Unknown species codes cause a useful validation error. `--allow-unmapped` may be used to continue with those quantities explicitly unestimated. Never change a Capture label to Aquaculture without replacing the production data. Every aggregation key includes year. The script rejects duplicates, negative/nonfinite quantities, inconsistent species/ISSCAAP mappings, unsupported units and years outside 1975–2023.

`example_load.R` runs the same pipeline from RStudio and reads the results while preserving country codes as character. The companion `aquafeed_historical_coefficients_v0_4.xlsx` is also included in this package; CSVs plus the scripts are the reproducible source of truth. Workbook formulas recalculate the displayed coefficient products, while the pipeline rebuilds the tables from the raw anchors.

## Package layout

- `sources/`: extracted facts, legacy raw Tacon tables, named source register and source limitations.
- `coefficients/`: annual reference/alternative shares and input-output coefficients; no-backcast version; national override.
- `inputs/`: original species2021 data and retained explicit species/GCAM crosswalks.
- `outputs/`: three 2021 runs, country/technology/year and species estimates, coverage flags, source-parameter trend checkpoints and comparison.
- `documentation/`: 22 explicit assumptions, data dictionary, evidence counts, arithmetic diagnostics and unchanged production-coverage audit.
- `tests/`: multi-year synthetic smoke tests and reference reproduction checks. Synthetic quantities are used only in temporary test fixtures and are not distributed as historical outputs.

**Next methodological priority:** obtain comparable total fish-oil inclusion including trimmings, and harmonize historical regional noncommercial and crop/animal feed rations. Meanwhile, use the two composition cases as sensitivities and keep pre-1995 backcasts explicitly separate from the better-supported 1995–2023 coefficient series.
