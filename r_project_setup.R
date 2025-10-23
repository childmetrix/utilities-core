# Function to create a new r project
# At bottom, just specify the base path and project name

# Will return, for example:
# base_folder              <- "D:/repo_mdcps_suspension_period/r_0.0_hotel/data"
# commitment               <- "0.0"
# commitment_description   <- ""  # e.g. "Hotel analysis"
# today_date               <- format(Sys.Date(), "%Y%m%d")

#’ Create a new RStudio project with boilerplate, Git & GitHub setup, and a patched template
#’
#’ @param base_path     Path to parent folder where project folder will be created
#’ @param project_name  Name of the new project folder (e.g. "r_0.0_hotel")
#’ @param template_path Path to your generic R-script template to copy into code/
#’ @return Invisibly returns NULL; side‐effects: creates folders, files, git repo, GitHub repo
create_rstudio_project <- function(base_path,
                                   project_name,
                                   template_path) {
  project_path     <- file.path(base_path, project_name)
  code_folder      <- file.path(project_path, "code")
  data_folder      <- file.path(project_path, "data")
  output_folder    <- file.path(project_path, "output")
  docs_folder      <- file.path(project_path, "docs")
  rproj_file       <- file.path(project_path, paste0(project_name, ".Rproj"))
  new_script       <- file.path(code_folder, paste0(project_name, ".R"))
  gitignore_file   <- file.path(project_path, ".gitignore")
  
  # 1) Create directory structure
  if (dir.exists(project_path)) {
    message("⚠️  Folder already exists at: ", project_path)
    return(invisible(NULL))
  }
  dir.create(project_path, recursive = TRUE)
  dir.create(code_folder)
  dir.create(data_folder)
  dir.create(output_folder)
  dir.create(docs_folder)
  
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
  
  # 3) Copy your generic R-script template into code/
  if (!file.exists(template_path)) {
    stop("Template not found: ", template_path)
  }
  file.copy(template_path, new_script, overwrite = TRUE)
  
  # 4) Patch the copied template
  commit_id <- sub("^r_([^_]+).*$", "\\1", project_name)  # e.g. "0.0"
  
  lines <- readLines(new_script, warn = FALSE)
  # 4a) base_folder <- ".../data"
  lines <- gsub(
    pattern     = "^\\s*base_folder\\s*<-.*$",
    replacement = sprintf('base_folder <- "%s/data"', project_path),
    x           = lines
  )
  # 4b) commitment <- "0.0"
  lines <- gsub(
    pattern     = "^\\s*commitment\\s*<-.*$",
    replacement = sprintf('commitment <- "%s"', commit_id),
    x           = lines
  )
  # 4c) insert placeholder for human-readable description
  idx <- grep("^\\s*commitment\\s*<-", lines)
  if (length(idx)) {
    lines <- append(
      lines,
      'commitment_description <- ""  # e.g. "Hotel analysis"',
      after = idx
    )
  }
  writeLines(lines, new_script)
  
  # 5) Write .gitignore
  writeLines(
    c(
      "*.csv", "*.xlsx", "*.xlsm", "*.docx", "*.pdf", "*.pptx", "*.accdb",
      ".Rproj.user/", ".Rhistory", ".RData",
      "*.png", "*.jpg", "*.jpeg", "*.bmp",
      "*.log", "*.tmp", "*.bak", "*.swp", "*~", ".DS_Store", "Thumbs.db",
      "*.sav", "*.txt", "*.html", "*.axx",
      "data/", "code/old/"
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
  run_in_project("git init")
  run_in_project('git config user.email "kurtheisler@childmetrix.com"')
  run_in_project('git config user.name  "kurtheisler"')
  run_in_project("git add .")
  run_in_project('git commit -m "Initial commit"')
  
  # rename default branch to main
  run_in_project("git branch -M main")
  
  # 7) Create or skip GitHub repo
  gh_view_status <- suppressWarnings(
    run_in_project(sprintf("gh repo view kurtheisler/%s", project_name))
  )
  if (gh_view_status != 0) {
    gh_create_status <- run_in_project(
      sprintf('gh repo create %s --private --confirm', project_name)
    )
    if (gh_create_status != 0) {
      warning("⚠️  Could not create GitHub repo; it may already exist remotely.")
    }
  } else {
    message("🔎 GitHub repo already exists; skipping creation.")
  }
  
  # 8) Wire up remote & push
  run_in_project(sprintf(
    'git remote add origin https://github.com/kurtheisler/%s.git',
    project_name
  ))
  
  # Use 'main' for the initial push
  run_in_project("git push -u origin main")
  
  message("✅ Project successfully created at: ", project_path)
}
# ──────────────────────────────────────────────────────────────────────────────
# USAGE EXAMPLE:
# When you’re ready to spin up a new project, simply call:

# Usage example:
create_rstudio_project(
  # base_path    = "D:/repo_maryland",
  # base_path    = "D:/repo_mdcps_suspension_period",
  base_path    = "D:/repo_childmetrix",
  project_name = "r_cfsr_profile",
  # template_path = "D:/repo_childmetrix/r_utilities/r_script_template_mdcps.R"
  template_path = "D:/repo_childmetrix/r_utilities/templates/r_script_template_generic.R"
)



