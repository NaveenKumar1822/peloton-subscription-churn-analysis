# Executive Recommendation — Peloton Subscription Retention

**Prepared by:** Naveen Kumar K  
**Data period:** July 2024 – December 2025 | **Customers analysed:** 4,200

---

## 1. Priority Problem

**42.1% of Peloton subscribers cancel within the observation window.** The mean monthly churn rate is 6.7%. The root cause is habit formation failure in the first 90 days: churned subscribers engage at half the workout rate of retained subscribers from their very first month, and this gap does not close over time. Monthly-plan billing compounds the risk by giving subscribers a low-friction cancellation option every 30 days.

---

## 2. Top 3 Churn Drivers (Evidence Summary)

| # | Driver | Churn rate gap | Effect size | Tenure-persistent? |
|---|---|---|---|---|
| 1 | **Low engagement** (< 2 workouts/month average) | Churned: 2.0 workouts/mo vs Active: 4.1 workouts/mo | rank-biserial r = −0.37 | ✓ All 5 tenure bands |
| 2 | **Monthly plan type** (vs Annual) | 51.2% vs 26.4% (Δ = 24.8pp) | Cramér's V = 0.24 | ✓ Persists within-band; mechanism differs by tenure |
| 3 | **Promo-offer acquisition** (vs other channels) | 50.8% vs 39.6% (Δ = 11.2pp); within monthly: 63.3% vs 47.7% | V = 0.107 | ✓ Early-tenure concentrated (first 60–90 days) |

---

## 3. Recommended Actions

### Action 1 — First-30-Day Activation Programme *(highest priority)*
Target: all new subscribers; elevated intensity for promo-acquired

- **Day 3:** Personalised class recommendation (device-matched)
- **Day 7:** Push notification to any subscriber with 0 workouts — "Your first class takes 15 minutes"
- **Day 14:** Launch a 4-week streak mechanic with milestone reward
- **Day 30:** "30-day check-in" for subscribers with fewer than 4 workouts in month 1

Rationale: Churned subscribers were twice as likely to complete zero first-month workouts (12.9% vs 6.5%). Early engagement is the single leading indicator of long-term retention.

### Action 2 — Monthly-to-Annual Upgrade Offer at Month 2–3
Target: monthly subscribers with ≥ 2 first-month workouts (engaged but not yet committed)

- Offer: first 2 months free on annual plan at the start of month 2 or 3
- Message: "You're showing up — lock in your rate and save"
- Delivery: in-app banner + single email; not a blanket promotional blast

Rationale: Monthly plan churn peaks in the 2–3 month band (45.6%). An annual upgrade converts a continuous cancellation risk into an annual decision.

### Action 3 — Annual Renewal Intervention at Month 10–11
Target: annual subscribers with declining engagement in months 8–10

- Month 10: "Your year in review" personalised summary (workouts completed, classes taken)
- Month 11: Renewal reminder with loyalty reward (one month of bonus content, tier upgrade for 60 days)
- Delivery: email sequence; in-app renewal prompt

Rationale: 75.9% of all annual churners cancel in a 10–14 month window. Intervening before the renewal decision is made is more effective than win-back after cancellation.

### Action 4 — Price-Sensitive Segment Retention Offer
Target: monthly basic/plus subscribers with 2–4 months tenure and ≥ 2 workouts/month who have not upgraded

- Offer: annual plan discount or one-month-free retention offer
- Do not apply to zero-engagement subscribers (address those with Action 1)

Rationale: "Too expensive" churners are engaged users (avg 3.67 workouts/month) making a price-value judgement — not disengaged users who need re-activation.

---

## 4. Target Segment Priority

1. **Promo-acquired monthly subscribers, months 1–3** — highest concentration of early churn; most responsive to onboarding intervention
2. **Any monthly subscriber with < 2 workouts in month 1** — early-warning threshold regardless of acquisition channel
3. **Annual subscribers in months 10–11** — renewal decision window

---

## 5. Measurement Plan

| Action | Primary KPI | Measurement method |
|---|---|---|
| Activation programme | First-month workout completion rate | A/B test: activation flow vs. current baseline |
| Upgrade offer | Monthly-to-annual conversion rate; 90-day churn of offer recipients | Holdout group experiment |
| Renewal intervention | Annual renewal rate; month-11 cancellation rate | Pre/post with matched control |
| Price-sensitive offer | Churn rate for targeted segment; LTV impact | A/B test with no-contact control |

**Success orientation:** Given the observational nature of the data, specific percentage targets are not prescribed. Each action should be validated with a controlled experiment before scaling. The goal of initial experiments is to establish whether the directional effects in this analysis hold under experimental conditions — particularly whether closing the first-month engagement gap reduces downstream churn.

---

## 6. Key Limitations

- **Observational data:** All findings are associations. Experimental validation is required before attributing outcomes to specific interventions.
- **Right-censoring:** 2,432 active customers have not yet churned in this dataset; the full eventual churn rate is higher than 42.1%.
- **21.6% missing cancel reasons:** The stated-reason analysis covers 78.4% of churners; the missing segment may have different patterns.
- **Monthly usage grain:** Within-month engagement variation (session timing, consistency) is not observable.

---

*Full methodology and evidence: `notebooks/peloton_subscription_churn_eda.ipynb` | `reports/findings.md`*
