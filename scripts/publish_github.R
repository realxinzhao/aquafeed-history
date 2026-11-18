# Locate the project without hard-coded machine-specific paths.
.af_root <- local({
  arguments <- commandArgs(trailingOnly = FALSE)
  command_file <- sub("^--file=", "", grep("^--file=", arguments, value = TRUE))
  source_files <- vapply(sys.frames(), function(frame) {
    value <- frame$ofile
    if (is.null(value)) "" else as.character(value)[1L]
  }, character(1))
  paths <- c(command_file, source_files[nzchar(source_files)])
  candidates <- unique(c(getwd(), dirname(paths)))
  found <- NULL
  for (start in candidates) {
    location <- normalizePath(start, winslash = "/", mustWork = FALSE)
    for (step in seq_len(20)) {
      if (file.exists(file.path(location, "AquafeedHistory.Rproj"))) { found <- location; break }
      parent <- dirname(location)
      if (identical(parent, location)) break
      location <- parent
    }
    if (!is.null(found)) break
  }
  if (is.null(found)) stop("Open AquafeedHistory.Rproj or run from the project directory", call. = FALSE)
  found
})
source(file.path(.af_root, "R/load.R"), local = TRUE)
af_load(.af_root)

arguments <- af_cli(commandArgs(trailingOnly = TRUE), value_flags = c("repo"), boolean_flags = c("publish", "help"))
repo <- if (is.null(arguments$repo)) "realxinzhao/aquafeed-history" else arguments$repo
af_assert(grepl("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", repo), "Expected owner/repository")
if (!isTRUE(arguments$publish)) {
  cat("Nothing uploaded. After reviewing files, run:\n",
      "  Rscript scripts/publish_github.R --publish --repo ", repo, "\n", sep = "")
} else {
  af_assert(nzchar(Sys.which("git")) && nzchar(Sys.which("gh")),
            "Install Git and GitHub CLI, then run 'gh auth login' in a terminal. Do not paste tokens into R files.")
  old_directory <- getwd(); setwd(.af_root)
  tryCatch({
    af_assert(!dir.exists(".git"),
      "A local Git repository already exists. Use the documented manual push steps; this helper will not replace its remotes/history.")
    login <- suppressWarnings(system2("gh", c("api", "user", "--jq", shQuote(".login")), stdout = TRUE, stderr = FALSE))
    af_assert(is.null(attr(login, "status")) && length(login) == 1L, "GitHub CLI is not authenticated; run gh auth login")
    owner <- strsplit(repo, "/", fixed = TRUE)[[1L]][1L]
    af_assert(identical(login, owner), paste("Authenticated account is", paste(login, collapse = " "), "not", owner))
    existing <- suppressWarnings(system2("gh", c("repo", "view", repo), stdout = FALSE, stderr = FALSE))
    af_assert(existing != 0L, "Remote repository already exists; refusing to create or overwrite it")
    # Check that a real author identity is configured, without assigning one for you.
    author <- system2("git", c("config", "user.name"), stdout = TRUE)
    email <- system2("git", c("config", "user.email"), stdout = TRUE)
    af_assert(length(author) > 0 && length(email) > 0,
      "Set your git user.name and user.email before publishing")
    run <- function(command, args) af_assert(system2(command, args) == 0L, paste("Command failed:", command, paste(args, collapse = " ")))
    run("git", c("init", "-b", "main"))
    run("git", c("add", "."))
    run("git", c("commit", "-m", shQuote("Add source-documented native-R aquafeed history pipeline")))
    run("gh", c("repo", "create", repo, "--private", "--source=.", "--remote=origin", "--push"))
    message("Created and pushed PRIVATE repository: ", repo)
  }, finally = setwd(old_directory))
}
