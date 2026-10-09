# Deviations and Unspecified Details

Plan locked 2026-10-08 (commit `1ce5acc`). Everything below is logged with its reason.
Items marked "unspecified detail" fill a gap the plan left open; they were written
here before the corresponding model was run.

| # | Stage | Type | What | Reason |
|---|---|---|---|---|
| 1 | 3 | Pre-specified rule applied | NH Asian collapsed into "NH other/multiracial" in both years. | Plan section 3 rule: collapse if fewer than 50 girls. 2024 analytic sample has 40 NH Asian girls. Same categories used for 2025 for comparability. |
| 2 | 4 | Unspecified detail | "Low vs high" family resilience for predicted probabilities = count of 2 vs 4. Binary supports use 0 vs 1. | Plan does not define low/high for the 0-4 count. The weighted mean is 3.57, so 0-1 would extrapolate into a sparse region. Chosen before Model 2 was run. |
| 3 | 4 | Unspecified detail | Joint test of the four interactions across the six income implicates: Wald chi-square (4 df) on the Rubin's-rules combined coefficients and covariance. | The plan specifies a joint Wald test and Rubin's rules but not how to combine them. This is the standard multivariate Wald on combined estimates. |
| 4 | 4 | Unspecified detail | Confidence intervals for weighted predicted probabilities from 2,000 draws of the combined coefficient distribution (multivariate normal), averaging predictions over the six implicates. | The plan asks for predicted probabilities but not their uncertainty method. Covariate values are held at observed values, so the intervals reflect coefficient uncertainty only. |
| 5 | 4 | Unspecified detail | Odds-ratio CIs use a normal approximation (estimate +/- 1.96 SE on the log-odds scale). | Design degrees of freedom are in the thousands, so t and normal intervals are indistinguishable. |
| 6 | 5 | Interpretation of an ambiguous rule | The ">5% missing triggers multiple imputation" rule (plan section 5) is applied to the primary-model variables only. All are at or below 5% (highest: co-occurring conditions 4.6%), so MI is not run. The ACE count (6.1% missing) is used only in sensitivity model S2, where it is analyzed complete-case: S2 n = 5,251 vs 5,442 in the primary model. | The plan says "any model variable" without specifying whether sensitivity-only covariates count. Decided by the author on 2026-10-08. Disclosure: the decision was made after all Stage 5 output, including the S2 complete-case estimates, had been printed. The S2 estimates are reported in full either way. |
| 7 | 5 | Unspecified detail | S3 (excluding autism) also excludes children whose autism status (`K2Q35A`) is missing. | Their exclusion status cannot be determined. |
