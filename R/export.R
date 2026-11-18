# The compact GCAM input is a projection of the full species-year coefficient table.
# Keep one writer for both formats; headers and data share one open connection.
af_gcamdata_column_types <- c(species_code = "c", year = "i",
  FeedCrops_per_t_output = "n", fishmeal_per_t_output = "n",
  fishoil_per_t_output = "n", OtherFeed_per_t_output = "n")

af_export_gcamdata_coefficients <- function(species, out,
    formats = c("csv", "csv.gz"), update_date = Sys.Date()) {
  af_assert(is.character(formats) && !anyNA(formats) &&
              all(formats %in% c("csv", "csv.gz")),
            "gcamdata_formats must contain only 'csv' and/or 'csv.gz'")
  formats <- unique(formats)
  columns <- names(af_gcamdata_column_types)
  af_assert(is.data.frame(species) && all(columns %in% names(species)),
            "GCAM export requires species_code, year and all four ingredient coefficients")
  x <- species[, columns, drop = FALSE]
  x$species_code <- as.character(x$species_code)
  af_assert(all(!is.na(x$species_code) & nzchar(trimws(x$species_code))),
            "GCAM export requires nonempty species codes")
  x$year <- af_year(x$year)
  for (field in columns[-c(1L, 2L)]) {
    x[[field]] <- af_num(x[[field]], field, allow_missing = TRUE)
    af_assert(all(is.na(x[[field]]) | x[[field]] >= 0),
              paste("Negative GCAM coefficient:", field))
  }
  af_unique(x, c("species_code", "year"), "GCAM species-year")
  x <- x[order(x$species_code, x$year), , drop = FALSE]
  date <- as.character(update_date)
  af_assert(length(date) == 1L && !is.na(date) &&
              grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", date) &&
              !is.na(as.Date(date, format = "%Y-%m-%d")),
            "update_date must be a date in YYYY-MM-DD form")
  if (!length(formats)) return(setNames(character(), character()))
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  old <- options(digits = 17); on.exit(options(old), add = TRUE)
  write_one <- function(format) {
    path <- file.path(out, paste0("aquaculture_feed_coefficients_species_year.", format))
    header <- c(
      paste0("File: ", basename(path)),
      "Title: Aquaculture commercial-feed ingredient inputs by species and year",
      "Units: t feed ingredient per t total aquaculture output (normally live weight)",
      paste0("Description: Effective coefficients = commercial_feed_share * efcr * ingredient_share; ",
             "share already applied. Ingredient mass as reported; no moisture or reduction-yield conversion. ",
             "Pearl/shell product rows use documented zero commercial grow-out inputs. ",
             "See docs/METHODS.md and outputs/02_coefficients for assumptions and provenance."),
      paste0("Data source: Tacon and Metian (2015); Tacon et al. (2026); FAO 564 (2011); ",
             "Naylor et al. (2021); Skretting (2021); documented coverage assumptions. ",
             "https://github.com/realxinzhao/aquafeed-history"),
      paste0("Date of CSV last update: ", date),
      paste0("Column types: ", paste0(af_gcamdata_column_types, collapse = "")),
      "----------")
    connection <- if (format == "csv.gz") gzfile(path, open = "wt", encoding = "UTF-8") else
      file(path, open = "wt", encoding = "UTF-8")
    on.exit(close(connection), add = TRUE)
    writeLines(paste0("# ", header), connection, useBytes = TRUE)
    utils::write.table(x, connection, sep = ",", row.names = FALSE, col.names = TRUE,
                       na = "", quote = TRUE, qmethod = "double")
    path
  }
  paths <- vapply(formats, write_one, character(1))
  invisible(paths)
}
