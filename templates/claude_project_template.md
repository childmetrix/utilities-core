# Project: [PROJECT_NAME]

## Commitment Reference

[State]-[Commitment Number] - [Full Description]

Example: ms-1.3a - Mississippi Consent Decree Commitment 1.3.a - Suspension Period Analysis

## Project Description

[Brief description of what this project analyzes and produces]

## Repository Information

**Repository**: [github.com/childmetrix/PROJECT_NAME](https://github.com/childmetrix/PROJECT_NAME)
**Local Path**: [Full path to project on local machine]

## Dependencies

### Utilities Used

This project depends on the following utility repositories:

```r
# Core utilities (always required)
source("D:/repo_childmetrix/utilities-core/loader.R")
source("D:/repo_childmetrix/utilities-core/functions/generic_functions.R")

# State/client-specific utilities (select appropriate ones)
# source("D:/repo_childmetrix/utilities-mdcps/functions/functions_mdcps.R")
# source("D:/repo_childmetrix/utilities-md/functions/functions_md.R")
# source("D:/repo_childmetrix/utilities-cfsr/functions/functions_cfsr_profile.R")
```

### R Packages

List key R packages used:
- tidyverse
- lubridate
- [Add other packages specific to this project]

## Project Structure

```
project-name/
├── .claude/
│   └── CLAUDE.md          # This file
├── data/                  # Input data files (not in git)
│   ├── raw/              # Original data files
│   └── processed/        # Cleaned/processed data
├── output/               # Generated outputs (not in git)
│   ├── figures/          # Charts and visualizations
│   ├── tables/           # Data tables for reports
│   └── reports/          # Final reports
├── scripts/              # R analysis scripts
│   ├── 01_data_prep.R    # Data preparation
│   ├── 02_analysis.R     # Main analysis
│   └── 03_reporting.R    # Report generation
├── functions/            # Project-specific functions (if any)
├── README.md
└── .gitignore
```

## Data Sources

### Input Data

[Describe where data comes from, what files are needed, how to access them]

Example:
- Source: Mississippi SACWIS system
- File: `monthly_data_YYYYMM.csv`
- Location: `data/raw/`
- Update frequency: Monthly

### Data Confidentiality

[Note any confidentiality requirements or restrictions]

## Key Outputs

[Describe what this project produces]

Example:
- Monthly trend analysis of suspension periods
- Summary statistics table
- Visualizations showing compliance with commitment targets
- Word report with findings

## Analysis Workflow

[Step-by-step description of how to run the analysis]

Example:
1. Place new data files in `data/raw/`
2. Run `scripts/01_data_prep.R` to clean and process data
3. Run `scripts/02_analysis.R` to perform calculations
4. Run `scripts/03_reporting.R` to generate outputs
5. Review outputs in `output/` directory

## Important Notes

[Any project-specific notes, caveats, or things to remember]

Example:
- Data is embargoed until [date]
- Analysis must align with prior year methodology for consistency
- Specific definitions used for [key metrics]

## Contact/Stakeholders

[Who to contact about this project, who receives outputs]

## Last Updated

[Date] - [Brief note about what changed]
