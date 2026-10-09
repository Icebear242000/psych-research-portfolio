# Behavioral Data Science Portfolio

Three quantitative research projects on psychological well-being and human behavior,
built by **Shree Pallavi Vegesana** (B.Tech Computer Science, M.S. Data Analytics) while
moving from data analytics into psychological science.

All three use publicly available data, report uncertainty, and state their limitations
alongside their results.

## Projects

### 1. [Social Support, National Income, and Life Satisfaction](./social-support-wellbeing)
Panel regression on 158 countries (2,241 country-years, 2005-2023) from the World
Happiness Report. Social support is associated with higher life satisfaction at every
income level, and the association is **stronger in higher-income countries**, which runs
against a simple "buffering" hypothesis. The interaction persists, but shrinks, once
country fixed effects are added.
*Python (statsmodels), cluster-robust inference, moderation analysis.*

### 2. [AI and Help-Seeking: Stack Overflow's Decline After ChatGPT](./ai-cognitive-offloading-stackoverflow)
Interrupted time series on 215 months of Stack Overflow question volume. After ChatGPT's
launch, volume fell about **9% per month faster** than the pre-launch trend, a result
that holds across four specifications. Framed as behavioral evidence relevant to
cognitive offloading, with explicit discussion of what it cannot show.
*Python (statsmodels), interrupted time series, HAC standard errors.*

### 3. [Supports and Day-to-Day Functioning in Children With ADHD, by Sex](./adhd-nsch-functioning)
Pre-registered analysis of the National Survey of Children's Health (6,000 children aged
6-17 with ADHD, 2024), replicated on 2025 data. Family resilience was associated with
higher odds of usually finishing tasks (**OR 1.42** in 2024, **1.33** in 2025) for both
girls and boys. Associations with activities and treatment did not replicate, and no
support differed reliably by sex.
*R (survey, mitools), complex survey design, multiply imputed income, pre-registered
analysis plan.*

## Running the code

Projects 1 and 2 (Python):

```
pip install -r requirements.txt
cd social-support-wellbeing && python analysis.py
cd ../ai-cognitive-offloading-stackoverflow && python analysis.py
```

Project 3 (R) needs the NSCH data files from census.gov; see
[its README](./adhd-nsch-functioning#reproduce).

## Contact

shreepallavivegesana@gmail.com | linkedin.com/in/shreepallavi-vegesana
