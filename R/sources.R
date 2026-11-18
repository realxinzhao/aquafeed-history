# Curated literature transcriptions are immutable inputs; harmonization is native R.
# This does NOT claim to extract tables automatically from copyrighted PDFs.
af_prepare_sources <- function(root = ".", write = TRUE) {
  folder <- file.path(root, "data/raw/literature")
  read <- function(name, required = character()) af_read_csv(file.path(folder, name), required)
  t15 <- read("Tacon2015_Table1_all_years.csv")
  t26 <- read("Tacon2026_Table3_all_years.csv")
  choose <- function(x, lo, hi) {
    x$year <- af_year(x$year)
    x <- x[x$period_type == "historical_estimate" & x$year >= lo & x$year <= hi, , drop = FALSE]
    for (column in c("production_t", "commercial_feed_share", "efcr", "reported_feed_t")) {
      x[[column]] <- af_num(x[[column]], column)
    }
    x$recalculated_feed_t <- x$production_t * x$commercial_feed_share * x$efcr
    x$difference_t <- x$reported_feed_t - x$recalculated_feed_t
    x
  }
  # A newer publication's future projections must never become historical records.
  selected <- rbind(choose(t15, 2000L, 2009L), choose(t26, 2010L, 2023L))
  selected$harmonization_note <- paste0(
    "Prefer Tacon2026 for overlapping 2010-2012; retain original Tacon2015 rows separately.")
  # Preserve the source-specific scope warning from the v0.4 baseline.
  # This older category combines freshwater and diadromous fishes; its
  # provenance note must not be replaced by the generic source-priority note.
  # This restores metadata only: the numerical coefficients and the explicit
  # downstream group-proxy mapping below remain unchanged.
  older_combined <- selected$source_id == "Tacon2015" &
    selected$source_group == "Other freshwater & diadromous fishes"
  selected$harmonization_note[older_combined] <- paste0(
    "Older combined miscellaneous freshwater/diadromous category; ",
    "NOT mapped to later separate groups without species information.")
  af_unique(selected, c("source_group", "year"), "selected Tacon")
  af_assert(nrow(selected) == 278L, "Unexpected selected Tacon table coverage; review source changes")
  selected$source_feed_group <- selected$source_group
  selected$source_feed_group[selected$source_group == "Other freshwater & diadromous fishes"] <-
    "Miscellaneous freshwater fish"
  anchors <- read("FAO564_historical_anchors.csv")
  anchors$year <- af_year(anchors$year)
  for (column in c("commercial_feed_share", "efcr", "fishmeal_share", "fishoil_share"))
    anchors[[column]] <- af_num(anchors[[column]], column)
  af_unique(anchors, c("source_feed_group", "year"), "FAO564")
  naylor <- read("Naylor2021_Table1_2017.csv")
  naylor$year <- af_year(naylor$year)
  for (column in grep("_share$", names(naylor), value = TRUE))
    naylor[[column]] <- af_num(naylor[[column]], column, allow_missing = TRUE)
  af_unique(naylor, c("source_feed_group", "year"), "Naylor")
  skretting <- read("Skretting2021_Table15.csv")
  for (column in grep("_pct$", names(skretting), value = TRUE))
    skretting[[column]] <- af_num(skretting[[column]], column)
  profiles <- read("Tacon2015_Figure5_profiles.csv")
  for (column in grep("_pct$", names(profiles), value = TRUE))
    profiles[[column]] <- af_num(profiles[[column]], column)
  profiles$crop <- (profiles$plant_protein_oil_pct + profiles$other_plant_pct) / 100
  profiles$aquatic <- profiles$aquatic_pct / 100
  profiles$animal <- profiles$animal_pct / 100
  profiles$additives <- profiles$additives_pct / 100
  profiles$unallocated <- 1 - profiles$crop - profiles$aquatic - profiles$animal - profiles$additives
  profiles$unallocated[abs(profiles$unallocated) < 1e-12] <- 0
  af_assert(all(profiles$unallocated >= 0), "Figure 5 profile exceeds 100%")
  mapping <- af_read_csv(file.path(root, "data/mappings/feed_group_recipe_map.csv"))
  af_unique(mapping, "source_feed_group", "feed-group recipe mapping")
  af_assert(all(mapping$reference_profile %in% profiles$profile), "Unknown reference recipe")
  registry <- read("source_register.csv")
  af_unique(registry, "source_id", "source register")
  aas <- read("Aas2022_Norway2020_Table1.csv")
  aas$tonnes_as_is <- af_num(aas$tonnes_as_is, "Aas tonnes")
  if (write) {
    output <- file.path(root, "data/processed")
    af_write_csv(selected, file.path(output, "selected_Tacon_history.csv"))
    af_write_csv(profiles, file.path(output, "reference_profile_balance.csv"))
  }
  list(selected = selected, fao = anchors, naylor = naylor,
       skretting = skretting, profiles = profiles, mapping = mapping,
       registry = registry, aas = aas)
}
