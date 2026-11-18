# Annualize source estimates without changing the v0.4 scientific choices.
af_interpolate <- function(anchors, year, fields) {
  af_assert(nrow(anchors) > 0L, "No coefficient anchors")
  anchors <- anchors[order(anchors$year), , drop = FALSE]
  af_unique(anchors, "year", "anchor")
  years <- anchors$year
  low <- if (any(years <= year)) max(years[years <= year]) else min(years)
  high <- if (any(years >= year)) min(years[years >= year]) else max(years)
  weight <- if (low == high) 0 else (year - low) / (high - low)
  left <- anchors[match(low, years), , drop = FALSE]
  right <- anchors[match(high, years), , drop = FALSE]
  values <- setNames(lapply(fields, function(field) {
    left[[field]] * (1 - weight) + right[[field]] * weight
  }), fields)
  status <- if (year < min(years)) "early_endpoint_hold_assumption" else
    if (year > max(years)) "late_endpoint_hold_assumption" else
      if (low == high) "published_estimate" else "linear_interpolation_assumption"
  list(values = values, low = low, high = high, status = status,
       source_low = left$source_id, source_high = right$source_id)
}

af_build_coefficients <- function(root = ".", write = TRUE,
                                  coefficient_dir = "data/processed/coefficients") {
  src <- af_prepare_sources(root, write = write)
  groups <- src$mapping$source_feed_group
  fw <- "Miscellaneous freshwater fish"
  diad <- "Miscellaneous diadromous fish and sturgeons"
  pcols <- c("source_id", "source_feed_group", "year", "commercial_feed_share", "efcr")
  p_all <- rbind(src$fao[src$fao$year == 1995, pcols, drop = FALSE],
                 src$selected[, pcols, drop = FALSE])
  # The separate diadromous group did not exist in the earlier source taxonomy.
  proxy <- p_all[p_all$source_feed_group == fw & p_all$year < 2010, , drop = FALSE]
  proxy$source_feed_group <- diad
  p_all <- rbind(p_all, proxy)
  af_unique(p_all, c("source_feed_group", "year"), "feed anchor")
  mcols <- c("source_id", "source_feed_group", "year", "fishmeal_share", "fishoil_share")
  marine2017 <- src$naylor
  marine2017$fishoil_share <- marine2017$fishoil_proxy_share
  m_all <- rbind(src$fao[, mcols, drop = FALSE], marine2017[, mcols, drop = FALSE])
  # Explicit miscellaneous freshwater marine-composition proxy for diadromous fish.
  m_all <- m_all[m_all$source_feed_group != diad, , drop = FALSE]
  mproxy <- m_all[m_all$source_feed_group == fw, , drop = FALSE]
  mproxy$source_feed_group <- diad
  m_all <- rbind(m_all, mproxy)
  af_unique(m_all, c("source_feed_group", "year"), "marine anchor")
  source_url <- function(id) {
    index <- match(id, src$registry$source_id)
    af_assert(!is.na(index), paste("Unregistered source:", id))
    src$registry$url[index]
  }
  bracket_urls <- function(x) {
    paste(vapply(unique(c(x$source_low, x$source_high)), source_url, character(1)),
          collapse = " | ")
  }
  rows <- vector("list", length(groups) * 49L)
  index <- 0L
  for (group in groups) {
    map <- src$mapping[src$mapping$source_feed_group == group, , drop = FALSE]
    profile <- src$profiles[src$profiles$profile == map$reference_profile, , drop = FALSE]
    af_assert(nrow(profile) == 1L, paste("Ambiguous profile for", group))
    ratios <- unlist(profile[c("crop", "animal", "additives", "unallocated")], use.names = FALSE) /
      (1 - profile$aquatic)
    p_anchors <- p_all[p_all$source_feed_group == group, , drop = FALSE]
    m_anchors <- m_all[m_all$source_feed_group == group, , drop = FALSE]
    for (year in 1975:2023) {
      p <- af_interpolate(p_anchors, year, c("commercial_feed_share", "efcr"))
      m <- af_interpolate(m_anchors, year, c("fishmeal_share", "fishoil_share"))
      marine <- m$values$fishmeal_share + m$values$fishoil_share
      nonmarine <- 1 - marine
      reference <- nonmarine * ratios
      recent <- reference
      recent_source <- "Tacon2015"
      recent_note <- "Unchanged generic conditional nonmarine allocation"
      if (nzchar(map$recent_profile)) {
        sk <- src$skretting[src$skretting$profile == map$recent_profile, , drop = FALSE]
        af_assert(nrow(sk) == 1L, paste("Unknown recent profile:", map$recent_profile))
        crop <- sk$vegetable_protein_pct + sk$vegetable_oil_pct + sk$starch_pct
        animal <- sk$land_animal_protein_pct + sk$land_animal_oil_pct
        micro <- sk$micronutrients_pct
        recent <- nonmarine * c(crop, animal, micro, 0) / (crop + animal + micro)
        recent_source <- "Skretting2021"
        recent_note <- paste0("2021 company conditional nonmarine mix transferred across geography; ",
                              "frozen backward/forward in this sensitivity, not historical observations")
      }
      feed_proxy <- (group == diad && year < 2010) || (group == fw && year >= 2000 && year <= 2009)
      marine_proxy <- group == diad
      origin_group <- if (group == diad) fw else group
      origins <- src$naylor[src$naylor$source_feed_group == origin_group, , drop = FALSE]
      origin_value <- function(field) {
        if (year >= 2017 && nrow(origins) == 1L) origins[[field]] else NA_real_
      }
      effective <- p$values$commercial_feed_share * p$values$efcr
      af_assert(p$values$commercial_feed_share >= 0 && p$values$commercial_feed_share <= 1 &&
                  p$values$efcr > 0, "Invalid commercial-feed share or eFCR")
      af_assert(marine >= 0 && marine <= 1, "Marine inclusion outside [0,1]")
      for (mix in list(reference, recent)) {
        af_assert(all(mix >= -1e-14) && abs(sum(mix) + marine - 1) < 1e-10,
                  "Ingredient recipe mass balance failed")
      }
      index <- index + 1L
      rows[[index]] <- list(
        source_feed_group = group, year = year,
        commercial_feed_share = p$values$commercial_feed_share, efcr = p$values$efcr,
        commercial_feed_per_t_output = effective,
        fishmeal_share = m$values$fishmeal_share, fishoil_proxy_share = m$values$fishoil_share,
        ReductionFish_proxy_share = marine, nonmarine_residual_share = nonmarine,
        FeedCrops_reference_share = reference[1], terrestrial_animal_reference_share = reference[2],
        additives_reference_share = reference[3], unallocated_reference_share = reference[4],
        OtherFeed_reference_share = sum(reference[2:4]),
        FeedCrops_recent_share = recent[1], terrestrial_animal_recent_share = recent[2],
        additives_recent_share = recent[3], unallocated_recent_share = recent[4],
        OtherFeed_recent_share = sum(recent[2:4]),
        FeedCrops_reference_per_t_output = effective * reference[1],
        ReductionFish_proxy_per_t_output = effective * marine,
        OtherFeed_reference_per_t_output = effective * sum(reference[2:4]),
        FeedCrops_recent_per_t_output = effective * recent[1],
        OtherFeed_recent_per_t_output = effective * sum(recent[2:4]),
        feed_coefficient_status = paste0(p$status, if (feed_proxy) ";group_proxy" else ""),
        feed_source_low = p$source_low, feed_source_high = p$source_high,
        feed_year_low = p$low, feed_year_high = p$high,
        marine_coefficient_status = paste0(m$status, if (marine_proxy) ";group_proxy" else ""),
        marine_source_low = m$source_low, marine_source_high = m$source_high,
        marine_year_low = m$low, marine_year_high = m$high,
        nonmarine_reference_source = "Tacon2015", nonmarine_recent_source = recent_source,
        reference_recipe_status = paste0("Illustrative conditional nonmarine ratios frozen across all years; ",
                                         "early crop/animal allocation not validated"),
        recent_recipe_status = recent_note,
        early_backcast = as.integer(year < 1995), early_nonmarine_caution = as.integer(year < 2015),
        fishoil_definition_warning = if (year > 2008)
          paste0("Post2008 interpolation transitions total fish oil estimates to Naylor wild-oil-only proxy; ",
                  "unreported trimming oil remains an unresolved omission") else
            "FAO564 total oil inclusion; no origin split",
        fishmeal_wild_share_known = origin_value("fishmeal_wild_share"),
        fishmeal_trimmings_share_known = origin_value("fishmeal_trimmings_share"),
        fishoil_wild_share_known = origin_value("fishoil_wild_share"),
        fishoil_trimmings_share_known = NA_real_,
        origin_status = if (year >= 2017 && nrow(origins) == 1L)
          "2017 published meal-origin shares held; trimming-oil unknown" else "Origins not resolved; not zero",
        feed_mass_basis = paste0("Commercial-feed mass; moisture not specified in Tacon; ",
                                 "NOT primary-equivalent or verified DM"),
        assumption_ids = "A01;A02;A03;A04;A05;A06;A07;A08;A09;A10",
        feed_source_urls = bracket_urls(p), marine_source_urls = bracket_urls(m),
        reference_recipe_source_url = source_url("Tacon2015"), recent_recipe_source_url = source_url(recent_source)
      )
    }
  }
  annual <- af_bind(rows)
  af_unique(annual, c("source_feed_group", "year"), "annual coefficient")
  strict <- annual
  keep <- c("year", "early_backcast", "early_nonmarine_caution", "feed_year_low", "feed_year_high",
            "marine_year_low", "marine_year_high")
  numeric <- setdiff(names(annual)[vapply(annual, is.numeric, logical(1))], keep)
  strict[strict$early_backcast == 1, numeric] <- NA_real_
  strict$feed_coefficient_status[strict$early_backcast == 1] <- "UNESTIMATED_BEFORE_1995"
  strict$marine_coefficient_status[strict$early_backcast == 1] <- "UNESTIMATED_BEFORE_1995"
  # Derive the Norway inventory from named source categories, not magic constants.
  cat_sum <- function(category) {
    af_assert(any(src$aas$category == category), paste("Missing Aas category:", category))
    sum(src$aas$tonnes_as_is[src$aas$category == category])
  }
  total <- cat_sum("total")
  crop <- cat_sum("crop")
  krill <- cat_sum("subset_not_additional")
  meal_wild <- cat_sum("marine_protein_including_krill") - krill
  meal_trim <- cat_sum("fishmeal_trimmings")
  oil_wild <- cat_sum("fishoil_whole")
  oil_trim <- cat_sum("fishoil_trimmings")
  meal <- meal_wild + meal_trim; oil <- oil_wild + oil_trim
  other <- total - crop - meal - oil
  additives <- cat_sum("additives"); novel <- cat_sum("other")
  norway <- af_bind(lapply(2020:2023, function(year) list(
    FAO_area_code = "162", species_code = "SAL", source_feed_group = "Salmon", year = year,
    FeedCrops_share = crop / total, fishmeal_share = meal / total, fishoil_share = oil / total,
    ReductionFish_share = (meal + oil) / total, OtherFeed_share = other / total,
    terrestrial_animal_share = 0, additives_share = additives / total,
    krill_share = krill / total, novel_share = novel / total,
    rounding_share = (other - additives - krill - novel) / total,
    fishmeal_wild_share = meal_wild / total, fishmeal_trimmings_share = meal_trim / total,
    fishoil_wild_share = oil_wild / total, fishoil_trimmings_share = oil_trim / total,
    composition_source_id = "Aas2022", composition_source_year = 2020L,
    status = if (year == 2020L) "national_inventory" else "2020_national_inventory_held_forward_assumption",
    commercial_feed_share_override = NA_real_, efcr_override = NA_real_,
    boundary_note = paste0("Composition-only override; keep Tacon p/eFCR. Ingredient inventory not substituted ",
                           "for complete-feed mass. Species restricted to Norway Atlantic salmon."),
    assumption_ids = "A11;A12", source_url = source_url("Aas2022")
  )))
  trends <- annual[annual$year %in% c(1975, 1995, 2000, 2008, 2010, 2017, 2021, 2023),
    c("source_feed_group", "year", "commercial_feed_share", "efcr", "commercial_feed_per_t_output",
      "fishmeal_share", "fishoil_proxy_share", "ReductionFish_proxy_share", "FeedCrops_reference_share",
      "FeedCrops_recent_share", "early_backcast"), drop = FALSE]
  if (write) {
    destination <- af_path(root, coefficient_dir)
    af_write_csv(annual, file.path(destination, "group_year_1975_2023.csv"))
    af_write_csv(strict, file.path(destination, "group_year_no_early_backcast.csv"))
    af_write_csv(norway, file.path(destination, "Norway_AtlanticSalmon_composition_2020_2023.csv"))
    af_write_csv(trends, file.path(root, "data/processed/coefficient_trend_checkpoints.csv"))
  }
  list(annual = annual, strict = strict, norway = norway, trends = trends, sources = src)
}
