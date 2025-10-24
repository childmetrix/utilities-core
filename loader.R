# D:/repo_childmetrix/utilities-core/loader.R
# Loads core packages and generic functions for all ChildMetrix projects

util_root <- "D:/repo_childmetrix/utilities-core"

# Load packages first
pkg_script <- file.path(util_root, "functions", "load_packages.R")
if (file.exists(pkg_script)) {
  source(pkg_script, local = FALSE, chdir = FALSE)
  if (exists("load_my_packages")) {
    load_my_packages()
  }
}

# Load generic functions
generic_functions_script <- file.path(util_root, "functions", "functions_generic.R")
if (file.exists(generic_functions_script)) {
  source(generic_functions_script, local = FALSE, chdir = FALSE)
}

# NOTE: templates/, project_setup.R are run manually when needed
# State-specific functions (MDCPS, MD, etc.) should be loaded separately

# Usage (at top of a project script)
# ----------------------------------
# source("D:/repo_childmetrix/utilities-core/loader.R")
# source("D:/repo_childmetrix/utilities-mdcps/functions/functions_mdcps.R")  # if needed

