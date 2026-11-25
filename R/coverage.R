# v0.7 coverage extension. All numeric anchors below are read from editable CSVs.
# Literature evidence and assumed global coefficients are deliberately separate.
af_coverage_policy <- function(config) {
  p <- if (is.null(config$coverage_policy)) "expanded" else config$coverage_policy
  af_assert(p %in% c("expanded", "original"), "coverage_policy must be expanded or original")
  p
}

af_species_mapping <- function(root, config = list(), input = NULL) {
  x <- af_species_mapping_core(root)
  x$original_source_feed_group <- x$source_feed_group
  x$coverage_layer <- ifelse(x$source_feed_group == "NONFED", "original_nonfed", "original_tacon_core")
  x$coverage_layer[x$source_feed_group %in% c("UNESTIMATED", "OUT_OF_SCOPE")] <- "unresolved_original"
  x$coverage_assumption_id <- ""
  x$coverage_source_ids <- ""
  x$output_basis <- ifelse(x$ISSCAAP == "Pearls, mother-of-pearl, shells", "pearl_shell_product", "reported_live_weight")
  x$species_name_original <- x$species_name_resolved
  x$identity_source_id <- ""
  x$identity_note <- ""
  x$coverage_confidence <- "original_assignment_unchanged"
  if (af_coverage_policy(config) == "expanded") {
    z <- af_read_csv(file.path(root, "data/mappings/coverage_species_overrides.csv"))
    af_unique(z, "species_code", "coverage overrides")
    k <- match(z$species_code, x$species_code)
    af_assert(!anyNA(k), "Coverage override code absent from crosswalk")
    af_assert(all(x$source_feed_group[k] == z$previous_source_feed_group), "Override changes a non-pending assignment")
    x$source_feed_group[k] <- z$source_feed_group
    x$coverage_layer[k] <- ifelse(z$source_feed_group == "NONFED", "coverage_assumed_zero", "coverage_extension")
    x$coverage_assumption_id[k] <- z$assumption_id
    x$coverage_source_ids[k] <- z$source_ids
    x$mapping_status[k] <- paste("Explicit coverage assumption", z$assumption_id)
    x$mapping_notes[k] <- z$mapping_rationale
    x$coverage_confidence[k] <- z$confidence
    x$output_basis[k] <- z$output_basis
    x$identity_source_id[k] <- z$identity_source_id
    x$identity_note[k] <- z$identity_note
    resolved <- nzchar(z$resolved_name_override)
    x$species_name_resolved[k[resolved]] <- z$resolved_name_override[resolved]
  }
  if (!is.null(input)) {
    x <- af_extend_species_mapping(root, x, input,
                                   allow_isscaap_proxy = af_coverage_policy(config) == "expanded")
  }
  x
}

af_extend_species_mapping <- function(root, x, input, allow_isscaap_proxy = TRUE) {
  if (!"species_code" %in% names(input)) return(x)
  codes <- sort(setdiff(unique(trimws(input$species_code)), x$species_code))
  if (!length(codes)) return(x)

  group_map <- af_read_csv(file.path(root, "data/mappings/GCAM_group_mapping.csv"))
  rows <- lapply(codes, function(code) {
    d <- input[trimws(input$species_code) == code, , drop = FALSE]
    isscaap <- unique(trimws(d$ISSCAAP))
    af_assert(length(isscaap) == 1L && nzchar(isscaap),
              paste("New species code has inconsistent ISSCAAP:", code))
    candidates <- x[x$ISSCAAP == isscaap, , drop = FALSE]
    feed_groups <- unique(candidates$source_feed_group[
      !is.na(candidates$source_feed_group) & nzchar(candidates$source_feed_group)
    ])
    gmap <- group_map[group_map$ISSCAAP == isscaap, , drop = FALSE]
    unique_group <- allow_isscaap_proxy && length(feed_groups) == 1L
    feed_group <- if (unique_group) feed_groups[1] else "UNESTIMATED"
    subsector <- if (nrow(gmap) == 1L) gmap$GCAM_subsector[1] else "OUT_OF_SCOPE"
    commodity <- if (nrow(gmap) == 1L) gmap$GCAM_commodity[1] else "OUT_OF_SCOPE"
    available_names <- unique(trimws(d$species_name[
      !is.na(d$species_name) & nzchar(trimws(d$species_name))
    ]))
    display_name <- if (length(available_names) == 1L) available_names else ""
    year_2021 <- d$year == "2021"
    production_2021 <- sum(af_num(d$value[year_2021], "2021 production", allow_missing = TRUE),
                           na.rm = TRUE)

    r <- x[1, , drop = FALSE]
    for (k in names(r)) r[[k]] <- if (is.numeric(r[[k]])) NA_real_ else ""
    r$species_code <- code
    r$species_name_original <- display_name
    r$species_name_resolved <- display_name
    r$ISSCAAP <- isscaap
    r$GCAM_subsector <- subsector
    r$GCAM_commodity <- commodity
    r$source_feed_group <- feed_group
    r$needs_taxonomic_review <- "TRUE"
    r$input_production_t <- format(production_2021, digits = 15, scientific = FALSE, trim = TRUE)
    r$original_source_feed_group <- "UNESTIMATED"
    r$identity_note <- "Name and ISSCAAP copied from production input; identity not independently reviewed."
    r$identity_notes <- r$identity_note

    if (!unique_group || feed_group %in% c("UNESTIMATED", "OUT_OF_SCOPE")) {
      r$mapping_status <- if (!allow_isscaap_proxy) {
        "AUTO: original coverage policy; new code retained as UNESTIMATED"
      } else if (unique_group) {
        "AUTO: unique ISSCAAP assignment is unestimated"
      } else {
        "AUTO: conflicting or absent ISSCAAP assignments; retained as UNESTIMATED"
      }
      r$mapping_notes <- paste0(
        "Automatic mapping from production input. Existing exact-ISSCAAP feed-group candidates: ",
        if (length(feed_groups)) paste(feed_groups, collapse = "; ") else "none",
        ". No zero-feed assumption applied."
      )
      r$coverage_layer <- "unresolved_new_species"
      r$coverage_assumption_id <- ""
      r$coverage_source_ids <- ""
      r$coverage_confidence <- "low"
    } else if (feed_group == "NONFED") {
      r$mapping_status <- "AUTO: unique ISSCAAP assignment; nonfed assumption"
      r$mapping_notes <- paste0(
        "Automatic exact-ISSCAAP assignment to NONFED; commercial-feed coefficient is zero by this explicit proxy."
      )
      r$coverage_layer <- "coverage_assumed_zero"
      r$coverage_assumption_id <- "AUTO_ISSCAAP_NONFED"
      r$coverage_source_ids <- ""
      r$coverage_confidence <- "low"
    } else {
      inherited_ids <- unique(candidates$coverage_assumption_id[
        candidates$source_feed_group == feed_group &
          !is.na(candidates$coverage_assumption_id) & nzchar(candidates$coverage_assumption_id)
      ])
      inherited_sources <- unique(candidates$coverage_source_ids[
        candidates$source_feed_group == feed_group &
          !is.na(candidates$coverage_source_ids) & nzchar(candidates$coverage_source_ids)
      ])
      r$mapping_status <- "AUTO: unique ISSCAAP source-feed-group proxy"
      r$mapping_notes <- paste0(
        "Automatic exact-ISSCAAP assignment to ", feed_group,
        "; new species treated as a coverage extension, not part of the Tacon-comparable core."
      )
      r$coverage_layer <- "coverage_extension"
      r$coverage_assumption_id <- paste(c("AUTO_ISSCAAP", inherited_ids), collapse = ";")
      r$coverage_source_ids <- paste(inherited_sources, collapse = ";")
      r$coverage_confidence <- "low"
    }
    r$output_basis <- if (isscaap == "Pearls, mother-of-pearl, shells") {
      "pearl_shell_product"
    } else {
      "reported_live_weight"
    }
    r
  })
  out <- rbind(x, af_bind(rows))
  rownames(out) <- NULL
  af_unique(out, "species_code", "extended species mapping")
  out
}

af_extend_coverage_groups <- function(root, g, baseline, config) {
  feeds <- c("FeedCrops", "fishmeal", "fishoil", "OtherFeed")
  g$coverage_layer <- "original_tacon_core"
  g$coverage_assumption_id <- ""
  g$coverage_confidence <- "original_assignment_unchanged"
  g$commercial_feed_per_t_output_low <- g$commercial_feed_per_t_output
  g$commercial_feed_per_t_output_high <- g$commercial_feed_per_t_output
  for (f in feeds) for (s in c("low", "high")) g[[paste0(f,"_per_t_output_",s)]] <- g[[paste0(f,"_per_t_output")]]
  if (af_coverage_policy(config) == "original") return(g)
  a <- af_read_csv(file.path(root, "data/mappings/coverage_assumption_groups.csv"))
  af_unique(a, "source_feed_group", "coverage assumption groups")
  for (k in c("efcr_anchor", "effective_anchor", "effective_anchor_low", "effective_anchor_high"))
    a[[k]] <- af_num(a[[k]], k)
  af_assert(all(a$efcr_anchor > 0 & a$effective_anchor > 0 & a$effective_anchor <= a$efcr_anchor), "Invalid p/e anchor")
  af_assert(all(a$effective_anchor_low >= 0 & a$effective_anchor_low <= a$effective_anchor & a$effective_anchor_high >= a$effective_anchor), "Invalid sensitivity bounds")
  extra <- vector("list", nrow(a))
  for (i in seq_len(nrow(a))) {
    r <- a[i, ]; donor <- trimws(r$trend_donor)
    z <- g[g$source_feed_group == donor, , drop=FALSE]
    af_assert(nrow(z) == config$year_end-config$year_start+1L, paste("Missing trend donor", donor))
    anchor <- baseline[baseline$source_feed_group == donor & baseline$year == as.integer(r$anchor_year), , drop=FALSE]
    af_assert(nrow(anchor) == 1L, "Ambiguous 2021 donor anchor")
    if (r$parameter_rule == "anchor_scaled") {
      z$efcr <- r$efcr_anchor * z$efcr / anchor$efcr
      z$commercial_feed_share <- pmin(1, (r$effective_anchor/r$efcr_anchor) * z$commercial_feed_share/anchor$commercial_feed_share)
    } else af_assert(r$parameter_rule == "donor", "Unknown parameter rule")
    if (r$recipe_mode == "fixed") {
      shares <- af_num(unlist(r[paste0(feeds,"_share")],use.names=FALSE), "recipe shares")
      af_assert(all(shares>=0 & shares<=1) && abs(sum(shares)-1)<1e-12, "Fixed recipe does not sum to one")
      for (j in seq_along(feeds)) z[[paste0(feeds[j],"_share")]] <- shares[j]
      z$terrestrial_animal_share <- 0
      z$additives_share <- 0
      z$unallocated_share <- z$OtherFeed_share # OtherFeed is NOT independently decomposed.
      z$fishoil_scope <- "assumed_total_oil_share; origins_not_separated"
    } else {
      af_assert(r$recipe_mode == "donor", "Unknown recipe mode")
      q <- g[g$source_feed_group == trimws(r$recipe_donor), , drop=FALSE]
      j <- match(z$year, q$year); af_assert(!anyNA(j), "Missing recipe donor year")
      for (k in c(paste0(feeds,"_share"),"terrestrial_animal_share","additives_share","unallocated_share","fishoil_scope")) z[[k]] <- q[[k]][j]
      z$fishoil_scope <- paste0("borrowed_recipe; ",z$fishoil_scope)
    }
    z$commercial_feed_per_t_output <- z$efcr*z$commercial_feed_share
    for (f in feeds) {
      z[[paste0("efcr_",f)]] <- z$efcr*z[[paste0(f,"_share")]]
      z[[paste0(f,"_per_t_output")]] <- z$commercial_feed_per_t_output*z[[paste0(f,"_share")]]
    }
    z$commercial_feed_per_t_output_low <- z$commercial_feed_per_t_output*r$effective_anchor_low/r$effective_anchor
    z$commercial_feed_per_t_output_high <- z$commercial_feed_per_t_output*r$effective_anchor_high/r$effective_anchor
    for (f in feeds) for (s in c("low","high")) z[[paste0(f,"_per_t_output_",s)]] <-
      z[[paste0("commercial_feed_per_t_output_",s)]]*z[[paste0(f,"_share")]]
    z$source_feed_group <- r$source_feed_group
    z$coefficient_id <- paste0(r$assumption_id,"_",z$year)
    z$coverage_layer <- "coverage_extension"
    z$coverage_assumption_id <- r$assumption_id
    z$coverage_confidence <- r$confidence
    z$feed_fill_method <- paste0("assumed_2021_anchor; ",r$parameter_rule,"; trend_donor=",donor)
    z$feed_fill_method[z$year<1995] <- paste0(z$feed_fill_method[z$year<1995],"; early_policy=",config$early_policy)
    for (k in c("fishmeal_fill_method","fishoil_fill_method","nonmarine_fill_method")) z[[k]] <-
      if(r$recipe_mode=="fixed") "assumed_fixed_recipe_all_years" else paste0("borrowed_year_specific_recipe=",trimws(r$recipe_donor))
    z$feed_source_ids <- r$source_ids
    for (k in c("fishmeal_source_ids","fishoil_source_ids","nonmarine_source_ids")) z[[k]] <-
      r$source_ids
    # These are ASSUMPTION anchor years, not falsely labelled observation years.
    for (k in c("feed_year_low","feed_year_high","marine_year_low","marine_year_high","fishoil_year_low","fishoil_year_high")) z[[k]] <- as.integer(r$anchor_year)
    z$assumption_ids <- paste(r$assumption_id,"C24","C26",sep=";")
    if (config$early_policy=="blank") {
      numeric_fields <- c("efcr","commercial_feed_share","commercial_feed_per_t_output",
        paste0(feeds,"_share"),paste0("efcr_",feeds),paste0(feeds,"_per_t_output"),
        "commercial_feed_per_t_output_low","commercial_feed_per_t_output_high",
        paste0(feeds,"_per_t_output_low"),paste0(feeds,"_per_t_output_high"))
      z[z$year<1995,numeric_fields] <- NA_real_
    }
    extra[[i]] <- z
  }
  out <- rbind(g, af_bind(extra)); out <- out[order(out$source_feed_group,out$year), ]
  rownames(out)<-NULL; af_unique(out,c("source_feed_group","year"),"expanded coefficients")
  out
}

af_append_coverage_evidence <- function(root, result, out) {
  e <- af_read_csv(file.path(root,"data/raw/literature/coverage_evidence.csv"))
  reg <- af_read_csv(file.path(root,"data/raw/literature/source_register.csv"))
  for (k in c("reported_fcr","reported_fcr_low","reported_fcr_high")) result[[k]] <- NA_real_
  result$reported_fcr_basis <- ""
  result$evidence_supports <- ""
  result$does_not_establish <- ""
  rows <- vector("list", nrow(e))
  for(i in seq_len(nrow(e))) {
    z <- result[1, ,drop=FALSE]
    for(k in names(z)) z[[k]] <- if(is.numeric(result[[k]])) NA_real_ else ""
    j <- match(e$source_id[i],reg$source_id); af_assert(!is.na(j),"Unknown evidence source")
    z$source_record_id <- e$evidence_id[i]; z$source_id <- e$source_id[i]
    z$source_feed_group <- e$source_group[i]
    z$year <- af_num(e$reference_year[i],allow_missing=TRUE)
    z$period_type <- e$evidence_type[i]
    z$geography <- reg$geography_scope[j]
    z$source_location <- reg$location[j]; z$source_url <- e$source_url[i]
    z$notes <- paste(e$supports[i],e$does_not_establish[i],sep="; NOT established: ")
    z$feed_mass_basis <- "Context-specific reported FCR; NOT a global commercial eFCR"
    for(k in c("reported_fcr","reported_fcr_low","reported_fcr_high")) z[[k]] <- af_num(e[[k]][i],allow_missing=TRUE)
    z$reported_fcr_basis <- e$reported_fcr_basis[i]
    z$evidence_supports <- e$supports[i]; z$does_not_establish <- e$does_not_establish[i]
    rows[[i]] <- z
  }
  result <- rbind(result,af_bind(rows))
  af_write_csv(e,file.path(root,out,"coverage_literature_evidence.csv"))
  result
}

# Readable per-code application audit, regenerated from the actual run.
af_coverage_mapping_audit <- function(root, co, allocated, years = integer()) {
  ov <- af_read_csv(file.path(root,"data/mappings/coverage_species_overrides.csv"))
  auto <- co$mapping[grepl("^AUTO:", co$mapping$mapping_status), , drop = FALSE]
  if (nrow(auto)) {
    auto_rows <- data.frame(
      species_code = auto$species_code,
      species_name_original = auto$species_name_original,
      ISSCAAP = auto$ISSCAAP,
      previous_source_feed_group = auto$original_source_feed_group,
      source_feed_group = auto$source_feed_group,
      assumption_id = auto$coverage_assumption_id,
      source_ids = auto$coverage_source_ids,
      mapping_rationale = auto$mapping_notes,
      confidence = auto$coverage_confidence,
      output_basis = auto$output_basis,
      resolved_name_override = "",
      identity_source_id = auto$identity_source_id,
      identity_note = auto$identity_note,
      stringsAsFactors = FALSE
    )
    ov <- rbind(ov, auto_rows)
  }
  k <- match(ov$species_code,co$mapping$species_code)
  ov$species_name_resolved <- co$mapping$species_name_resolved[k]
  ov$coverage_layer <- co$mapping$coverage_layer[k]
  years <- intersect(as.integer(years),sort(unique(allocated$year)))
  for(yr in years) {
    tab <- af_aggregate_demand(allocated[allocated$year==yr, ],"species_code")
    j <- match(ov$species_code,tab$species_code)
    for(f in c("production_t","commercial_feed_t","commercial_feed_low_t","commercial_feed_high_t")) {
      v <- tab[[f]][j];v[is.na(j)] <- 0
      ov[[paste0(f,"_",yr)]] <- v
    }
  }
  ov
}
