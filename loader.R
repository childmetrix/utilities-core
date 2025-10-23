# D:/repo_childmetrix/r_utilities/loader.R

util_root <- "D:/repo_childmetrix/r_utilities"

source_dir <- function(path) {
  if (!dir.exists(path)) return(invisible(NULL))
  files <- list.files(path, pattern = "\\.R$", full.names = TRUE)
  for (f in sort(files)) source(f, local = FALSE, chdir = FALSE)
}

# Load packages first 
pkg_script <- file.path(util_root, "core", "r_load_packages.R")
if (file.exists(pkg_script)) {
  source(pkg_script, local = FALSE, chdir = FALSE)
  load_my_packages()  # <— add this
}

# Load all scripts in these subfolder
# Core = generic_functions.R and r_load_packages.R
source_dir(file.path(util_root, "core")) 
# source_dir(file.path(util_root, "domain_specific"))

# NOTE: snippets/, templates/, archive/ are intentionally NOT sourced
# r_project_setup.R lives in the root and is run manually when you start a new project.

# Usage (at top of a project script)
# ----------------------------------

# Load packages and generic functions
# source("D:/repo_childmetrix/r_utilities/loader.R")
# Load functions specific to this project
# source(file.path(util_root, "project_specific", "cfsr_profile.R"), chdir = FALSE)

