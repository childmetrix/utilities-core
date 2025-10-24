# Function to create a new R project with enforced naming conventions
#
# NAMING CONVENTIONS:
# - Repo folders: kebab-case in format <state>-<project>-<commitment>
#   Example: "ms-mdcps-1-3-b"
# - R scripts: snake_case
#   Example: "1_3_b.R"
#
# This ensures consistency across all ChildMetrix projects

#' Create a new RStudio project with enforced naming conventions
#'
#' @param base_path          Path to parent folder where project folder will be created
#' @param state              State abbreviation (e.g., "ms", "md", "ky", "mi")
#' @param project            Project name (e.g., "mdcps", "cfsr")
#' @param commitment         Commitment number (e.g., "1.3.a", "5.2.c")
#' @param commitment_desc    Optional human-readable description
#' @param template_path      Path to your R-script template to copy into code/
#' @return Invisibly returns NULL; side-effects: creates folders, files, git repo, GitHub repo
#'
#' @examples
#' # Mississippi MDCPS project
#' create_rstudio_project(
#'   base_path = "D:/repo_mdcps_suspension_period",
#'   state = "ms",
#'   project = "mdcps",
#'   commitment = "1.3.a",
#'   commitment_desc = "Suspension period analysis",
#'   template_path = "D:/repo_childmetrix/utilities-mdcps/templates/r_script_template_mdcps.R"
#' )
#'
#' # Maryland project
#' create_rstudio_project(
#'   base_path = "D:/maryland",
#'   state = "md",
#'   project = "maryland",
#'   commitment = "5.2.c",
#'   template_path = "D:/repo_childmetrix/utilities-md/templates/r_script_template_md.R"
#' )
create_rstudio_project <- function(base_path,
                                   state,
                                   project,
                                   commitment,
                                   commitment_desc = "",
                                   template_path) {

  # Validate inputs
  if (missing(base_path) || missing(state) || missing(project) || missing(commitment) || missing(template_path)) {
    stop("Missing required arguments: base_path, state, project, commitment, template_path")
  }

  # Convert commitment to kebab-case for folder (1.3.a -> 1-3-a)
  commitment_kebab <- gsub("\\.", "-", tolower(commitment))

  # Convert commitment to snake_case for R script (1.3.a -> 1_3_a)
  commitment_snake <- gsub("\\.", "_", tolower(commitment))

  # Build folder name: <state>-<project>-<commitment> (kebab-case)
  # Example: ms-mdcps-1-3-a
  folder_name <- paste(tolower(state), tolower(project), commitment_kebab, sep = "-")

  # Build R script name: <commitment>.R (snake_case)
  # Example: 1_3_a.R
  script_name <- paste0(commitment_snake, ".R")

  # Define paths
  project_path     <- file.path(base_path, folder_name)
  code_folder      <- file.path(project_path, "code")
  data_folder      <- file.path(project_path, "data")
  output_folder    <- file.path(project_path, "output")
  docs_folder      <- file.path(project_path, "docs")
  claude_folder    <- file.path(project_path, ".claude")
  rproj_file       <- file.path(project_path, paste0(folder_name, ".Rproj"))
  new_script       <- file.path(code_folder, script_name)
  gitignore_file   <- file.path(project_path, ".gitignore")
  claude_file      <- file.path(claude_folder, "CLAUDE.md")

  # 1) Create directory structure
  if (dir.exists(project_path)) {
    message("⚠️  Folder already exists at: ", project_path)
    return(invisible(NULL))
  }

  message("📁 Creating project: ", folder_name)
  message("   Folder (kebab-case): ", folder_name)
  message("   Script (snake_case): ", script_name)

  dir.create(project_path, recursive = TRUE)
  dir.create(code_folder)
  dir.create(data_folder)
  dir.create(output_folder)
  dir.create(docs_folder)
  dir.create(claude_folder)

  # 2) Write a minimal .Rproj
  writeLines(
    c(
      "Version: 1.0",
      "",
      "RestoreWorkspace: No",
      "SaveWorkspace: No",
      "AlwaysSaveHistory: Default"
    ), con = rproj_file
  )

  # 3) Copy your R-script template into code/
  if (!file.exists(template_path)) {
    stop("Template not found: ", template_path)
  }
  file.copy(template_path, new_script, overwrite = TRUE)

  # 3b) Copy CLAUDE.md template for Claude Code
  claude_template_path <- file.path(dirname(template_path), "claude_project_template.md")
  if (file.exists(claude_template_path)) {
    file.copy(claude_template_path, claude_file, overwrite = TRUE)

    # Patch the CLAUDE.md template with project details
    claude_lines <- readLines(claude_file, warn = FALSE)
    claude_lines <- gsub("\\[PROJECT_NAME\\]", folder_name, claude_lines)
    claude_lines <- gsub("\\[STATE\\]", toupper(state), claude_lines)
    claude_lines <- gsub("\\[COMMITMENT\\]", commitment, claude_lines)
    claude_lines <- gsub("\\[COMMITMENT_DESC\\]", commitment_desc, claude_lines)
    writeLines(claude_lines, claude_file)

    message("✅ CLAUDE.md template copied to .claude/")
  } else {
    warning("⚠️  CLAUDE.md template not found at: ", claude_template_path)
  }

  # 4) Patch the copied R script template
  lines <- readLines(new_script, warn = FALSE)

  # 4a) base_folder <- ".../data"
  lines <- gsub(
    pattern     = "^\\s*base_folder\\s*<-.*$",
    replacement = sprintf('base_folder <- "%s/data"', project_path),
    x           = lines
  )

  # 4b) commitment <- "1.3.a"
  lines <- gsub(
    pattern     = "^\\s*commitment\\s*<-.*$",
    replacement = sprintf('commitment <- "%s"', commitment),
    x           = lines
  )

  # 4c) Insert commitment_description if not already present
  if (!any(grepl("commitment_description\\s*<-", lines))) {
    idx <- grep("^\\s*commitment\\s*<-", lines)
    if (length(idx)) {
      desc_line <- if (nzchar(commitment_desc)) {
        sprintf('commitment_description <- "%s"', commitment_desc)
      } else {
        'commitment_description <- ""  # e.g. "Suspension period analysis"'
      }
      lines <- append(lines, desc_line, after = idx[1])
    }
  }

  # 4d) today_date
  lines <- gsub(
    pattern     = "^\\s*today_date\\s*<-.*$",
    replacement = sprintf('today_date <- "%s"', format(Sys.Date(), "%Y%m%d")),
    x           = lines
  )

  writeLines(lines, new_script)

  # 5) Write .gitignore
  writeLines(
    c(
      "# Data files",
      "*.csv", "*.xlsx", "*.xlsm", "*.accdb", "*.sav",
      "",
      "# Output files",
      "*.docx", "*.pdf", "*.pptx",
      "*.png", "*.jpg", "*.jpeg", "*.bmp",
      "*.txt", "*.html",
      "",
      "# R files",
      ".Rproj.user/", ".Rhistory", ".RData",
      "",
      "# Temp files",
      "*.log", "*.tmp", "*.bak", "*.swp", "*~", "*.axx",
      ".DS_Store", "Thumbs.db",
      "",
      "# Directories",
      "data/",
      "code/old/"
    ),
    con = gitignore_file
  )

  # Helper to run shell commands inside the new project folder
  run_in_project <- function(cmd) {
    full_cmd <- sprintf('cd /d "%s" && %s', project_path, cmd)
    res      <- system2("cmd", args = c("/c", full_cmd), stdout = TRUE, stderr = TRUE)
    status   <- attr(res, "status")
    if (is.null(status)) status <- 0
    return(status)
  }

  # 6) Initialize Git
  message("🔧 Initializing Git...")
  run_in_project("git init")
  run_in_project('git config user.email "kurtheisler@childmetrix.com"')
  run_in_project('git config user.name  "kurtheisler"')
  run_in_project("git add .")
  run_in_project('git commit -m "Initial commit"')
  run_in_project("git branch -M main")

  # 7) Create GitHub repo (using childmetrix organization)
  gh_owner <- "childmetrix"
  message("🌐 Creating GitHub repo at: ", gh_owner, "/", folder_name)

  gh_view_status <- suppressWarnings(
    run_in_project(sprintf("gh repo view %s/%s", gh_owner, folder_name))
  )

  if (gh_view_status != 0) {
    gh_create_status <- run_in_project(
      sprintf('gh repo create %s/%s --private --confirm', gh_owner, folder_name)
    )
    if (gh_create_status != 0) {
      warning("⚠️  Could not create GitHub repo; it may already exist remotely.")
    }
  } else {
    message("🔎 GitHub repo already exists; skipping creation.")
  }

  # 8) Wire up remote & push
  run_in_project(sprintf(
    'git remote add origin https://github.com/%s/%s.git',
    gh_owner, folder_name
  ))

  message("⬆️  Pushing to GitHub...")
  run_in_project("git push -u origin main")

  message("✅ Project successfully created!")
  message("   📂 Local:  ", project_path)
  message("   🌐 GitHub: https://github.com/", gh_owner, "/", folder_name)
  message("   📝 Script: code/", script_name)

  invisible(NULL)
}

# ──────────────────────────────────────────────────────────────────────────────
# USAGE EXAMPLES
# ──────────────────────────────────────────────────────────────────────────────

# Example 1: Mississippi MDCPS project
# Folder: ms-mdcps-1-3-b
# Script: 1_3_b.R
create_rstudio_project(
  base_path = "D:/repo_mdcps_suspension_period",
  state = "ms",
  project = "mdcps",
  commitment = "1.3.b",
  commitment_desc = "Suspension period analysis",
  template_path = "D:/repo_childmetrix/utilities-mdcps/templates/r_script_template_mdcps.R"
)

# Example 2: Maryland project
# Folder: md-maryland-5-2-c
# Script: 5_2_c.R
# create_rstudio_project(
#   base_path = "D:/maryland",
#   state = "md",
#   project = "maryland",
#   commitment = "5.2.c",
#   commitment_desc = "Enrollment trends",
#   template_path = "D:/repo_childmetrix/utilities-md/templates/r_script_template_md.R"
# )

# Example 3: CFSR project (no state)
# Folder: cfsr-profile-2-1-a
# Script: 2_1_a.R
# create_rstudio_project(
#   base_path = "D:/repo_childmetrix",
#   state = "cfsr",
#   project = "profile",
#   commitment = "2.1.a",
#   template_path = "D:/repo_childmetrix/utilities-core/templates/r_script_template_generic.R"
# )
