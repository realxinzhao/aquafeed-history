# Runtime checks for the native-R pipeline. Expected numeric fixtures were produced
# by an independent Python audit; passing them must be established by executing R.
af_checks_v06 <- function(root, raw, co, demand_result=NULL, config) {
  checks <- list()
  check <- function(name, expression) {
    detail <- ""
    ok <- tryCatch({value<-force(expression); isTRUE(value)}, error=function(e) {
      detail<<-conditionMessage(e);FALSE
    })
    if(!ok && !nzchar(detail)) detail<-"Assertion was FALSE"
    checks[[length(checks)+1L]] <<- data.frame(check=name,passed=ok,detail=detail)
  }
  rejects <- function(expr) inherits(tryCatch({force(expr);NULL},error=identity),"error")
  compare <- function(actual, filename, keys, fields, tol, reference="v0.6") {
    expected<-af_read_csv(file.path(root,"tests/reference",reference,filename))
    af_assert(nrow(actual)==nrow(expected),"Regression row count differs")
    i<-match(af_key(expected,keys),af_key(actual,keys))
    af_assert(!anyNA(i),"Regression keys differ")
    for(k in fields) {
      a<-as.numeric(actual[[k]][i]); e<-af_num(expected[[k]],k,allow_missing=TRUE)
      af_assert(identical(is.na(a),is.na(e)),paste("Missingness differs:",k))
      af_assert(af_max_abs(a-e)<=tol,paste("Numerical difference:",k,"max",af_max_abs(a-e)))
    }
    TRUE
  }
  v<-co$species; g<-co$groups
  fields<-c("efcr","commercial_feed_share","commercial_feed_per_t_output",
    paste0(c("FeedCrops","fishmeal","fishoil","OtherFeed"),"_share"),
    paste0("efcr_",c("FeedCrops","fishmeal","fishoil","OtherFeed")),
    paste0(c("FeedCrops","fishmeal","fishoil","OtherFeed"),"_per_t_output"))
  share<-paste0(c("FeedCrops","fishmeal","fishoil","OtherFeed"),"_share")
  conditional<-paste0("efcr_",c("FeedCrops","fishmeal","fishoil","OtherFeed"))
  effective<-paste0(c("FeedCrops","fishmeal","fishoil","OtherFeed"),"_per_t_output")
  check("Species-year keys unique",!anyDuplicated(af_key(v,c("species_code","year"))))
  check("Coefficient grid expands mapping by all configured years",
        nrow(v)==nrow(co$mapping)*(config$year_end-config$year_start+1L))
  check("Original non-pending species assignments preserved",{
    old <- af_read_csv(file.path(root,"tests/reference/v0.6/species_mapping_applied.csv"))
    old <- old[!old$source_feed_group %in% c("UNESTIMATED","OUT_OF_SCOPE"), ,drop=FALSE]
    ix <- match(old$species_code,co$mapping$species_code)
    !anyNA(ix) && all(old$source_feed_group==co$mapping$source_feed_group[ix])
  })
  check("No regional coefficient dimension",!any(c("region","FAO_area_code","country") %in% names(v)))
  check("p is bounded",all(is.na(g$commercial_feed_share) | (g$commercial_feed_share>=0 & g$commercial_feed_share<=1)))
  check("eFCR is nonnegative",all(is.na(g$efcr)|g$efcr>=0))
  check("Ingredient shares bounded",all(is.na(as.matrix(g[share]))| (as.matrix(g[share])>=0 & as.matrix(g[share])<=1)))
  check("Ingredient shares sum to one",af_max_abs(rowSums(g[share])-1)<1e-12)
  check("Conditional source eFCR sums to total",af_max_abs(rowSums(g[conditional])-g$efcr)<1e-12)
  check("Effective source coefficients sum to total",af_max_abs(rowSums(g[effective])-g$commercial_feed_per_t_output)<1e-12)
  check("Effective total is p times eFCR",af_max_abs(g$commercial_feed_per_t_output-g$efcr*g$commercial_feed_share)<1e-12)
  for(f in c("FeedCrops","fishmeal","fishoil","OtherFeed")) check(paste("Effective",f,"applies p exactly once"),
       af_max_abs(g[[paste0(f,"_per_t_output")]]-g$commercial_feed_share*g[[paste0("efcr_",f)]])<1e-12)
  check("Raw undated profiles keep missing year",all(is.na(raw$year[raw$period_type=="undated_illustrative_profile"])))
  check("Raw Naylor total oil remains missing",all(is.na(raw$fishoil_share[raw$source_id=="Naylor2021"])))
  check("Raw company marine protein not called fishmeal",all(is.na(raw$fishmeal_share[raw$source_id=="Skretting2021"])))
  check("Unknown feed is not coerced to zero",all(is.na(v$commercial_feed_per_t_output[v$source_feed_group=="UNESTIMATED"])))
  check("Nonfed effective inputs are zero",all(v$commercial_feed_per_t_output[v$source_feed_group=="NONFED"]==0))
  check("Nonfed conditional eFCR is undefined",all(is.na(v$efcr[v$source_feed_group=="NONFED"])))
  check("Silver/bighead correction explicitly mapped",all(co$mapping$source_feed_group[co$mapping$species_code %in% c("SVC","BIC")]=="NONFED"))
  if(af_coverage_policy(config)=="expanded") {
    check("Indian major carps use explicit coverage assumption",all(co$mapping$source_feed_group[co$mapping$species_code %in% c("CTT","LRH","CMG")]=="X_Indian_major_carps"))
    check("All historical pending species are explicitly assigned",!any(co$mapping$source_feed_group %in% c("UNESTIMATED","OUT_OF_SCOPE")))
    check("Every audited coverage override is applied",sum(co$mapping$coverage_layer %in% c("coverage_extension","coverage_assumed_zero"))==nrow(af_read_csv(file.path(root,"data/mappings/coverage_species_overrides.csv"))))
    check("All explicit zero overrides applied",sum(co$mapping$coverage_layer=="coverage_assumed_zero")==sum(af_read_csv(file.path(root,"data/mappings/coverage_species_overrides.csv"))$source_feed_group=="NONFED"))
    check("New reported FCR evidence is not a measured global eFCR",all(is.na(raw$efcr[grepl("^CE",raw$source_record_id)])))
    check("Sensitivity bounds contain selected coefficient",all(is.na(g$commercial_feed_per_t_output) | (g$commercial_feed_per_t_output_low<=g$commercial_feed_per_t_output & g$commercial_feed_per_t_output_high>=g$commercial_feed_per_t_output)))
    check("New zero rows keep conditional eFCR undefined",all(is.na(v$efcr[v$coverage_layer=="coverage_assumed_zero"])))
    check("No claim of complete all-external-feed accounting",all(!v$complete_all_external_feed_estimate))
    check("All coverage source identifiers resolve",{
      z<-af_read_csv(file.path(root,"data/mappings/coverage_species_overrides.csv"))
      ids<-unique(unlist(strsplit(z$source_ids,";",fixed=TRUE)))
      all(ids %in% af_read_csv(file.path(root,"data/raw/literature/source_register.csv"))$source_id)
    })
  } else check("Original policy retains unestimated carp scope",all(co$mapping$source_feed_group[co$mapping$species_code %in% c("CTT","LRH","CMG")]=="UNESTIMATED"))
  if(config$year_start<=2021 && config$year_end>=2021) {
    a<-v[v$year==2021 & v$species_code=="TLN", ]
    check("2021 tilapia coverage and total",nrow(a)==1L && abs(a$efcr-1.7)<1e-12 && abs(a$commercial_feed_per_t_output-1.632)<1e-12)
    if(isTRUE(config$use_recent_fishoil)) check("2021 tilapia oil total is explicit company proxy",abs(a$fishoil_share-0.002)<1e-12)
  }
  check("Projection rows not selected for total-feed history",all(af_prepare_sources(root,FALSE)$selected$period_type=="historical_estimate"))
  if(config$early_policy=="blank") check("Blank policy suppresses early values",all(is.na(g$efcr[g$year<1995]))) else
    check("Early backcast clearly flagged",all(g$early_backcast[g$year<1995]==1L))
  standard<-config$year_start==1973L && config$year_end==2023L && config$early_policy=="hold" &&
    isTRUE(config$use_recent_fishoil) && isTRUE(config$use_recent_nonmarine)
  # Do not fail legitimate user-edited assumptions against frozen default-scenario outputs.
  guard<-af_read_csv(file.path(root,"tests/reference/v0.7/scientific_input_md5.csv"))
  hashes<-unname(tools::md5sum(file.path(root,guard$path)))
  default_science<-!anyNA(hashes) && identical(hashes,guard$md5)
  if(standard && default_science) {
    check("All previously populated numeric species values unchanged",{
      old <- af_read_csv(file.path(root,"tests/reference/v0.6.1/species_coefficients_baseline.csv"))
      ov <- af_read_csv(file.path(root,"data/mappings/coverage_species_overrides.csv"))
      old <- old[!old$species_code %in% ov$species_code, ,drop=FALSE]
      j <- match(af_key(old,c("species_code","year")),af_key(v,c("species_code","year")))
      af_assert(!anyNA(j),"Missing previously mapped species/year")
      for(f in fields) {
        a <- af_num(old[[f]],allow_missing=TRUE); b <- v[[f]][j]
        af_assert(identical(is.na(a),is.na(b)),paste("Missingness changed",f))
        af_assert(af_max_abs(a-b)<1e-10,paste("Value changed",f))
      }
      TRUE
    })
    check("Original group coefficients unchanged",compare(g[g$coverage_layer=="original_tacon_core", ],"expected_group_year.csv",c("source_feed_group","year"),fields,1e-10))
    if(af_coverage_policy(config)=="expanded") check("Expanded annual coefficients vs independent audit",
      compare(g,"expected_group_year.csv",c("source_feed_group","year"),c(fields,"commercial_feed_per_t_output_low","commercial_feed_per_t_output_high"),1e-10,"v0.7"))
  } else message("Default numeric fixtures skipped: configuration or scientific inputs changed. Structural checks still run.")
  if(!is.null(demand_result)) {
    d<-demand_result$demand; a<-d$allocated
    check("Country demand totals equal global totals",af_max_abs(stats::aggregate(d$country$commercial_feed_t,list(d$country$year),sum,na.rm=TRUE)$x-d$global$commercial_feed_t)<1e-5)
    check("Country-technology demand totals equal global totals",af_max_abs(stats::aggregate(d$country_technology$commercial_feed_t,list(d$country_technology$year),sum,na.rm=TRUE)$x-d$global$commercial_feed_t)<1e-5)
    check("Coverage partition conserves production",af_max_abs(a$production_t-(a$feed_coefficient_covered_output_t+a$nonfed_output_t+a$unestimated_output_t+a$excluded_output_t))<1e-6)
    check("Commercially fed output does not exceed covered production",all(a$estimated_commercially_fed_output_t<=a$feed_coefficient_covered_output_t+1e-8))
    check("Original core plus extensions conserve total",af_max_abs(d$global$tacon_comparable_feed_t+d$global$coverage_extension_feed_t-d$global$commercial_feed_t)<1e-5)
    check("Product tonnes separated from live denominator",af_max_abs(d$global$production_t-d$global$live_output_t-d$global$non_live_product_output_t)<1e-5)
    if(af_coverage_policy(config)=="expanded" && config$early_policy=="hold") {
      check("Default expanded commercial coverage is complete",all(d$global$unestimated_output_t==0 & d$global$excluded_output_t==0))
    }
    check("Feed components conserve feed",af_max_abs(rowSums(a[c("FeedCrops_t","fishmeal_t","fishoil_t","OtherFeed_t")])-a$commercial_feed_t)<1e-6)
    if(nrow(d$weights)) check("Historical mixture weights sum to one",all(abs(stats::aggregate(d$weights$weight,d$weights[c("FAO_area_code","water_area_code","ISSCAAP")],sum)$x-1)<1e-10))
    input<-af_read_csv(af_path(root,config$production_file))
    check("Production input total conserved",abs(sum(a$production_t)-sum(as.numeric(input$value)))<1e-4)
    if("species_code" %in% names(input)) {
      check("All supplied species have an explicit mapping",all(input$species_code %in% co$mapping$species_code))
      check("Direct species processing preserves record count",nrow(a)==nrow(input))
      check("Direct species uses unit weight and no inferred mixtures",
        nrow(d$weights)==0L && all(a$weight==1) && all(a$mixture_basis=="observed_species_production"))
    }
    z<-input[seq_len(min(3L,nrow(input))), ,drop=FALSE]
    test<-z;test$supply[1]<-"Capture"
    check("Capture input rejected",rejects(af_clean_production(test,1973:2023)))
    test<-z;test$measure[1]<-"Q_kg"
    check("Wrong units rejected",rejects(af_clean_production(test,1973:2023)))
    test<-z;test$value[1]<-"-1"
    check("Negative production rejected",rejects(af_clean_production(test,1973:2023)))
    test<-rbind(z,z[1, ,drop=FALSE])
    check("Duplicate production rejected",rejects(af_clean_production(test,1973:2023)))
    if("species_code" %in% names(z)) {
      test<-z;test$species_code[1]<-""
      check("Empty species code rejected",rejects(af_clean_production(test,1973:2023)))
      test<-z;test$species_code[1]<-"__UNMAPPED_TEST__"
      ctest<-config;ctest$root<-root
      check("Unmapped species code rejected",rejects(af_apply_history(test,NULL,co,ctest)))
    }
    test<-z;test$year[1]<-"2024"
    check("Unsupported year rejected",rejects(af_clean_production(test,1973:2023)))
    expected_input_md5 <- af_read_csv(file.path(root,"tests/reference/v0.6.1/input_md5.csv"))$md5[1]
    is_reference_input <- identical(unname(tools::md5sum(af_path(root,config$production_file))),expected_input_md5)
    if(standard && is_reference_input && default_science) {
      selected_ref<-if(af_coverage_policy(config)=="expanded") "v0.7" else "v0.6.1"
      compare_fields<-intersect(c(af_coverage_metrics,af_demand_metrics),names(af_read_csv(file.path(root,"tests/reference",selected_ref,"expected_global_demand.csv"))))
      check("Original comparable subtotal agrees with previous release",{
        original<-af_read_csv(file.path(root,"tests/reference/v0.6.1/expected_global_demand.csv"))
        i<-match(as.integer(original$year),d$global$year)
        !anyNA(i) && af_max_abs(d$global$tacon_comparable_feed_t[i]-as.numeric(original$commercial_feed_t))<1e-3
      })
      check("Global historical demand vs independent audit",compare(d$global,"expected_global_demand.csv","year",compare_fields,1e-3,selected_ref))
      check("Country historical demand vs independent audit",compare(d$country,"expected_country_demand.csv",c("FAO_area_code","year"),compare_fields,1e-3,selected_ref))
    }
  }
  sys.source(file.path(root,"tests/test_gcamdata_exports.R"),envir=environment())
  af_test_gcamdata_exports(check,rejects,co,config)
  result<-af_bind(checks)
  af_write_csv(result,file.path(root,"validation/R_test_results.csv"))
  if(any(!result$passed)) stop(sprintf("%s R checks failed; see %s",sum(!result$passed),file.path(root,"validation/R_test_results.csv")),call.=FALSE)
  message(nrow(result)," native-R checks passed.")
  invisible(result)
}
