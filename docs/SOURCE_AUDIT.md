# v0.7 current audit

See `COVERAGE_ASSUMPTIONS.md`, `coverage_evidence.csv`, and the source register. The numeric defaults
for added groups are explicitly analyst choices. Trials, mash-feed system FCRs and commercial
production-weighted coefficients are not interchangeable. Older unresolved-mapping statements
below describe the earlier releases and are superseded by the optional v0.7 coverage extension.

# Source audit carried forward from v0.6

## v0.6.1 update

This is an input and mapping update, not a fresh literature audit. All literature
transcriptions and group-year coefficient values are unchanged. The supplied historical
species panel replaces the previous fixed-2021 species-mixture approximation.
184 explicit mapping extensions are documented in `historical_species_mapping_additions.csv`
and assumption F21. Unknown species pathways and common names remain flagged.
The source-access limitations below describe the earlier v0.6 audit and are retained.


The evidence register is `data/raw/literature/source_register.csv`. Individual transcriptions
retain table/page references and source URLs. Prior input transcriptions are retained
without changing their published numerical values; selected harmonized estimates are
written to outputs, never back into raw files.

## Source roles

- **Tacon and Metian 2015 / Tacon et al. 2026:** p and eFCR estimates by broad group.
  Apply 2015 for 2000–2009 and 2026 for 2010–2023. These are authors' estimates, not an
  independent annual census. Table footnotes define p as commercial-feed coverage.
- **FAO Technical Paper 564 (2011):** historical p/eFCR and fishmeal/oil inclusion anchors.
  Tables 3 and 11. Later projected columns are not historical observations.
- **Naylor et al. 2021, Table 1:** 2017 p/eFCR metadata newly transcribed for source review;
  it does not override the newer Tacon p/eFCR series. The table splits wild/trimming meal,
  but oil is labelled wild. Milkfish trimming meal is blank. The supplied web copy's
  Table 1 was visually inspected. The July 2021 Publisher Correction was checked and concerns competing-interest
  disclosures (https://doi.org/10.1038/s41586-021-03736-4). The April 2021 Author
  Correction remains inaccessible; do not claim the complete correction audit is closed.
- **Tacon 2015 Figure 5:** undated broad illustrative ingredient profiles. Shrimp labelled
  shares sum to 90%; preserve remaining mass. Choosing 2015 as the transition start is a
  modeling assumption, not a date supplied for an observed formulation.
- **Skretting 2021 Table 15:** company averages for four product groups, retained from
  the existing curated transcription. Marine protein is not pure fishmeal. Use total
  fish oil for salmon/shrimp/tilapia and nonmarine conditional ratios only; do not transfer
  seabass/seabream composition to all marine fish. Full PDF access was unreliable during
  this update, so this carried-forward transcription was not freshly visually rechecked.
- **Aas 2022, Norway 2020 inventory:** raw national composition review only; no regional
  override in the final no-region coefficients. As-is inventory and dry-matter FCR bases
  must not be mixed with Tacon's unspecified-moisture feed definition.
- **Gephart 2021 SI, Table S5:** explicit zero FCR for silver and bighead carp supports
  the NONFED grow-out proxy. Priors are not a new observation of 2021 practices.
- **MacLeod/FAO626, Shen, Cottrell:** retained in the register and prior source files for
  review; not silently used as additional independent annual observations. Hypothetical
  diets are not observed historical diets. Regional FCRs need their own harmonization.

## External application checks added

**Alltech Agri-Food Outlook 2023:** global aquaculture feed 51.510 Mt (2021), 52.914 Mt
(2022). Fixed report vintage; retained exactly rather than mixing later revised totals.
The primary report's parsed/indexed table was accessible, although later PDF fetches and
screenshots were unreliable. Source: https://www.alltech.com/sites/default/files/2023-02/Alltech-Agri-Food-Outlook-2023-EN-v7.pdf

**USDA FAS CH2023-0045, Grain and Feed Annual, China, 6 April 2023, Table 2:** CFIA aqua
feed production of 21.24 Mt (2020), 22.93 Mt (2021), 25.26 Mt (2022). Primary official
report text inspected; screenshot endpoint failed. USDA reproduces the CFIA figures,
not an independent USDA aquafeed survey. Source URL is in the benchmark CSV.

Tacon's total-feed time series is retained as an internal consistency benchmark, not an
independent accuracy test. No benchmark is used to adjust eFCR, p or recipes.

## Uncertainty not resolved by this release

The strongest gaps are early commercial-feed adoption; incomplete feed-pathway coverage; crop/terrestrial animal composition outside
three company proxies; total oil where only wild oil is reported; and country variation
in feeding practices. Company and illustrative profiles are not global production-weighted
surveys. No invented confidence intervals or regional calibration multipliers are supplied.
