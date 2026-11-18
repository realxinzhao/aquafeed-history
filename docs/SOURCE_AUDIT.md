# v0.7 current audit

See `COVERAGE_ASSUMPTIONS.md`, `coverage_evidence.csv`, and the source register. The numeric defaults
for added groups are explicitly analyst choices. Trials, mash-feed system FCRs and commercial
production-weighted coefficients are not interchangeable. Older unresolved-mapping statements
below describe the earlier releases and are superseded by the optional v0.7 coverage extension.

## IFFO and Glencross 2024 review

Reviewed 18 November 2026. The previous register omitted IFFO; no documented exclusion
decision was found. It is now recorded as review evidence, alongside the linked
[Glencross et al. (2024) paper](https://doi.org/10.1080/23308249.2024.2337426)
([institutional full text](https://dspace.stir.ac.uk/handle/1893/36800)). These two
records belong to the same evidence family and are not independent confirmations.

The [IFFO eFCR page](https://www.iffo.com/efcr-data) reports 2000, 2010 and 2020 values
for eight parent groups, two nested subsets and a total. It describes industry FCRs
and expert-informed regional fed-volume estimates, but supplies no separate
`commercial_feed_share` table. Its prose gives aggregate endpoints 0.81/0.732 while
its table gives 0.75/0.71. Retain this discrepancy in any future transcription.

Glencross Table 2 (printed p.549; PDF p.6) matches the webpage table. Table 3 (p.550;
PDF p.7) adds fishmeal/oil inclusion and aggregate origin shares; Table 1 (p.548)
provides reduction yields. The relevant table pages were visually inspected. These
are useful candidate evidence, but not a full crop/terrestrial-animal recipe.

For this project's annual history, Tacon remains more directly usable because its
selected tables distinguish conditional eFCR from commercial-feed share. Do not
insert IFFO sector eFCRs into the conditional `efcr` field and multiply by our share
without first establishing the denominator: the public sources do not resolve that
decomposition sufficiently. Comparing against effective `commercial_feed_per_t_output`
is a hypothesis to investigate, not an established equivalence.

Use [IFFO's species definitions](https://www.iffo.com/species-categories-explained)
before comparing groups: its cyprinids include silver/bighead and Indian major carps;
marine finfish include milkfish; eels include Asian swamp eel. Shrimp and Atlantic
salmon are subsets of broader rows and must not be counted twice. A future comparison
needs a species crosswalk and production weights. Shared FAO inputs and unspecified
industry-source overlap also prevent assuming statistical independence.

This addition changes bibliography and review guidance only. No IFFO numerical rows
are ingested into stage 1 or selected as default coefficients. Only the register's
checksum in the default-input manifest is refreshed, preserving the existing numeric
regression checks and fixtures.

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
