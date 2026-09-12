init_project <- function(root) {
  if (length(root) != 1L || is.na(root) || !nzchar(root)) stop("Explicit project root required")
  dirs <- c("00_admin", "01_data/raw", "01_data/derived", "02_code", "03_output")
  for (d in dirs) dir.create(file.path(root, d), recursive = TRUE, showWarnings = FALSE)
  if (!length(list.files(root, pattern = "\\.Rproj$", ignore.case = TRUE)))
    writeLines(c("Version: 1.0", "", "RestoreWorkspace: No", "SaveWorkspace: No", "Encoding: UTF-8"), file.path(root, "Project.Rproj"))
  invisible(normalizePath(root))
}

strict_numeric <- function(x, missing = c("", "NA")) {
  text <- trimws(as.character(x))
  text[is.na(text) | text %in% missing] <- NA_character_
  valid <- is.na(text) | grepl("^[+-]?([0-9]+(\\.[0-9]*)?|\\.[0-9]+)([eE][+-]?[0-9]+)?$", text)
  if (any(!valid)) stop("Numeric parsing failed: ", paste(paste0("row ", which(!valid), " = ", dQuote(text[!valid])), collapse = "; "))
  out <- as.numeric(text)
  overflow <- !is.na(out) & !is.finite(out)
  if (any(overflow)) stop("Non-finite numeric result: ", paste(paste0("row ", which(overflow), " = ", dQuote(text[overflow])), collapse = "; "))
  out
}

check_mapping <- function(mapping) {
  if (!is.character(mapping) || is.null(names(mapping)) || anyNA(mapping) ||
      anyNA(names(mapping)) || any(!nzchar(names(mapping))) || any(!nzchar(mapping)) ||
      anyDuplicated(names(mapping)) || anyDuplicated(unname(mapping)))
    stop("Provide a unique named character code-to-label mapping")
}

labelled_factor <- function(x, mapping, ordered = FALSE) {
  check_mapping(mapping)
  x <- as.character(x)
  if (any(!is.na(x) & !x %in% names(mapping))) stop("Unknown category codes; inspect codebook")
  factor(x, levels = names(mapping), labels = unname(mapping), ordered = ordered)
}

factor_codes <- function(x, mapping) {
  check_mapping(mapping)
  labels <- as.character(x)
  if (any(!is.na(labels) & !labels %in% unname(mapping))) stop("Unknown category labels")
  unname(names(mapping)[match(labels, unname(mapping))])
}

numeric_summary <- function(x) {
  if (!is.numeric(x) || any(is.infinite(x))) stop("Numeric finite-or-missing data required")
  n <- sum(!is.na(x))
  values <- x[!is.na(x)]
  q <- if (n) as.numeric(quantile(values, c(.25, .5, .75), names = FALSE)) else rep(NA_real_, 3)
  result <- data.frame(n_total = length(x), n_valid = n, n_missing = sum(is.na(x)),
             mean = if (n) mean(values) else NA_real_,
             sd = if (n > 1L) sd(values) else NA_real_,
             q1 = q[1], median = q[2], q3 = q[3])
  if (any(is.infinite(as.matrix(result)))) stop("Numeric overflow during summary; check scale or units")
  result
}

categorical_summary <- function(x) {
  if (!is.factor(x)) stop("Use a codebook-defined factor")
  if (!length(levels(x))) stop("Factor has no defined levels; supply codebook levels to report missingness")
  counts <- table(x, useNA = "no")
  n <- sum(!is.na(x))
  data.frame(level = names(counts), n = as.integer(counts),
             percent = if (n) 100 * as.integer(counts) / n else rep(NA_real_, length(counts)),
             n_valid = rep(n, length(counts)), n_missing = rep(sum(is.na(x)), length(counts)))
}
