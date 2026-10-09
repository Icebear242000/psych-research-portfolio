# 03_models.R
# Main models per ANALYSIS_PLAN.md section 5 (locked 2026-10-08).
#   Model 1: weighted logistic regression, sex + four supports + covariates.
#   Model 2: Model 1 + four sex x support interactions.
#   Joint Wald test of the interactions, then individual tests with Holm correction.
#   Odds ratios (95% CI), sex-specific support ORs, and weighted predicted
#   probabilities by sex at low vs high support.
# Each model is fit once per income implicate (FPL_I1-I6) and combined with
# Rubin's rules. Complete-case for item nonresponse. Unspecified details are
# logged in DEVIATIONS.md (items 2-5).
#
# Usage: Rscript R/03_models.R [year] [outcome]   (defaults: 2024 finish)

suppressPackageStartupMessages({
  library(dplyr)
  library(survey)
  library(mitools)
  library(ggplot2)
})
options(survey.lonely.psu = "certainty")
set.seed(20261008)

args <- commandArgs(trailingOnly = TRUE)
year <- if (length(args) >= 1) args[1] else "2024"
outcome <- if (length(args) >= 2) args[2] else "finish"
stopifnot(outcome %in% c("finish", "calm"))
tag <- sprintf("%s_%s", outcome, year)
d <- readRDS(file.path("data", "derived", sprintf("nsch_%s_analysis.rds", year)))

supports <- c("fam_resilience", "any_activity", "adhd_med", "behav_treat")
covars <- c("age", "severity", "race_eth", "fpl", "parent_educ", "insurance", "n_cooccur")
rhs1 <- paste(c("girl", supports, covars), collapse = " + ")
rhs2 <- paste(rhs1, "+", paste0("girl:", supports, collapse = " + "))
f1 <- as.formula(paste(outcome, "~", rhs1))
f2 <- as.formula(paste(outcome, "~", rhs2))

# complete-case flag on the full file (income is never missing: it is imputed)
cc_vars <- c(outcome, "girl", supports, setdiff(covars, "fpl"))
d$in_model <- d$in_adhd_6_17 & complete.cases(d[, cc_vars])
cat(sprintf("[%s] model sample: n = %d (boys %d, girls %d)\n", tag, sum(d$in_model),
            sum(d$in_model & d$girl == 0), sum(d$in_model & d$girl == 1)))

imp <- imputationList(lapply(1:6, function(k) { x <- d; x$fpl <- d[[paste0("fpl", k)]]; x }))
mdes <- svydesign(ids = ~HHID, strata = ~strata, weights = ~FWC, nest = TRUE, data = imp)
msub <- subset(mdes, in_model)

fit1 <- with(msub, svyglm(f1, family = quasibinomial()))
fit2 <- with(msub, svyglm(f2, family = quasibinomial()))
m1 <- MIcombine(fit1); m2 <- MIcombine(fit2)

or_table <- function(m, model) {
  b <- coef(m); se <- sqrt(diag(vcov(m)))
  data.frame(model = model, term = names(b), log_odds = b, se = se,
             OR = exp(b), OR_low = exp(b - 1.96 * se), OR_high = exp(b + 1.96 * se),
             p = 2 * pnorm(-abs(b / se)), row.names = NULL)
}
ors <- rbind(or_table(m1, "Model 1"), or_table(m2, "Model 2"))

# ---- interaction tests ---------------------------------------------------------
int_terms <- paste0("girl:", supports)
b <- coef(m2)[int_terms]; V <- vcov(m2)[int_terms, int_terms]
W <- as.numeric(t(b) %*% solve(V) %*% b)
joint <- data.frame(test = "Joint Wald, 4 sex x support interactions", chisq = W, df = 4,
                    p = pchisq(W, 4, lower.tail = FALSE))
ind <- ors[ors$model == "Model 2" & ors$term %in% int_terms, c("term", "OR", "OR_low", "OR_high", "p")]
ind$p_holm <- p.adjust(ind$p, method = "holm")

# ---- sex-specific support ORs from Model 2 ------------------------------------
sex_or <- do.call(rbind, lapply(supports, function(s) {
  cf <- coef(m2); V2 <- vcov(m2)
  g <- c(s, paste0("girl:", s))
  boys_b <- cf[s]; boys_se <- sqrt(V2[s, s])
  girls_b <- sum(cf[g]); girls_se <- sqrt(sum(V2[g, g]))
  data.frame(support = s, sex = c("Boys", "Girls"), log_odds = c(boys_b, girls_b),
             se = c(boys_se, girls_se), row.names = NULL)
}))
sex_or <- sex_or |> mutate(OR = exp(log_odds), OR_low = exp(log_odds - 1.96 * se),
                           OR_high = exp(log_odds + 1.96 * se))

# ---- weighted predicted probabilities (Model 2) --------------------------------
levels_lo_hi <- list(fam_resilience = c(2, 4), any_activity = c(0, 1),
                     adhd_med = c(0, 1), behav_treat = c(0, 1))
draws <- MASS::mvrnorm(2000, coef(m2), vcov(m2))
tt <- delete.response(terms(f2))
base_sets <- lapply(imp$imputations, function(x) x[x$in_model, ])
pp <- do.call(rbind, lapply(names(levels_lo_hi), function(s) {
  do.call(rbind, lapply(c(0, 1), function(g) {
    do.call(rbind, lapply(seq_along(levels_lo_hi[[s]]), function(j) {
      val <- levels_lo_hi[[s]][j]
      # average predicted probability over the analytic sample, averaged over implicates
      app_draws <- rowMeans(sapply(base_sets, function(x) {
        x$girl <- g; x[[s]] <- val
        fv <- intersect(all.vars(tt), names(x)[sapply(x, is.factor)])
        X <- model.matrix(tt, model.frame(tt, x, xlev = lapply(x[fv], levels)))
        X <- X[, colnames(draws)]
        w <- x$FWC / sum(x$FWC)
        as.numeric(plogis(draws %*% t(X)) %*% w)
      }))
      data.frame(support = s, sex = ifelse(g == 1, "Girls", "Boys"),
                 level = ifelse(j == 1, "low", "high"), value = val,
                 prob = mean(app_draws), prob_low = quantile(app_draws, 0.025),
                 prob_high = quantile(app_draws, 0.975), row.names = NULL)
    }))
  }))
}))

# ---- save ------------------------------------------------------------------------
dir.create("output", showWarnings = FALSE)
write.csv(ors, file.path("output", sprintf("models_or_%s.csv", tag)), row.names = FALSE)
write.csv(rbind(cbind(joint, term = NA, OR = NA, OR_low = NA, OR_high = NA, p_holm = NA)[, c("test","term","OR","OR_low","OR_high","chisq","df","p","p_holm")],
                cbind(test = "Individual interaction", ind[, c("term","OR","OR_low","OR_high")],
                      chisq = NA, df = 1, p = ind$p, p_holm = ind$p_holm)),
          file.path("output", sprintf("interaction_tests_%s.csv", tag)), row.names = FALSE)
write.csv(sex_or, file.path("output", sprintf("sex_specific_or_%s.csv", tag)), row.names = FALSE)
write.csv(pp, file.path("output", sprintf("predicted_probs_%s.csv", tag)), row.names = FALSE)

lab <- c(fam_resilience = "Family resilience (per item, 0-4)", any_activity = "Any organized activity",
         adhd_med = "ADHD medication", behav_treat = "Behavioral treatment")
fp <- sex_or |> mutate(support = factor(lab[support], levels = rev(lab)))
g <- ggplot(fp, aes(x = OR, y = support, colour = sex)) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "grey50") +
  geom_pointrange(aes(xmin = OR_low, xmax = OR_high), position = position_dodge(width = 0.5)) +
  scale_x_log10() + scale_colour_manual(values = c(Boys = "#1f77b4", Girls = "#d6604d")) +
  labs(x = "Odds ratio (log scale), 95% CI", y = NULL, colour = NULL,
       title = sprintf("Supports and %s, by sex (NSCH %s)",
                       if (outcome == "finish") "usually/always finishing tasks" else "usually/always staying calm", year),
       subtitle = "Children aged 6-17 with current ADHD; survey-weighted, adjusted for covariates") +
  theme_minimal(base_size = 11) + theme(legend.position = "top", plot.title.position = "plot")
ggsave(file.path("output", sprintf("forest_%s.png", tag)), g, width = 8, height = 4.2, dpi = 150)

# ---- print (numbers only) ------------------------------------------------------
fmt <- function(x, d = 2) formatC(x, format = "f", digits = d)
cat(sprintf("\n[%s] MODEL 1 and MODEL 2: odds ratios (95%% CI), supports and sex\n", tag))
show <- ors[ors$term %in% c("girl", supports, int_terms), ]
print(data.frame(model = show$model, term = show$term,
                 OR = paste0(fmt(show$OR), " (", fmt(show$OR_low), "-", fmt(show$OR_high), ")"),
                 p = fmt(show$p, 4)), row.names = FALSE)
cat(sprintf("\n[%s] JOINT TEST: chi-square = %.2f, df = 4, p = %.4f\n", tag, W, joint$p))
cat(sprintf("\n[%s] INDIVIDUAL INTERACTIONS (Holm-adjusted)\n", tag))
print(data.frame(term = ind$term, OR = paste0(fmt(ind$OR), " (", fmt(ind$OR_low), "-", fmt(ind$OR_high), ")"),
                 p = fmt(ind$p, 4), p_holm = fmt(ind$p_holm, 4)), row.names = FALSE)
cat(sprintf("\n[%s] SEX-SPECIFIC SUPPORT ORs (Model 2)\n", tag))
print(data.frame(support = sex_or$support, sex = sex_or$sex,
                 OR = paste0(fmt(sex_or$OR), " (", fmt(sex_or$OR_low), "-", fmt(sex_or$OR_high), ")")), row.names = FALSE)
cat(sprintf("\n[%s] WEIGHTED PREDICTED PROBABILITIES (Model 2), %%\n", tag))
print(data.frame(support = pp$support, sex = pp$sex, level = paste0(pp$level, " (", pp$value, ")"),
                 prob = paste0(fmt(100 * pp$prob, 1), " (", fmt(100 * pp$prob_low, 1), "-", fmt(100 * pp$prob_high, 1), ")")),
      row.names = FALSE)
cat(sprintf("\nSaved output/*_%s.csv and output/forest_%s.png\n", tag, tag))
