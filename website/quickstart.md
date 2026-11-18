# Get started

This guide takes you from the source repository to GCAM inputs and historical
demand checks. The calculation and export require **base R**, with no additional
R packages or external API access. Native R execution is documented in the
[validation record](validation.md).

## Open the project

Clone the repository, or download its ZIP from GitHub:

```sh
git clone https://github.com/realxinzhao/aquafeed-history.git
cd aquafeed-history
```

Open `AquafeedHistory.Rproj` in RStudio. For terminal commands, start in the project
directory. The curated source tables and production inputs are included in the
repository.

## Generate coefficients

In RStudio:

```r
source("scripts/export_gcamdata_coefficients.R")
```

The terminal equivalent is `Rscript scripts/export_gcamdata_coefficients.R`.
This builds the source-evidence table and annual coefficients without reading the
production panel.

| Location | Product |
|---|---|
| `outputs/gcamdata/` | `aquaculture_feed_coefficients_species_year.csv` and `.csv.gz`: compact GCAM inputs. |
| `outputs/02_coefficients/` | Full species-year coefficient CSV, `coefficient_provenance_group_year.csv`, and `species_mapping_applied.csv`. |
| `outputs/01_sources/` | Literature evidence retained separately from the filled coefficients. |

The two compact formats contain the same six columns:

| Column | Meaning |
|---|---|
| `species_code` | FAO species/item code, stored as character. |
| `year` | Integer coefficient year. |
| `FeedCrops_per_t_output` | Crop-derived ingredients per tonne of total output. |
| `fishmeal_per_t_output` | Fishmeal ingredients per tonne of total output. |
| `fishoil_per_t_output` | Fish-oil ingredients per tonne of total output. |
| `OtherFeed_per_t_output` | Other commercial-feed ingredients per tonne of total output. |

Both include comment metadata and `Column types: cinnnn`, followed by CSV column
names. Missing coefficients remain blank; documented zero inputs remain zero.
Copy one format into your gcamdata input directory, and retain the full table and
provenance files with any archived release. Repeated exports replace the files.

For an ordinary R read outside gcamdata:

```r
coeff <- read.csv(
  "outputs/gcamdata/aquaculture_feed_coefficients_species_year.csv.gz",
  comment.char = "#",
  colClasses = c("character", "integer", rep("numeric", 4)),
  na.strings = ""
)
```

## Apply the coefficients

Join production to coefficients using **species code and year**. For each ingredient:

```text
effective coefficient = commercial_feed_share × efcr × ingredient_share
ingredient demand     = production × effective coefficient
```

The exported `_per_t_output` fields already contain this effective coefficient.
**Do not multiply by eFCR or commercial-feed share again.** The four ingredient
coefficients sum to total commercial-feed input per tonne of output.

For a GCAM region/technology, first sum ingredient demand across its mapped
species/countries, then divide by the same production total:

```text
regional coefficient = sum(production × coefficient) / sum(production)
```

Handle zero-production denominators explicitly. Preserve unknown values for review;
silently replacing them with zero would lower estimated demand. See the
[methods guide](methods.md#applying-the-output-in-gcam) for scope and mass-basis details.

## Reproduce demand and checks

```r
source("run_all.R")
```

This also applies coefficients to the supplied 1973–2022 species histories and
generates global, country and country-technology results under
`outputs/03_demand_checks/`. The pipeline writes `validation/R_test_results.csv`
and records configuration, checksums and R session information in `outputs/run_info/`.
Coefficients extend through 2023, but the supplied production panel ends in 2022.

## Configuration

Edit [config/default.R](https://github.com/realxinzhao/aquafeed-history/blob/main/config/default.R)
before running:

| Setting | Default and alternative |
|---|---|
| `gcamdata_formats` | `c("csv", "csv.gz")`; select one format, or `character()` to disable compact exports. |
| `coverage_policy` | `"expanded"` includes documented gap-filling assumptions; `"original"` retains the earlier incomplete scope. |
| `early_policy` | `"hold"` extends 1995 parameters backward; `"blank"` leaves early fed coefficients missing. |

## Common interpretation questions

**What is OtherFeed?** Terrestrial animal ingredients, additives and unallocated or
specialty components within commercial feed. It does not represent unestimated
species or direct wet feed.

**Can meal and oil be summed as ReductionFish?** They can form an ingredient-stage
composite. Wet-fish demand still needs separate yields and whole-fish/by-product
accounting.

**Are these dry-matter coefficients?** Mass follows the source's reported
ingredient/feed basis. No common moisture correction or conversion to primary crops
is applied. Keep any downstream conversion explicit.

**Does complete coverage mean all feed is measured?** It means numerical coverage
under the selected commercial-feed assumptions. Direct wet feed, farm-made
supplements and hatchery inputs remain outside this account. Review the
[coverage assumptions](coverage.md) before interpreting totals.
