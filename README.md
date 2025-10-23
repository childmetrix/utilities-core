# utilities-core

Core R utilities used across all ChildMetrix projects.

## Contents

### Root Files
- **loader.R** - Loads packages and functions for all projects
- **r_project_setup.R** - Sets up new R projects

### Functions (`/functions`)
- **generic_functions.R** - Generic helper functions used across all projects
- **r_load_packages.R** - Package loading utilities

### Templates (`/templates`)
- **r_script_template_generic.R** - Generic R script template

## Usage

Source these files in your project scripts:

```r
# Load core utilities
source("D:/repo_childmetrix/utilities-core/loader.R")
source("D:/repo_childmetrix/utilities-core/functions/generic_functions.R")
```

## Projects Using This Repo

This repo is used by all ChildMetrix projects across:
- Mississippi (MDCPS)
- Maryland
- Kentucky
- Michigan
- CFSR

## Maintenance

When adding new generic functions:
1. Add to appropriate file in `/functions`
2. Update this README
3. Test across multiple projects before committing
