# Exercise the public file contract: metadata, gzip, missing values and reruns.
af_test_gcamdata_exports <- function(check, rejects, co, config) {
  columns <- c("species_code", "year", "FeedCrops_per_t_output",
    "fishmeal_per_t_output", "fishoil_per_t_output", "OtherFeed_per_t_output")
  read_export <- function(path) {
    utils::read.csv(path, comment.char = "#", check.names = FALSE,
      colClasses = c("character", "integer", rep("numeric", 4)),
      na.strings = "", stringsAsFactors = FALSE)
  }
  read_lines <- function(path) {
    con <- if (grepl("[.]gz$", path)) gzfile(path, "rt") else file(path, "rt")
    on.exit(close(con), add = TRUE)
    readLines(con, warn = FALSE)
  }
  equal_values <- function(actual, expected) {
    expected <- expected[order(expected$species_code, expected$year), columns, drop = FALSE]
    rownames(expected) <- NULL
    isTRUE(all.equal(actual, expected, check.attributes = FALSE, tolerance = 1e-14))
  }
  formats <- if(is.null(config$gcamdata_formats)) c("csv", "csv.gz") else config$gcamdata_formats
  check("Configured GCAM exports exist",identical(names(co$gcamdata_files),unique(formats)) &&
          all(file.exists(co$gcamdata_files)))
  for (format in names(co$gcamdata_files)) {
    path <- co$gcamdata_files[[format]]
    check(paste("GCAM metadata and schema",format),{
      lines <- read_lines(path)
      header <- lines[startsWith(lines,"#")]
      identical(header[1],paste0("# File: ",basename(path))) &&
        length(header)==8L && sum(header=="# Column types: cinnnn")==1L &&
        all(vapply(c("Title:","Units:","Description:","Data source:","Date of CSV last update:"),
          function(label) sum(startsWith(header,paste0("# ",label)))==1L,logical(1))) &&
        identical(names(read_export(path)),columns)
    })
    check(paste("GCAM values match full coefficient table",format),
          equal_values(read_export(path),co$species))
  }
  folder <- tempfile("aquafeed-export-")
  on.exit(unlink(folder,recursive=TRUE),add=TRUE)
  # Character codes (including literal NA), CSV quoting, tiny numbers and missing
  # coefficients must survive both formats without being coerced into zero.
  sample <- data.frame(species_code=c("001","NA","A,\"B"),year=c(1973L,2021L,2023L),
    FeedCrops_per_t_output=c(0,NA,1.23456789012345),fishmeal_per_t_output=c(0,0.1,1e-12),
    fishoil_per_t_output=c(NA,0,0.02),OtherFeed_per_t_output=c(0,0.4,0.03))
  paths <- af_export_gcamdata_coefficients(sample,folder,update_date="2026-01-01")
  check("GCAM export preserves codes, zeros and missing values in both formats",
    all(vapply(paths,function(path) equal_values(read_export(path),sample),logical(1))))
  check("CSV and gzip contain identical metadata and data apart from filename",{
    plain <- read_lines(paths[["csv"]]); zipped <- read_lines(paths[["csv.gz"]])
    identical(plain[-1],zipped[-1])
  })
  check("GCAM gz output has a gzip signature",{
    con <- file(paths[["csv.gz"]],"rb")
    signature <- readBin(con,"raw",n=2L);close(con)
    identical(signature,as.raw(c(0x1f,0x8b)))
  })
  before <- lapply(paths,read_lines)
  af_export_gcamdata_coefficients(sample,folder,update_date="2026-01-01")
  check("Repeated GCAM exports replace rather than append files",
        identical(before,lapply(paths,read_lines)))
  check("Single-format GCAM export does not create the other format",{
    csv_only <- af_export_gcamdata_coefficients(sample,file.path(folder,"csv-only"),"csv")
    gz_only <- af_export_gcamdata_coefficients(sample,file.path(folder,"gz-only"),"csv.gz")
    length(list.files(dirname(csv_only)))==1L && length(list.files(dirname(gz_only)))==1L &&
      equal_values(read_export(csv_only),sample) && equal_values(read_export(gz_only),sample)
  })
  check("Invalid export formats rejected",rejects(af_export_gcamdata_coefficients(sample,folder,"zip")))
  check("Duplicate GCAM keys rejected",rejects(af_export_gcamdata_coefficients(rbind(sample,sample[1,]),folder)))
  check("Fractional GCAM years rejected",{
    bad <- sample;bad$year[1] <- 2021.5
    rejects(af_export_gcamdata_coefficients(bad,folder))
  })
  invisible(NULL)
}
