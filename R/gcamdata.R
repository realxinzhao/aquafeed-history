# v0.6: source evidence -> filled group-year coefficients -> species-year CSV.
# Reuses the tested v0.5 source-selection functions; no Python dependency.

af_stage1_sources <- function(root = ".", out = "outputs/01_sources") {
  s <- af_prepare_sources(root, write = FALSE)
  folder <- file.path(root, "data/raw/literature")
  rows <- list()
  template <- list(source_record_id = "", source_id = "", source_feed_group = "",
    year = NA_integer_, period_type = "", geography = "Global/group estimate",
    efcr = NA_real_, commercial_feed_share = NA_real_, FeedCrops_share = NA_real_,
    fishmeal_share = NA_real_, fishoil_share = NA_real_, OtherFeed_share = NA_real_,
    fishmeal_wild_share = NA_real_, fishmeal_trimmings_share = NA_real_,
    fishoil_wild_share = NA_real_, marine_protein_share = NA_real_,
    aquatic_combined_share = NA_real_, terrestrial_animal_share = NA_real_,
    additives_share = NA_real_, unallocated_share = NA_real_,
    feed_mass_basis = "Commercial-feed mass as reported; moisture unspecified",
    source_location = "", source_url = "", notes = "")
  add <- function(...) {
    r <- template; fields <- list(...); r[names(fields)] <- fields
    r$source_record_id <- sprintf("SRC%04d", length(rows) + 1L)
    for (k in c("FeedCrops", "fishmeal", "fishoil", "OtherFeed"))
      r[[paste0("efcr_", k)]] <- r$efcr * r[[paste0(k, "_share")]]
    r$commercial_feed_per_t_output <- r$efcr * r$commercial_feed_share
    rows[[length(rows) + 1L]] <<- r
  }
  for (filename in c("Tacon2015_Table1_all_years.csv", "Tacon2026_Table3_all_years.csv")) {
    z <- af_read_csv(file.path(folder, filename))
    for (i in seq_len(nrow(z))) add(source_id = z$source_id[i],
      source_feed_group = z$source_group[i], year = af_year(z$year[i]),
      period_type = z$period_type[i], efcr = as.numeric(z$efcr[i]),
      commercial_feed_share = as.numeric(z$commercial_feed_share[i]),
      source_location = z$source_table[i], source_url = z$source_url[i], notes = z$notes[i])
  }
  for (i in seq_len(nrow(s$fao))) {
    z <- s$fao[i, ]; add(source_id = z$source_id, source_feed_group = z$source_feed_group,
      year = z$year, period_type = "historical_estimate", efcr = z$efcr,
      commercial_feed_share = z$commercial_feed_share, fishmeal_share = z$fishmeal_share,
      fishoil_share = z$fishoil_share, source_url = z$source_url,
      source_location = paste(z$share_efcr_location, z$ingredients_location, sep = "; "),
      notes = "Feed-source eFCRs are within-source products, not separately measured efficiencies.")
  }
  meta <- af_read_csv(file.path(folder, "Naylor2021_Table1_feed_metadata_2017.csv"))
  for (i in seq_len(nrow(s$naylor))) {
    z <- s$naylor[i, ]; m <- meta[match(z$source_feed_group, meta$source_feed_group), ]
    # Preserve the missing oil-origin component and milkfish blank in the RAW table.
    fm_trim <- if (z$source_feed_group == "Milkfish") NA_real_ else z$fishmeal_trimmings_share
    add(source_id = "Naylor2021", source_feed_group = z$source_feed_group, year = 2017L,
      period_type = "historical_estimate", efcr = as.numeric(m$efcr),
      commercial_feed_share = as.numeric(m$commercial_feed_share),
      fishmeal_share = z$fishmeal_wild_share + fm_trim,
      fishmeal_wild_share = z$fishmeal_wild_share, fishmeal_trimmings_share = fm_trim,
      fishoil_wild_share = z$fishoil_wild_share, fishoil_share = NA_real_,
      source_location = z$location, source_url = z$source_url,
      notes = paste("Oil column is wild-fish oil, NOT total oil. Total oil stays NA here.",
                    "Milkfish trimming-meal blank stays NA. Correction audit remains pending."))
  }
  for (i in seq_len(nrow(s$profiles))) {
    z <- s$profiles[i, ]; add(source_id = "Tacon2015_Fig5", source_feed_group = z$profile,
      year = NA_integer_, period_type = "undated_illustrative_profile", FeedCrops_share = z$crop,
      aquatic_combined_share = z$aquatic, terrestrial_animal_share = z$animal,
      additives_share = z$additives, unallocated_share = z$unallocated,
      OtherFeed_share = z$animal + z$additives + z$unallocated,
      source_location = z$source_location, source_url = z$source_url,
      notes = "Not a 2015 observation. Shrimp labels sum to 90%; residual remains unallocated.")
  }
  for (i in seq_len(nrow(s$skretting))) {
    z <- s$skretting[i, ]; crop <- (z$vegetable_protein_pct + z$vegetable_oil_pct + z$starch_pct)/100
    animal <- (z$land_animal_protein_pct + z$land_animal_oil_pct)/100
    add(source_id = "Skretting2021", source_feed_group = z$profile, year = 2021L,
      period_type = "company_reported_average", geography = "Skretting portfolio; not a global survey",
      FeedCrops_share = crop, fishoil_share = z$fish_oil_pct/100,
      marine_protein_share = z$marine_protein_pct/100, terrestrial_animal_share = animal,
      additives_share = z$micronutrients_pct/100, OtherFeed_share = animal + z$micronutrients_pct/100,
      source_location = z$location, source_url = z$source_url,
      notes = "Marine protein includes crustacean meal; fishmeal stays NA. Rounding not normalized in raw table.")
  }
  # National inventory retained as evidence, NOT assigned globally or selected as farm eFCR.
  a <- s$aas; total <- a$tonnes_as_is[a$category == "total"]
  af_assert(length(total) == 1L, "Ambiguous Aas total")
  amount <- function(cat) sum(a$tonnes_as_is[a$category %in% cat])
  fm <- amount(c("marine_protein_including_krill", "fishmeal_trimmings")) -
    amount("subset_not_additional")
  crop <- amount("crop")/total; fo <- amount(c("fishoil_whole", "fishoil_trimmings"))/total
  add(source_id = "Aas2022", source_feed_group = "Salmon", year = 2020L,
    period_type = "national_inventory", geography = "Norway; Atlantic salmon only",
    FeedCrops_share = crop, fishmeal_share = fm/total, fishoil_share = fo,
    OtherFeed_share = 1 - crop - fm/total - fo,
    feed_mass_basis = "Ingredient-as-is inventory; not substituted for Tacon farm eFCR",
    source_location = "Table 1; krill subtracted from combined forage-meal row",
    source_url = a$source_url[1], notes = "Review evidence only: no regional override in species-year export.")
  result <- af_append_coverage_evidence(root, af_bind(rows), out)
  af_write_csv(result, file.path(root, out, "literature_source_estimates.csv"))
  result
}

af_species_mapping_core <- function(root) {
  x <- af_read_csv(file.path(root, "data/mappings/species_crosswalk.csv"))
  z <- af_read_csv(file.path(root, "data/mappings/species_fill_overrides.csv"))
  af_unique(x, "species_code", "species mapping")
  for (i in seq_len(nrow(z))) {
    k <- match(z$species_code[i], x$species_code)
    af_assert(!is.na(k), paste("Override code absent", z$species_code[i]))
    x$source_feed_group[k] <- z$source_feed_group[i]
    x$mapping_status[k] <- paste("Literature-supported nonfed grow-out proxy", z$assumption_id[i])
    x$mapping_notes[k] <- z$note[i]
  }
  x
}

af_interp_value <- function(years, values, target) {
  # Linear interpolation, constant endpoint extrapolation. Never extrapolate a trend unboundedly.
  stats::approx(years, values, xout = target, rule = 2, ties = "ordered")$y
}

af_stage2_coefficients <- function(root = ".", config) {
  baseline <- af_build_coefficients(root = root, write = FALSE)$annual
  src <- af_prepare_sources(root, write = FALSE)
  af_assert(config$year_start >= 1900 && config$year_end <= 2023 &&
              config$year_start <= config$year_end, "Unsupported coefficient interval")
  af_assert(config$early_policy %in% c("hold", "blank"), "early_policy must be hold or blank")
  years <- seq.int(config$year_start, config$year_end)
  groups <- src$mapping$source_feed_group
  index <- expand.grid(source_feed_group = groups, year = years, stringsAsFactors = FALSE)
  use_year <- pmax(index$year, 1975L)
  key <- paste(index$source_feed_group, use_year, sep = "\034")
  b <- baseline[match(key, af_key(baseline, c("source_feed_group", "year"))), , drop = FALSE]
  af_assert(!anyNA(b$year), "Coefficient join failed")
  b$year <- index$year
  b$early_backcast <- as.integer(b$year < 1995)
  b$fishoil_share <- b$fishoil_proxy_share
  b$fishoil_scope <- ifelse(b$year <= 2008, "total_as_reported",
    "wild_fishoil_as_total_proxy; trimming_oil_unestimated")
  b$fishoil_fill_method <- b$marine_coefficient_status
  b$fishoil_source_ids <- paste(b$marine_source_low, b$marine_source_high, sep = ";")
  b$fishoil_year_low <- b$marine_year_low; b$fishoil_year_high <- b$marine_year_high
  # Unlike v0.4, do not interpolate total oil through a wild-only anchor when a total-oil
  # endpoint is available. Company-to-global transfer is explicitly an assumption.
  if (isTRUE(config$use_recent_fishoil)) for (group in c("Salmon", "Marine shrimp", "Tilapia")) {
    ii <- which(b$source_feed_group == group & b$year > 2008)
    start <- src$fao$fishoil_share[src$fao$source_feed_group == group & src$fao$year == 2008]
    end <- src$skretting$fish_oil_pct[src$skretting$profile == group]/100
    af_assert(length(start) == 1L && length(end) == 1L, "Oil anchor missing")
    b$fishoil_share[ii] <- af_interp_value(c(2008L, 2021L), c(start, end), b$year[ii])
    b$fishoil_scope[ii] <- "total_oil_estimate; company_to_global_transfer"
    b$fishoil_fill_method[ii] <- ifelse(b$year[ii] < 2021,
      "linear_2008_global_to_2021_company_assumption", ifelse(b$year[ii] == 2021,
      "company_to_global_proxy", "2021_company_endpoint_hold"))
    b$fishoil_source_ids[ii] <- ifelse(b$year[ii] < 2021, "FAO564_2011;Skretting2021", "Skretting2021")
    b$fishoil_year_low[ii] <- ifelse(b$year[ii] < 2021, 2008L, 2021L)
    b$fishoil_year_high[ii] <- 2021L
  }
  b$FeedCrops_share <- b$terrestrial_animal_share <- b$additives_share <- b$unallocated_share <- NA_real_
  b$nonmarine_fill_method <- "undated_2015_profile_conditional_ratios_held"
  b$nonmarine_source_ids <- "Tacon2015"
  for (group in groups) {
    ii <- which(b$source_feed_group == group)
    m <- src$mapping[src$mapping$source_feed_group == group, ]
    pr <- src$profiles[src$profiles$profile == m$reference_profile, ]
    ratio0 <- unlist(pr[c("crop", "animal", "additives", "unallocated")], use.names = FALSE)/(1-pr$aquatic)
    ratio1 <- ratio0
    recent <- isTRUE(config$use_recent_nonmarine) && nzchar(m$recent_profile)
    if (recent) {
      sk <- src$skretting[src$skretting$profile == m$recent_profile, ]
      ratio1 <- c(sk$vegetable_protein_pct+sk$vegetable_oil_pct+sk$starch_pct,
                  sk$land_animal_protein_pct+sk$land_animal_oil_pct, sk$micronutrients_pct, 0)
      ratio1 <- ratio1/sum(ratio1)
    }
    for (j in seq_along(ii)) {
      k <- ii[j]; w <- if (recent) max(0, min(1, (b$year[k]-2015)/6)) else 0
      mix <- (1-b$fishmeal_share[k]-b$fishoil_share[k])*((1-w)*ratio0+w*ratio1)
      b[k, c("FeedCrops_share","terrestrial_animal_share","additives_share","unallocated_share")] <- as.list(mix)
      if (recent && b$year[k] > 2015) {
        b$nonmarine_fill_method[k] <- if (b$year[k] < 2021) "conditional_ratio_interpolation_2015_2021_assumption" else
          "2021_company_conditional_ratio_transfer_hold"
        b$nonmarine_source_ids[k] <- if (b$year[k] < 2021) "Tacon2015;Skretting2021" else "Skretting2021"
      }
    }
  }
  b$OtherFeed_share <- b$terrestrial_animal_share+b$additives_share+b$unallocated_share
  b$feed_fill_method <- b$feed_coefficient_status
  b$fishmeal_fill_method <- b$marine_coefficient_status
  b$coefficient_id <- paste0("G", match(b$source_feed_group, groups), "_", b$year)
  b$feed_source_ids <- paste(b$feed_source_low, b$feed_source_high, sep = ";")
  b$fishmeal_source_ids <- paste(b$marine_source_low, b$marine_source_high, sep = ";")
  b$assumption_ids <- "F01;F02;F03;F04;F05;F06;F07;F08;F09;F10;F11"
  b$commercial_feed_per_t_output <- b$efcr*b$commercial_feed_share
  for (feed in c("FeedCrops", "fishmeal", "fishoil", "OtherFeed")) {
    b[[paste0("efcr_",feed)]] <- b$efcr*b[[paste0(feed,"_share")]]
    b[[paste0(feed,"_per_t_output")]] <- b$commercial_feed_share*b[[paste0("efcr_",feed)]]
  }
  early <- b$year < 1995
  b$feed_fill_method[early] <- "1995_endpoint_hold_assumption_not_observed"
  # Blank alternative keeps source provenance but suppresses all model values before 1995.
  value_cols <- c("efcr","commercial_feed_share","commercial_feed_per_t_output",
    paste0(c("FeedCrops","fishmeal","fishoil","OtherFeed"),"_share"),
    paste0("efcr_",c("FeedCrops","fishmeal","fishoil","OtherFeed")),
    paste0(c("FeedCrops","fishmeal","fishoil","OtherFeed"),"_per_t_output"))
  if (config$early_policy == "blank") {
    b[early,value_cols] <- NA_real_; b$feed_fill_method[early] <- "pre1995_not_estimated"
  }
  # Provenance lives in a compact group-year sidecar, avoiding huge URLs on every species row.
  pcols <- c("coefficient_id","source_feed_group","year",value_cols,
    "terrestrial_animal_share","additives_share","unallocated_share",
    "feed_fill_method","fishmeal_fill_method","fishoil_fill_method","nonmarine_fill_method",
    "feed_source_ids","fishmeal_source_ids","fishoil_source_ids","nonmarine_source_ids",
    "feed_year_low","feed_year_high","marine_year_low","marine_year_high",
    "fishoil_year_low","fishoil_year_high","early_backcast","fishoil_scope","feed_mass_basis","assumption_ids")
  g <- b[,pcols,drop=FALSE]; g <- g[order(g$source_feed_group,g$year), ]
  rownames(g) <- NULL
  g <- af_extend_coverage_groups(root,g,baseline,config)
  cross <- af_species_mapping(root,config)
  ix <- rep(seq_len(nrow(cross)), each=length(years)); x <- cross[ix, ]
  x$year <- rep(years, times=nrow(cross))
  match_id <- match(af_key(x,c("source_feed_group","year")),af_key(g,c("source_feed_group","year")))
  y <- g[match_id, setdiff(names(g),c("source_feed_group","year")),drop=FALSE]
  result <- cbind(data.frame(species_code=x$species_code,species_name=x$species_name_resolved,
    ISSCAAP=x$ISSCAAP,year=x$year,stringsAsFactors=FALSE),y,
    data.frame(source_feed_group=x$source_feed_group,mapping_status=x$mapping_status,stringsAsFactors=FALSE))
  rownames(result) <- NULL
  result$coverage_layer <- x$coverage_layer
  result$coverage_assumption_id <- x$coverage_assumption_id
  result$coverage_confidence <- x$coverage_confidence
  result$original_source_feed_group <- x$original_source_feed_group
  result$output_basis <- x$output_basis
  result$species_name_original <- x$species_name_original
  result$identity_source_id <- x$identity_source_id
  result$identity_note <- x$identity_note
  result$complete_all_external_feed_estimate <- FALSE
  result$coefficient_status <- ifelse(!is.na(match_id),"estimated_with_documented_fills",x$source_feed_group)
  nofeed <- x$source_feed_group == "NONFED"
  result$commercial_feed_per_t_output[nofeed] <- 0
  for (f in c("FeedCrops","fishmeal","fishoil","OtherFeed")) result[[paste0(f,"_per_t_output")]][nofeed] <- 0
  for (f in c("commercial_feed", "FeedCrops", "fishmeal", "fishoil", "OtherFeed"))
    for (q in c("low","high")) result[[paste0(f,"_per_t_output_",q)]][nofeed] <- 0
  zero_new <- nofeed & x$coverage_layer=="coverage_assumed_zero"
  result$commercial_feed_share[zero_new] <- 0
  result$coefficient_id[nofeed] <- "NONFED_GROWOUT"
  result$coefficient_id[zero_new] <- paste0(x$coverage_assumption_id[zero_new],"_ZERO")
  result$coefficient_status[x$coverage_layer=="coverage_extension"] <- "assumption_based_coverage_extension"
  result$coefficient_status[zero_new] <- "assumed_zero_commercial_growout"
  result$feed_fill_method[nofeed] <- "zero_commercial_growout_input_assumption"
  result$coefficient_id[x$source_feed_group=="UNESTIMATED"] <- "UNESTIMATED"
  result$coefficient_id[x$source_feed_group=="OUT_OF_SCOPE"] <- "OUT_OF_SCOPE"
  result$species_name[result$species_name=="NA"] <- ""
  main_cols <- c("species_code","species_name","ISSCAAP","year",value_cols,
    "source_feed_group","coefficient_id","mapping_status","coefficient_status",
    "feed_fill_method","fishmeal_fill_method","fishoil_fill_method","nonmarine_fill_method",
    "early_backcast","fishoil_scope","coverage_layer","coverage_assumption_id","coverage_confidence",
    "original_source_feed_group","output_basis","species_name_original","identity_source_id","identity_note",
    "commercial_feed_per_t_output_low","commercial_feed_per_t_output_high",
    paste0(c("FeedCrops","fishmeal","fishoil","OtherFeed"),"_per_t_output_low"),
    paste0(c("FeedCrops","fishmeal","fishoil","OtherFeed"),"_per_t_output_high"),
    "complete_all_external_feed_estimate")
  result <- result[,main_cols,drop=FALSE]
  result <- result[order(result$species_code,result$year), ]; rownames(result)<-NULL
  af_unique(result,c("species_code","year"),"species-year coefficient")
  output <- file.path(root,config$output_dir,"02_coefficients")
  af_write_csv(result,file.path(output,"aquaculture_feed_coefficients_species_year.csv"))
  af_write_csv(g,file.path(output,"coefficient_provenance_group_year.csv"))
  af_write_csv(cross,file.path(output,"species_mapping_applied.csv"))
  formats <- if(is.null(config$gcamdata_formats)) c("csv", "csv.gz") else config$gcamdata_formats
  exported <- af_export_gcamdata_coefficients(result,
    file.path(root,config$output_dir,"gcamdata"), formats=formats)
  list(species=result,groups=g,mapping=cross,gcamdata_files=exported)
}
