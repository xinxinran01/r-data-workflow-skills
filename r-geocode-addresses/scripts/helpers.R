init_project <- function(root) {
  if (length(root) != 1L || is.na(root) || !nzchar(root)) stop("Explicit project root required")
  dirs <- c("00_admin", "01_data/raw", "01_data/derived", "02_code", "03_output")
  for (d in dirs) dir.create(file.path(root, d), recursive = TRUE, showWarnings = FALSE)
  if (!length(list.files(root, pattern = "\\.Rproj$", ignore.case = TRUE)))
    writeLines(c("Version: 1.0", "", "RestoreWorkspace: No", "SaveWorkspace: No", "Encoding: UTF-8"), file.path(root, "Project.Rproj"))
  invisible(normalizePath(root))
}

prepare_addresses <- function(data, address_col) {
  if (!is.data.frame(data) || !address_col %in% names(data)) stop("Address column missing")
  added <- c("source_row_id", "address_original", "address_clean", "query_id")
  if (any(added %in% names(data))) stop("Reserved output columns already exist")
  clean <- trimws(as.character(data[[address_col]]))
  clean[!is.na(clean) & clean == ""] <- NA_character_
  unique_addresses <- unique(clean[!is.na(clean)])
  queries <- data.frame(query_id = seq_along(unique_addresses), address_clean = unique_addresses)
  data$source_row_id <- seq_len(nrow(data))
  data$address_original <- as.character(data[[address_col]])
  data$address_clean <- clean
  data$query_id <- match(clean, unique_addresses)
  list(rows = data, queries = queries)
}

attach_geocodes <- function(prepared, responses) {
  req <- c("query_id", "longitude", "latitude", "status", "coord_system")
  if (!is.data.frame(responses) || !all(req %in% names(responses))) stop("Response schema incomplete")
  if (anyNA(responses$query_id) || anyDuplicated(responses$query_id)) stop("Duplicate or missing response query_id")
  if (any(!responses$query_id %in% prepared$queries$query_id)) stop("Unknown query_id")
  if (!is.numeric(responses$longitude) || !is.numeric(responses$latitude)) stop("Coordinates must be numeric")
  systems <- c("GCJ-02", "BD-09", "WGS84")
  if (anyNA(responses$coord_system) || any(!responses$coord_system %in% systems)) stop("Unknown coordinate system")
  statuses <- c("ok", "no_result", "ambiguous", "low_precision", "api_error")
  if (anyNA(responses$status) || any(!responses$status %in% statuses)) stop("Unknown response status")
  ok <- responses$status == "ok"
  valid <- is.finite(responses$longitude) & is.finite(responses$latitude) &
    abs(responses$longitude) <= 180 & abs(responses$latitude) <= 90
  if (any(ok & !valid)) stop("Successful responses need valid coordinates")
  if (any(!ok & (!is.na(responses$longitude) | !is.na(responses$latitude))))
    stop("Non-ok coordinates belong in a separate review table")
  rows <- prepared$rows
  if (any(c("longitude", "latitude", "geocode_status", "coord_system") %in% names(rows)))
    stop("Reserved result columns already exist")
  idx <- match(rows$query_id, responses$query_id)
  rows$longitude <- responses$longitude[idx]
  rows$latitude <- responses$latitude[idx]
  rows$coord_system <- responses$coord_system[idx]
  rows$geocode_status <- responses$status[idx]
  rows$geocode_status[is.na(idx)] <- "no_result"
  rows$geocode_status[is.na(rows$query_id)] <- "missing_address"
  rows
}
