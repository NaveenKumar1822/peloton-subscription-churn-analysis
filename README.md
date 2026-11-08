# Peloton Subscription Churn Analysis

**A Python EDA + SQL business analytics project**

[![Python](https://img.shields.io/badge/Python-3.9%2B-blue)](https://python.org)
[![SQL](https://img.shields.io/badge/SQL-PostgreSQL-336791)](https://postgresql.org)
[![Analysis](https://img.shields.io/badge/Type-EDA%20%2B%20Business%20Analysis-green)]()

---

## Business Problem

Peloton's fitness app offers on-demand workouts and live classes via monthly and annual subscriptions. Subscription cancellations are increasing, and leadership wants to understand why subscribers are leaving and what actions can improve retention.

> **Central question:** What customer characteristics, subscription attributes, engagement patterns, and behavioural factors are associated with subscription churn — and what evidence-based actions should Peloton prioritise to improve retention?

---

## Objective

This project performs a **structured exploratory data analysis** of 4,200 Peloton subscribers across 18 months to:

1. Identify and validate the **top 3 factors associated with churn**
2. Control for **right-censoring and tenure** throughout the analysis
3. Cross-validate findings against **stated cancellation reasons**
4. Translate evidence into **specific, measurable retention recommendations**

This is intentionally an **EDA and business analysis project** — no machine learning models are built.

---

## Dataset

Two CSV files are analysed (not committed — see `data/README.md` for placement instructions):

| File | Rows | Grain | Key fields |
|---|---|---|---|
| `subscriptions.csv` | 4,200 | One per customer | signup_date, plan_type, plan_tier, acquisition_channel, churned, churn_date, cancel_reason |
| `usage.csv` | 30,685 (raw) | One per customer per month | workouts_completed, minutes_active, classes_booked, support_tickets |

**Key data quality issues found and resolved:**
- 160 exact duplicate usage rows — dropped (data export artifact)
- 101 `plan_tier` capitalisation inconsistencies — normalised to lowercase
- 506 missing `minutes_active` values — excluded from minutes-specific analyses; not imputed
- 382 churned customers with no stated cancel reason — recoded as `"unknown"` and reported separately

---

## Analytical Approach

### Churn Definition
A customer is churned if `churned == 'yes'`. Active customers are **right-censored** at the analysis cutoff (2025-12-31) — they are not treated as "successfully retained."

### Tenure
Tenure is measured in **completed 30-day months** (a documented approximation of billing months). Active customers' tenure runs to the analysis cutoff. Five tenure bands are used: 0–1, 2–3, 4–6, 7–12, and 13+ months.

### Monthly Churn Rate
Calculated as `cancellations in month M ÷ customers active at start of month M`. Same-month signups are excluded from the denominator to avoid inflating churn rates in high-growth months.

### Engagement Analysis
Customer-level **per-month averages** are used throughout — not lifetime totals — to ensure fair comparison between churned customers (shorter observation windows) and active customers (ongoing observation).

### Statistical Testing
12 pre-specified tests (Chi-square for categorical variables; Mann-Whitney U for continuous) with **Benjamini-Hochberg FDR correction at q = 0.10**. Effect sizes reported alongside p-values. Statistical significance is supporting evidence; practical magnitude, tenure consistency, and business relevance jointly determine the Top 3 factors.

### Leakage Prevention
Explicit filters exclude post-churn usage from all aggregations. Per-month averages rather than cumulative totals remove observation-window bias. The churn date is used only for tenure calculation and usage filtering — never as a predictor variable.

### Tenure-Stratified Validation
Every major candidate factor is re-examined within each tenure band. Cells with n < 30 are flagged and not interpreted.

---

## Key Findings

> All findings are **associative, not causal**.

### Finding 1 — Low Engagement is the Strongest Behavioural Predictor
Churned subscribers completed a median of **2.0 workouts per month** vs **4.1** for active subscribers (rank-biserial r = −0.37, p ≈ 0, BH-adjusted). The gap is present from month 1 and consistent across all tenure bands. Churned subscribers were **twice as likely to complete zero workouts in their first month** (12.9% vs 6.5%). The stated cancellation reason "not using enough" (41% of known reasons) independently corroborates the behavioural data.

### Finding 2 — Monthly Billing Creates Persistent Cancellation Risk
Monthly plan subscribers churn at **51.2% vs 26.4%** for annual (Δ = 24.8pp; V = 0.24, p ≈ 0). This gap persists within tenure bands. A distinct mechanism applies to annual subscribers: **75.9% of annual churners cancel in a 10–14 month window**, consistent with the annual renewal decision point — a separate retention risk requiring a separate intervention.

### Finding 3 — Promo-Acquired Subscribers are an Early-Churn Segment
Promo-offer subscribers churn at **50.8% vs 39.6%** for other channels (Δ = 11.2pp; V = 0.107, p ≈ 0). Within monthly plans, the gap is 15.6pp (63.3% vs 47.7%). The effect is **early-tenure concentrated**: promo churn peaks in the 2–3 month band and falls below other channels by months 4–6, suggesting an onboarding problem rather than an intrinsic customer quality difference.

### Finding 4 — "Too Expensive" Churners are Engaged Users (Behavioural Contradiction)
Customers who stated "too expensive" averaged **3.67 workouts/month** — higher than those who stated "not using enough" (2.12). They are engaged users making a price-value judgement. Re-engagement campaigns will not retain this segment; a price or commitment-structure offer is the appropriate lever.

---

## Business Recommendations

| Action | Target segment | Rationale |
|---|---|---|
| **First-30-Day Activation Programme** | All new subscribers; elevated for promo-acquired | First-month engagement gap is the earliest observable churn signal |
| **Monthly-to-Annual Upgrade Offer (Month 2–3)** | Monthly subscribers with ≥ 2 first-month workouts | Converts continuous cancellation risk to an annual decision |
| **Annual Renewal Intervention (Month 10–11)** | Annual subscribers with declining engagement in months 8–10 | 75.9% of annual churners fall in a 10–14 month window |
| **Price-Sensitive Segment Offer** | Engaged monthly subscribers (≥ 2 workouts/month) on basic/plus tier | "Too expensive" churners are engaged — the right lever is pricing, not re-engagement |

Full recommendation (one page): [`reports/recommendation.md`](reports/recommendation.md)

---

## Tools

| Tool | Purpose |
|---|---|
| Python 3.9+ | Primary analysis environment |
| pandas | Data loading, cleaning, and manipulation |
| NumPy | Numerical computation |
| Matplotlib + Seaborn | Visualisation (14 analytical charts) |
| SciPy | Mann-Whitney U and Chi-square statistical tests |
| statsmodels | Benjamini-Hochberg FDR multiple-testing correction |
| PostgreSQL | SQL validation and supporting analysis |
| Git / GitHub | Version control and portfolio presentation |

---

## Project Structure

```
peloton-subscription-churn-analysis/
│
├── data/
│   └── README.md                          ← Dataset placement instructions
│
├── notebooks/
│   └── peloton_subscription_churn_eda.ipynb  ← Full 20-section analysis notebook
│
├── sql/
│   ├── 01_data_quality.sql               ← Data quality audit queries
│   ├── 02_churn_definition.sql           ← Churn definition + monthly churn rate
│   ├── 03_tenure_analysis.sql            ← Tenure distribution + right-censoring
│   ├── 04_customer_segmentation.sql      ← Churn rates by all categorical dimensions
│   ├── 05_usage_engagement.sql           ← Engagement aggregations + comparison
│   ├── 06_first_month_analysis.sql       ← First-month behaviour analysis
│   ├── 07_churn_driver_validation.sql    ← Tenure-stratified top-3 validation
│   └── 08_final_validation.sql           ← Cross-validation of Python results
│
├── reports/
│   ├── findings.md                       ← Structured business insights (4 findings)
│   ├── recommendation.md                 ← One-page executive recommendation
│   └── chart01–chart12.png               ← Saved visualisations from notebook
│
├── README.md                             ← This file
├── requirements.txt                      ← Python dependencies
└── .gitignore
```

---

## Reproducibility

### Python

```bash
# 1. Clone the repository
git clone https://github.com/<your-username>/peloton-subscription-churn-analysis.git
cd peloton-subscription-churn-analysis

# 2. Install dependencies
pip install -r requirements.txt

# 3. Place the datasets in the data/ directory
#    (see data/README.md for instructions)

# 4. Run the notebook
jupyter notebook notebooks/peloton_subscription_churn_eda.ipynb
# Execute all cells top-to-bottom (Kernel → Restart & Run All)
```

The notebook reads from `../data/` relative to the notebooks directory. No absolute paths are used.

### SQL (PostgreSQL)

```sql
-- 1. Create schema and load raw tables (see data/README.md for COPY commands)
-- 2. Run scripts in order
\i sql/01_data_quality.sql
\i sql/02_churn_definition.sql
\i sql/03_tenure_analysis.sql
\i sql/04_customer_segmentation.sql
\i sql/05_usage_engagement.sql
\i sql/06_first_month_analysis.sql
\i sql/07_churn_driver_validation.sql
\i sql/08_final_validation.sql
-- Script 08 includes a PASS/FAIL cross-validation against notebook results
```

---

## Limitations

1. **Observational data — no causality.** All findings are associations. No randomised experiment exists.
2. **Right-censoring.** 2,432 active customers have not yet churned in this dataset; true eventual churn exceeds 42.1%.
3. **Monthly usage granularity.** Within-month engagement variation (consistency, timing) is not observable.
4. **Missing cancel reasons.** 21.6% of churners provided no reason; the stated-reason distribution reflects 78.4% of churners.
5. **Annual plan semantics.** The data does not distinguish mid-period cancellations from renewal lapses for annual subscribers.
6. **No session-level or content-type data.** Workout type, duration per session, and time-of-day patterns are not available.

---

## About This Project

This project was built as part of a Data Analyst portfolio, following the [Data Career School customer churn project specification](https://www.datacareerschool.com/datalabs/customer-churn-analysis). The analytical framework, churn methodology, tenure-adjustment approach, and business recommendations were developed from scratch using the actual datasets.

**Author:** Naveen Kumar K  
**Skills demonstrated:** EDA · SQL · Statistical testing · Business analysis · Tenure-aware analysis · Data storytelling
