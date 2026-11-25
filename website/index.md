---
hide:
  - toc
---

<div class="af-eyebrow">Research documentation</div>

# Aquafeed coefficients for GCAM

<div class="af-intro" markdown>
Commercial-feed ingredients per tonne of aquaculture output, with sources and
assumptions you can trace.
</div>

Aquafeed history is a reproducible R project for connecting aquaculture production
to feed demand in GCAM. It combines literature estimates of feed conversion and
commercial-feed adoption with ingredient profiles, explicit species mappings and
documented assumptions.

<div class="af-actions" markdown>
[Get started](quickstart.md){ .md-button .md-button--primary }
[Read the methods](methods.md){ .md-button }
</div>

## What the dataset provides

| Dimension | Default coverage |
|---|---|
| Species/items | 778 codes in the applied mapping |
| Coefficient years | 1973–2024; 40,456 species-year rows |
| Feed ingredients | FeedCrops, fishmeal, fish oil and OtherFeed |
| Geography | Common species-year coefficients; no regional coefficient dimension |
| Mass basis | Ingredient/feed mass as reported; no common moisture normalization |
| Production application | FAO FISHSTAT data processed by gcamfaostat; species histories for 1973–2024 |

Most species inherit coefficients from broader feeding groups. The annual table
combines reported estimates, interpolation, transfers and analyst assumptions; its
resolution does not imply an independent measurement for every species and year.
The [methods guide](methods.md) explains these distinctions.

The 2024 coefficient vector holds the finalized 2023 coefficients forward. This is an
explicit modeling assumption, not a 2024 literature estimate. New production codes
inherit a feed group only when the exact ISSCAAP group has a unanimous assignment;
conflicting cases remain unestimated.

## Generate the GCAM inputs

Open `AquafeedHistory.Rproj` and run:

```r
source("scripts/export_gcamdata_coefficients.R")
```

This creates compact CSV and gzip inputs with GCAM metadata headers, plus a full
table containing coefficient and mapping information. Calculation and export use
base R. See the [quickstart](quickstart.md) for file paths and application examples.

## Follow the evidence

| Your question | Start here |
|---|---|
| Which literature supplies the coefficients? | [Methods and source roles](methods.md#source-roles), then the [source register](sources.md). |
| How are missing species and years filled? | [Coverage assumptions](coverage.md) and [historical construction](methods.md#annualization-and-composition). |
| How should I apply the coefficients in GCAM? | [Quickstart](quickstart.md#apply-the-coefficients) and [GCAM interpretation](methods.md#applying-the-output-in-gcam). |
| How well do estimates agree with the literature? | [Benchmark interpretation](methods.md#validation-and-its-interpretation) and [execution checks](validation.md). |
| What remains uncertain? | [Source audit](source-audit.md) and [publication priorities](roadmap.md). |

## Read the validation at the right scale

The original 12-group subtotal closely reproduces Tacon's feed estimates for 2021
and 2022. Because those parameters help construct the dataset, this is a
source-consistency check. Expanded coverage assumptions are reported separately,
and external Alltech/CFIA discrepancies remain visible. [See the comparisons and
their limitations](methods.md#validation-and-its-interpretation).

For GCAM use, the effective ingredient coefficients already include commercial-feed
share. Fishmeal and oil are processed ingredient tonnes; converting them to wet
reduction-fish demand requires a separate processing assumption.
