init_project <- function(root) {
  if (length(root) != 1L || is.na(root) || !nzchar(root)) stop("Explicit project root required")
  dirs <- c("00_admin", "01_data/raw", "01_data/derived", "02_code", "03_output")
  for (d in dirs) dir.create(file.path(root, d), recursive = TRUE, showWarnings = FALSE)
  if (!length(list.files(root, pattern = "\\.Rproj$", ignore.case = TRUE)))
    writeLines(c("Version: 1.0", "", "RestoreWorkspace: No", "SaveWorkspace: No", "Encoding: UTF-8"), file.path(root, "Project.Rproj"))
  invisible(normalizePath(root))
}

clean_key <- function(x) {
  x <- trimws(as.character(x))
  x[!is.na(x) & x == ""] <- NA_character_
  x
}

reconcile_keys <- function(a, b, a_key, b_key, threshold = 4, max_pairs = 1e6) {
  if (!a_key %in% names(a) || !b_key %in% names(b)) stop("Key column missing")
  if (length(threshold) != 1L || !is.finite(threshold) || threshold < 0) stop("Invalid threshold")
  ak <- clean_key(a[[a_key]]); bk <- clean_key(b[[b_key]])
  only_a <- setdiff(unique(ak[!is.na(ak)]), unique(bk[!is.na(bk)]))
  only_b <- setdiff(unique(bk[!is.na(bk)]), unique(ak[!is.na(ak)]))
  if (length(only_a) * length(only_b) > max_pairs) stop("Too many candidate pairs; block by context")
  pairs <- expand.grid(b_name = only_b, a_name = only_a, stringsAsFactors = FALSE)
  pairs$distance <- if (nrow(pairs)) vapply(seq_len(nrow(pairs)), function(i)
    as.numeric(adist(pairs$b_name[i], pairs$a_name[i])), numeric(1)) else numeric()
  pairs <- pairs[pairs$distance <= threshold, , drop = FALSE]
  pairs <- pairs[order(pairs$b_name, pairs$distance, pairs$a_name), , drop = FALSE]
  pairs$decision <- rep("pending", nrow(pairs))
  list(only_in_A = data.frame(key = only_a), only_in_B = data.frame(key = only_b),
       candidates = pairs, missing_A = data.frame(row_id = which(is.na(ak))),
       missing_B = data.frame(row_id = which(is.na(bk))))
}

safe_left_join <- function(a, b, a_key, b_key) {
  if (inherits(a, "sf") || inherits(b, "sf")) stop("Use sf-aware join for spatial objects")
  if (!a_key %in% names(a) || !b_key %in% names(b)) stop("Key column missing")
  if ("match_status" %in% c(names(a), names(b))) stop("Reserved match_status column")
  ak <- clean_key(a[[a_key]]); bk <- clean_key(b[[b_key]])
  if (anyDuplicated(bk[!is.na(bk)])) stop("Duplicate B keys need an explicit resolution")
  index <- match(ak, bk)
  index[is.na(ak)] <- NA_integer_
  extra <- b[index, setdiff(names(b), b_key), drop = FALSE]
  names(extra) <- make.unique(c(names(a), names(extra)), sep = "_b")[seq_along(names(extra)) + ncol(a)]
  out <- cbind(a, extra)
  out$match_status <- ifelse(is.na(ak), "missing_key", ifelse(is.na(index), "unmatched", "matched"))
  rownames(out) <- NULL
  out
}

apply_review <- function(b, b_key, review, valid_a) {
  if (!b_key %in% names(b) || !all(c("b_name", "a_name", "decision") %in% names(review)))
    stop("Review schema missing")
  if (anyNA(review$decision) || any(!review$decision %in% c("accept", "reject", "pending"))) stop("Invalid decision")
  if (any(review$decision == "pending")) stop("Review still pending")
  pair <- data.frame(b_name = clean_key(review$b_name), a_name = clean_key(review$a_name))
  if (anyNA(pair) || anyDuplicated(pair)) stop("Duplicate or conflicting decisions for the same pair")
  r <- review[review$decision == "accept", , drop = FALSE]
  from <- clean_key(r$b_name); to <- clean_key(r$a_name)
  bk <- clean_key(b[[b_key]])
  if (anyNA(from) || anyNA(to) || anyDuplicated(from)) stop("Conflicting or duplicate accepted mapping")
  if (any(!from %in% bk) || any(!to %in% clean_key(valid_a))) stop("Unknown mapping source or target")
  if (anyDuplicated(bk[!is.na(bk)])) stop("B source keys are not unique")
  if (any(from %in% clean_key(valid_a))) stop("Reviewed source already matches A exactly")
  idx <- match(bk, from)
  out <- b
  out[[b_key]] <- bk
  out[[b_key]][!is.na(idx)] <- to[idx[!is.na(idx)]]
  out
}

sum_preserve_na <- function(x) {
  if (!is.numeric(x) || any(is.infinite(x))) stop("Finite numeric values required")
  if (!length(x) || all(is.na(x))) return(NA_real_)
  result <- sum(x, na.rm = TRUE)
  if (!is.finite(result)) stop("Numeric overflow during aggregation")
  result
}
