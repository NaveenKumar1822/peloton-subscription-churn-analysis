-- ============================================================
-- 03_tenure_analysis.sql
-- Peloton Subscription Churn Analysis
-- Purpose: Tenure distribution, band analysis, and right-
--          censoring summary
-- Depends on: peloton.customer_base (02_churn_definition.sql)
-- ============================================================


-- ── 1. TENURE DISTRIBUTION SUMMARY ───────────────────────────
SELECT
    churned,
    COUNT(*)                          AS n,
    MIN(tenure_months)                AS tenure_min,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY tenure_months) AS tenure_p25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY tenure_months) AS tenure_median,
    ROUND(AVG(tenure_months), 2)      AS tenure_mean,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tenure_months) AS tenure_p75,
    MAX(tenure_months)                AS tenure_max
FROM peloton.customer_base
GROUP BY churned
ORDER BY churned;


-- ── 2. TENURE BAND DISTRIBUTION ───────────────────────────────
SELECT
    tenure_band,
    COUNT(*)                                              AS total_customers,
    SUM(churned_flag)                                     AS churned,
    COUNT(*) - SUM(churned_flag)                          AS active_censored,
    ROUND(SUM(churned_flag)::NUMERIC / COUNT(*), 4)       AS churn_rate
FROM peloton.customer_base
GROUP BY tenure_band
ORDER BY
    CASE tenure_band
        WHEN '0-1 month'   THEN 1
        WHEN '2-3 months'  THEN 2
        WHEN '4-6 months'  THEN 3
        WHEN '7-12 months' THEN 4
        WHEN '13+ months'  THEN 5
    END;
-- Expected: 0-1 band = 100% churn (structural); 13+ band = 8.8% (loyal segment)


-- ── 3. ZERO-TENURE CUSTOMERS (same-day cancellations) ─────────
SELECT
    customer_id,
    signup_date,
    churn_date,
    plan_type,
    plan_tier,
    acquisition_channel,
    cancel_reason
FROM peloton.customer_base
WHERE zero_tenure = TRUE
ORDER BY signup_date;
-- Expected: 7 customers


-- ── 4. SIGNUP COHORT DISTRIBUTION ────────────────────────────
-- Shows right-censoring visually: recent cohorts have fewer churned customers
SELECT
    DATE_TRUNC('month', signup_date)::DATE AS signup_month,
    COUNT(*)                               AS total_signups,
    SUM(churned_flag)                      AS churned,
    COUNT(*) - SUM(churned_flag)           AS still_active,
    ROUND(SUM(churned_flag)::NUMERIC / COUNT(*), 4) AS raw_churn_rate
FROM peloton.customer_base
GROUP BY DATE_TRUNC('month', signup_date)
ORDER BY signup_month;
-- Note: cohorts from Aug-Oct 2025 show very low churn rates — right-censoring artifact


-- ── 5. RIGHT-CENSORING ANALYSIS ───────────────────────────────
-- What proportion of active customers have had < 6 months exposure?
SELECT
    CASE
        WHEN tenure_months < 3  THEN 'Under 3 months exposure'
        WHEN tenure_months < 6  THEN '3–5 months exposure'
        WHEN tenure_months < 12 THEN '6–11 months exposure'
        ELSE '12+ months exposure'
    END AS exposure_group,
    COUNT(*) AS n,
    ROUND(COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM peloton.customer_base WHERE churned = 'no'), 4) AS pct_of_active
FROM peloton.customer_base
WHERE churned = 'no'
GROUP BY 1
ORDER BY 1;
