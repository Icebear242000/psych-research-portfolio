"""
Social Support, National Income, and Life Satisfaction
A cross-national panel analysis (World Happiness Report data, 2005-2023)

Question: Is the association between social support and life satisfaction
moderated by national income (log GDP per capita)?

Run from this folder:  python analysis.py
Outputs: results.txt, fig1_support_vs_satisfaction.png, fig2_simple_slopes.png
"""

import numpy as np
import pandas as pd
import statsmodels.formula.api as smf
import matplotlib.pyplot as plt

# ---------------------------------------------------------------
# 1. Load and prepare
# ---------------------------------------------------------------
raw = pd.read_csv("data.csv")
df = raw.rename(columns={
    "Country name": "country",
    "Life Ladder": "life_satisfaction",
    "Log GDP per capita": "log_gdp",
    "Social support": "social_support",
    "Healthy life expectancy at birth": "health",
    "Freedom to make life choices": "freedom",
})

predictors = ["social_support", "log_gdp", "health", "freedom"]
n_raw = len(df)
df = df.dropna(subset=["life_satisfaction"] + predictors).copy()
print(f"Raw country-years: {n_raw} | complete cases: {len(df)} | countries: {df['country'].nunique()}")

# z-score predictors so coefficients = change in life satisfaction (0-10 scale) per 1 SD
for c in predictors:
    df[f"{c}_z"] = (df[c] - df[c].mean()) / df[c].std()

cluster = {"cov_type": "cluster", "cov_kwds": {"groups": df["country"]}}

# ---------------------------------------------------------------
# 2. Models (all with country-clustered standard errors)
# ---------------------------------------------------------------
# M1: main effects + year fixed effects
m1 = smf.ols("life_satisfaction ~ social_support_z + log_gdp_z + health_z + freedom_z + C(year)",
             data=df).fit(**cluster)

# M2: adds the social support x GDP interaction (the moderation test)
m2 = smf.ols("life_satisfaction ~ social_support_z * log_gdp_z + health_z + freedom_z + C(year)",
             data=df).fit(**cluster)

# M3: robustness - adds country fixed effects, so only WITHIN-country change over time
# identifies the effects (removes stable differences between countries)
m3 = smf.ols("life_satisfaction ~ social_support_z * log_gdp_z + health_z + freedom_z + C(year) + C(country)",
             data=df).fit(**cluster)

keep = ["social_support_z", "log_gdp_z", "health_z", "freedom_z", "social_support_z:log_gdp_z"]

def tidy(model, name):
    ci = model.conf_int()
    out = pd.DataFrame({"coef": model.params, "ci_low": ci[0], "ci_high": ci[1], "p": model.pvalues})
    out = out.loc[[k for k in keep if k in out.index]].round(3)
    return f"\n{name}  (N={int(model.nobs)}, R2={model.rsquared:.3f})\n{out.to_string()}\n"

# ---------------------------------------------------------------
# 3. Simple slopes of social support at -1 / 0 / +1 SD of GDP (from M2)
# ---------------------------------------------------------------
slopes = []
for g in (-1, 0, 1):
    t = m2.t_test(f"social_support_z + {g}*social_support_z:log_gdp_z = 0")
    est = float(np.squeeze(t.effect))
    lo, hi = np.squeeze(t.conf_int())
    slopes.append((g, est, lo, hi, float(np.squeeze(t.pvalue))))
slope_df = pd.DataFrame(slopes, columns=["gdp_sd", "slope", "ci_low", "ci_high", "p"]).round(3)

# ---------------------------------------------------------------
# 4. Save results
# ---------------------------------------------------------------
report = (
    f"Complete cases: {len(df)} country-years, {df['country'].nunique()} countries, "
    f"{int(df['year'].min())}-{int(df['year'].max())}\n"
    + tidy(m1, "M1: main effects (+ year FE)")
    + tidy(m2, "M2: + social support x GDP interaction (+ year FE)")
    + tidy(m3, "M3: robustness, + country FE (within-country variation only)")
    + "\nSimple slopes of social support (from M2), by national income level:\n"
    + slope_df.to_string(index=False) + "\n"
)
print(report)
with open("results.txt", "w") as f:
    f.write(report)

# ---------------------------------------------------------------
# 5. Figures
# ---------------------------------------------------------------
df["income_group"] = pd.qcut(df["log_gdp"], 3, labels=["Lower income", "Middle income", "Higher income"])
colors = {"Lower income": "#d62728", "Middle income": "#7f7f7f", "Higher income": "#1f77b4"}

fig, ax = plt.subplots(figsize=(8, 6))
for grp, col in colors.items():
    sub = df[df["income_group"] == grp]
    ax.scatter(sub["social_support"], sub["life_satisfaction"], s=10, alpha=0.35, color=col, label=grp)
    b = np.polyfit(sub["social_support"], sub["life_satisfaction"], 1)
    xs = np.linspace(sub["social_support"].min(), sub["social_support"].max(), 50)
    ax.plot(xs, np.polyval(b, xs), color=col, linewidth=2.5)
ax.set_xlabel("Social support (share of people who have someone to count on)")
ax.set_ylabel("Life satisfaction (0-10 Cantril ladder)")
ax.set_title(f"Social support vs. life satisfaction, by national income\n"
             f"({df['country'].nunique()} countries, {len(df)} country-years)")
ax.legend(title="Log GDP per capita tercile")
fig.tight_layout()
fig.savefig("fig1_support_vs_satisfaction.png", dpi=150)
plt.close(fig)

fig, ax = plt.subplots(figsize=(6.5, 4.5))
ax.errorbar(slope_df["gdp_sd"], slope_df["slope"],
            yerr=[slope_df["slope"] - slope_df["ci_low"], slope_df["ci_high"] - slope_df["slope"]],
            fmt="o-", capsize=5, color="#1f77b4")
ax.set_xticks([-1, 0, 1])
ax.set_xticklabels(["-1 SD\n(lower income)", "Mean", "+1 SD\n(higher income)"])
ax.set_ylabel("Effect of +1 SD social support\non life satisfaction (points)")
ax.set_title("Simple slopes with 95% CIs (M2)")
ax.axhline(0, color="black", linewidth=0.5)
fig.tight_layout()
fig.savefig("fig2_simple_slopes.png", dpi=150)
plt.close(fig)
print("Saved results.txt, fig1_support_vs_satisfaction.png, fig2_simple_slopes.png")
