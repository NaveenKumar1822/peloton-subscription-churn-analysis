-- ============================================================
-- 07_churn_driver_validation.sql
-- Peloton Subscription Churn Analysis
-- Purpose: Tenure-stratified validation of the Top 3 churn
--          factors. Uses CTEs and window functions.
--          Minimum n=30 rule applied; small cells flagged.
-- Depends on: peloton.customer_base, peloton.customer_usage_summary
-- ============================================================


-- ── 1. TENURE-STRATIFIED: PLAN TYPE ──────────────────────────
-- Question: Does monthly plan's higher churn persist within each tenure band?
WITH strat AS (
    SELECT
        tenure_band,
        plan_type,
        COUNT(*)                           AS n,
        SUM(churned_flag)                  AS churned,
        ROUND(SUM(churned_flag)::NUMERIC / COUNT(*), 4) AS churn_rate
    FROM peloton.customer_base
    GROUP BY tenure_band, plan_type
)
SELECT
    tenure_band,
    plan_type,
    n,
    churned,
    churn_rate,
    -- Flag cells with n < 30 per minimum-cell-size rule
    CASE WHEN n < 30 THEN 'FLAG: n < 30' ELSE 'OK' END AS data_quality_flag,
    -- Within-band rank (highest churn = 1)
    RANK() OVER (PARTITION BY tenure_band ORDER BY churn_rate DESC) AS rank_within_band
FROM strat
ORDER BY
    CASE tenure_band
        WHEN '0-1 month'   THEN 1
        WHEN '2-3 months'  THEN 2
        WHEN '4-6 months'  THEN 3
        WHEN '7-12 months' THEN 4
        WHEN '13+ months'  THEN 5
    END,
    churn_rate DESC;
-- Key finding: monthly exceeds annual in 2-3, 4-6, 13+ bands.
-- At 7-12 months annual spikes (renewal effect): 75.9% of annual churners
-- have tenure 10-14 months.


-- ── 2. ANNUAL PLAN: RENEWAL-WINDOW ANALYSIS ──────────────────
-- What proportion of annual churners cancel in the renewal window?
SELECT
    COUNT(*)                                             AS total_annual_churners,
    COUNT(*) FILTER (WHERE tenure_months BETWEEN 10 AND 14)
                                                         AS renewal_window_10_14,
    ROUND(COUNT(*) FILTER (WHERE tenure_months BETWEEN 10 AND 14)::NUMERIC
          / COUNT(*), 4)                                 AS pct_in_renewal_window
FROM peloton.customer_base
WHERE plan_type = 'annual' AND churned_flag = 1;
-- Expected: ≈ 75.9% of annual churners fall in 10–14 month window


-- ── 3. TENURE-STRATIFIED: ACQUISITION CHANNEL ─────────────────
-- Question: Does promo_offer channel's higher churn persist across bands?
WITH strat_ch AS (
    SELECT
        tenure_band,
        acquisition_channel,
        COUNT(*)                           AS n,
        SUM(churned_flag)                  AS churned,
        ROUND(SUM(churned_flag)::NUMERIC / COUNT(*), 4) AS churn_rate
    FROM peloton.customer_base
    GROUP BY tenure_band, acquisition_channel
)
SELECT
    tenure_band,
    acquisition_channel,
    n,
    churned,
    churn_rate,
    CASE WHEN n < 30 THEN 'FLAG: n < 30' ELSE 'OK' END AS data_quality_flag,
    RANK() OVER (PARTITION BY tenure_band ORDER BY churn_rate DESC) AS rank_within_band
FROM strat_ch
ORDER BY
    CASE tenure_band
        WHEN '0-1 month'   THEN 1
        WHEN '2-3 months'  THEN 2
        WHEN '4-6 months'  THEN 3
        WHEN '7-12 months' THEN 4
        WHEN '13+ months'  THEN 5
    END,
    churn_rate DESC;
-- Key finding: promo highest churn in 2-3 month band (60.4%).
-- Effect diminishes in 4-6 band: promo drops to ~28%, below organic/partner.
-- Early-tenure concentrated — an ONBOARDING problem for promo segment.


-- ── 4. TENURE-STRATIFIED: ENGAGEMENT (WORKOUTS) ──────────────
-- Question: Does the engagement gap between churned/active persist across bands?
WITH eng_strat AS (
    SELECT
        cus.tenure_band,
        cus.churned_flag,
        COUNT(*)                                                AS n,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
              (ORDER BY cus.avg_monthly_workouts)::NUMERIC, 2)  AS median_workouts,
        ROUND(AVG(cus.avg_monthly_workouts)::NUMERIC, 2)        AS mean_workouts
    FROM peloton.customer_usage_summary cus
    GROUP BY cus.tenure_band, cus.churned_flag
)
SELECT
    tenure_band,
    churned_flag,
    n,
    median_workouts,
    mean_workouts,
    -- Gap to other status in same band (window function)
    median_workouts - LAG(median_workouts) OVER (
        PARTITION BY tenure_band ORDER BY churned_flag
    ) AS median_gap_vs_prev_status
FROM eng_strat
ORDER BY
    CASE tenure_band
        WHEN '0-1 month'   THEN 1
        WHEN '2-3 months'  THEN 2
        WHEN '4-6 months'  THEN 3
        WHEN '7-12 months' THEN 4
        WHEN '13+ months'  THEN 5
    END,
    churned_flag;
-- Key finding: active > churned median workouts in every tenure band.
-- Gap narrows in 13+ months but persists.


-- ── 5. PROMO CHANNEL — WITHIN PLAN TYPE VALIDATION ───────────
-- Controls for the plan_type × channel confound
SELECT
    plan_type,
    CASE WHEN acquisition_channel = 'promo_offer' THEN 'promo' ELSE 'non-promo' END AS channel_group,
    COUNT(*)                           AS n,
    SUM(churned_flag)                  AS churned,
    ROUND(SUM(churned_flag)::NUMERIC / COUNT(*), 4) AS churn_rate
FROM peloton.customer_base
GROUP BY plan_type, channel_group
ORDER BY plan_type, churn_rate DESC;
-- Expected: within monthly plan: promo 63.3% vs non-promo 47.7% (Δ = 15.6pp)
-- Expected: within annual plan:  promo 30.3% vs non-promo 25.2% (Δ = 5.1pp)
-- Conclusion: promo effect exists within both plan types — not purely plan confounding


-- ── 6. TOP 3 FACTOR SUMMARY CTE ──────────────────────────────
-- Single query that cross-validates all three top factors
WITH factor1_workouts AS (
    SELECT
        'Factor 1: Engagement' AS factor,
        churned_flag::TEXT AS group_value,
        COUNT(*)           AS n,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_monthly_workouts)::NUMERIC, 2)
                           AS key_metric,
        'median avg monthly workouts' AS metric_label
    FROM peloton.customer_usage_summary
    GROUP BY churned_flag
),
factor2_plan AS (
    SELECT
        'Factor 2: Plan Type' AS factor,
        plan_type AS group_value,
        COUNT(*)  AS n,
        ROUND(SUM(churned_flag)::NUMERIC / COUNT(*), 4) AS key_metric,
        'churn rate' AS metric_label
    FROM peloton.customer_base
    GROUP BY plan_type
),
factor3_channel AS (
    SELECT
        'Factor 3: Acq Channel (promo vs other)' AS factor,
        CASE WHEN acquisition_channel = 'promo_offer' THEN 'promo_offer' ELSE 'non-promo' END AS group_value,
        COUNT(*) AS n,
        ROUND(SUM(churned_flag)::NUMERIC / COUNT(*), 4) AS key_metric,
        'churn rate' AS metric_label
    FROM peloton.customer_base
    GROUP BY
        CASE WHEN acquisition_channel = 'promo_offer' THEN 'promo_offer' ELSE 'non-promo' END
)
SELECT * FROM factor1_workouts
UNION ALL SELECT * FROM factor2_plan
UNION ALL SELECT * FROM factor3_channel
ORDER BY factor, key_metric;
