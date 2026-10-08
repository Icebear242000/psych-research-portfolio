# Variable Map (Stage 1)

Built 2026-10-08 from the 2024 NSCH Topical Variable List (dated 10/06/2025), the 2024
NSCH Methodology Report, the NSCH Analytic Guide, and the 2024 and 2025 topical Stata
files (`nsch_2024e_topical.dta`, `nsch_2025e_topical.dta`). Every name, label, and
response option below was read from the codebook and checked against the codes
actually present in the data. No outcome distributions or associations were examined.

## 1. Sanity checks

| Check | Expected | 2024 | 2025 |
|---|---|---|---|
| Children aged 3-17 with a determinable current-ADHD status | about 44,600 | **44,606** | 39,199 |
| Weighted % current ADHD, ages 3-17 (FWC weight) | 11.7% (CDC) | **11.7%** | 11.5% |
| Analytic subpopulation: current ADHD, ages 6-17 (before outcome missingness) | a few thousand | **6,068** (boys 3,780, girls 2,288) | 5,335 (boys 3,366, girls 1,969) |

Current ADHD = `K2Q31A = 1` and `K2Q31B = 1`. Not current = `K2Q31A = 2`, or
`K2Q31A = 1` and `K2Q31B = 2`. Children missing `K2Q31A`, or with `K2Q31A = 1` and
`K2Q31B` missing, are undetermined (413 in 2024). Total file size: 51,375 children
(2024) and 45,139 (2025). `SC_SEX` has no missing values in the analytic group in either year.

**2025 comparability:** every variable below has an identical label, question wording,
and response options in the 2025 codebook, and the same codes in the data.

## 2. Survey design (Analytic Guide)

| Element | Variable | Notes |
|---|---|---|
| Weight | `FWC` | Selected Child Weight. All values > 0. |
| Strata | `FIPSST` x `STRATUM` | Guide: "strata (state=fipsst, stratum=stratum)". `STRATUM` values `1`, `2A` (string). Cross them into one strata variable. |
| PSU | `HHID` | One sampled child per household. |
| Variance | Taylor series linearization | Guide's Stata example: `singleunit(certainty)`; R equivalent: `options(survey.lonely.psu = "certainty")`. |
| Subpopulation | Subset the design object | Guide: BY/WHERE subsetting "will not provide appropriate variance estimation". |

## 3. Sample definition

| Item | Variable | Codebook text | Codes |
|---|---|---|---|
| Ever ADHD | `K2Q31A` | Has a doctor or other health care provider EVER told you that this child has ADD or ADHD? | 1 = Yes, 2 = No |
| Current ADHD | `K2Q31B` | If yes, does this child CURRENTLY have the condition? | 1 = Yes, 2 = No (skip if K2Q31A = 2) |
| Age | `SC_AGE_YEARS` | How old is this child? | 0-17 |
| Form type | `FORMTYPE` | Operational | T1 = ages 0-5, T2 = 6-11, T3 = 12-17 (verified in data) |

**Age range confirmed as 6-17:** the outcome items are asked only on forms T2 and T3,
which cover ages 6-17 exactly.

## 4. Outcomes

| Role | Variable | Codebook text | Codes | Planned coding |
|---|---|---|---|---|
| **Primary** | `K7Q84_R` | How often does this child work to finish tasks they start? | 1 = Always, 2 = Usually, 3 = Sometimes, 4 = Never | 1 = Always/Usually (1-2); 0 = Sometimes/Never (3-4). Fixed in plan before viewing. |
| Secondary | `K7Q85_R` | ...stay calm and in control when faced with a challenge? | same 4 options | same dichotomy |
| Secondary | `K7Q82_R` | ...care about doing well in school? | same 4 options | same dichotomy |
| Secondary | `K7Q83_R` | ...do all required homework? | same 4 options | same dichotomy |

Note: the plan's "missed school days" option was not mapped; the two school-engagement
items above are the closest flourishing-section items. Which secondary outcomes to keep
is decision D6.

## 5. Moderator

| Variable | Codebook text | Codes |
|---|---|---|
| `SC_SEX` | What is this child's sex? | 1 = Male, 2 = Female |

## 6. Supports (candidate items; final choice is decision D1-D3)

### Support 1: Family connection

| Variable | Codebook text | Codes | Forms |
|---|---|---|---|
| `K8Q21` | How well can you and this child share ideas or talk about things that really matter? | 1 = Very well, 2 = Somewhat well, 3 = Not very well, 4 = Not well at all | T2, T3 |
| `TALKABOUT` | When your family faces problems, how often: talk together about what to do | 1 = All, 2 = Most, 3 = Some, 4 = None of the time | all |
| `WKTOSOLVE` | ...work together to solve our problems | same | all |
| `STRENGTHS` | ...know we have strengths to draw on | same | all |
| `HOPEFUL` | ...stay hopeful even in difficult times | same | all |

**Not found:** the plan says "a pre-built score". The Census public-use file has **no
pre-built family resilience or connection score**; the four "facing problems" items are
provided separately. A score has to be constructed (D1).

### Support 2: Activities and community

| Variable | Codebook text | Codes | Forms |
|---|---|---|---|
| `K7Q30` | Past 12 months: sports team or sports lessons | 1 = Yes, 2 = No | T2, T3 |
| `K7Q31` | Past 12 months: clubs or organizations | 1 = Yes, 2 = No | T2, T3 |
| `K7Q32` | Past 12 months: other organized activities or lessons (music, dance, language, arts) | 1 = Yes, 2 = No | T2, T3 |
| `K7Q37` | Past 12 months: community service or volunteer work | 1 = Yes, 2 = No | T2, T3 |
| `K9Q96` | At least one other adult in school, neighborhood, or community who knows this child well and who they can rely on for advice or guidance | 1 = Yes, 2 = No | T2, T3 |
| `K10Q30` | People in this neighborhood help each other out | 1 = Definitely agree ... 4 = Definitely disagree | all |
| `K10Q31` | We watch out for each other's children in this neighborhood | same | all |

### Support 3: Treatment

| Variable | Codebook text | Codes |
|---|---|---|
| `K2Q31D` | Is this child CURRENTLY taking medication for ADD or ADHD? | 1 = Yes, 2 = No |
| `ADDTREAT` | Past 12 months: behavioral treatment for ADD or ADHD, such as training or an intervention to help with behavior | 1 = Yes, 2 = No |
| `K4Q22_R` | Past 12 months: treatment or counseling from a mental health professional | 1 = Yes, 2 = No but needed, 3 = No, did not need |
| `K4Q23` | Past 12 months: medication for difficulties with emotions, concentration, or behavior | 1 = Yes, 2 = No |

`K2Q31D` and `ADDTREAT` are the ADHD-specific items and match the plan; `K4Q22_R` and
`K4Q23` are listed for completeness only.

## 7. Covariates

| Construct | Variable | Codes | Planned coding |
|---|---|---|---|
| Age | `SC_AGE_YEARS` | 6-17 | continuous |
| ADHD severity | `K2Q31C` | 1 = Mild, 2 = Moderate, 3 = Severe | 3 categories |
| Race/ethnicity | `SC_HISPANIC_R` + `SC_RACE_R` | Hispanic: 1 = Yes, 2 = No. Race: 1 White, 2 Black, 3 AIAN, 4 Asian, 5 NHPI, 7 Two or more | Hispanic; NH White; NH Black; NH Asian; NH other/multiracial (D5) |
| Household income | `FPL_I1`-`FPL_I6` | family poverty ratio, 50-400 (% FPL), **multiply imputed, six implicates** | D4 |
| Parent education | `HIGRADE_TVIS` | 1 < HS, 2 HS, 3 Some college/Associate, 4 College degree+ | 4 categories |
| Insurance type | `INSTYPE` | 1 Public only, 2 Private only, 3 Private and public, 5 Not insured | 4 categories |
| Co-occurring conditions | see below | each 1 = Yes, 2 = No | count (D7) |

Candidate co-occurring conditions ("currently has"): `K2Q30B` learning disability,
`K2Q32B` depression, `K2Q33B` anxiety, `K2Q34B` behavior problems, `K2Q35B` autism,
`K2Q36B` developmental delay, `K2Q37B` speech disorder, `K2Q38B` Tourette syndrome,
`K2Q60B` intellectual disability. Physical conditions (asthma `K2Q40B`, epilepsy
`K2Q42B`, and others) also exist.

## 8. Sensitivity-analysis variables

| Use | Variable(s) | Codes |
|---|---|---|
| Exclude autism | `K2Q35A` (ever told) | 1 = Yes, 2 = No |
| ACEs covariate | `ACE1` hard to cover basics (1 Never, 2 Rarely, 3 Somewhat often, 4 Very often); `ACE3` divorced/separated; `ACE4` parent died; `ACE5` parent jailed; `ACE6` household violence; `ACE7` victim/witness of violence; `ACE8` lived with mentally ill person; `ACE9` lived with alcohol/drug problem; `ACE10` treated unfairly because of race; `ACE11` treated unfairly because of health condition | ACE3-ACE11: 1 = Yes, 2 = No |

There is no `ACE2` in the public file. An ACE count has to be constructed (D8).

## 9. Missingness in the analytic group (non-outcome variables, 2024, unweighted)

All under 5%, so multiple imputation for item missingness is **not triggered** by these
variables (outcome missingness to be reported in Stage 3):
`K2Q31C` 0.6%, `K2Q31D` 0.4%, `ADDTREAT` 0.1%, `K8Q21` 1.4%, family resilience items
2.6-2.9%, activity items 1.1-1.5%, `K9Q96` 2.6%, `INSTYPE` 1.4%, FPL / race / ethnicity /
education 0%.

## 10. Decisions needed before locking the plan

| # | Decision | Options | Suggested |
|---|---|---|---|
| D1 | Family connection score | (a) 4 resilience items, count answered "all/most of the time" (0-4); (b) `K8Q21` alone; (c) both as separate supports | (a) as Support 1; it covers all ages and is the closest to a "pre-built" construct |
| D2 | Activities/community measure | (a) any organized activity (`K7Q30`/`31`/`32`, yes to any); (b) count 0-4 incl. `K7Q37`; (c) add mentor `K9Q96` | (a); mentor `K9Q96` fits the plan's "adult support" wording but mixes two ideas into one score, so it is your call whether to include it |
| D3 | Treatment | (a) medication and behavioral treatment as two separate terms (4 interactions in Model 2); (b) one 4-level variable (none / meds only / behavioral only / both) | (a) keeps them interpretable, but changes the plan's "three interactions" to four |
| D4 | Income with six FPL implicates | (a) fit models on each implicate and combine with Rubin's rules (Census guidance); (b) use `FPL_I1` only | (a) |
| D5 | Race/ethnicity categories | 5 categories above, or collapse further if cells are small among girls | 5 categories, collapse only if a cell has fewer than ~50 girls |
| D6 | Secondary outcomes | `K7Q85_R` stays calm; `K7Q82_R` cares about school; `K7Q83_R` homework | `K7Q85_R` only, to limit multiple testing |
| D7 | Co-occurring conditions | (a) the 9 mental/developmental conditions above; (b) also physical conditions | (a) |
| D8 | ACE count | `ACE3`-`ACE11` yes = 1, plus `ACE1` "somewhat/very often" = 1 (0-10) | as stated |
