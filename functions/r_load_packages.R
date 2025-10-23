# Packages to load

pkg_list <- c(
  "forcats",    # Categorical factor manipulation functions (part of the tidyverse)
  "flextable",  # Create and customize tables for reporting (Word, PowerPoint, HTML)
  "fuzzyjoin",  # Join data frames using inexact/fuzzy matching
  "fs",         # Cross-platform file system operations (directory listing, file manipulation)
  "ggrepel",    # Prevent overlapping text labels in ggplot2 plots
  "glue",       # String interpolation and concatenation
  "gridExtra",  # Arrange multiple grid-based plots (grid, lattice, ggplot2)
  "here",       # Construct file paths relative to a project root
  "hrbrthemes", # Additional themes and typography options for ggplot2
  "janitor",    # Data-cleaning helpers (clean column names, remove empty rows/columns, tabulations)
  "kableExtra", # Enhance knitr::kable tables with advanced formatting
  "lubridate",  # Simplifies working with dates/times (parsing, arithmetic, time zones)
  "openxlsx",   # Read and write XLSX files without Java dependencies
  "officer",    # Manipulate Microsoft Word and PowerPoint documents (tables, slides, formatting)
  "paletteer",  # Access curated color palettes from multiple packages
  "patchwork",  # Combine multiple ggplot2 plots into cohesive layouts
  "plyr",       # Tools for splitting, applying, and combining data (part of the tidyverse)
  "plotly",     # Create interactive web-based plots via the plotly.js library
  "prettydoc",  # Provides modern, minimal HTML themes for R Markdown
  "purrr",      # Functional programming tools for iteration and list manipulation
  "readxl",     # Read Excel files (XLSX, XLS)
  "rmarkdown",  # Dynamic document generation from R Markdown to HTML, PDF, Word, etc.
  "rmdformats", # Additional R Markdown output formats and templates
  "reticulate", # Interface to Python from R (call Python code, objects, and modules)
  "rlang",      # Tools for programming with the tidyverse (tidy evaluation, expression handling)
  "scales",     # Scale transformations and label formatting for ggplot2 (comma, percent, date scales)
  "stringdist", # Approximate string matching and string distance calculations
  "stringr",    # String manipulation functions (part of the tidyverse)
  "tidyverse",  # Collection of packages for data science (ggplot2, dplyr, tidyr, readr, purrr, tibble, stringr, forcats, etc.)
  "writexl",    # Write data frames to Excel files (XLSX), including multiple sheets
  "gt",         # Create and format tables for reporting (HTML, R Markdown, Word, PowerPoint)
  "clock",       # Date and time manipulation; has add_with_rollback which handles leap year issues
  "htmlwidgets",  # Create interactive web-based widgets (tables, plots, etc. for R Markdown)
  "networkD3",     # Create network diagrams using D3.js in R
  "digest",          # Create hash digests of R objects (for caching, data integrity checks
  "pdftools",        # Extract text and metadata from PDF files
  "tidyxl"      # Import non-tabular data from Excel files (XLSX, XLS)
)

# Function to load packages
load_my_packages <- function(pkgs = pkg_list) {
  # install pacman if missing
  if (!requireNamespace("pacman", quietly = TRUE)) {
    install.packages("pacman")
  }
  # load (and install if needed) everything in one go
  pacman::p_load(char = pkgs, install = TRUE, update = FALSE)
}
