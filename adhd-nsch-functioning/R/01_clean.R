# 01_clean.R
# Build analysis variables exactly as specified in ANALYSIS_PLAN.md (locked
# 2026-10-08) and output/variable_map.md. Variables are built on the FULL file
# so the survey design can be declared on all children; the ADHD analytic group
# is a flag, not a filter.
#
# Usage: Rscript R/01_clean.R [year]   (default 2024; 2025 is the replication)

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
})

args <- commandArgs(trailingOnly = TRUE)
year <- if (length(args) >= 1) args[1] else "2024"
stopifnot(year %in% c("2024", "2025"))

raw_path <- file.path("data", "raw", sprintf("nsch_%s_topical_Stata", year),
                      sprintf("nsch_%se_topical.dta", year))
raw <- read_dta(raw_path) |> zap_labels() |> zap_formats()
names(raw) <- toupper(names(raw))
cat(sprintf("[%s] raw file: %d children, %d variables\n", year, nrow(raw), ncol(raw)))

# yes/no items: 1 = Yes -> 1, 2 = No -> 0, anything else -> NA
yn <- function(x) case_when(x == 1 ~ 1L, x == 2 ~ 0L, TRUE ~ NA_integer_)
# frequency items coded 1-4 where 1-2 is the "positive" end
top2 <- function(x) case_when(x %in% 1:2 ~ 1L, x %in% 3:4 ~ 0L, TRUE ~ NA_integer_)
fpl_cat <- function(x) cut(x, breaks = c(-Inf, 99.999, 199.999, 399.999, Inf),
                           labels = c("<100%", "100-199%", "200-399%", "400%+"))

d <- raw |>
  transmute(
    HHID, FWC,
    strata = paste(FIPSST, STRATUM, sep = "_"),
    age = SC_AGE_YEARS,

    # sample definition
    adhd_current = case_when(K2Q31A == 2 ~ 0L,
                             K2Q31A == 1 & K2Q31B == 1 ~ 1L,
                             K2Q31A == 1 & K2Q31B == 2 ~ 0L,
                             TRUE ~ NA_integer_),
    in_adhd_6_17 = !is.na(adhd_current) & adhd_current == 1 & age >= 6 & age <= 17,

    # outcomes
    finish_raw = if_else(K7Q84_R %in% 1:4, as.integer(K7Q84_R), NA_integer_),
    finish     = top2(K7Q84_R),
    calm_raw   = if_else(K7Q85_R %in% 1:4, as.integer(K7Q85_R), NA_integer_),
    calm       = top2(K7Q85_R),

    # moderator
    girl = case_when(SC_SEX == 2 ~ 1L, SC_SEX == 1 ~ 0L, TRUE ~ NA_integer_),

    # Support 1: family resilience count 0-4 (DRC item coding); NA if any item missing
    fam_resilience = top2(TALKABOUT) + top2(WKTOSOLVE) + top2(STRENGTHS) + top2(HOPEFUL),
    fam_resilient_all4 = as.integer(fam_resilience == 4),

    # Support 2: any organized activity (sports, clubs, other organized activities)
    any_activity = case_when(K7Q30 == 1 | K7Q31 == 1 | K7Q32 == 1 ~ 1L,
                             K7Q30 == 2 & K7Q31 == 2 & K7Q32 == 2 ~ 0L,
                             TRUE ~ NA_integer_),

    # Support 3a/3b: treatment
    adhd_med   = yn(K2Q31D),
    behav_treat = yn(ADDTREAT),

    # covariates
    severity = factor(case_when(K2Q31C == 1 ~ "Mild", K2Q31C == 2 ~ "Moderate",
                                K2Q31C == 3 ~ "Severe"),
                      levels = c("Mild", "Moderate", "Severe")),
    race_eth5 = factor(case_when(
      SC_HISPANIC_R == 1 ~ "Hispanic",
      SC_HISPANIC_R == 2 & SC_RACE_R == 1 ~ "NH White",
      SC_HISPANIC_R == 2 & SC_RACE_R == 2 ~ "NH Black",
      SC_HISPANIC_R == 2 & SC_RACE_R == 4 ~ "NH Asian",
      SC_HISPANIC_R == 2 & SC_RACE_R %in% c(3, 5, 7) ~ "NH other/multiracial"),
      levels = c("NH White", "Hispanic", "NH Black", "NH Asian", "NH other/multiracial")),
    parent_educ = factor(case_when(HIGRADE_TVIS == 1 ~ "Less than high school",
                                   HIGRADE_TVIS == 2 ~ "High school",
                                   HIGRADE_TVIS == 3 ~ "Some college/associate",
                                   HIGRADE_TVIS == 4 ~ "College degree+"),
                         levels = c("College degree+", "Some college/associate",
                                    "High school", "Less than high school")),
    insurance = factor(case_when(INSTYPE == 1 ~ "Public only", INSTYPE == 2 ~ "Private only",
                                 INSTYPE == 3 ~ "Private and public", INSTYPE == 5 ~ "Uninsured"),
                       levels = c("Private only", "Public only", "Private and public", "Uninsured")),
    # income: six Census implicates, kept separate for Rubin's rules
    fpl1 = fpl_cat(FPL_I1), fpl2 = fpl_cat(FPL_I2), fpl3 = fpl_cat(FPL_I3),
    fpl4 = fpl_cat(FPL_I4), fpl5 = fpl_cat(FPL_I5), fpl6 = fpl_cat(FPL_I6),

    # sensitivity variables
    autism_ever = yn(K2Q35A),
    ace_count = case_when(ACE1 %in% 3:4 ~ 1L, ACE1 %in% 1:2 ~ 0L) +
                yn(ACE3) + yn(ACE4) + yn(ACE5) + yn(ACE6) + yn(ACE7) +
                yn(ACE8) + yn(ACE9) + yn(ACE10) + yn(ACE11)
  )

# Race/ethnicity used in models. Pre-specified rule (ANALYSIS_PLAN.md, section 3):
# collapse a category into "NH other/multiracial" if it has fewer than 50 girls in
# the 2024 analytic sample. Table 1 (2024) found 40 NH Asian girls, so NH Asian is
# collapsed. The same 4 categories are used for 2025 so the years are comparable.
d$race_eth <- factor(ifelse(d$race_eth5 == "NH Asian", "NH other/multiracial",
                            as.character(d$race_eth5)),
                     levels = c("NH White", "Hispanic", "NH Black", "NH other/multiracial"))

# Co-occurring condition items are skipped (NA) when the "ever" item is No.
# Recode: a current-condition item is 0 when the matching "ever" item is No.
cur_items <- c("K2Q30", "K2Q32", "K2Q33", "K2Q34", "K2Q35", "K2Q36", "K2Q37", "K2Q38", "K2Q60")
cur <- sapply(cur_items, function(k) {
  a <- raw[[paste0(k, "A")]]; b <- raw[[paste0(k, "B")]]
  case_when(a == 2 ~ 0L, a == 1 & b == 1 ~ 1L, a == 1 & b == 2 ~ 0L, TRUE ~ NA_integer_)
})
d$n_cooccur <- as.integer(rowSums(cur))   # NA if any of the nine is undetermined

# ---- sanity checks -------------------------------------------------------
w <- d$FWC
ok <- !is.na(d$adhd_current) & d$age >= 3
cat(sprintf("[%s] ages 3-17 with determinable ADHD status: n = %d\n", year, sum(ok)))
cat(sprintf("[%s] weighted %% current ADHD (3-17): %.1f%%\n", year,
            100 * weighted.mean(d$adhd_current[ok], w[ok])))
a <- d[d$in_adhd_6_17, ]
cat(sprintf("[%s] analytic subpopulation (current ADHD, 6-17): n = %d (boys %d, girls %d)\n",
            year, nrow(a), sum(a$girl == 0, na.rm = TRUE), sum(a$girl == 1, na.rm = TRUE)))
stopifnot(all(a$fam_resilience %in% c(0:4, NA)),
          all(a$n_cooccur %in% c(0:9, NA)),
          all(a$ace_count %in% c(0:10, NA)),
          sum(is.na(a$girl)) == 0)

dir.create(file.path("data", "derived"), showWarnings = FALSE, recursive = TRUE)
out <- file.path("data", "derived", sprintf("nsch_%s_analysis.rds", year))
saveRDS(d, out)
cat(sprintf("[%s] saved %s (%d rows)\n", year, out, nrow(d)))
