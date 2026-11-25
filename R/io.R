# Base-R utilities. Codes are always read as character to preserve leading zeros.
af_assert <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
  invisible(TRUE)
}

af_read_csv <- function(path, required = character()) {
  af_assert(file.exists(path), paste("Missing file:", path))
  compressed <- grepl("[.]gz$", path, ignore.case = TRUE)
  open_input <- function() {
    if (compressed) gzfile(path, open = "rt") else
      file(path, open = "rt", encoding = "UTF-8-BOM")
  }
  probe <- open_input()
  probe_closed <- FALSE
  on.exit(if (!probe_closed) close(probe), add = TRUE)
  skip <- 0L
  repeat {
    line <- readLines(probe, n = 1L, warn = FALSE)
    if (!length(line)) break
    line <- trimws(sub("^\\ufeff", "", line))
    if (!nzchar(line) || startsWith(line, "#")) skip <- skip + 1L else break
  }
  close(probe)
  probe_closed <- TRUE
  if (compressed) {
    input <- open_input()
    on.exit(close(input), add = TRUE)
    x <- utils::read.csv(input, skip = skip, colClasses = "character",
                         check.names = FALSE, stringsAsFactors = FALSE,
                         na.strings = character(), row.names = NULL)
  } else {
    x <- utils::read.csv(path, skip = skip, colClasses = "character",
                         check.names = FALSE, stringsAsFactors = FALSE,
                         na.strings = character(), row.names = NULL,
                         fileEncoding = "UTF-8-BOM")
  }
  names(x)[names(x) == ""] <- ".input_row"
  af_assert(!anyDuplicated(names(x)), paste("Duplicate CSV column names:", path))
  missing <- setdiff(required, names(x))
  af_assert(length(missing) == 0L,
            paste("Missing columns in", path, ":", paste(missing, collapse = ", ")))
  x
}

af_write_csv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  # Headers are written even for a zero-row result. No stale previous-run files.
  old <- options(digits = 17); on.exit(options(old), add = TRUE)
  utils::write.table(x, path, sep = ",", row.names = FALSE, col.names = TRUE,
                     na = "", quote = TRUE, qmethod = "double", fileEncoding = "UTF-8")
  invisible(path)
}

af_num <- function(x, label = "numeric field", allow_missing = FALSE) {
  text <- as.character(x)
  missing <- is.na(x) | text == ""
  value <- suppressWarnings(as.numeric(text))
  bad <- !missing & !is.finite(value)
  af_assert(!any(bad), paste("Invalid/non-finite", label,
                             paste(unique(text[bad]), collapse = ", ")))
  af_assert(allow_missing || !any(missing), paste("Missing", label))
  value[missing] <- NA_real_
  value
}

af_year <- function(x) {
  text <- as.character(x)
  af_assert(all(!is.na(text) & grepl("^[0-9]{4}$", text)),
            "Year must be a four-digit integer; fractional/missing years are rejected")
  as.integer(text)
}

af_key <- function(x, columns) {
  af_assert(all(columns %in% names(x)), "Key column missing")
  if (!nrow(x)) return(character())
  af_assert(!anyNA(x[columns]), "Missing key value")
  do.call(paste, c(x[columns], sep = "\034"))
}

af_unique <- function(x, columns, label) {
  af_assert(!anyDuplicated(af_key(x, columns)), paste("Duplicate", label, "key"))
  invisible(x)
}

af_bind <- function(rows) {
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) return(data.frame())
  out <- do.call(rbind, lapply(rows, function(x) {
    if (is.data.frame(x)) x else as.data.frame(x, stringsAsFactors = FALSE,
                                             optional = TRUE)
  }))
  rownames(out) <- NULL
  out
}

af_sum_known <- function(x) if (all(is.na(x))) NA_real_ else sum(x, na.rm = TRUE)
af_max_abs <- function(x) if (!length(x) || all(is.na(x))) 0 else max(abs(x), na.rm = TRUE)
af_path <- function(root, x) {
  if (grepl("^(/|[A-Za-z]:[/\\\\]|\\\\\\\\)", x)) x else file.path(root, x)
}

af_manifest <- function(root, output, input, settings, extra_files = character()) {
  files <- unique(c(input, extra_files,
    list.files(file.path(root, "data/raw/literature"), full.names = TRUE),
    list.files(file.path(root, "data/mappings"), full.names = TRUE),
    list.files(file.path(root, "R"), pattern = "[.]R$", full.names = TRUE)))
  files <- files[file.exists(files)]
  hashes <- data.frame(path = files, md5 = unname(tools::md5sum(files)),
                       bytes = file.info(files)$size, stringsAsFactors = FALSE)
  root_norm <- normalizePath(root, winslash = "/", mustWork = TRUE)
  full <- normalizePath(hashes$path, winslash = "/", mustWork = TRUE)
  hashes$path <- ifelse(startsWith(full, paste0(root_norm, "/")),
                        substring(full, nchar(root_norm) + 2L), basename(full))
  af_write_csv(hashes, file.path(output, "input_and_code_manifest.csv"))
  settings <- c(list(version = "0.7-R", scientific_baseline = "unchanged v0.6.1 core plus explicit v0.7 coverage assumptions",
                     R_version = as.character(getRversion()),
                     timestamp_UTC = format(Sys.time(), tz = "UTC", usetz = TRUE)), settings)
  values <- vapply(settings, function(x) paste(x, collapse = ";"), character(1))
  af_write_csv(data.frame(key = names(values), value = unname(values)),
               file.path(output, "run_settings.csv"))
  capture.output(utils::sessionInfo(), file = file.path(output, "sessionInfo.txt"))
  invisible(hashes)
}
