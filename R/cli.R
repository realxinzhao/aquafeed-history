af_cli <- function(arguments, value_flags, boolean_flags = character()) {
  result <- list()
  i <- 1L
  while (i <= length(arguments)) {
    token <- arguments[i]
    af_assert(startsWith(token, "--"), paste("Expected --option, received", token))
    flag <- substring(token, 3L)
    af_assert(flag %in% c(value_flags, boolean_flags), paste("Unknown option:", token))
    if (flag %in% boolean_flags) {
      result[[flag]] <- TRUE; i <- i + 1L
    } else {
      af_assert(i < length(arguments) && !startsWith(arguments[i + 1L], "--"), paste("Value required for", token))
      result[[flag]] <- arguments[i + 1L]; i <- i + 2L
    }
  }
  result
}
