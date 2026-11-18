# Priorities for a publishable aquafeed coefficient dataset

The defensible contribution is a **reproducible, literature-constrained reconstruction
of commercial aquafeed coefficients by species/item and year**, with explicit mapping
and filling assumptions. The export contains species-level assignments; it does not
contain independently measured feed conversion ratios for every species and year.
Publication should make that distinction prominent and quantify which assumptions
drive the results. The priorities below are proposed research improvements, not
changes already made to the coefficients.

## 1. Make the evidence behind each estimate easy to assess

The existing [source register](../data/raw/literature/source_register.csv),
[coverage assumptions](../data/mappings/coverage_assumption_groups.csv) and group-year
provenance provide a useful foundation. Add a consistent evidence classification for
each parameter: reported group estimate, national/company inventory, trial evidence,
taxonomic transfer, interpolation, endpoint hold, or analyst assumption. Summarize
both production and estimated feed by evidence class and year. Numeric coverage
alone cannot show evidence quality.

Keep conditional eFCR (`e`) separate from the commercial-feed adoption share (`p`)
and the effective coefficient (`a = p * e`). Aggregate feed/output observations
identify `a`; they do not uniquely identify `p` and `e`. For example, the Indian-carp
anchor currently sets `e = 2`, `p = 0.25`, and `a = 0.5` as documented assumptions.
[FAO 578](https://www.fao.org/4/i3146e/i3146e.pdf) concerns particular Indian farming
systems and feed practices; it does not supply that global adoption share. Seek
separate adoption evidence before interpreting changes in `p` as measured
intensification. Retain trial FCR, mortality treatment, grow-out stage, feed type,
feed moisture and output basis wherever a study reports them.

**Useful result:** a compact evidence matrix and a ranked list of assumptions by
their contribution to global and regional feed demand.

## 2. Audit high-impact differences in farming systems

Keep the requested species-year table as the common baseline. Evaluate a small,
separately versioned country/system adjustment layer where evidence supports it.
Prioritize commercial-feed adoption before assuming the same feeding system for
all producers of one species.

A concrete first case is `RCW` (red swamp crawfish), currently mapped to the common
freshwater-crustacean coefficients. The [LSU Crawfish Production Manual, chapters 5
and 9](https://www.lsuagcenter.com/NR/rdonlyres/3AD14F0D-567D-4334-B572-D55D1C55A1F1/34429/pub2637CrawfishProductionManualLOWRES.pdf)
describes southern US production relying on forage-supported food webs, with
prepared feeds uncommon. This supports auditing the global-to-US transfer; it does
not establish a universal zero coefficient or a measured 2021 adoption rate.
Document any adjustment's geography, period, system coverage and uncertainty, and
show its effect before adopting it. Indian carp and other mixed natural-food,
supplementary-feed and compound-feed systems deserve the same distinction.

**Useful result:** a few well-supported regional case studies, with the unadjusted
baseline retained for comparison.

## 3. Strengthen historical reconstruction and ingredient evidence

The default pre-1995 endpoint hold, donor-based histories for added groups and
company-to-global recipe transfers are explicit construction rules. Test credible
alternatives, especially earlier commercial-feed adoption trajectories; do not
treat annual interpolation as new annual information. Report sensitivity by period,
and consider presenting 1973–1994 separately from years with stronger anchors.

Resolve the remaining fish-oil boundary: [Naylor et al. (2021), Table
1](https://doi.org/10.1038/s41586-021-03308-6) reports wild-fish oil, while most model
applications require total oil. Close the correction/transcription audit recorded
in [SOURCE_AUDIT.md](SOURCE_AUDIT.md), seek trimming-oil evidence, and retain whole-fish
and by-product origins separately where supportable. Extend crop/terrestrial-animal
recipe evidence beyond illustrative profiles and three transferred company averages.
For early periods, explicitly test the modern recipe allocations already flagged
in the source register. Maintain ingredient-as-reported mass until a separately
documented moisture or processing conversion is applied.

**Useful result:** bounded historical and recipe scenarios with clear provenance,
rather than unsupported precision in early years.

## 4. Add independent checks with matched boundaries

Retain Tacon comparisons as source-consistency checks: its parameters help construct
the estimates, so close agreement does not independently validate them. Continue to
show the original 12-group subtotal and the coverage extension separately.

Use independent national farm-feed use or ingredient inventories where possible.
The [Norwegian salmon inventory](https://doi.org/10.1016/j.aqrep.2022.101316) is a useful
national case; match its as-is ingredient boundary before comparing it with modeled
compound-feed mass. For the existing Alltech and CFIA comparisons, explain factory
production versus domestic consumption, feed trade, stocks, product scope and report
vintage. The [benchmark input table](../data/raw/benchmarks/commercial_feed_benchmarks.csv)
already records these differences. A regional ratio between wet fish assigned to
feed and aquaculture meal/oil use is not a processing-yield estimate.

**Useful result:** a boundary-reconciliation table and residuals by country/group,
with validation data kept separate from any data used for subsequent calibration.

## 5. Expand uncertainty and freeze a reproducible release

Current low/high bounds vary only the added groups' effective coefficients while
holding the original coefficients and recipe proportions fixed. Extend sensitivity
to adoption, eFCR, ingredient shares and mappings, preserving valid shares and
correlations. Use documented scenarios where probability distributions are not
justified; label these as scenarios, not statistical confidence intervals.

For release, retain successful native-R workflow logs and numerical/export checks;
record the configuration, input checksums, R version and exact Git commit with each
output. Update obsolete provenance descriptions, provide complete citations and
`CITATION.cff`, and choose code and data licensing appropriate to the source terms.
Archive a tagged release and derived tables with a persistent identifier. A formal
installable R package is optional: a small, tested research project can be sufficient.

The most valuable next research work is the evidence-weighted audit, targeted
farming-system checks and independent comparisons. Additional software structure
should support those tasks.
