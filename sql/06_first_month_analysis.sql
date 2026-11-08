-- ============================================================
-- 06_first_month_analysis.sql
-- Peloton Subscription Churn Analysis
-- Purpose: Extract first-subscription-month usage; compare
--          churned vs active first-month engagement
-- DCS Requirement: Section 11 — First-Month Behaviour
-- Depends on: peloton.customer_base, peloton.usage_clean
-- ============================================================


-- ── 1. BUILD FIRST-MONTH USAGE TABLE ─────────────────────────
DROP TABLE IF EXISTS peloton.first_month_usage;

CREATE TABLE peloton.first_month_usage AS
SELECT
    cb.customer_id,
    cb.signup_date,
    DATE_TRUNC('month', cb.signup_date)::DATE AS signup_month,
    cb.churned_flag,
    cb.churn_date,
    cb.plan_type,
    cb.acquisition_channel,
    cb.tenure_months,
    u.workouts_completed  AS fm_workouts,
    u.minutes_active      AS fm_minutes,
    u.classes_booked      AS fm_classes,
    u.support_tickets     AS fm_support,
    -- Flag customers who cancelled in their very first month
    CASE
        WHEN cb.churned_flag = 1
         AND DATE_TRUNC('month', cb.churn_date) = DATE_TRUNC('month', cb.signup_date)
        THEN TRUE
        ELSE FALSE
    END                   AS first_month_churner
FROM peloton.customer_base cb
LEFT JOIN peloton.usage_clean u
       ON cb.customer_id  = u.customer_id
      AND u.month_dt       = DATE_TRUNC('month', cb.signup_date)::DATE;

SELECT COUNT(*) AS total_rows FROM peloton.first_month_usage;
-- Expected: 4,200

SELECT COUNT(*) AS first_month_churners
FROM peloton.first_month_usage
WHERE first_month_churner = TRUE;
-- Expected: 151

SELECT COUNT(*) AS missing_first_month
FROM peloton.first_month_usage
WHERE fm_workouts IS NULL;
-- Expected: 0


-- ── 2. FIRST-MONTH ENGAGEMENT: CHURNED VS ACTIVE ─────────────
SELECT
    churned_flag,
    COUNT(*)                            AS n,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY fm_workouts)
                                        AS median_fm_workouts,
    ROUND(AVG(fm_workouts)::NUMERIC, 2) AS mean_fm_workouts,
    ROUND(AVG(fm_classes)::NUMERIC, 2)  AS mean_fm_classes,
    ROUND(AVG(fm_support)::NUMERIC, 3)  AS mean_fm_support,
    -- Proportion with zero first-month workouts
    ROUND(COUNT(*) FILTER (WHERE fm_workouts = 0)::NUMERIC / COUNT(*), 4)
                                        AS pct_zero_workouts
FROM peloton.first_month_usage
GROUP BY churned_flag
ORDER BY churned_flag;
-- Expected: churned median ≈ 2.0 vs active ≈ 4.0 workouts
-- Expected: churned zero-workout pct ≈ 12.9% vs active ≈ 6.5%


-- ── 3. FIRST-MONTH CHURNERS — DETAIL ─────────────────────────
-- Interpretation caveat: for these customers, first-month metrics
-- ARE their entire observed lifetime. Not leakage, but noted.
SELECT
    COUNT(*)                            AS n,
    ROUND(AVG(fm_workouts)::NUMERIC, 2) AS avg_workouts,
    COUNT(*) FILTER (WHERE fm_workouts = 0) AS zero_workouts,
    ROUND(COUNT(*) FILTER (WHERE fm_workouts = 0)::NUMERIC / COUNT(*), 4)
                                        AS pct_zero_workouts,
    ROUND(AVG(fm_support)::NUMERIC, 3)  AS avg_support_tickets
FROM peloton.first_month_usage
WHERE first_month_churner = TRUE;


-- ── 4. FIRST-MONTH ENGAGEMENT BY ACQUISITION CHANNEL ─────────
SELECT
    acquisition_channel,
    churned_flag,
    COUNT(*)                                     AS n,
    ROUND(AVG(fm_workouts)::NUMERIC, 2)          AS avg_fm_workouts,
    ROUND(COUNT(*) FILTER (WHERE fm_workouts = 0)::NUMERIC / COUNT(*), 4)
                                                 AS pct_zero_fm_workouts
FROM peloton.first_month_usage
GROUP BY acquisition_channel, churned_flag
ORDER BY acquisition_channel, churned_flag;
-- Expect: promo_offer churned to have notably low first-month engagement


-- ── 5. FIRST-MONTH ENGAGEMENT BY PLAN TYPE ───────────────────
SELECT
    plan_type,
    churned_flag,
    COUNT(*)                                     AS n,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY fm_workouts)
                                                 AS median_fm_workouts,
    ROUND(AVG(fm_workouts)::NUMERIC, 2)          AS avg_fm_workouts
FROM peloton.first_month_usage
GROUP BY plan_type, churned_flag
ORDER BY plan_type, churned_flag;


-- ── 6. ENGAGEMENT THRESHOLDS — EARLY SIGNAL ──────────────────
-- What % of eventual churners had < 2 workouts in month 1?
SELECT
    churned_flag,
    COUNT(*)                                             AS n,
    COUNT(*) FILTER (WHERE fm_workouts < 2)              AS low_engagement_lt2,
    COUNT(*) FILTER (WHERE fm_workouts BETWEEN 2 AND 4)  AS medium_2_to_4,
    COUNT(*) FILTER (WHERE fm_workouts > 4)              AS high_gt4,
    ROUND(COUNT(*) FILTER (WHERE fm_workouts < 2)::NUMERIC / COUNT(*), 4)
                                                         AS pct_low_lt2
FROM peloton.first_month_usage
GROUP BY churned_flag
ORDER BY churned_flag;
-- Useful for establishing an early-warning threshold for activation campaigns
