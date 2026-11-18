# Coverage extension assumptions — v0.7

All numbers in the table are **selected 2021 modeling assumptions** unless an explicit original-group transfer is stated. Source FCR ranges are contextual evidence, not estimates of global uptake. Numerical values may be edited in the CSV without changing code.

## 2021 anchors

| ID | Group | Conditional eFCR | Assumed p | Effective t/t | Low | High | Recipe |
|---|---|---:|---:|---:|---:|---:|---|
| C01 | Indian major carps | 2 | 0.2500 | 0.5 | 0.1 | 1 | fixed assumed mix |
| C02 | Other cyprinids | 2 | 0.2500 | 0.5 | 0.1 | 1 | borrow Chinese fed carps |
| C03 | Carassius extension | 1.7 | 0.6100 | 1.037 | 0.5185 | 1.5555 | borrow Chinese fed carps |
| C04 | Misc diadromous | 1.8 | 0.2778 | 0.5 | 0.1 | 1 | borrow Miscellaneous diadromous fish and sturgeons |
| C05 | Trout like | 1.3 | 1.0000 | 1.3 | 0.65 | 1.95 | borrow Trout |
| C06 | Smelts | 1.6 | 0.0625 | 0.1 | 0 | 0.5 | borrow Milkfish |
| C07 | Shads | 1.6 | 0.0625 | 0.1 | 0 | 0.5 | borrow Milkfish |
| C08 | Marine crabs | 1.8 | 0.2778 | 0.5 | 0.1 | 1.2 | borrow Marine shrimp |
| C09 | Lobsters | 2 | 0.1000 | 0.2 | 0.02 | 0.8 | borrow Marine fishes |
| C10 | Other marine crustaceans | 2 | 0.1500 | 0.3 | 0.05 | 1 | borrow Marine shrimp |
| C11 | Brine shrimps | 1.5 | 0.0667 | 0.1 | 0 | 0.5 | fixed assumed mix |
| C12 | Abalones | 2 | 0.2500 | 0.5 | 0.1 | 1 | fixed assumed mix |
| C13 | Other gastropods | 2 | 0.1500 | 0.3 | 0.05 | 0.9 | fixed assumed mix |
| C14 | Predatory gastropods | 2 | 0.1500 | 0.3 | 0.05 | 0.9 | fixed assumed mix |
| C15 | Unspecified molluscs | 2 | 0.0500 | 0.1 | 0 | 0.5 | fixed assumed mix |
| C16 | Softshell other turtles | 1.5 | 0.6000 | 0.9 | 0.3 | 1.5 | borrow River eels |
| C17 | Green turtle | 2 | 0.0500 | 0.1 | 0 | 0.5 | fixed assumed mix |
| C18 | Frogs | 1.8 | 0.5000 | 0.9 | 0.3 | 1.8 | fixed assumed mix |
| C19 | Sea cucumbers | 2 | 0.0500 | 0.1 | 0 | 0.5 | fixed assumed mix |
| C20 | Sea urchins | 2 | 0.0500 | 0.1 | 0 | 0.5 | fixed assumed mix |
| C21 | Tunas | 3 | 0.0333 | 0.1 | 0 | 0.5 | borrow River eels |
| C22 | Cephalopods | 2 | 0.0500 | 0.1 | 0 | 0.5 | borrow River eels |
| C23 | Other invertebrates | 2 | 0.0500 | 0.1 | 0 | 0.5 | fixed assumed mix |

## Evidence and limitations by group

### C01 — Indian major carps
Rounded 2 t/t conditional eFCR and assumed p=0.25 at 2021. Source demonstrates feeding, not these global values. 95% crop is an assumed crop-dominant commercial recipe.

Time donor: **Chinese fed carps**. Parameter rule: `anchor_scaled`. Bran/oilcake farm-made supplementary feed remains unquantified; may be material.
Sources (supporting context, not necessarily these numbers):
- FAO578_2013: Ramakrishna, Shipton and Hasan (2013). Feeding and feed management of Indian major carps in Andhra Pradesh, India. FAO Technical Paper 578. https://www.fao.org/4/i3146e/i3146e.pdf
- FAO_Mrigal: FAO Cultured Aquatic Species Information Programme. Cirrhinus mrigala. https://www.fao.org/fishery/docs/CDrom/aquaculture/I1129m/file/en/en_mrigalcarp.htm
Assumed shares [FeedCrops, fishmeal, fishoil, OtherFeed]: 0.95, 0.01, 0, 0.04.

### C02 — Other cyprinids
Conservative positive effective input for named or unspecified carp-group items; p=0.25 and FCR=2 are assumptions. Donor recipe and relative historical trend only.

Time donor: **Chinese fed carps**. Parameter rule: `anchor_scaled`. Not quantified; outside commercial-feed boundary
Sources (supporting context, not necessarily these numbers):
- FAO578_2013: Ramakrishna, Shipton and Hasan (2013). Feeding and feed management of Indian major carps in Andhra Pradesh, India. FAO Technical Paper 578. https://www.fao.org/4/i3146e/i3146e.pdf
- Tacon2026: Tacon et al. (2026), Global Aquaculture and Aquafeed Production Update https://doi.org/10.1080/23308249.2025.2568830
- Tacon2015: Tacon & Metian (2015), Feed Matters https://doi.org/10.1080/23308249.2014.987209

### C03 — Carassius extension
Prussian carp transferred to Carassius feeding-group proxy; central p and e copy donor exactly. Low/high vary effective intensity only.

Time donor: **Chinese fed carps**. Parameter rule: `donor`. Not quantified; outside commercial-feed boundary
Sources (supporting context, not necessarily these numbers):
- Tacon2026: Tacon et al. (2026), Global Aquaculture and Aquafeed Production Update https://doi.org/10.1080/23308249.2025.2568830

### C04 — Misc diadromous
Unspecified diadromous and stickleback: bounded positive input; no species-specific measurement.

Time donor: **Miscellaneous diadromous fish and sturgeons**. Parameter rule: `anchor_scaled`. Not quantified; outside commercial-feed boundary
Sources (supporting context, not necessarily these numbers):
- Tacon2026: Tacon et al. (2026), Global Aquaculture and Aquafeed Production Update https://doi.org/10.1080/23308249.2025.2568830

### C05 — Trout like
Ayu and long-finned charr use trout as an explicit feeding proxy, not a statement that they are trout. Central e and p copy donor.

Time donor: **Trout**. Parameter rule: `donor`. Not quantified; outside commercial-feed boundary
Sources (supporting context, not necessarily these numbers):
- Tacon2026: Tacon et al. (2026), Global Aquaculture and Aquafeed Production Update https://doi.org/10.1080/23308249.2025.2568830
- FAO_CompoundAyu: FAO. Compound feed composition examples, Section 6.6.2 Other Species. https://www.fao.org/4/s4314e/s4314e07.htm

### C06 — Smelts
Low effective manufactured-feed scenario accommodates reservoir or extensive production; no direct global estimate.

Time donor: **Milkfish**. Parameter rule: `anchor_scaled`. Not quantified; outside commercial-feed boundary
Sources (supporting context, not necessarily these numbers):
- Tacon2026: Tacon et al. (2026), Global Aquaculture and Aquafeed Production Update https://doi.org/10.1080/23308249.2025.2568830

### C07 — Shads
Milkfish-based relative trend and recipe transferred to unspecified shad culture; low-confidence effective anchor.

Time donor: **Milkfish**. Parameter rule: `anchor_scaled`. Not quantified; outside commercial-feed boundary
Sources (supporting context, not necessarily these numbers):
- Tacon2026: Tacon et al. (2026), Global Aquaculture and Aquafeed Production Update https://doi.org/10.1080/23308249.2025.2568830

### C08 — Marine crabs
Rounded conditional 1.8 within published juvenile formulated FCR range; p=0.278 is assumed. Shrimp recipe proxy.

Time donor: **Freshwater crustaceans**. Parameter rule: `anchor_scaled`. Natural/raw fish, molluscs and wastes not included; significant possible noncompound pathway.
Sources (supporting context, not necessarily these numbers):
- FAO567_2011: Shelley and Lovatelli (2011). Mud crab aquaculture: a practical manual. FAO Technical Paper 567. https://www.fao.org/fishery/docs/DOCUMENT/aquaculture/aq2010_11/root/2011/ba0110e.pdf
- Tacon2026: Tacon et al. (2026), Global Aquaculture and Aquafeed Production Update https://doi.org/10.1080/23308249.2025.2568830

### C09 — Lobsters
Low effective compound input reflects natural-feed reliance qualitatively; no numerical uptake evidence. FCR and adoption assumed.

Time donor: **Freshwater crustaceans**. Parameter rule: `anchor_scaled`. Raw fish and other natural animal feeds not included; do not interpret this as total feed.
Sources (supporting context, not necessarily these numbers):
- Sudewi2024_Lobster: Sudewi et al. (2024). Growth and survival of spiny lobster Panulirus homarus juveniles fed with different formulated feeds. https://agris.fao.org/search/en/providers/122436/records/67644e5f6a5a95f3405a81b3
- FAO567_2011: Shelley and Lovatelli (2011). Mud crab aquaculture: a practical manual. FAO Technical Paper 567. https://www.fao.org/fishery/docs/DOCUMENT/aquaculture/aq2010_11/root/2011/ba0110e.pdf
- Tacon2026: Tacon et al. (2026), Global Aquaculture and Aquafeed Production Update https://doi.org/10.1080/23308249.2025.2568830

### C10 — Other marine crustaceans
Crustacean-related proxy for mantis shrimps and unspecified records; no direct quantitative evidence.

Time donor: **Freshwater crustaceans**. Parameter rule: `anchor_scaled`. Not quantified; outside commercial-feed boundary
Sources (supporting context, not necessarily these numbers):
- FAO567_2011: Shelley and Lovatelli (2011). Mud crab aquaculture: a practical manual. FAO Technical Paper 567. https://www.fao.org/fishery/docs/DOCUMENT/aquaculture/aq2010_11/root/2011/ba0110e.pdf
- Tacon2026: Tacon et al. (2026), Global Aquaculture and Aquafeed Production Update https://doi.org/10.1080/23308249.2025.2568830

### C11 — Brine shrimps
Precautionary manufactured-feed allowance for brine shrimp; FCR and p are unsupported scenario values. Identity/product basis requires review.

Time donor: **Chinese fed carps**. Parameter rule: `anchor_scaled`. Natural algae and cyst/live-biomass reporting differences are not resolved.
Sources (supporting context, not necessarily these numbers):
- Tacon2026: Tacon et al. (2026), Global Aquaculture and Aquafeed Production Update https://doi.org/10.1080/23308249.2025.2568830
Assumed shares [FeedCrops, fishmeal, fishoil, OtherFeed]: 0.75, 0, 0, 0.25.

### C12 — Abalones
Rounded conditional 2 within artificial-diet research range; assumed p=0.25. Crop/fishmeal/other recipe is a modeling assumption.

Time donor: **Chinese fed carps**. Parameter rule: `anchor_scaled`. Fresh seaweed feed excluded; marine macroalgal ingredients are OtherFeed, not FeedCrops.
Sources (supporting context, not necessarily these numbers):
- SEAFDEC_Abalone: Fermin and Hurtado. Research on Molluscs and Seaweeds. ADSEA 1999 proceedings, SEAFDEC Aquaculture Department. https://repository.seafdec.org.ph/bitstream/handle/10862/473/adsea99p209-219.pdf
Assumed shares [FeedCrops, fishmeal, fishoil, OtherFeed]: 0.75, 0.1, 0.01, 0.14.

### C13 — Other gastropods
Transfer from artificial-fed gastropod pathway; no observation of selected species or ingredient shares.

Time donor: **Chinese fed carps**. Parameter rule: `anchor_scaled`. Not quantified; outside commercial-feed boundary
Sources (supporting context, not necessarily these numbers):
- SEAFDEC_Abalone: Fermin and Hurtado. Research on Molluscs and Seaweeds. ADSEA 1999 proceedings, SEAFDEC Aquaculture Department. https://repository.seafdec.org.ph/bitstream/handle/10862/473/adsea99p209-219.pdf
Assumed shares [FeedCrops, fishmeal, fishoil, OtherFeed]: 0.7, 0.05, 0.01, 0.24.

### C14 — Predatory gastropods
Animal-rich manufactured-feed scenario for named predatory/ambiguous marine snails; not a measured formulation.

Time donor: **Marine fishes**. Parameter rule: `anchor_scaled`. Not quantified; outside commercial-feed boundary
Sources (supporting context, not necessarily these numbers):
- FAO567_2011: Shelley and Lovatelli (2011). Mud crab aquaculture: a practical manual. FAO Technical Paper 567. https://www.fao.org/fishery/docs/DOCUMENT/aquaculture/aq2010_11/root/2011/ba0110e.pdf
- SEAFDEC_Abalone: Fermin and Hurtado. Research on Molluscs and Seaweeds. ADSEA 1999 proceedings, SEAFDEC Aquaculture Department. https://repository.seafdec.org.ph/bitstream/handle/10862/473/adsea99p209-219.pdf
Assumed shares [FeedCrops, fishmeal, fishoil, OtherFeed]: 0.3, 0.35, 0.03, 0.32.

### C15 — Unspecified molluscs
Mixed-category assumption: positive effective input rather than assuming all unidentified molluscs are bivalves; p=0.05 at 2021.

Time donor: **Chinese fed carps**. Parameter rule: `anchor_scaled`. Fed/nonfed mix and fresh seaweed use uncertain; hatchery inputs excluded.
Sources (supporting context, not necessarily these numbers):
- FAO_OysterGrowout: FAO Cultured Aquatic Species Information Programme. Crassostrea gigas. https://www.fao.org/fishery/docs/DOCUMENT/aquaculture/CulturedSpecies/file/en/en_pacificcuppedoyster.htm
- SEAFDEC_Abalone: Fermin and Hurtado. Research on Molluscs and Seaweeds. ADSEA 1999 proceedings, SEAFDEC Aquaculture Department. https://repository.seafdec.org.ph/bitstream/handle/10862/473/adsea99p209-219.pdf
Assumed shares [FeedCrops, fishmeal, fishoil, OtherFeed]: 0.7, 0.05, 0.01, 0.24.

### C16 — Softshell other turtles
Farm proxy e=1.5 and p=0.6, not juvenile trial FCR. Animal-rich eel recipe borrowed; experiment supports pathway, not chosen proportions.

Time donor: **Chinese fed carps**. Parameter rule: `anchor_scaled`. Not quantified; outside commercial-feed boundary
Sources (supporting context, not necessarily these numbers):
- Qiu2023_Turtle: Qiu et al. (2023). Effects of the Replacement of Dietary Fish Meal with Poultry By-Product Meal on Growth and Intestinal Health of Chinese Soft-Shelled Turtle. Animals 13, 865. https://www.mdpi.com/2076-2615/13/5/865
- Tacon2026: Tacon et al. (2026), Global Aquaculture and Aquafeed Production Update https://doi.org/10.1080/23308249.2025.2568830

### C17 — Green turtle
Low-confidence positive compound-feed allowance for historical green-turtle record; generic plant-rich recipe assumed; no species farm coefficient located.

Time donor: **Chinese fed carps**. Parameter rule: `anchor_scaled`. Not quantified; outside commercial-feed boundary
Sources (supporting context, not necessarily these numbers):
- Tacon2026: Tacon et al. (2026), Global Aquaculture and Aquafeed Production Update https://doi.org/10.1080/23308249.2025.2568830
Assumed shares [FeedCrops, fishmeal, fishoil, OtherFeed]: 0.85, 0, 0, 0.15.

### C18 — Frogs
Rounded farm-transfer FCR=1.8 and p=0.5; American-bullfrog experiment in Mexico supports formulated-feed pathway but not global uptake or East Asian species transfer.

Time donor: **Chinese fed carps**. Parameter rule: `anchor_scaled`. Not quantified; outside commercial-feed boundary
Sources (supporting context, not necessarily these numbers):
- Fonseca2023_Frog: Fonseca-Madrigal et al. (2023). Effect of dietary protein:lipid ratio on growth and body composition in bullfrog. Revista Brasileira de Zootecnia 52:e20220104. https://rbz.org.br/wp-content/uploads/articles_xml/1806-9290-rbz-52-e20220104/1806-9290-rbz-52-e20220104.pdf
Assumed shares [FeedCrops, fishmeal, fishoil, OtherFeed]: 0.45, 0.35, 0.03, 0.17.

### C19 — Sea cucumbers
Small positive compound allowance; minerals/algal ingredients retained in OtherFeed. e, p and recipe are assumptions.

Time donor: **Chinese fed carps**. Parameter rule: `anchor_scaled`. Natural detritus, sea ranching, and fresh algae not counted as manufactured feed.
Sources (supporting context, not necessarily these numbers):
- Unuma2013: Unuma et al. (2013). Flocculent Feed for the Sea Cucumber Apostichopus japonicus Containing Diatomite and Zeolite. Aquaculture Science 61, 331-339. https://www.jstage.jst.go.jp/article/aquaculturesci/61/4/61_331/_article/-char/en
- EC_KUE: European Commission commercial designations register. Actinopyga echinites. https://fish-commercial-names.ec.europa.eu/fish-names/species/actinopyga-echinites_en
Assumed shares [FeedCrops, fishmeal, fishoil, OtherFeed]: 0.2, 0.02, 0, 0.78.

### C20 — Sea urchins
Weak echinoderm/grazer analogy; explicitly assumed effective 0.1. No species-specific global FCR or recipe was found.

Time donor: **Chinese fed carps**. Parameter rule: `anchor_scaled`. Not quantified; outside commercial-feed boundary
Sources (supporting context, not necessarily these numbers):
- SEAFDEC_Abalone: Fermin and Hurtado. Research on Molluscs and Seaweeds. ADSEA 1999 proceedings, SEAFDEC Aquaculture Department. https://repository.seafdec.org.ph/bitstream/handle/10862/473/adsea99p209-219.pdf
- Unuma2013: Unuma et al. (2013). Flocculent Feed for the Sea Cucumber Apostichopus japonicus Containing Diatomite and Zeolite. Aquaculture Science 61, 331-339. https://www.jstage.jst.go.jp/article/aquaculturesci/61/4/61_331/_article/-char/en
Assumed shares [FeedCrops, fishmeal, fishoil, OtherFeed]: 0.6, 0.05, 0.01, 0.34.

### C21 — Tunas
Small compound-feed scenario rather than claiming zero; conditional 3 and uptake 0.0333 are placeholders, not trial measurements.

Time donor: **Marine fishes**. Parameter rule: `anchor_scaled`. Dominant baitfish/fattening inputs remain unquantified; no wet-fish conversion or capture-based biomass-gain adjustment.
Sources (supporting context, not necessarily these numbers):
- SARDI2007_Tuna: Fernandes et al. (2007). Aquafin CRC Southern Bluefin Tuna Environment Subproject: Evaluation of Waste Composition and Waste Mitigation. SARDI Research Report Series 207. https://www.ccsbt.org/system/files/resource/en/4d940448b4cef/info05.pdf
- Tacon2026: Tacon et al. (2026), Global Aquaculture and Aquafeed Production Update https://doi.org/10.1080/23308249.2025.2568830

### C22 — Cephalopods
Precautionary small compound allowance; taxonomic transfer weak and fully assumed. Not evidence for established commercial-pellet adoption.

Time donor: **Marine fishes**. Parameter rule: `anchor_scaled`. Fresh animal feed and capture-based fattening inputs are not quantified.
Sources (supporting context, not necessarily these numbers):
- Tacon2026: Tacon et al. (2026), Global Aquaculture and Aquafeed Production Update https://doi.org/10.1080/23308249.2025.2568830
- FAO567_2011: Shelley and Lovatelli (2011). Mud crab aquaculture: a practical manual. FAO Technical Paper 567. https://www.fao.org/fishery/docs/DOCUMENT/aquaculture/aq2010_11/root/2011/ba0110e.pdf

### C23 — Other invertebrates
Generic bounded allowance for worms/unspecified invertebrates; not a measured taxon diet.

Time donor: **Chinese fed carps**. Parameter rule: `anchor_scaled`. Natural food, detritus and noncompound feed not quantified.
Sources (supporting context, not necessarily these numbers):
- Unuma2013: Unuma et al. (2013). Flocculent Feed for the Sea Cucumber Apostichopus japonicus Containing Diatomite and Zeolite. Aquaculture Science 61, 331-339. https://www.jstage.jst.go.jp/article/aquaculturesci/61/4/61_331/_article/-char/en
- Tacon2026: Tacon et al. (2026), Global Aquaculture and Aquafeed Production Update https://doi.org/10.1080/23308249.2025.2568830
Assumed shares [FeedCrops, fishmeal, fishoil, OtherFeed]: 0.6, 0.1, 0.01, 0.29.

## Zero conventions
Z01: four pearl/shell product records have zero additional commercial grow-out feed. Do not add their product mass to animal live-weight denominators.
Z02: HXP explicitly mixes silver/bighead carp, inheriting existing SVC/BIC zero-commercial-grow-out convention.
Z03: YMX is a bivalve (FAO table B-51); inherit the commercial grow-out zero convention, not a zero hatchery assumption.

## Data-quality correction
KUE is Actinopyga echinites (sea cucumber), not the conflicting supplied common name. The original label is kept. Identity was verified in the official EC register; no assumption that a species code determines feeding efficiency.

## What this release does not solve
Positive fallback values eliminate omission from the commercial account. They do not quantify every direct feed input. Raw fish in tuna/lobster/crab systems, supplementary crop feeds in carp systems, fresh seaweed in gastropod systems, hatchery inputs and natural pond food remain separate. Small coefficients for weakly evidenced pathways are scenario placeholders; their low case can be zero. No global observation, precision or statistical interval is implied.

Different farms may use both commercial and farm-made feeds. A production-share formulation cannot identify all such combinations without system-level data. The nominal p and e are an assumption-based decomposition of an effective commercial input intensity, not independently estimated variables.

The two donor-copy groups keep e and p exactly equal to their existing donors; low/high cases vary effective intensity and are not claims that uptake can exceed 100%. Bounds do not have separate p/e columns. All other groups use bounded p(t) and borrowed relative e(t).
