# 02_table1.R
# Sample flow, missingness per model variable, and a weighted Table 1 by sex,
# using the design in ANALYSIS_PLAN.md section 5 (FWC weight, FIPSST x STRATUM
# strata, HHID PSU, Taylor linearization). The analytic group is a subpopulation
# of the full design. No outcome models are fit here.
#
# Usage: Rscript R/02_table1.R [year]   (default 2024)

suppressPackageStartupMessages({
  library(dplyr)
  library(survey)
  library(mitools)
})
options(survey.lonely.psu = "certainty")

args <- commandArgs(trailingOnly = TRUE)
year <- if (length(args) >= 1) args[1] else "2024"
d <- readRDS(file.path("data", "derived", sprintf("nsch_%s_analysis.rds", year)))
dir.create("output", showWarnings = FALSE)

model_vars <- c("finish", "girl", "fam_resilience", "any_activity", "adhd_med", "behav_treat",
                "age", "severity", "race_eth", "fpl1", "parent_educ", "insurance", "n_cooccur")

# ---- sample flow ---------------------------------------------------------
adhd <- d[d$in_adhd_6_17, ]
flow <- data.frame(
  step = c("Children in file",
           "Current ADHD, aged 6-17 (subpopulation)",
           "  excluded: missing primary outcome (finish tasks)",
           "Analytic sample (outcome observed)",
           "  of whom complete on all Model 1 variables"),
  all = c(nrow(d), nrow(adhd), sum(is.na(adhd$finish)), sum(!is.na(adhd$finish)),
          sum(complete.cases(adhd[, model_vars]))),
  boys = c(NA, sum(adhd$girl == 0), sum(is.na(adhd$finish) & adhd$girl == 0),
           sum(!is.na(adhd$finish) & adhd$girl == 0),
           sum(complete.cases(adhd[, model_vars]) & adhd$girl == 0)),
  girls = c(NA, sum(adhd$girl == 1), sum(is.na(adhd$finish) & adhd$girl == 1),
            sum(!is.na(adhd$finish) & adhd$girl == 1),
            sum(complete.cases(adhd[, model_vars]) & adhd$girl == 1))
)
cat(sprintf("\n[%s] SAMPLE FLOW\n", year)); print(flow, row.names = FALSE)

# ---- missingness among current ADHD 6-17 (unweighted) --------------------
miss <- data.frame(
  variable = model_vars,
  pct_missing_all   = sapply(model_vars, function(v) 100 * mean(is.na(adhd[[v]]))),
  pct_missing_boys  = sapply(model_vars, function(v) 100 * mean(is.na(adhd[[v]][adhd$girl == 0]))),
  pct_missing_girls = sapply(model_vars, function(v) 100 * mean(is.na(adhd[[v]][adhd$girl == 1])))
)
miss[, -1] <- round(miss[, -1], 1)
cat(sprintf("\n[%s] MISSINGNESS (%% of current ADHD 6-17)\n", year)); print(miss, row.names = FALSE)
over5 <- miss$variable[miss$pct_missing_all > 5]
cat(sprintf("Variables over 5%% missing (triggers MI sensitivity per plan): %s\n",
            if (length(over5)) paste(over5, collapse = ", ") else "none"))

# ---- design and subpopulation --------------------------------------------
des <- svydesign(ids = ~HHID, strata = ~strata, weights = ~FWC, nest = TRUE, data = d)
d$in_analytic <- d$in_adhd_6_17 & !is.na(d$finish)
des <- update(des, in_analytic = d$in_analytic, sex = factor(ifelse(d$girl == 1, "Girls", "Boys")))
sub <- subset(des, in_analytic)

# weighted N (population represented) and unweighted n
wN <- svyby(~I(in_analytic * 1), ~sex, sub, svytotal)
nn <- table(d$girl[d$in_analytic])
cat(sprintf("\n[%s] unweighted n: boys %d, girls %d | weighted N: boys %.0f, girls %.0f\n",
            year, nn[["0"]], nn[["1"]], coef(wN)[["Boys"]], coef(wN)[["Girls"]]))

# race cell check (collapse rule in plan: < 50 girls)
rc <- table(d$race_eth5[d$in_analytic & d$girl == 1])
cat("\nGirls per race/ethnicity category (analytic sample):\n"); print(rc)
small <- names(rc)[rc < 50]
cat(sprintf("Categories under 50 girls (to collapse into NH other/multiracial): %s\n",
            if (length(small)) paste(small, collapse = ", ") else "none"))

# ---- weighted Table 1 ------------------------------------------------------
fmt_ci <- function(est, se, pct) {
  k <- if (pct) 100 else 1; dg <- if (pct) 1 else 2
  sprintf(paste0("%.", dg, "f (%.", dg, "f-%.", dg, "f)"),
          k * est, k * (est - 1.96 * se), k * (est + 1.96 * se))
}
rows <- list()
add_rows <- function(est_tab, label_map, pct) {
  # est_tab: data.frame with columns term, Boys, Boys_se, Girls, Girls_se, All, All_se
  for (i in seq_len(nrow(est_tab))) {
    r <- est_tab[i, ]
    rows[[length(rows) + 1]] <<- data.frame(
      characteristic = label_map[[r$term]] %||% r$term,
      boys = fmt_ci(r$Boys, r$Boys_se, pct), girls = fmt_ci(r$Girls, r$Girls_se, pct),
      all = fmt_ci(r$All, r$All_se, pct))
  }
}
`%||%` <- function(a, b) if (is.null(a)) b else a

# svyby coefficient names are "Boys:term", or just "Boys" for a single numeric term
est_by <- function(f) {
  by <- svyby(f, ~sex, sub, svymean, na.rm = TRUE)
  al <- svymean(f, sub, na.rm = TRUE)
  terms <- names(coef(al)); cf <- coef(by)
  se <- sqrt(diag(vcov(by))); names(se) <- names(cf)
  key <- function(g) if (length(terms) == 1) g else paste0(g, ":", terms)
  data.frame(term = terms,
             Boys = unname(cf[key("Boys")]), Boys_se = unname(se[key("Boys")]),
             Girls = unname(cf[key("Girls")]), Girls_se = unname(se[key("Girls")]),
             All = unname(coef(al)), All_se = unname(SE(al)))
}

lab <- list(
  finish = "Usually/always works to finish tasks (primary outcome), %",
  calm = "Usually/always stays calm when challenged (secondary outcome), %",
  fam_resilience = "Family resilience count (0-4), mean",
  fam_resilient_all4 = "Resilient family, all 4 items (DRC indicator), %",
  any_activity = "Any organized activity, past 12 months, %",
  adhd_med = "Currently taking ADHD medication, %",
  behav_treat = "Behavioral treatment, past 12 months, %",
  age = "Age in years, mean",
  n_cooccur = "Co-occurring conditions (0-9), mean"
)
pct_vars <- c("finish", "calm", "fam_resilient_all4", "any_activity", "adhd_med", "behav_treat")
mean_vars <- c("fam_resilience", "age", "n_cooccur")
for (v in pct_vars)  add_rows(est_by(as.formula(paste0("~", v))), lab, TRUE)
for (v in mean_vars) add_rows(est_by(as.formula(paste0("~", v))), lab, FALSE)
for (v in c("severity", "race_eth", "parent_educ", "insurance")) {
  e <- est_by(as.formula(paste0("~", v)))
  e$term <- paste0(v, ": ", sub(paste0("^", v), "", e$term))
  add_rows(e, list(), TRUE)
}

# income: six implicates combined with Rubin's rules
imp <- imputationList(lapply(1:6, function(k) { x <- d; x$fpl <- d[[paste0("fpl", k)]]; x }))
mdes <- svydesign(ids = ~HHID, strata = ~strata, weights = ~FWC, nest = TRUE, data = imp)
mdes <- update(mdes, in_analytic = in_adhd_6_17 & !is.na(finish),
               sex = factor(ifelse(girl == 1, "Girls", "Boys")))
msub <- subset(mdes, in_analytic)
inc_by <- MIcombine(with(msub, svyby(~fpl, ~sex, svymean, na.rm = TRUE)))
inc_al <- MIcombine(with(msub, svymean(~fpl, na.rm = TRUE)))
lv <- levels(d$fpl1)
inc <- data.frame(term = paste0("Household income (% FPL, 6 implicates): ", lv),
                  Boys = coef(inc_by)[paste0("Boys:fpl", lv)], Boys_se = SE(inc_by)[paste0("Boys:fpl", lv)],
                  Girls = coef(inc_by)[paste0("Girls:fpl", lv)], Girls_se = SE(inc_by)[paste0("Girls:fpl", lv)],
                  All = coef(inc_al)[paste0("fpl", lv)], All_se = SE(inc_al)[paste0("fpl", lv)])
add_rows(inc, list(), TRUE)

t1 <- do.call(rbind, rows)
hdr <- sprintf("Weighted estimates (95%% CI). Unweighted n: boys %d, girls %d, all %d.",
               nn[["0"]], nn[["1"]], sum(nn))

write.csv(t1, file.path("output", sprintf("table1_%s.csv", year)), row.names = FALSE)
write.csv(miss, file.path("output", sprintf("missingness_%s.csv", year)), row.names = FALSE)
write.csv(flow, file.path("output", sprintf("sample_flow_%s.csv", year)), row.names = FALSE)
md <- c(sprintf("# Table 1 (%s): children aged 6-17 with current ADHD, by sex", year), "", hdr, "",
        "| Characteristic | Boys | Girls | All |", "|---|---|---|---|",
        sprintf("| %s | %s | %s | %s |", t1$characteristic, t1$boys, t1$girls, t1$all))
writeLines(md, file.path("output", sprintf("table1_%s.md", year)))
cat(sprintf("\n[%s] TABLE 1\n%s\n", year, hdr)); print(t1, row.names = FALSE, right = FALSE)
cat(sprintf("\nSaved output/table1_%s.{md,csv}, missingness_%s.csv, sample_flow_%s.csv\n", year, year, year))
