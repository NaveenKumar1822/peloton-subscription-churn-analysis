# Peloton Subscription Churn Analysis — Key Findings

**Analysis period:** July 2024 – December 2025  
**Dataset:** 4,200 subscribers | 30,525 monthly usage records (after deduplication)  
**Overall churn rate:** 42.1% (1,768 of 4,200 customers cancelled within the observation window)  
**Mean monthly churn rate:** 6.7% (exposure-adjusted; excludes same-month signups from denominator)

> All findings below are **associative, not causal**. This is an observational dataset with no experimental design. Language such as "associated with," "linked to," and "shows higher churn" is used throughout. No causal inference is claimed.

---

## Finding 1 — Low Engagement is the Strongest Behavioural Predictor of Churn

**What the data shows:**  
Churned subscribers completed a median of **2.0 workouts per month** compared to **4.1 workouts per month** for retained subscribers — a 2× engagement gap. Active minutes tell the same story: churned subscribers averaged 62.1 active minutes per month vs 123.3 for active subscribers. The gap is present from month 1 and is consistent across every tenure band.

**Evidence:**  
- Mann-Whitney U, rank-biserial r = −0.37, p ≈ 0 (BH-adjusted) — the strongest effect size among all continuous predictors
- Active minutes: r = −0.36, p ≈ 0 (independent corroboration of the same construct)
- First-month engagement gap: churned subscribers had a median of 2.0 first-month workouts vs 4.0 for retained subscribers (r = −0.27, p ≈ 0)
- Churned subscribers were **twice as likely to complete zero workouts in their first month** (12.9% vs 6.5%)
- Pre-churn trajectory analysis (3 months before the churn or index month): the gap is **consistent rather than a sudden drop** — churned subscribers were persistently lower throughout, not just declining at the end

**Tenure validation:**  
Engagement gap confirmed in all 5 tenure bands (0–1, 2–3, 4–6, 7–12, 13+ months). Effect is smallest in the 13+ month band (long-tenured churners had accumulated stronger habits) but remains directionally consistent.

**Cancellation reason corroboration:**  
"Not using enough" is the single most common stated cancellation reason (570 customers, 41.1% of churners with known reasons). The behavioural data confirms this group has the lowest average monthly workouts (2.1/month) among all reason groups — the stated reason and the behavioural pattern agree.

**Business meaning:**  
Peloton's core retention problem is **habit formation failure**. Subscribers who do not build a consistent workout routine cancel. The first month is the most critical window — the engagement trajectory is set early and does not recover for the majority of eventual churners.

---

## Finding 2 — Monthly Billing Creates Persistent Cancellation Risk; Annual Billing Introduces Renewal-Decision Risk

**What the data shows:**  
Monthly plan subscribers churn at **51.2%** vs **26.4%** for annual subscribers — a 24.8 percentage-point gap. This is the largest raw difference between any two groups in the dataset. However, the two plan types face **structurally different churn mechanisms**:

- **Monthly subscribers** face continuous cancellation risk at every billing cycle
- **Annual subscribers** face concentrated renewal-decision risk: 75.9% of all annual churners cancel within a 10–14 month tenure window, consistent with the annual renewal decision point

**Evidence:**  
- Chi-square Cramér's V = 0.24, p ≈ 0 (BH-adjusted) — largest categorical effect size in the dataset
- Within monthly plan: promo-acquired monthly subscribers churn at 63.3% vs 47.7% for other channels
- Within annual plan: 322 of 406 churned annual subscribers (79.3%) fall in the 7–12 month tenure band
- Tenure-stratified validation: monthly churn exceeds annual churn in the 2–3, 4–6, and 13+ month bands. At 7–12 months, annual churn (42.1%) exceeds monthly (30.7%) due to the renewal spike

**Tenure validation:**  
The monthly vs annual gap is confirmed within-band for 3 of the 4 interpretable bands (excluding 0–1 month where right-censoring dominates). The relationship does not disappear after controlling for tenure — it changes character between plan types.

**Business meaning:**  
Switching a monthly subscriber to an annual plan removes 11 of 12 monthly cancellation opportunities and converts the retention challenge from an ongoing one to an annual event. The annual renewal spike indicates that even committed annual subscribers must be re-won at the 10–11 month mark.

---

## Finding 3 — Promo-Offer Subscribers Churn at Higher Rates, Concentrated in the First 60–90 Days

**What the data shows:**  
Subscribers acquired through promotional offers churn at **50.8%** compared to **39.6%** for all other channels combined — an 11.2pp gap. Within the monthly plan, the promo gap widens to **15.6pp** (63.3% vs 47.7%). However, the elevated churn is **early-tenure concentrated**: promo churn is highest in the 2–3 month band (60.4%) and falls below other channels by the 4–6 month band (28.0%). Promo subscribers who survive the first 90 days are not meaningfully more at risk than subscribers from other channels.

**Evidence:**  
- Chi-square Cramér's V = 0.107, p ≈ 0 (BH-adjusted), across acquisition channels
- Referral channel (lowest churn, 33.8%) vs promo_offer (50.8%): 17.0pp gap — the largest channel contrast in the dataset
- Promo subscribers have shorter average tenure than non-promo subscribers (5.8 vs 6.7 completed 30-day months)
- Promo subscribers are slightly more likely to be on monthly plans (62.1% vs 63.7% for non-promo — the difference is not material, confirming the channel effect is not purely a plan-type confound)
- Within-plan-type validation: promo churn exceeds non-promo churn for both monthly (63.3% vs 47.7%) and annual (30.3% vs 25.2%) plan types

**Tenure validation:**  
The promo channel effect is early-tenure concentrated and largely absent after the 4–6 month band. This suggests the problem is not intrinsic to promo customers but is an **onboarding and activation problem** for this segment.

**Business meaning:**  
Promotional offers attract a customer segment with weaker initial motivation — likely price-sensitive customers who signed up for the discount rather than the fitness value proposition. The critical intervention window is the **first 60 days**. A targeted early-engagement programme for promo-acquired subscribers could substantially reduce this segment's churn without requiring a change to the acquisition strategy.

---

## Finding 4 — "Too Expensive" Churners are Engaged Users, Not Disengaged Ones

**What the data shows:**  
Customers who stated "too expensive" as their cancellation reason showed **higher engagement** than customers who stated "not using enough": 3.67 vs 2.12 average monthly workouts. Both groups are below the active-customer baseline (4.9 workouts/month), but the gap between them is striking. "Too expensive" churners are Peloton subscribers who value the product but cannot justify the price-to-value ratio at their current plan level.

**Evidence:**  
- "too_expensive" group: n = 322, avg workouts = 3.67/month, 78.9% on monthly plans, avg monthly price = $17.26
- "not_using_enough" group: n = 570, avg workouts = 2.12/month
- "found_alternative" group: avg workouts = 3.55/month (also relatively engaged)
- "technical_issues" group: 100% had at least one support contact — perfectly consistent with stated reason

**Business meaning:**  
Retention strategy must be **segmented by churn reason**. Sending re-engagement campaigns to "too expensive" churners is mismatched — they were engaged. The right lever for this segment is **price or commitment structure**: an annual plan offer, a tier-downgrade option, or a loyalty pricing programme. A blanket re-engagement intervention will not retain price-sensitive but engaged churners.

---

## Summary Table

| Factor | Churn gap | Statistical evidence | Tenure persistent? | Actionability |
|---|---|---|---|---|
| Low engagement (avg workouts) | Median 2.0 vs 4.1 | r = −0.37, p ≈ 0 | ✓ All bands | ✓ Activation programme |
| Monthly plan type | 51.2% vs 26.4% | V = 0.24, p ≈ 0 | ✓ (different mechanisms) | ✓ Upgrade offers |
| Promo-offer channel | 50.8% vs 39.6% | V = 0.107, p ≈ 0 | ✓ Early-tenure concentrated | ✓ 60-day programme |
| Plan tier | 42.1–43.4% | V = 0.013, p = 0.74 | n/a | ✗ Not a meaningful predictor |
| Age group | 38.9–42.8% | V = 0.022, p = 0.74 | n/a | ✗ Not a meaningful predictor |
| Primary device | 40.4–45.0% | V = 0.044, p = 0.02 | Needs further study | Weak |

---

*Findings based on observational data. No causal relationships are claimed. All statistics computed in Python (pandas, scipy, statsmodels) and validated in PostgreSQL. Full methodology documented in `notebooks/peloton_subscription_churn_eda.ipynb`.*
