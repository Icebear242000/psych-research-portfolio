# Behavioral Data Science Portfolio

Two quantitative research projects on psychological well-being and human behavior,
built by **Shree Pallavi Vegesana** (B.Tech Computer Science, M.S. Data Analytics) while
moving from data analytics into psychological science.

Both projects use publicly available data, report uncertainty, and state their
limitations alongside their results.

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

## Running the code

```
pip install -r requirements.txt
cd social-support-wellbeing && python analysis.py
cd ../ai-cognitive-offloading-stackoverflow && python analysis.py
```

## Contact

shreepallavivegesana@gmail.com | linkedin.com/in/shreepallavi-vegesana
