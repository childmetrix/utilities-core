########################################
# Detect columns read in as chr or numeric that should be Date ----
########################################

# Usage
# date_cols <- c("custody_end", "narr_date", "case_begin_date")
# mdcps_df[date_cols] <- lapply(mdcps_df[date_cols], to_date_safe)

# e.g., "10/06/2025", "2025-10-06", "2025-10-06 14:22:00", or "45743" 
# (Excel serial, even as a string) → becomes a proper Date.

# Coerce to Date ONLY if the input isn't already Date/DATETIME
to_date_safe <- function(x) {
  # Don't touch true Dates or POSIXct (datetimes)
  if (inherits(x, "Date") || inherits(x, c("POSIXct","POSIXt"))) return(x)
  
  # Normalize types
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) {
    x <- trimws(x)
    x[x == ""] <- NA
  }
  
  n   <- length(x)
  out <- rep(as.Date(NA), n)
  is_char <- is.character(x)
  is_num  <- is.numeric(x)
  
  # 1) Excel serials: numeric OR digit/commas/decimal characters (e.g., "45,688", "45688.0")
  idx <- (is_num & !is.na(x)) |
    (is_char & grepl("^[0-9][0-9,\\.]*$", x))
  if (any(idx)) {
    x_clean <- x
    if (is_char) x_clean <- gsub(",", "", x_clean)  # drop thousands separators
    as_num <- suppressWarnings(as.numeric(x_clean))
    out[idx & !is.na(as_num)] <- as.Date(as_num[idx & !is.na(as_num)], origin = "1899-12-30")
  }
  
  # 2) ISO "YYYY-MM-DD"
  idx <- is_char & is.na(out) & grepl("^\\d{4}-\\d{2}-\\d{2}$", x)
  if (any(idx)) out[idx] <- as.Date(x[idx], format = "%Y-%m-%d")
  
  # 3) Timestamp "YYYY-MM-DD HH:MM(:SS)?"
  idx <- is_char & is.na(out) &
    grepl("^\\d{4}-\\d{2}-\\d{2}[ T]\\d{2}:\\d{2}(:\\d{2})?$", x)
  if (any(idx)) {
    ts <- suppressWarnings(strptime(x[idx], format = "%Y-%m-%d %H:%M:%S", tz = "UTC"))
    miss <- is.na(ts)
    if (any(miss)) {
      ts[miss] <- suppressWarnings(strptime(x[idx][miss], format = "%Y-%m-%d %H:%M", tz = "UTC"))
    }
    out[idx] <- as.Date(ts)
  }
  
  # 4) M/D/Y (1-2 digit month/day, 4-digit year)
  idx <- is_char & is.na(out) & grepl("^\\d{1,2}/\\d{1,2}/\\d{4}$", x)
  if (any(idx)) out[idx] <- as.Date(x[idx], format = "%m/%d/%Y")
  
  # 5) M/D/YY (2-digit year)
  idx <- is_char & is.na(out) & grepl("^\\d{1,2}/\\d{1,2}/\\d{2}$", x)
  if (any(idx)) out[idx] <- as.Date(x[idx], format = "%m/%d/%y")
  
  # 6) Compact YYYYMMDD
  idx <- is_char & is.na(out) & grepl("^\\d{8}$", x)
  if (any(idx)) {
    y <- substr(x[idx], 1, 4)
    m <- substr(x[idx], 5, 6)
    d <- substr(x[idx], 7, 8)
    out[idx] <- suppressWarnings(as.Date(paste(y, m, d, sep = "-"), format = "%Y-%m-%d"))
  }
  
  out
}

########################################
# Define period_start, period_end, and folder_date_quarter based on date folder ----
########################################

get_period_dates <- function(folder_date) {
  # Ensure folder_date is a character string
  folder_date <- as.character(folder_date)
  
  # Define patterns for quarter-based, month-based, and year-based folder dates
  quarter_pattern <- "^([0-9]{4})_[Qq]([1-4])$"
  month_pattern   <- "^([0-9]{4})_(0[1-9]|1[0-2])$"
  year_pattern    <- "^([0-9]{4})_CY$"
  
  if(grepl(quarter_pattern, folder_date)) {
    matches <- regmatches(folder_date, regexec(quarter_pattern, folder_date))[[1]]
    year <- as.integer(matches[2])
    quarter <- as.integer(matches[3])
    folder_date_readable <- sprintf("%04d Q%d", year, quarter)
    folder_date_quarter <- folder_date_readable  # Already in the desired format
    period_start <- as.Date(sprintf("%04d-%02d-01", year, (quarter - 1) * 3 + 1))
    period_end <- if(quarter == 4) {
      as.Date(sprintf("%04d-12-31", year))
    } else {
      as.Date(sprintf("%04d-%02d-01", year, quarter * 3 + 1)) - 1
    }
  } else if(grepl(month_pattern, folder_date)) {
    matches <- regmatches(folder_date, regexec(month_pattern, folder_date))[[1]]
    year <- as.integer(matches[2])
    month <- as.integer(matches[3])
    folder_date_readable <- sprintf("%04d %02d", year, month)
    # Compute the quarter from the month (months 1-3: Q1, 4-6: Q2, etc.)
    quarter <- ceiling(month / 3)
    folder_date_quarter <- sprintf("%04d Q%d", year, quarter)
    period_start <- as.Date(sprintf("%04d-%02d-01", year, month))
    period_end <- if(month == 12) {
      as.Date(sprintf("%04d-12-31", year))
    } else {
      as.Date(sprintf("%04d-%02d-01", year, month + 1)) - 1
    }
  } else if(grepl(year_pattern, folder_date)) {
    matches <- regmatches(folder_date, regexec(year_pattern, folder_date))[[1]]
    year <- as.integer(matches[2])
    folder_date_readable <- sprintf("%04d CY", year)
    folder_date_quarter <- NULL  # No quarter for year-based pattern
    period_start <- as.Date(sprintf("%04d-01-01", year))  # First day of the year
    period_end <- as.Date(sprintf("%04d-12-31", year))    # Last day of the year
  } else {
    stop("folder_date must be in the format 'YYYY_QX' (e.g., '2024_Q2'), 'YYYY_MM' (e.g., '2024_04'), or 'YYYY_CY' (e.g., '2024_CY').")
  }
  
  cy_start <- as.Date(sprintf("%04d-01-01", year))
  
  # Return a list with all period-related elements, including folder_date_quarter (NULL for year-based)
  return(list(
    period_start = period_start,
    period_end = period_end,
    cy_start = cy_start,
    folder_date_readable = folder_date_readable,
    folder_date_quarter = folder_date_quarter
  ))
}

########################################
# Calculate reporting quarter from a date (YYYY Q#) ----
########################################

# Purpose: Converts a date to reporting quarter format "YYYY Q#"
# Returns NA for missing dates
#
# Usage:
#   date_to_reporting_quarter(placement_end)
#   df %>% mutate(qtr = date_to_reporting_quarter(event_date))
#
# Example:
#   date_to_reporting_quarter(as.Date("2025-03-15"))  # Returns "2025 Q1"
#   date_to_reporting_quarter(as.Date("2025-07-01"))  # Returns "2025 Q3"

date_to_reporting_quarter <- function(date) {
  ifelse(
    !is.na(date),
    paste0(
      format(as.Date(date), "%Y"),
      " Q",
      ((as.integer(format(as.Date(date), "%m")) - 1) %/% 3) + 1
    ),
    NA_character_
  )
}

########################################
# Set up project folders (data/[folder_date]/raw, output/[folder_date], etc.)
# Adds data/YYYY_cumulative based on folder_date's year.
########################################

# Set up project folders
#   - data/[folder_date]/{raw, processed}
#   - data/YYYY_cumulative
#   - output/[folder_date]
#   - folder_data (root path to data/)
# --------------------------------------

setup_folders <- function(folder_date,
                          assign_globals = TRUE,
                          data_root = "data",
                          output_root = "output") {
  folder_date <- toupper(folder_date)

  # Period info (assumes your helper exists)
  dates <- get_period_dates(folder_date)
  reporting_period_start <- dates$period_start
  reporting_period_end   <- dates$period_end
  folder_date_readable   <- dates$folder_date_readable
  folder_date_quarter    <- dates$folder_date_quarter
  cy_start               <- dates$cy_start

  # Roots
  folder_data <- data_root  # <- NEW: project data root (e.g., "data")

  # Paths
  year_str          <- substr(folder_date, 1L, 4L)
  folder_raw        <- file.path(folder_data, folder_date, "raw")
  folder_processed  <- file.path(folder_data, folder_date, "processed")
  folder_output     <- file.path(output_root, folder_date)
  # folder_cumulative <- file.path(folder_data, paste0(year_str, "_cumulative"))

  # Create dirs (idempotent)
  if (!dir.exists(folder_data))        dir.create(folder_data, recursive = TRUE)
  if (!dir.exists(folder_output))      dir.create(folder_output, recursive = TRUE)
  if (!dir.exists(folder_raw))         dir.create(folder_raw, recursive = TRUE)
  if (!dir.exists(folder_processed))   dir.create(folder_processed, recursive = TRUE)
  # if (!dir.exists(folder_cumulative))  dir.create(folder_cumulative, recursive = TRUE)

  # Assign globals
  if (assign_globals) {
    assign("folder_data", folder_data, envir = .GlobalEnv)                 # <- NEW
    assign("folder_date", folder_date, envir = .GlobalEnv)
    assign("reporting_period_start", reporting_period_start, envir = .GlobalEnv)
    assign("reporting_period_end", reporting_period_end, envir = .GlobalEnv)
    assign("folder_date_readable", folder_date_readable, envir = .GlobalEnv)
    assign("folder_date_quarter", folder_date_quarter, envir = .GlobalEnv)
    assign("cy_start", cy_start, envir = .GlobalEnv)
    assign("folder_raw", folder_raw, envir = .GlobalEnv)
    assign("folder_processed", folder_processed, envir = .GlobalEnv)
    assign("folder_output", folder_output, envir = .GlobalEnv)
    # assign("folder_cumulative", folder_cumulative, envir = .GlobalEnv)
  }

  # Return key paths
  list(
    folder_data             = folder_data,            # <- NEW
    folder_date             = folder_date,
    reporting_period_start  = reporting_period_start,
    reporting_period_end    = reporting_period_end,
    folder_date_readable    = folder_date_readable,
    folder_date_quarter     = folder_date_quarter,
    cy_start                = cy_start,
    folder_raw              = folder_raw,
    folder_processed        = folder_processed,
    folder_output           = folder_output
    # folder_cumulative       = folder_cumulative
  )
}

########################################
# Save csv or excel to data\processed\[2025_01]\[2025-09-23]
########################################

# Usage
# --------------------------------------

# save_to_folder_run(claiming_df)          # prefers .xlsx if writexl is installed, else .csv
# save_to_folder_run(claiming_df, "csv")   # force CSV
# save_to_folder_run(claiming_df, "xlsx")  # force XLSX (needs writexl)

# [2025_01] is subfolder based on folder_date. Created at set up.
# [2025-09-23] is today's run date. Created with function when save is
# attempted.

# Make run folder under output/[folder_date]
#   - Creates YYYY-MM-DD subfolder (for today's run, to separate multiple runs
#     and attempts for the same quarter; version control)
#   - Assigns run_dir and run_date globally if requested
# --------------------------------------

# Creates: data/<folder_date>/processed/<YYYY-MM-DD>  and sets global folder_run
make_data_run_folder <- function(
    folder_date    = get("folder_date", envir = .GlobalEnv),
    run_date       = Sys.Date(),
    data_root      = "data",
    assign_globals = TRUE
) {
  if (is.null(folder_date) || is.na(folder_date)) {
    stop("folder_date not found. Set folder_date like '2025_09' first.")
  }
  
  processed_path <- file.path(data_root, as.character(folder_date), "processed")
  if (!dir.exists(processed_path)) {
    dir.create(processed_path, recursive = TRUE)
    message("Created processed folder: ", processed_path)
  }
  
  run_dir_name <- format(run_date, "%Y-%m-%d")
  folder_run <- file.path(processed_path, run_dir_name)
  if (!dir.exists(folder_run)) {
    dir.create(folder_run, recursive = TRUE)
    message("Created run folder: ", folder_run)
  } else {
    message("Run folder already exists: ", folder_run)
  }
  
  if (assign_globals) {
    assign("folder_run", folder_run, envir = .GlobalEnv)
    assign("run_date",   run_date,   envir = .GlobalEnv)
  }
  
  folder_run
}

# Helper: build a filepath inside folder_run
path_in_run <- function(filename) {
  if (!exists("folder_run", envir = .GlobalEnv)) stop("folder_run not set. Call make_data_run_folder() first.")
  file.path(get("folder_run", envir = .GlobalEnv), filename)
}

# Save 
# --------------------------------------

# Save a data frame into data/<folder_date>/processed/<run_date>/<name>.{csv|xlsx}
# Usage: save_to_folder_run(claiming_df)

save_to_folder_run <- function(df,
                               ext = NULL,              # "xlsx" or "csv"; if NULL -> prefer xlsx when openxlsx/writexl is available
                               sep = " - ",
                               na_str = "",
                               header_align = "left") { # "left","center","right"
  # ---- resolve paths ----
  if (!exists("folder_run", envir = .GlobalEnv)) {
    if (exists("make_data_run_folder", mode = "function")) {
      make_data_run_folder()
    } else {
      stop("folder_run not found. Call make_data_run_folder() first (or create folder_run).")
    }
  }
  folder_run <- get("folder_run", envir = .GlobalEnv)
  if (!dir.exists(folder_run)) dir.create(folder_run, recursive = TRUE)
  
  # ---- filename parts from globals ----
  gd <- function(x) if (exists(x, envir = .GlobalEnv)) get(x, envir = .GlobalEnv) else NA
  parts <- c(
    gd("folder_date"),
    gd("commitment"),
    gd("commitment_description"),
    format(if (!is.na(gd("run_date"))) gd("run_date") else Sys.Date(), "%Y-%m-%d")
  )
  name <- paste(Filter(function(x) nzchar(trimws(as.character(x))), parts), collapse = sep)
  name <- gsub('[/\\\\:*?"<>|]+', "-", name)
  name <- trimws(gsub("\\s+", " ", name))
  if (!nzchar(name)) name <- format(Sys.time(), "export-%Y%m%d-%H%M%S")
  
  # ---- choose extension ----
  if (is.null(ext) || !nzchar(ext)) {
    ext <- if (requireNamespace("openxlsx", quietly = TRUE) || requireNamespace("writexl", quietly = TRUE)) "xlsx" else "csv"
  }
  ext <- tolower(ext)
  outfile <- file.path(folder_run, paste0(name, ".", ext))
  
  # ---- write ----
  if (identical(ext, "xlsx")) {
    if (requireNamespace("openxlsx", quietly = TRUE)) {
      # Precise control: left-align headers
      wb <- openxlsx::createWorkbook()
      openxlsx::addWorksheet(wb, "Sheet1")
      hdr_style <- openxlsx::createStyle(textDecoration = "bold", halign = header_align, valign = "top")
      openxlsx::writeData(wb, "Sheet1", df, headerStyle = hdr_style, borders = "none")
      openxlsx::setColWidths(wb, "Sheet1", cols = 1:ncol(df), widths = "auto")
      openxlsx::saveWorkbook(wb, outfile, overwrite = TRUE)
    } else if (requireNamespace("writexl", quietly = TRUE)) {
      # Minimal styling; Excel may center headers visually
      writexl::write_xlsx(df, outfile)
    } else {
      message("No XLSX writer available; saving as CSV instead.")
      outfile <- sub("\\.xlsx$", ".csv", outfile, ignore.case = TRUE)
      write.csv(df, outfile, row.names = FALSE, na = na_str, fileEncoding = "UTF-8")
    }
  } else if (identical(ext, "csv")) {
    # Write UTF-8 BOM first for Excel compatibility
    con <- file(outfile, open = "wb")
    writeBin(charToRaw('\ufeff'), con)  # UTF-8 BOM
    close(con)
    # Append CSV data
    write.table(df, outfile, sep = ",", row.names = FALSE, na = na_str,
                fileEncoding = "UTF-8", append = TRUE, col.names = TRUE, qmethod = "double")
  } else {
    stop("Unsupported ext: ", ext, " (use 'csv' or 'xlsx').")
  }
  
  message("Saved: ", outfile)
  invisible(outfile)
}

########################################
# Save multi-sheet Excel workbook to data\processed\[2025_01]\[2025-09-23]
########################################

# Usage
# --------------------------------------

# sheets_to_save <- list(
#   "Population Details" = thv_children,
#   "Quarter Summary"    = thv_children_quarter_long,
#   "Monthly Summary"    = thv_children_month_long
# )
# save_workbook_to_folder_run(sheets_to_save)

# Save a named list of data frames as a multi-sheet Excel workbook
# into data/<folder_date>/processed/<run_date>/<name>.xlsx
#
# Args:
#   sheets_list    - Named list where names = sheet names, values = data frames
#   sep            - Separator for filename parts (default: " - ")
#   header_align   - Header alignment: "left", "center", or "right" (default: "left")
#
# Returns:
#   Invisibly returns the path to the saved file

save_workbook_to_folder_run <- function(
  sheets_list,
  sep = " - ",
  header_align = "left"
) {
  # ---- validate input ----
  if (!is.list(sheets_list) || is.null(names(sheets_list)) || any(names(sheets_list) == "")) {
    stop("sheets_list must be a named list where names are sheet names and values are data frames.")
  }

  if (!all(sapply(sheets_list, is.data.frame))) {
    stop("All elements in sheets_list must be data frames.")
  }

  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    stop("The openxlsx package is required for multi-sheet workbooks. Install it with: install.packages('openxlsx')")
  }

  # ---- resolve paths ----
  if (!exists("folder_run", envir = .GlobalEnv)) {
    if (exists("make_data_run_folder", mode = "function")) {
      make_data_run_folder()
    } else {
      stop("folder_run not found. Call make_data_run_folder() first (or create folder_run).")
    }
  }
  folder_run <- get("folder_run", envir = .GlobalEnv)
  if (!dir.exists(folder_run)) dir.create(folder_run, recursive = TRUE)

  # ---- filename parts from globals ----
  gd <- function(x) if (exists(x, envir = .GlobalEnv)) get(x, envir = .GlobalEnv) else NA
  parts <- c(
    gd("folder_date"),
    gd("commitment"),
    gd("commitment_description"),
    format(if (!is.na(gd("run_date"))) gd("run_date") else Sys.Date(), "%Y-%m-%d")
  )
  name <- paste(Filter(function(x) nzchar(trimws(as.character(x))), parts), collapse = sep)
  name <- gsub('[/\\\\:*?"<>|]+', "-", name)
  name <- trimws(gsub("\\s+", " ", name))
  if (!nzchar(name)) name <- format(Sys.time(), "export-%Y%m%d-%H%M%S")

  outfile <- file.path(folder_run, paste0(name, ".xlsx"))

  # ---- create workbook ----
  wb <- openxlsx::createWorkbook()
  hdr_style <- openxlsx::createStyle(textDecoration = "bold", halign = header_align, valign = "top")

  # ---- add sheets ----
  for (sheet_name in names(sheets_list)) {
    df <- sheets_list[[sheet_name]]

    # Sanitize sheet name (Excel has 31 char limit and some forbidden characters)
    clean_sheet_name <- substr(gsub('[/\\\\:*?\\[\\]]+', "-", sheet_name), 1, 31)

    openxlsx::addWorksheet(wb, clean_sheet_name)
    openxlsx::writeData(wb, clean_sheet_name, df, headerStyle = hdr_style, borders = "none")
    openxlsx::setColWidths(wb, clean_sheet_name, cols = 1:ncol(df), widths = "auto")
  }

  # ---- save workbook ----
  openxlsx::saveWorkbook(wb, outfile, overwrite = TRUE)

  message("Saved workbook with ", length(sheets_list), " sheet(s): ", outfile)
  invisible(outfile)
}

########################################
# Find one or more files (csv, excel, etc.) in same path by keyword ----
########################################

# Still being used?

get_subfolder_path <- function(base_path, folder_date) {
  # 1) Parse year and quarter from folder_date, assuming folder_date looks like "YYYY_qX"
  year <- sub("_.*", "", folder_date)     # e.g. "2023"
  quarter <- sub(".*_", "", folder_date)  # e.g. "q1"
  
  # 2) Build a pattern that matches:
  #    - "YYYY_qX" or "YYYY qX"
  #    - "qX_YYYY" or "qX YYYY"
  #    The (?i) makes it case-insensitive.
  folder_pattern <- paste0("(?i)^(", 
                           year, "[ _]?", quarter, 
                           "|", 
                           quarter, "[ _]?", year, 
                           ")$")
  
  # 3) List immediate subfolders in base_path (no recursion)
  subfolders <- list.dirs(base_path, full.names = FALSE, recursive = FALSE)
  
  # 4) Find the matching subfolder
  matching_folders <- subfolders[grepl(folder_pattern, subfolders, ignore.case = TRUE)]
  
  if (length(matching_folders) == 0) {
    stop(paste("No matching folder found for:", folder_date))
  } else if (length(matching_folders) > 1) {
    warning(paste("Multiple folders match the date pattern. Using the first:", matching_folders[1]))
  }
  
  # Return the path to the "raw" subfolder of the match
  file.path(base_path, matching_folders[1], "raw")
}

# library(readr)    # For reading CSV files
# library(readxl)   # For reading Excel files
# library(jsonlite) # For reading JSON files

get_and_read_files <- function(subfolder_path, patterns) {
  # Initialize a list to store the data frames
  data_frames <- list()
  
  # Iterate over the patterns
  for (i in seq_along(patterns)) {
    pattern <- patterns[i]
    # List all files in the subfolder that match the pattern
    matching_files <- list.files(path = subfolder_path, pattern = pattern, full.names = TRUE)
    
    # Error and warning checks
    if (length(matching_files) == 0) {
      stop(paste("No matching file found for pattern:", pattern))
    } else if (length(matching_files) > 1) {
      warning(paste("Multiple matching files found for pattern:", pattern, ". The first one will be used."))
    }
    
    # Select the first matching file
    file_path <- matching_files[1]
    
    # Read the file based on its extension
    if (grepl("\\.csv$", file_path)) {
      data_frames[[paste0("df", i)]] <- read_csv(file_path)
    } else if (grepl("\\.xlsx$", file_path) || grepl("\\.xls$", file_path)) {
      data_frames[[paste0("df", i)]] <- read_excel(file_path)
    } else if (grepl("\\.json$", file_path)) {
      data_frames[[paste0("df", i)]] <- fromJSON(file_path)
    } else {
      stop(paste("Unsupported file type for file:", file_path))
    }
  }
  
  return(data_frames)
}

# # Example Usage
# folder_date <- "2024_q1"
# base_path <- "D:/repo_mdcps_suspension_period/r_9.6/data"
# subfolder_path <- file.path(base_path, folder_date)
# patterns <- c("_expanded_population_details\\.csv$", 
#               "_placements_expanded_2\\.csv$", 
#               "_permanency_plans_expanded\\.csv$")
# 
# data_frames <- get_and_read_files(subfolder_path, patterns)
# 
# # Assign to specific variables
# custody_df <- data_frames$df1
# allegations_df <- data_frames$df2
# plans_df <- data_frames$df3

########################################
# Open an excel or csv file based on keyword ----
########################################

# Function Name: find_file
#
# Purpose:
#   This function searches for a file within specified directories (either raw 
#   or processed data) based on a keyword. It supports CSV and Excel file 
#   formats and returns the file as a data frame. If multiple or no matches are 
#   found, the function returns appropriate messages to guide the user.
#
# Usage:
#   data_df <- find_file(keyword = "BASE", 
#                        directory_type = "raw", 
#                        file_type = "excel", 
#                        sheet_name = "Sheet1", 
#                        col_types = c("EBP_Reason" = "character", "EBP_Comments" = "character"))
#
# Parameters:
#   keyword         - A string that represents the keyword to search in the file names.
#   directory_type  - A string specifying the directory to search in. Can be either "raw" for raw data 
#                     or "processed" for processed data. Defaults to "raw" if not specified.
#   file_type       - The type of file to look for: "csv" for CSV files, "excel" for Excel files. 
#                     Defaults to "csv".
#   sheet_name      - (Optional) A string specifying the Excel sheet name to be read. If not specified, 
#                     the first sheet is read.
#   col_types       - (Optional) A named vector specifying the desired data types for certain columns. 
#                     For Excel files, it specifies "text" or "guess" for each column. For CSV files, 
#                     it maps column names to R types (e.g., "character", "numeric"). If not provided, 
#                     defaults to the file’s own type guessing.
#
# Returns:
#   A data frame containing the contents of the file. If more than one file is found or no files are 
#   found, it returns NULL or an error message.
#
# Dependencies:
#   - readxl package (for reading Excel files)
#
# Notes:
#   - Ensure that the global variables `folder_raw` and `folder_processed` are defined and set to appropriate 
#     directories before calling this function.
#   - Excel files with temporary backup symbols (e.g., "~$") are excluded automatically.
#
# Example:
#   # Example usage for finding a CSV file in processed data
#   processed_df <- find_file(keyword = "summary", directory_type = "processed", file_type = "csv")
#
# -----------------------------------------------------------------------------

find_file <- function(keyword, 
                      directory_type = "raw", 
                      file_type = "csv", 
                      sheet_name = NULL, 
                      col_types = NULL,
                      skip = 0) {
  
  # normalize directory_type
  directory_type <- tolower(directory_type)
  if (!exists("folder_raw") || !exists("folder_processed")) {
    stop("Global variables 'folder_raw' and/or 'folder_processed' are not defined.")
  }
  if (!(directory_type %in% c("raw", "processed"))) {
    stop("Invalid directory_type. Supported types are 'raw' and 'processed'.")
  }
  
  # pick folder
  directory <- if (directory_type == "raw") folder_raw else folder_processed
  
  # normalize file_type and build file‐matching regex
  file_type <- tolower(file_type)
  file_pattern <- switch(
    file_type,
    excel = "(?i)\\.(xlsx|xlsm)$",
    csv   = "(?i)\\.csv$",
    stop("Invalid file_type. Supported types are 'excel' and 'csv'.")
  )
  
  # list and filter out temp files
  files <- list.files(directory, pattern = file_pattern,
                      full.names = TRUE, recursive = FALSE)
  files <- files[!grepl("~\\$", files)]
  
  # find keyword
  master_file <- grep(keyword, files, value = TRUE, ignore.case = TRUE)
  
  # reader
  read_selected_file <- function(file_path) {
    if (file_type == "excel") {
      # ----- normalize extension for openxlsx -----
      ext <- tools::file_ext(file_path)
      if (!tolower(ext) %in% c("xlsx", "xlsm")) {
        stop("Excel files must have .xlsx or .xlsm extension.")
      }
      # rebuild path string with lowercase extension
      file_path_norm <- sub(
        paste0("\\.", ext, "$"),
        paste0(".", tolower(ext)),
        file_path,
        ignore.case = FALSE
      )
      
      data_df <- openxlsx::read.xlsx(
        xlsxFile    = file_path_norm,
        # sheet       = sheet_name %||% 1,
        sheet       = if (is.null(sheet_name)) 1 else sheet_name,
        detectDates = TRUE
      )
      
      if (!is.null(col_types)) {
        for (nm in names(col_types)) {
          if (nm %in% names(data_df)) {
            data_df[[nm]] <- as.character(data_df[[nm]])
          } else {
            warning("Column ", nm, " not found; cannot force to character.")
          }
        }
      }
      
    } else {
      # CSV path unchanged
      if (is.null(col_types)) {
        data_df <- readr::read_csv(file_path, skip = skip)
      } else {
        data_df <- readr::read_csv(
          file_path,
          skip      = skip,
          col_types = readr::cols(.default = readr::col_guess(), !!!col_types)
        )
      }
      
      # auto‐detect M/D/YYYY columns
      date_like_cols <- data_df %>%
        select(where(is.character)) %>%
        select_if(~ all(is.na(.) | grepl("^\\d{1,2}/\\d{1,2}/\\d{4}$", .))) %>%
        names()
      
      if (length(date_like_cols)) {
        message("Auto‐parsing these columns as Dates: ", 
                paste(date_like_cols, collapse = ", "))
        data_df <- data_df %>%
          mutate(across(all_of(date_like_cols), lubridate::mdy))
      }
    }
    
    data_df
  }
  
  # dispatch single vs. multiple vs. none
  if (length(master_file) == 1) {
    message("Reading: ", basename(master_file))
    return(read_selected_file(master_file))
    
  } else if (length(master_file) > 1) {
    info <- file.info(master_file)
    sel  <- rownames(info)[which.max(info$mtime)]
    message(
      "Multiple matches; using most recently modified:\n  ",
      basename(sel), "\nAll matches:\n  ",
      paste(basename(master_file), collapse = "\n  ")
    )
    return(read_selected_file(sel))
    
  } else {
    stop("No file with keyword '", keyword, "' found in ", directory_type, " folder.")
  }
}

########################################
# Compare the values of one or two ID fields in two data frames ----
########################################

compare_files <- function(df1, df2, id_cols, df1_label = "df1", df2_label = "df2") {
  col1 <- paste0("in_", df1_label)
  col2 <- paste0("in_", df2_label)
  
  pres1 <- df1 %>%
    select(all_of(id_cols)) %>%
    distinct() %>%
    mutate(!!col1 := TRUE)
  
  pres2 <- df2 %>%
    select(all_of(id_cols)) %>%
    distinct() %>%
    mutate(!!col2 := TRUE)
  
  cmp <- full_join(pres1, pres2, by = id_cols) %>%
    mutate(
      !!col1   := coalesce(!!sym(col1), FALSE),
      !!col2   := coalesce(!!sym(col2), FALSE),
      in_both  = !!sym(col1) & !!sym(col2)
    ) %>%
    arrange(across(all_of(id_cols)))
  
  return(cmp)
}

write_comparisons <- function(df1, df2, id_cols, metrics, out_path,
                              df1_label = "df1", df2_label = "df2") {
  # 1) Deduplicate on the key columns
  df1_base <- df1 %>% distinct(across(all_of(id_cols)), .keep_all = TRUE)
  df2_base <- df2 %>% distinct(across(all_of(id_cols)), .keep_all = TRUE)
  
  # 2) Create the workbook now, before writing sheets
  wb <- createWorkbook()
  
  # 3) For each metric, compare, write sheet, and build summary row
  summary_list <- imap(metrics, function(filter_expr, metric_name) {
    d1  <- df1_base %>% filter(!!filter_expr)
    d2  <- df2_base %>% filter(!!filter_expr)
    
    cmp <- compare_files(d1, d2, id_cols, df1_label, df2_label)
    
    # Write this metric’s comparison into its own sheet
    addWorksheet(wb, metric_name)
    writeData(wb, sheet = metric_name, cmp)
    
    # Build a one-row summary of counts
    tibble(
      metric = metric_name,
      !!paste0("in_", df1_label) := sum(cmp[[paste0("in_", df1_label)]]),
      !!paste0("in_", df2_label) := sum(cmp[[paste0("in_", df2_label)]])
    )
  })
  
  # 4) Save the workbook once all sheets are added
  saveWorkbook(wb, out_path, overwrite = TRUE)
  
  # 5) Return the combined summary table
  bind_rows(summary_list)
}

########################################
# Convert all POSIXct or POSIXt fields to date fields in multiple data frames
########################################

  # Purpose: Converts all POSIXct/POSIXt columns to Date in the named data frames, 
  # and attempts to parse shorter character columns into dates (YYYY-MM-DD).
  #
  # Criteria for character columns to be converted:
  #   1) The longest non-NA string must be <= max_length_threshold.
  #   2) At least parse_threshold fraction of non-NA rows parse as YYYY-MM-DD.
  #
  # Args:
  #   df_names           - A character vector of data frame names (in global env).
  #   max_length_threshold - Maximum length of strings to consider for date parsing.
  #   parse_threshold    - Proportion (0-1) of non-NA rows that must parse 
  #                        cleanly as dates for conversion.
  #
  # Example usage:
  # Convert all dates in data_df except the POSIXct “updateon” column:
  # convert_dates("data_df", exclude = "updateon")
  # Or, with many data frames
  # convert_dates(
  #   c("data_df", "eric_detail_df"),
  #   exclude = c("updateon", "another_datetime_col")
  # )

  # convert_dates(
  #   df_names           = "data_df",
  #   exclude            = "updateon",
  #   max_length_threshold = 30,
  #   parse_threshold    = 0.8
  # )
  #   df_names <- c("custody_df", "placements_df")
  #   convert_dates(df_names, max_length_threshold = 40, parse_threshold = 0.9)
  #
  # This function overwrites the original data frames in the global environment.
  
  convert_dates <- function(
    df_names, 
    exclude = character(),       # NEW: names of columns to skip
    max_length_threshold = 30,   # Skip character columns longer than this
    parse_threshold = 0.8        # Require 80% parse success to convert char→Date
  ) {
    
    # Purpose: Converts POSIXct/POSIXt columns to Date, and
    #          parses short character columns (YYYY-MM-DD) into Date,
    #          in each named data frame, EXCEPT any columns in `exclude`.
    
    # 1) Pull data frames from global env
    data_list <- mget(df_names, envir = .GlobalEnv)
    
    # 2) Validate
    if (!all(sapply(data_list, is.data.frame))) {
      stop("All df_names must refer to data frames.")
    }
    
    # 3) Process each data frame
    converted_list <- lapply(data_list, function(df) {
      
      for (col_name in names(df)) {
        # Skip excluded columns
        if (col_name %in% exclude) next
        
        col_data <- df[[col_name]]
        
        # 3a) POSIXct / POSIXt → Date
        if (inherits(col_data, "POSIXct") || inherits(col_data, "POSIXt")) {
          df[[col_name]] <- as.Date(col_data)
          
          # 3b) Potential character date columns
        } else if (is.character(col_data)) {
          # Trim whitespace
          df[[col_name]] <- trimws(col_data)
          non_na_vals <- df[[col_name]][!is.na(df[[col_name]])]
          if (length(non_na_vals) == 0) next
          
          # Skip if strings too long
          if (max(nchar(non_na_vals), na.rm = TRUE) > max_length_threshold) next
          
          # Attempt parse
          parsed <- tryCatch(
            as.Date(df[[col_name]], format = "%Y-%m-%d"),
            error = function(e) rep(NA, length(df[[col_name]]))
          )
          
          # Check parse ratio
          original_non_na <- sum(!is.na(df[[col_name]]))
          parsed_non_na   <- sum(!is.na(parsed))
          ratio <- if (original_non_na == 0) 0 else parsed_non_na / original_non_na
          
          if (ratio >= parse_threshold && parsed_non_na > 0) {
            df[[col_name]] <- parsed
          }
        }
      }
      
      df
    })
    
    # 4) Overwrite in global env
    list2env(converted_list, envir = .GlobalEnv)
  }



########################################
# Calculate length of stay  ----
########################################

# TODO: 
  # Use curly-curly operator to convert variables to strings, and eliminate
  # user from having to put them in "" (this is NSE)

# Purpose: Creates variables, los_days, los_months, los_years, based on the two 
# dates you provide or optionally a third censor date to use when the end date
# is missing. Returns NA if the start or end date are missing or if the 
# "start" date (e.g., removal_date, admission_date) is > the end date.
# Also works if the two fields provided are numeric (it will simply subtract
# the two). Also prints out some basic frequencies. 

# Function name: calculate_los()

# Arguments (3): name of data frame, start date, end date
# Optional argument (1): censor_date

# Examples: 

  # data_df <- calculate_los(data_df, "date_of_admission_rev", "date_of_discharge_rev")

  # data_df <- data_df %>% 
  #   mutate(censor_date = as.Date("2024-02-14")) %>%
  #   calculate_los(entry_date, exit_date, censor_date)

  # data_df <- calculate_los(data_df, "date_of_admission_rev", "date_of_discharge_rev", "censor_date")

# Notes: Consider renaming the returned variables to be more specific. e.g., 
# data_df <- data_df %>%
# rename(
#   removal_los_days = los_days,
#   removal_los_months = los_months,
#   removal_los_years = los_years,
#  )

calculate_los <- function(df, start_date, end_date, censor_date = NA) {
  # Convert to date format if not already
  df[[start_date]] <- ymd(df[[start_date]])
  df[[end_date]] <- ymd(df[[end_date]])
  
  # Handle optional censor_date
  if (!is.na(censor_date) && censor_date %in% names(df)) {
    df[[censor_date]] <- ymd(df[[censor_date]])
  }
  
  # Calculate LOS
  df$los_days <- as.integer(ifelse(is.na(df[[end_date]]), 
                                   if (!is.na(censor_date) && censor_date %in% names(df)) lubridate::interval(df[[start_date]], df[[censor_date]]) / days(1) else NA,
                                   lubridate::interval(df[[start_date]], df[[end_date]]) / days(1)))
  df$los_months <- as.integer(ifelse(is.na(df[[end_date]]), 
                                     if (!is.na(censor_date) && censor_date %in% names(df)) time_length(lubridate::interval(df[[start_date]], df[[censor_date]]), "months") else NA,
                                     time_length(lubridate::interval(df[[start_date]], df[[end_date]]), "months")))
  df$los_years <- as.integer(ifelse(is.na(df[[end_date]]), 
                                    if (!is.na(censor_date) && censor_date %in% names(df)) time_length(lubridate::interval(df[[start_date]], df[[censor_date]]), "years") else NA,
                                    time_length(lubridate::interval(df[[start_date]], df[[end_date]]), "years")))
  
# Report statistics
 cat("Number of records with start date but missing end date (still in setting; will be NA unless censor date was provided):", sum(!is.na(df[[start_date]]) & is.na(df[[end_date]])), "\n")
 cat("Number of records with end date but missing start date (will be NA):", sum(is.na(df[[start_date]]) & !is.na(df[[end_date]])), "\n")
 cat("Number of records missing both dates (will be NA):", sum(is.na(df[[start_date]]) & is.na(df[[end_date]])), "\n")
 cat("Number of records where start date is > end date:", sum(df[[start_date]] > df[[end_date]], na.rm = TRUE), "\n")
 cat("Number of records where LOS couldn't be calculated (i.e., NA):", sum(is.na(df$los_days)), "\n")
 if (!is.null(censor_date) && censor_date %in% names(df)) {
   cat("Number of records where LOS was calculated using the censor date:", sum(!is.na(df[[start_date]]) & is.na(df[[end_date]]) & !is.na(df[[censor_date]])), "\n")
 } else {
   cat("Censor date not provided or not used for any records.\n")
 }
 cat("Minimum LOS in days:", min(df$los_days, na.rm = TRUE), "\n")
 cat("Maximum LOS in days:", max(df$los_days, na.rm = TRUE), "\n")
 cat("Mean LOS in days:", mean(df$los_days, na.rm = TRUE), "\n")
 cat("Median LOS in days:", median(df$los_days, na.rm = TRUE), "\n")

  # Optionally, remove temporary columns start_date and end_date
  # df <- select(df, -start_date, -start_date, -censor_date)

   return(df)
 }

########################################
# Calculate CY, FFY, or SFY of any date  ----
########################################

# Purpose: Extracts from the date you provide the calendar year (Jan - Dec), 
# state fiscal year (Jul - Jun), and federal fiscal year (Oct to Sep). 
# Stores these in event_cy, event_ffy, and event_sfy. Returns NA if the date is
# missing. Also prints out some basic frequencies. 

# Function name: calculate_year()

# Arguments (2): name of data frame, event date

# Example: data_df <- calculate_year(data_df, "entry_date")

# Notes: Consider renaming the returned variables to be more specific. e.g., 
# data_df <- data_df %>%
# rename(
#   entry_cy = event_cy,
#   entry_sfy = event_sfy,
#   entry_ffy = event_ffy,
#  )

calculate_year <- function(data_frame, date_field) {

  # Convert the date field to a Date object and calculate years
  data_frame <- data_frame %>%
    mutate(
      event_date = as.Date(!!sym(date_field)),
      event_cy = year(event_date),
      event_sfy = ifelse(month(event_date) >= 7, year(event_date) + 1, year(event_date)),
      event_ffy = ifelse(month(event_date) >= 10, year(event_date) + 1, year(event_date))
    )
  
  # Dynamically refer to the column for reporting statistics
  date_column = data_frame[[date_field]]
  
  cat("Number of records with event date missing (will be NA):", sum(is.na(date_column)), "\n")
  cat("Number of records for each calendar year:\n")
  print(table(data_frame$event_cy, useNA = "ifany"))
  cat("Number of records for each state fiscal year:\n")
  print(table(data_frame$event_sfy, useNA = "ifany"))
  cat("Number of records for each federal fiscal year:\n")
  print(table(data_frame$event_ffy, useNA = "ifany"))
  
  # Optionally, remove temporary columns event_date
  data_frame <- select(data_frame, -event_date)
  
  return(data_frame)
}
