# utilities-core

Core R utilities used across all ChildMetrix projects.

**Repository**: [github.com/childmetrix/utilities-core](https://github.com/childmetrix/utilities-core)

## Purpose

This repo contains generic R functions, package loaders, project setup scripts, and templates that are used across ALL ChildMetrix projects regardless of client/state.

## Contents

### Root Files

**loader.R**
- Primary package loader for all projects
- Loads commonly used packages (tidyverse, lubridate, etc.)
- Use: `source("D:/repo_childmetrix/utilities-core/loader.R")`

**r_project_setup.R**
- Creates new R project structure
- Copies script templates to new project
- Sets up standard folder structure (data/, output/, scripts/, etc.)

### Functions Directory

**generic_functions.R**
- Generic helper functions used across all projects
- Data cleaning utilities
- Date manipulation functions
- Common transformations
- Use: `source("D:/repo_childmetrix/utilities-core/functions/generic_functions.R")`

**r_load_packages.R**
- Package management utilities
- Check and install missing packages
- Load packages with error handling

### Templates Directory

**r_script_template_generic.R**
- Generic R script template for new analysis scripts
- Includes standard header, sections for setup, analysis, output
- Copied by `r_project_setup.R` when creating new projects

**claude_project_template.md**
- Template for project-level CLAUDE.md files
- Copied and renamed to `.claude/CLAUDE.md` in new projects
- Helps Claude Code understand project structure and dependencies

## Usage in Projects

Every ChildMetrix project should source core utilities at the top of scripts:

```r
# Load core utilities
source("D:/repo_childmetrix/utilities-core/loader.R")
source("D:/repo_childmetrix/utilities-core/functions/generic_functions.R")
```

## When to Add Functions Here

Add functions to utilities-core when they are:
- Generic and reusable across multiple clients/states
- Not specific to any particular state or client
- Stable and well-tested
- Documented clearly

## When NOT to Add Functions Here

Do NOT add functions here if they are:
- Specific to a state (Mississippi, Maryland, etc.) → use state-specific utilities repo
- Specific to a client/project → keep in project repo
- Experimental or untested → test in project first, then promote later
- Contain client-specific logic or assumptions

## Maintenance

When modifying core utilities:
1. Test changes across multiple projects before committing
2. Update this CLAUDE.md if you add new files or functions
3. Document breaking changes clearly
4. Consider backward compatibility - many projects depend on this
