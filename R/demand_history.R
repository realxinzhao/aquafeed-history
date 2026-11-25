# Application checks, not coefficient calibration. No fitted regional multipliers.
# Aggregated histories are never represented as observed species histories.
af_demand_metrics <- c("commercial_feed_t","FeedCrops_t","fishmeal_t","fishoil_t","OtherFeed_t")
af_demand_metrics <- c(af_demand_metrics,"tacon_comparable_feed_t","coverage_extension_feed_t",
  "commercial_feed_low_t","commercial_feed_high_t")
af_coverage_metrics <- c("production_t","feed_coefficient_covered_output_t","nonfed_output_t",
                        "unestimated_output_t","excluded_output_t","estimated_commercially_fed_output_t",
  "assumption_covered_output_t","assumed_zero_output_t","non_live_product_output_t","live_output_t")

af_clean_production <- function(d, years) {
  req <- c("FAO_area_code","water_area_code","ISSCAAP","year","value","supply","measure")
  af_assert(all(req %in% names(d)),"Production columns missing")
  af_assert(all(d$supply=="Aquaculture"),"Refusing capture-production records")
  af_assert(all(d$measure=="Q_tlw"),"Expected live-weight tonnes (Q_tlw)")
  d$year <- af_year(d$year); d$value <- af_num(d$value,"production")
  af_assert(all(d$value>=0),"Negative production")
  af_assert(all(d$year %in% years),"Production year outside coefficient coverage")
  for (k in c("FAO_area_code","water_area_code")) d[[k]] <- as.character(af_num(d[[k]],k))
  if ("species_code" %in% names(d)) d$species_code <- trimws(d$species_code)
  keys <- c("FAO_area_code","water_area_code",if ("species_code" %in% names(d)) "species_code" else "ISSCAAP","year")
  for (k in keys) af_assert(all(!is.na(d[[k]]) & nzchar(trimws(as.character(d[[k]]))) &
    !(as.character(d[[k]]) %in% c("NA", "NaN"))), paste("Missing production key:", k))
  af_unique(d,keys,"production")
  d$input_row_id <- seq_len(nrow(d))
  d
}

af_make_history_weights <- function(history, reference, crosswalk, method="country_2021") {
  af_assert(method %in% c("country_2021","global_2021"),"Unknown history mixture method")
  ref <- af_clean_production(reference,2021L)
  af_assert("species_code" %in% names(ref),"2021 reference must include species_code")
  ix <- match(ref$species_code,crosswalk$species_code)
  af_assert(!anyNA(ix),"Unmapped 2021 reference species")
  af_assert(all(ref$ISSCAAP==crosswalk$ISSCAAP[ix]),"Reference ISSCAAP/crosswalk mismatch")
  ref$source_feed_group <- crosswalk$source_feed_group[ix]
  ref <- ref[ref$value>0, ]
  make <- function(keys) {
    w <- stats::aggregate(ref$value,ref[c(keys,"source_feed_group")],sum)
    names(w)[ncol(w)] <- "reference_production_t"
    totals <- ave(w$reference_production_t,af_key(w,keys),FUN=sum)
    w$weight <- w$reference_production_t/totals
    w
  }
  keys <- c("FAO_area_code","water_area_code","ISSCAAP")
  cell <- make(keys); country <- make(c("FAO_area_code","ISSCAAP")); world <- make("ISSCAAP")
  cells <- unique(history[keys]); result <- vector("list",nrow(cells))
  for (i in seq_len(nrow(cells))) {
    x <- cells[i, ]; chosen <- world[world$ISSCAAP==x$ISSCAAP, ]
    basis <- "2021_global_ISSCAAP_mix"
    if (method=="country_2021") {
      a <- cell[cell$FAO_area_code==x$FAO_area_code & cell$water_area_code==x$water_area_code & cell$ISSCAAP==x$ISSCAAP, ]
      b <- country[country$FAO_area_code==x$FAO_area_code & country$ISSCAAP==x$ISSCAAP, ]
      if (nrow(a)) {chosen<-a;basis<-"2021_country_water_ISSCAAP_mix"} else
        if (nrow(b)) {chosen<-b;basis<-"2021_country_ISSCAAP_mix"}
    }
    if (!nrow(chosen)) {
      chosen <- data.frame(source_feed_group="UNESTIMATED",reference_production_t=NA_real_,weight=1)
      basis <- "no_reference_species_mix_unestimated"
    }
    result[[i]] <- cbind(x[rep(1L,nrow(chosen)), ,drop=FALSE],
      chosen[c("source_feed_group","reference_production_t","weight")],
      data.frame(mixture_basis=rep(basis,nrow(chosen)),reference_year=2021L,
                 historical_transfer="2021_mix_held; not observed historical species composition"))
  }
  w <- af_bind(result); rownames(w)<-NULL
  sums <- stats::aggregate(w$weight,w[keys],sum)
  af_assert(all(abs(sums$x-1)<1e-10),"Mixture weights do not sum to one")
  w
}

af_aggregate_demand <- function(d, keys) {
  if (!nrow(d)) {
    r <- d[FALSE,keys,drop=FALSE]
    for(k in c(af_coverage_metrics,af_demand_metrics,"modeled_production_fraction")) r[[k]] <- numeric(0)
    r$complete_feed_estimate <- logical(0)
    r$complete_all_external_feed_estimate <- logical(0)
    return(r)
  }
  ix <- split(seq_len(nrow(d)),af_key(d,keys),drop=TRUE)
  out <- lapply(ix,function(i) {
    r <- d[i[1],keys,drop=FALSE]
    for (k in af_coverage_metrics) r[[k]] <- sum(d[[k]][i])
    for (k in af_demand_metrics) r[[k]] <- af_sum_known(d[[k]][i])
    r$modeled_production_fraction <- if (r$production_t>0)
      (r$feed_coefficient_covered_output_t+r$nonfed_output_t)/r$production_t else NA_real_
    r$complete_feed_estimate <- r$unestimated_output_t<1e-8 && r$excluded_output_t<1e-8
    r$complete_all_external_feed_estimate <- FALSE
    r
  })
  result <- af_bind(out)
  result <- result[do.call(order,result[keys]), ,drop=FALSE];rownames(result)<-NULL
  result
}

af_apply_history <- function(input, reference, co, config, mixture_method="country_2021") {
  d <- af_clean_production(input,seq.int(config$year_start,config$year_end))
  if ("species_code" %in% names(d)) {
    ix <- match(d$species_code,co$mapping$species_code)
    af_assert(!anyNA(ix),paste("New species require explicit mapping:",paste(unique(d$species_code[is.na(ix)]),collapse=", ")))
    af_assert(all(d$ISSCAAP==co$mapping$ISSCAAP[ix]),"Species/ISSCAAP conflict")
    d$source_feed_group <- co$mapping$source_feed_group[ix]
    d$coverage_layer <- co$mapping$coverage_layer[ix]
    d$coverage_assumption_id <- co$mapping$coverage_assumption_id[ix]
    d$output_basis <- co$mapping$output_basis[ix]
    d$weight <- 1; d$mixture_basis<-"observed_species_production"
    weights <- data.frame()
  } else {
    weights <- af_make_history_weights(d,reference,co$mapping,mixture_method)
    d <- merge(d,weights,by=c("FAO_area_code","water_area_code","ISSCAAP"),sort=FALSE,all.x=TRUE)
    af_assert(!anyNA(d$weight),"Missing aggregation weights")
  }
  gmap <- af_read_csv(file.path(config$root,"data/mappings/GCAM_group_mapping.csv"))
  m <- match(d$ISSCAAP,gmap$ISSCAAP)
  for (k in c("GCAM_subsector","GCAM_commodity")) {
    v <- gmap[[k]][m];v[is.na(v)]<-"OUT_OF_SCOPE"
    if (k %in% names(d)) af_assert(all(is.na(m)|d[[k]]==v),paste("Supplied",k,"conflicts with mapping")) else d[[k]]<-v
  }
  d$production_t <- d$value*d$weight
  ix <- match(af_key(d,c("source_feed_group","year")),af_key(co$groups,c("source_feed_group","year")))
  c <- co$groups[ix, ]; fed <- !is.na(c$commercial_feed_per_t_output)
  nonfed <- d$source_feed_group=="NONFED"; excluded<-d$source_feed_group=="OUT_OF_SCOPE"
  d$feed_coefficient_covered_output_t <- ifelse(fed,d$production_t,0)
  d$estimated_commercially_fed_output_t <- ifelse(fed, d$production_t*c$commercial_feed_share, 0)
  d$nonfed_output_t <- ifelse(nonfed,d$production_t,0)
  d$excluded_output_t <- ifelse(excluded,d$production_t,0)
  d$unestimated_output_t <- ifelse(!(fed|nonfed|excluded),d$production_t,0)
  fields <- c("commercial_feed_per_t_output","FeedCrops_per_t_output","fishmeal_per_t_output","fishoil_per_t_output","OtherFeed_per_t_output")
  for (k in seq_along(fields)) {
    d[[af_demand_metrics[k]]] <- d$production_t*c[[fields[k]]]
    d[[af_demand_metrics[k]]][nonfed|d$production_t==0] <- 0
  }
  # Layered totals: source-consistency benchmark excludes the explicitly new assumptions.
  if (!"coverage_layer" %in% names(d)) {
    d$coverage_layer <- ifelse(grepl("^X_",d$source_feed_group),"coverage_extension","original_tacon_core")
    d$coverage_assumption_id <- ifelse(is.na(c$coverage_assumption_id),"",c$coverage_assumption_id)
    d$output_basis <- ifelse(d$ISSCAAP=="Pearls, mother-of-pearl, shells","pearl_shell_product","reported_live_weight")
  }
  ext <- d$coverage_layer=="coverage_extension"
  d$tacon_comparable_feed_t <- ifelse(ext,0,d$commercial_feed_t)
  d$coverage_extension_feed_t <- ifelse(ext,d$commercial_feed_t,0)
  d$commercial_feed_low_t <- d$production_t*c$commercial_feed_per_t_output_low
  d$commercial_feed_high_t <- d$production_t*c$commercial_feed_per_t_output_high
  d$commercial_feed_low_t[nonfed|d$production_t==0] <- 0
  d$commercial_feed_high_t[nonfed|d$production_t==0] <- 0
  d$assumed_zero_output_t <- ifelse(d$coverage_layer=="coverage_assumed_zero",d$production_t,0)
  d$assumption_covered_output_t <- ifelse((ext & fed)|d$coverage_layer=="coverage_assumed_zero",d$production_t,0)
  d$non_live_product_output_t <- ifelse(d$output_basis=="pearl_shell_product",d$production_t,0)
  d$live_output_t <- d$production_t-d$non_live_product_output_t
  d$feed_fill_method <- c$feed_fill_method;d$fishoil_scope<-c$fishoil_scope
  d$early_backcast <- as.integer(d$year<1995 & fed)
  af_assert(abs(sum(d$production_t)-sum(as.numeric(input$value)))<1e-4,"Allocation changed total production")
  balance <- rowSums(d[c("FeedCrops_t","fishmeal_t","fishoil_t","OtherFeed_t")])-d$commercial_feed_t
  af_assert(af_max_abs(balance)<1e-6,"Row feed mass balance failed")
  list(allocated=d,weights=weights,global=af_aggregate_demand(d,"year"),
    country=af_aggregate_demand(d,c("FAO_area_code","year")),
    technology=af_aggregate_demand(d,c("GCAM_subsector","year")),
    country_technology=af_aggregate_demand(d,c("FAO_area_code","GCAM_subsector","year")))
}

af_compare_benchmarks <- function(demand, benchmarks) {
  b <- benchmarks;b$year<-as.integer(b$year);b$benchmark_feed_t<-as.numeric(b$benchmark_feed_t)
  b$estimated_commercial_feed_t<-NA_real_
  b$expanded_commercial_feed_t<-NA_real_
  b$comparison_scope <- ifelse(b$source_id=="Tacon2026","original_12_group_subtotal","expanded_commercial_total")
  for (i in seq_len(nrow(b))) {
    tab <- if (b$geography[i]=="Global") demand$global else demand$country[demand$country$FAO_area_code==b$FAO_area_code[i], ]
    tab <- tab[tab$year==b$year[i], ]
    field <- if(b$source_id[i]=="Tacon2026") "tacon_comparable_feed_t" else "commercial_feed_t"
    if(nrow(tab)==1L) {
      b$estimated_commercial_feed_t[i] <- tab[[field]]
      b$expanded_commercial_feed_t[i] <- tab$commercial_feed_t
    }
  }
  b$difference_t <- b$estimated_commercial_feed_t-b$benchmark_feed_t
  b$relative_difference <- b$difference_t/b$benchmark_feed_t
  b$status <- ifelse(is.na(b$relative_difference),"NO_MATCHING_PRODUCTION_YEAR_OR_REGION",
    ifelse(abs(b$relative_difference)>0.2,"LARGE_DIFFERENCE_REVIEW_NOT_A_CODE_FAILURE","COMPARISON_ONLY_NOT_VALIDATION_PROOF"))
  b
}

af_stage3_check_demand <- function(root,co,config) {
  config$root <- root
  input<-af_read_csv(af_path(root,config$production_file))
  direct_input <- "species_code" %in% names(input)
  need_ref <- !direct_input || isTRUE(config$run_2021_reference_check)
  ref <- if(need_ref) af_read_csv(af_path(root,config$species_reference_file)) else NULL
  output<-file.path(root,config$output_dir,"03_demand_checks")
  dir.create(output,recursive=TRUE,showWarnings=FALSE)
  # Remove conditional products from older runs, including the superseded mixture history.
  for(f in c("historical_species_mix_assumptions.csv",
      "global_feed_demand_global_mix_sensitivity.csv","country_feed_demand_global_mix_sensitivity.csv",
      "species_2021_direct_check.csv","allocated_production_and_feed.csv",
      "unestimated_production_by_species_year.csv")) unlink(file.path(output,f))
  old_coverage_audits <- list.files(output, pattern="^coverage_mapping_audit_[0-9]+_[0-9]+[.]csv$",
                                    full.names=TRUE)
  if(length(old_coverage_audits)) unlink(old_coverage_audits)
  d<-af_apply_history(input,ref,co,config,"country_2021")
  af_write_csv(d$global,file.path(output,"global_feed_demand.csv"))
  af_write_csv(d$country,file.path(output,"country_feed_demand.csv"))
  af_write_csv(d$technology,file.path(output,"technology_feed_demand.csv"))
  af_write_csv(d$country_technology,file.path(output,"country_technology_feed_demand.csv"))
  if(nrow(d$weights)) af_write_csv(d$weights,file.path(output,"historical_species_mix_assumptions.csv"))
  if(isTRUE(config$write_allocated_rows)) af_write_csv(d$allocated,file.path(output,"allocated_production_and_feed.csv"))
  unknown<-d$allocated[d$allocated$unestimated_output_t>0, ]
  af_write_csv(af_aggregate_demand(unknown,c("FAO_area_code","ISSCAAP","year")),
    file.path(output,"unestimated_production_by_country_group_year.csv"))
  if(direct_input) {
    af_write_csv(af_aggregate_demand(unknown,c("species_code","ISSCAAP","year")),
      file.path(output,"unestimated_production_by_species_year.csv"))
  }
  if(direct_input) {
    audit_years <- intersect(seq.int(2021L,config$year_end),sort(unique(d$allocated$year)))
    if(af_coverage_policy(config)=="expanded" && length(audit_years)) {
      audit_name <- paste0("coverage_mapping_audit_",min(audit_years),"_",max(audit_years),".csv")
      af_write_csv(af_coverage_mapping_audit(root,co,d$allocated,audit_years),
        file.path(output,audit_name))
    }
    extrows <- d$allocated[d$allocated$coverage_layer %in% c("coverage_extension","coverage_assumed_zero"), ]
    af_write_csv(af_aggregate_demand(extrows,c("source_feed_group","coverage_assumption_id","year")),
      file.path(output,"coverage_extension_by_group_year.csv"))
    af_write_csv(af_aggregate_demand(extrows,c("species_code","coverage_assumption_id","year")),
      file.path(output,"coverage_extension_by_species_year.csv"))
  }
  af_write_csv(d$global[c("year","tacon_comparable_feed_t","coverage_extension_feed_t","commercial_feed_t",
    "commercial_feed_low_t","commercial_feed_high_t","unestimated_output_t","excluded_output_t",
    "assumption_covered_output_t","assumed_zero_output_t","non_live_product_output_t",
    "complete_feed_estimate","complete_all_external_feed_estimate")],file.path(output,"core_vs_expanded_global.csv"))
  benchmarks<-af_read_csv(file.path(root,"data/raw/benchmarks/commercial_feed_benchmarks.csv"))
  comparison<-af_compare_benchmarks(d,benchmarks)
  af_write_csv(comparison,file.path(output,"benchmark_comparison.csv"))
  if(isTRUE(config$run_global_mix_sensitivity) && !direct_input) {
    z<-af_apply_history(input,ref,co,config,"global_2021")
    af_write_csv(z$global,file.path(output,"global_feed_demand_global_mix_sensitivity.csv"))
    af_write_csv(z$country,file.path(output,"country_feed_demand_global_mix_sensitivity.csv"))
  }
  if(isTRUE(config$run_2021_reference_check)) {
    reference_check<-af_apply_history(ref,ref,co,config)
    af_write_csv(reference_check$global,file.path(output,"species_2021_direct_check.csv"))
  }
  audit<-data.frame(item=c("input_rows","first_year","last_year","number_years","reporting_areas",
    "ISSCAAP_groups","contains_species_code","species_codes","calculation_basis",
    "production_2021_t","production_2022_t","production_2023_t","production_2024_t"),
    value=c(nrow(input),min(as.integer(input$year)),max(as.integer(input$year)),length(unique(input$year)),
      length(unique(input$FAO_area_code)),length(unique(input$ISSCAAP)),direct_input,
      if(direct_input) length(unique(input$species_code)) else NA,
      if(direct_input) "observed_species_production; no_2021_species_mixture" else "2021_species_mixture_assumption",
      sum(as.numeric(input$value[input$year=="2021"])),sum(as.numeric(input$value[input$year=="2022"])),
      sum(as.numeric(input$value[input$year=="2023"])),sum(as.numeric(input$value[input$year=="2024"]))),stringsAsFactors=FALSE)
  af_write_csv(audit,file.path(output,"production_input_audit.csv"))
  list(demand=d,comparison=comparison)
}
