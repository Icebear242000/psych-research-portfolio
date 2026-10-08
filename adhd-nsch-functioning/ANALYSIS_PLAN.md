# Analysis Plan: Supports and Day-to-Day Functioning Among Children With ADHD, by Sex

**Author:** Shree Pallavi Vegesana
**Data:** National Survey of Children's Health (NSCH), 2024 public-use file (replication on 2025)
**Status:** LOCKED. Variable names and response options were confirmed against the 2024 Topical Variable List and the data (see `output/variable_map.md`). No outcome distributions or associations were examined before locking.
**Date locked:** 2026-10-08 (the Git commit of this file is the timestamp)

## 1. Question

Among U.S. children with a parent-reported current ADHD diagnosis, which supports (family, activities, treatment) are associated with better day-to-day functioning, and do those associations differ for girls and boys?

Why it matters: ADHD in girls was historically under-recognized, and most research on supports looks at boys or at mixed samples. A strengths-based question asks what goes *with* better functioning, not only what goes wrong.

## 2. Data and sample

- NSCH 2024 topical public-use file (parent-reported; administered by the U.S. Census Bureau for HRSA). In 2024 about 44,600 children aged 3-17 had a response to the current-ADHD question.
- **Inclusion:** current ADHD: `K2Q31A = 1` (doctor or provider ever told parent) and `K2Q31B = 1` (currently has it); age 6-17 (`SC_AGE_YEARS`), which is exactly the age range of forms T2/T3 on which the functioning items are asked.
- **Exclusion:** missing the primary outcome.
- Analytic subpopulation before outcome missingness: n = 6,068 in 2024 (3,780 boys, 2,288 girls); n = 5,335 in 2025. Final n after exclusions will be reported before modeling.

## 3. Measures

| Role | Construct | Variable(s) and coding |
|---|---|---|
| Primary outcome | Finishes tasks they start | `K7Q84_R` ("Work to finish tasks they start?"). 1 = Always/Usually (codes 1-2); 0 = Sometimes/Never (codes 3-4). |
| Secondary outcome (exploratory) | Stays calm when challenged | `K7Q85_R`, same dichotomy. Run with the Model 1/Model 2 specification only. |
| Moderator | Child sex | `SC_SEX`: 1 = Male, 2 = Female (coded girl = 1). |
| Support 1 | Family connection | Family resilience count, 0-4: number of `TALKABOUT`, `WKTOSOLVE`, `STRENGTHS`, `HOPEFUL` answered "all of the time" or "most of the time" (codes 1-2), following the Data Resource Center for Child and Adolescent Health item coding. Entered as continuous. Table 1 also reports the DRC yes/no indicator (all four met). |
| Support 2 | Activities and community | Any organized activity in the past 12 months: 1 if yes to any of `K7Q30` (sports), `K7Q31` (clubs/organizations), `K7Q32` (other organized activities or lessons); 0 if no to all three. `K7Q37` and `K9Q96` are not used. |
| Support 3a | Treatment: medication | `K2Q31D`: currently taking ADHD medication (1 = Yes, 2 = No). |
| Support 3b | Treatment: behavioral | `ADDTREAT`: behavioral treatment for ADHD in past 12 months (1 = Yes, 2 = No). |
| Covariate | Age | `SC_AGE_YEARS`, continuous. |
| Covariate | ADHD severity | `K2Q31C`: mild / moderate / severe. |
| Covariate | Race/ethnicity | `SC_HISPANIC_R` + `SC_RACE_R`: Hispanic; non-Hispanic White; non-Hispanic Black; non-Hispanic Asian; non-Hispanic other or multiracial. A category is collapsed into "other" only if it has fewer than 50 girls in the analytic sample, decided from Table 1 before outcome models. |
| Covariate | Household income | `FPL_I1`-`FPL_I6` (six implicates): <100%, 100-199%, 200-399%, 400%+ of the federal poverty level. |
| Covariate | Parent education | `HIGRADE_TVIS`: less than high school; high school; some college/associate; college degree or higher. |
| Covariate | Insurance type | `INSTYPE`: public only; private only; private and public; uninsured. |
| Covariate | Co-occurring conditions | Count (0-9) of current: learning disability `K2Q30B`, depression `K2Q32B`, anxiety `K2Q33B`, behavior problems `K2Q34B`, autism `K2Q35B`, developmental delay `K2Q36B`, speech disorder `K2Q37B`, Tourette syndrome `K2Q38B`, intellectual disability `K2Q60B`. |

The cutpoint for the primary outcome is fixed now, before looking at its distribution.

## 4. Hypotheses

- **H1a (confirmatory):** Higher family connection is associated with higher odds of usually/always finishing tasks.
- **H1b (confirmatory):** Greater activity/community support is associated with higher odds of the same.
- **H1c (descriptive):** Treatment associations are reported without a predicted direction. Children with greater difficulties are more likely to be treated (confounding by indication), so a null or negative association would not be surprising.
- **H2 (confirmatory, two-sided):** The associations in H1 differ by sex (sex x support interactions). I make no directional prediction, because I don't have a theoretically grounded one.

## 5. Analysis

1. **Design-based inference.** Per the NSCH Analytic Guide: weight `FWC`; strata = `FIPSST` crossed with `STRATUM`; PSU = `HHID`; Taylor-series linearization; single-PSU strata treated as certainty units. Analyze the ADHD group as a **subpopulation of the full design** (subset the design object, don't drop rows first).
2. **Table 1:** weighted descriptives by sex, with missingness per variable.
3. **Model 1:** weighted logistic regression, main effects of sex, the supports (family resilience, organized activity, medication, behavioral treatment), and covariates. **Model 2:** adds the four sex x support terms. Test the four interaction terms jointly (Wald), then individually with Holm correction across the four. (Treatment is entered as two terms, medication and behavioral treatment, so Model 2 has four interactions rather than three.)
4. **Report** odds ratios with 95% CIs and weighted predicted probabilities (marginal effects), because odds ratios alone are hard to interpret.
5. **Missing data:** complete-case primary for item nonresponse. If any model variable has more than 5% missing, add multiple imputation as a sensitivity analysis. Household income is already multiply imputed by the Census Bureau: every model is fit once per FPL implicate (1-6) and results are combined with Rubin's rules (`mitools::MIcombine`), following the NSCH guide to analysis with imputed data.
6. **Software:** R (`survey`/`srvyr`). Python's statsmodels does not provide design-based variance for complex surveys.

## 6. Sensitivity and replication

- Ordinal model of the original frequency response (no dichotomizing).
- Add ACEs as a covariate (it may be a confounder or lie on the causal path, so it is not in the primary model). ACE count, 0-10: `ACE3`-`ACE11` each 1 if Yes, plus `ACE1` = 1 if "somewhat often" or "very often" (there is no `ACE2` in the public file).
- Exclude children with a co-occurring autism diagnosis (`K2Q35A = 1`).
- Repeat the primary models on the 2025 file and report whether direction and size hold. No formal pooling.
  (Pre-lock change, 2026-10-08: the draft named 2023. The 2025 file was released before this plan was locked, and replicating in data collected after the main year is the stronger test. Changed before any outcome data were examined.)
- Any deviation from this plan will be labeled as a deviation.

## 7. Limitations to state in the write-up

- Parent-reported and cross-sectional: no causal claims. Use "associated with," never "improves."
- Reverse causation: struggling children may receive more supports.
- **Selection:** girls have been under-diagnosed, so diagnosed girls may be systematically different from diagnosed boys. A sex difference here is not necessarily a sex difference in ADHD.
- Population inference is to U.S. children with a parent-reported diagnosis, not to children with ADHD overall.
- The data are about children. They cannot speak to adults with ADHD.

## 8. Ethics and reporting

De-identified public data; no re-identification attempts; cite the NSCH as the data provider requests. Reporting follows STROBE for cross-sectional studies.

## 9. Workflow

0. Download the 2024 and 2025 topical Stata files, variable lists, and the 2024 methodology report.
1. Build the variable map, finalize this plan, commit it to Git. *This timestamp is the point of the plan.*
2. Clean data and produce Table 1.
3. Run Models 1 and 2, then sensitivity and replication.
4. Write the README with results, figures, and limitations.
