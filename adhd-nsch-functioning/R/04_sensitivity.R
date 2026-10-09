# 04_sensitivity.R
# Sensitivity analyses and replication per ANALYSIS_PLAN.md section 6 (locked
# 2026-10-08), primary outcome only:
#   S1  ordinal model of the original 4-level response (no dichotomizing)
#   S2  + ACE count as a covariate
#   S3  excluding children with an autism diagnosis (K2Q35A = 1)
#   S4  multiple imputation for item nonresponse: only if a model variable is
#       > 5% missing (checked below; Table 1 found none)
#   R1  primary models repeated on the 2025 file (no pooling)
# Same design, complete-case rule, and Rubin's-rules income handling as 03_models.R.
#
# Usage: Rscript R/04_sensitivity.R

suppressPackageStartupMessages({
  library(dplyr)
  library(survey)
  library(mitools)
})
options(survey.lonely.psu = "certainty")

supports <- c("fam_resilience", "any_activity", "adhd_med", "behav_treat")
base_covars <- c("age", "severity", "race_eth", "fpl", "parent_educ", "insurance", "n_cooccur")
int_terms <- paste0("girl:", supports)

load_year <- function(year) {
  d <- readRDS(file.path("data", "derived", sprintf("nsch_%s_analysis.rds", year)))
  # ordinal outcome, higher = better: Never < Sometimes < Usually < Always
  d$finish_ord <- factor(5 - d$finish_raw, levels = 1:4,
                         labels = c("Never", "Sometimes", "Usually", "Always"), ordered = TRUE)
  d
}

fit_spec <- function(d, outcome = "finish", covars = base_covars, keep = TRUE, ordinal = FALSE) {
  rhs1 <- paste(c("girl", supports, covars), collapse = " + ")
  rhs2 <- paste(rhs1, "+", paste(int_terms, collapse = " + "))
  y <- if (ordinal) "finish_ord" else outcome
  cc_vars <- c(y, "girl", supports, setdiff(covars, "fpl"))
  d$in_model <- d$in_adhd_6_17 & keep & complete.cases(d[, cc_vars])
  imp <- imputationList(lapply(1:6, function(k) { x <- d; x$fpl <- d[[paste0("fpl", k)]]; x }))
  des <- subset(svydesign(ids = ~HHID, strata = ~strata, weights = ~FWC, nest = TRUE, data = imp), in_model)
  fit <- function(rhs) {
    f <- as.formula(paste(y, "~", rhs))
    if (ordinal) MIcombine(with(des, svyolr(f))) else MIcombine(with(des, svyglm(f, family = quasibinomial())))
  }
  list(m1 = fit(rhs1), m2 = fit(rhs2), n = sum(d$in_model),
       n_boys = sum(d$in_model & d$girl == 0), n_girls = sum(d$in_model & d$girl == 1))
}

summarise_spec <- function(res, spec) {
  b1 <- coef(res$m1); V1 <- vcov(res$m1); b2 <- coef(res$m2); V2 <- vcov(res$m2)
  row <- function(term, b, se) data.frame(spec = spec, term = term, log_or = b, se = se,
                                          OR = exp(b), OR_low = exp(b - 1.96 * se), OR_high = exp(b + 1.96 * se))
  m1 <- do.call(rbind, lapply(supports, function(s) row(paste0("M1 ", s), b1[[s]], sqrt(V1[s, s]))))
  sx <- do.call(rbind, lapply(supports, function(s) {
    g <- c(s, paste0("girl:", s))
    rbind(row(paste0("M2 boys ", s), b2[[s]], sqrt(V2[s, s])),
          row(paste0("M2 girls ", s), sum(b2[g]), sqrt(sum(V2[g, g]))))
  }))
  it <- do.call(rbind, lapply(int_terms, function(t) row(paste0("M2 ", t), b2[[t]], sqrt(V2[t, t]))))
  bi <- b2[int_terms]; W <- as.numeric(t(bi) %*% solve(V2[int_terms, int_terms]) %*% bi)
  p_ind <- 2 * pnorm(-abs(it$log_or / it$se))
  list(est = rbind(m1, sx, it),
       tests = data.frame(spec = spec, n = res$n, n_boys = res$n_boys, n_girls = res$n_girls,
                          joint_chisq = W, joint_p = pchisq(W, 4, lower.tail = FALSE),
                          min_holm_p = min(p.adjust(p_ind, "holm")),
                          min_holm_term = int_terms[which.min(p.adjust(p_ind, "holm"))]))
}

d24 <- load_year("2024"); d25 <- load_year("2025")

# S4 trigger check (plan: MI only if a model variable is > 5% missing)
mv <- c("finish", "girl", supports, setdiff(base_covars, "fpl"), "ace_count")
a <- d24[d24$in_adhd_6_17, ]
pm <- sapply(mv, function(v) 100 * mean(is.na(a[[v]])))
cat("Percent missing among current ADHD 6-17 (2024):\n"); print(round(pm, 1))
# The 5% rule applies to the primary-model variables (DEVIATIONS.md item 6).
# ace_count enters only sensitivity model S2 and is analyzed complete-case there.
prim_vars <- setdiff(names(pm), "ace_count")
cat(sprintf("S4 multiple imputation triggered (primary-model variables): %s\n",
            if (any(pm[prim_vars] > 5)) "YES" else "no (all <= 5%)"))
cat(sprintf("ace_count (S2 only): %.1f%% missing; complete-case in S2\n\n", pm[["ace_count"]]))

specs <- list(
  "Primary (2024)"             = function() fit_spec(d24),
  "S1 Ordinal outcome (2024)"  = function() fit_spec(d24, ordinal = TRUE),
  "S2 + ACE count (2024)"      = function() fit_spec(d24, covars = c(base_covars, "ace_count")),
  "S3 Excluding autism (2024)" = function() fit_spec(d24, keep = !is.na(d24$autism_ever) & d24$autism_ever == 0),
  "R1 Replication (2025)"      = function() fit_spec(d25)
)
out <- lapply(names(specs), function(s) { cat("fitting:", s, "\n"); summarise_spec(specs[[s]](), s) })
est <- do.call(rbind, lapply(out, `[[`, "est"))
tests <- do.call(rbind, lapply(out, `[[`, "tests"))

# cross-check: the primary spec must reproduce 03_models.R exactly
prim <- read.csv(file.path("output", "models_or_finish_2024.csv"))
chk <- prim$OR[prim$model == "Model 1" & prim$term %in% supports]
mine <- est$OR[est$spec == "Primary (2024)" & est$term %in% paste0("M1 ", supports)]
stopifnot(isTRUE(all.equal(unname(chk), unname(mine), tolerance = 1e-8)))
cat("\nCross-check: primary spec matches 03_models.R output.\n")

# ---- tables ------------------------------------------------------------------------
fmt <- function(e) sprintf("%.2f (%.2f-%.2f)", e$OR, e$OR_low, e$OR_high)
wide <- reshape(data.frame(term = est$term, spec = est$spec, val = fmt(est)),
                idvar = "term", timevar = "spec", direction = "wide")
names(wide) <- sub("^val\\.", "", names(wide))

# direction/size consistency, 2024 primary vs 2025 replication
p24 <- est[est$spec == "Primary (2024)", ]; r25 <- est[est$spec == "R1 Replication (2025)", ]
rep <- data.frame(term = p24$term,
                  OR_2024 = fmt(p24), OR_2025 = fmt(r25),
                  same_direction = ifelse(sign(p24$log_or) == sign(r25$log_or), "yes", "no"),
                  ratio_2025_to_2024 = sprintf("%.2f", r25$OR / p24$OR),
                  ci_2024_excludes_1 = ifelse(p24$OR_low > 1 | p24$OR_high < 1, "yes", "no"),
                  ci_2025_excludes_1 = ifelse(r25$OR_low > 1 | r25$OR_high < 1, "yes", "no"))

write.csv(est, file.path("output", "sensitivity_estimates.csv"), row.names = FALSE)
write.csv(tests, file.path("output", "sensitivity_interaction_tests.csv"), row.names = FALSE)
write.csv(wide, file.path("output", "sensitivity_table.csv"), row.names = FALSE)
write.csv(rep, file.path("output", "replication_2024_vs_2025.csv"), row.names = FALSE)

cat("\nINTERACTION TESTS BY SPECIFICATION\n")
print(transform(tests, joint_chisq = round(joint_chisq, 2), joint_p = round(joint_p, 4),
                min_holm_p = round(min_holm_p, 4)), row.names = FALSE)
cat("\nODDS RATIOS (95% CI) BY SPECIFICATION\n"); print(wide, row.names = FALSE)
cat("\nREPLICATION: 2024 PRIMARY vs 2025\n"); print(rep, row.names = FALSE)
cat("\nSaved output/sensitivity_*.csv and output/replication_2024_vs_2025.csv\n")
