"""
AI Cognitive Offloading: Evidence from Stack Overflow's Post-ChatGPT Decline
Interrupted time series analysis of monthly Stack Overflow question volume.

Run from this folder:  python analysis.py
Outputs: results.txt, fig1_raw_series.png, fig2_counterfactual_log.png

Design notes
- ChatGPT launched 30 Nov 2022, so December 2022 is the first full "post" month.
- Outcome is log(monthly questions): effects read as % change per month.
- Month-of-year dummies absorb seasonality (e.g., March peaks, December dips).
- HAC (Newey-West) standard errors, 12 lags, handle autocorrelation.
- Primary specification uses a LOCAL pre-period (Jan 2017 onward). A single straight
  line through 2008-2022 mixes the site's growth years with its decline years and is
  a poor stand-in for the trend immediately before ChatGPT. The full-history version
  is reported as a sensitivity check, not hidden.
- The final month (May 2026) may be a partial month in the source, so a spec that
  drops it is also reported.
"""

import numpy as np
import pandas as pd
import statsmodels.formula.api as smf
import matplotlib.pyplot as plt

df = pd.read_csv("data.csv")
df["date"] = pd.to_datetime(dict(year=df.year, month=df.month, day=1))
df = df.sort_values("date").reset_index(drop=True)
df["log_q"] = np.log(df["num_questions"])
df["moy"] = df["date"].dt.month

BREAK = pd.Timestamp("2022-12-01")


def fit_its(data, label):
    d = data.copy().reset_index(drop=True)
    d["t"] = np.arange(len(d))
    d["post"] = (d["date"] >= BREAK).astype(int)
    d["t_post"] = (d["t"] - d.loc[d["post"] == 1, "t"].min()) * d["post"]
    m = smf.ols("log_q ~ t + post + t_post + C(moy)", data=d).fit(
        cov_type="HAC", cov_kwds={"maxlags": 12})
    b = m.params
    ci = m.conf_int()
    pct = lambda x: (np.exp(x) - 1) * 100
    return {
        "label": label, "n": len(d), "model": m, "data": d,
        "pre_trend_pct": pct(b["t"]),
        "extra_post_trend_pct": pct(b["t_post"]),
        "extra_post_ci": (pct(ci.loc["t_post", 0]), pct(ci.loc["t_post", 1])),
        "net_post_trend_pct": pct(b["t"] + b["t_post"]),
        "level_shift_pct": pct(b["post"]),
        "p_slope_change": m.pvalues["t_post"],
    }


specs = [
    fit_its(df, "A. Full history (Jul 2008 - May 2026)"),
    fit_its(df[df["date"] >= "2017-01-01"], "B. PRIMARY: local pre-period (Jan 2017 - May 2026)"),
    fit_its(df[(df["date"] >= "2017-01-01") & (df["date"] < "2026-05-01")],
            "C. As B, dropping possibly-partial May 2026"),
    fit_its(df[(df["date"] >= "2019-01-01") & (df["date"] < "2026-05-01")],
            "D. As C, shorter pre-period (Jan 2019 start)"),
]

lines = ["Interrupted time series: slope change at ChatGPT launch (first post month: Dec 2022)\n"]
for s in specs:
    lo, hi = s["extra_post_ci"]
    lines.append(
        f"{s['label']}  (n={s['n']} months)\n"
        f"  pre-launch trend:            {s['pre_trend_pct']:+.2f}% per month\n"
        f"  extra post-launch trend:     {s['extra_post_trend_pct']:+.2f}% per month "
        f"(95% CI {lo:+.2f} to {hi:+.2f}; p={s['p_slope_change']:.4f})\n"
        f"  net post-launch trend:       {s['net_post_trend_pct']:+.2f}% per month\n"
        f"  immediate level shift:       {s['level_shift_pct']:+.1f}%\n"
    )
report = "\n".join(lines)
print(report)
with open("results.txt", "w") as f:
    f.write(report)

# ---------------- Figures ----------------
fig, ax = plt.subplots(figsize=(11, 5.5))
ax.plot(df["date"], df["num_questions"], color="#1f77b4")
ax.axvline(pd.Timestamp("2022-11-30"), color="red", linestyle="--", label="ChatGPT launch (30 Nov 2022)")
ax.set_ylabel("New questions per month")
ax.set_title("Stack Overflow monthly question volume, 2008-2026")
ax.legend()
fig.tight_layout()
fig.savefig("fig1_raw_series.png", dpi=150)
plt.close(fig)

# Counterfactual from the primary spec: what the pre-launch trend alone would predict
p = specs[1]
d, m = p["data"], p["model"]
cf = d.copy()
cf["post"], cf["t_post"] = 0, 0
d["fitted"] = m.predict(d)
d["counterfactual"] = m.predict(cf)

fig, ax = plt.subplots(figsize=(11, 5.5))
ax.plot(d["date"], np.exp(d["log_q"]), color="#1f77b4", label="Actual")
ax.plot(d["date"], np.exp(d["counterfactual"]), color="gray", linestyle=":", linewidth=2,
        label="Pre-launch trend continued (counterfactual)")
ax.axvline(pd.Timestamp("2022-11-30"), color="red", linestyle="--", label="ChatGPT launch")
ax.set_yscale("log")
ax.set_ylabel("New questions per month (log scale)")
ax.set_title("Actual vs. pre-launch trend continued (primary specification, 2017-2026)")
ax.legend()
fig.tight_layout()
fig.savefig("fig2_counterfactual_log.png", dpi=150)
plt.close(fig)
print("Saved results.txt, fig1_raw_series.png, fig2_counterfactual_log.png")
