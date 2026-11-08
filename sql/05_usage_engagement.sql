-- ============================================================
-- 05_usage_engagement.sql
-- Peloton Subscription Churn Analysis
-- Purpose: Build cleaned usage table; compute per-customer
--          engagement averages; compare churned vs active
-- Depends on: peloton.customer_base (02_churn_definition.sql)
--             peloton.usage_raw     (loaded from usage.csv)
-- ============================================================


-- ── 1. BUILD DEDUPLICATED USAGE TABLE ────────────────────────
-- Remove 160 exact duplicate (customer_id, month) rows
DROP TABLE IF EXISTS peloton.usage_clean;

CREATE TABLE peloton.usage_clean AS
SELECT DISTINCT ON (customer_id, month)
    customer_id,
    month,
    TO_DATE(month, 'YYYY-MM') AS month_dt,
    workouts_completed,
    minutes_active,       -- nullable: 506 rows; not imputed
    classes_booked,
    support_tickets
FROM peloton.usage_raw
ORDER BY customer_id, month;

SELECT COUNT(*) AS usage_clean_rows FROM peloton.usage_clean;
-- Expected: 30,525 (30,685 - 160 duplicates)


-- ── 2. DEFENSIVE POST-CHURN EXCLUSION ────────────────────────
-- Confirm zero usage rows exist after a customer's churn month
-- (confirmed in Phase 1; this query validates the raw data)
SELECT COUNT(*) AS post_churn_rows
FROM peloton.usage_clean u
JOIN peloton.customer_base cb ON u.customer_id = cb.customer_id
WHERE cb.churned = 'yes'
  AND u.month_dt > DATE_TRUNC('month', cb.churn_date);
-- Expected: 0


-- ── 3. BUILD CUSTOMER-LEVEL USAGE SUMMARY ────────────────────
-- Uses PER-MONTH AVERAGES to avoid observation-window bias
-- Churned customers have shorter histories → averages are fair; totals are not
DROP TABLE IF EXISTS peloton.customer_usage_summary;

CREATE TABLE peloton.customer_usage_summary AS
WITH valid_usage AS (
    -- Apply defensive post-churn filter even though Phase 1 confirmed 0 violations
    SELECT u.*
    FROM peloton.usage_clean u
    JOIN peloton.customer_base cb ON u.customer_id = cb.customer_id
    WHERE cb.churned = 'no'
       OR u.month_dt <= DATE_TRUNC('month', cb.churn_date)
)
SELECT
    cb.customer_id,
    cb.churned_flag,
    cb.tenure_months,
    cb.tenure_band,
    cb.plan_type,
    cb.acquisition_channel,
    COUNT(vu.month)                                AS months_in_usage,
    -- Per-month averages (NULLs in minutes_active excluded from mean automatically)
    ROUND(AVG(vu.workouts_completed)::NUMERIC, 4)  AS avg_monthly_workouts,
    ROUND(AVG(vu.minutes_active)::NUMERIC, 4)      AS avg_monthly_minutes,
    ROUND(AVG(vu.classes_booked)::NUMERIC, 4)      AS avg_monthly_classes,
    ROUND(AVG(vu.support_tickets)::NUMERIC, 4)     AS avg_monthly_support,
    SUM(vu.support_tickets)                         AS total_support_tickets,
    CASE WHEN SUM(vu.support_tickets) > 0 THEN 1 ELSE 0 END AS any_support_contact
FROM peloton.customer_base cb
LEFT JOIN valid_usage vu ON cb.customer_id = vu.customer_id
GROUP BY cb.customer_id, cb.churned_flag, cb.tenure_months,
         cb.tenure_band, cb.plan_type, cb.acquisition_channel;

SELECT COUNT(*) AS summary_rows FROM peloton.customer_usage_summary;
-- Expected: 4,200


-- ── 4. ENGAGEMENT COMPARISON: CHURNED VS ACTIVE ───────────────
SELECT
    churned_flag,
    COUNT(*)                                    AS n,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_monthly_workouts)::NUMERIC, 2)
                                                AS median_workouts,
    ROUND(AVG(avg_monthly_workouts)::NUMERIC, 2) AS mean_workouts,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_monthly_minutes)::NUMERIC, 2)
                                                AS median_minutes,
    ROUND(AVG(avg_monthly_minutes)::NUMERIC, 2)  AS mean_minutes,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_monthly_classes)::NUMERIC, 2)
                                                AS median_classes,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_monthly_support)::NUMERIC, 3)
                                                AS median_support,
    ROUND(AVG(any_support_contact)::NUMERIC, 3) AS pct_any_support
FROM peloton.customer_usage_summary
GROUP BY churned_flag
ORDER BY churned_flag;
-- Expected: active median workouts ≈ 4.1; churned ≈ 2.0


-- ── 5. ZERO-WORKOUT CUSTOMERS ────────────────────────────────
-- What proportion had zero workouts on average?
SELECT
    churned_flag,
    COUNT(*)                                   AS n,
    COUNT(*) FILTER (WHERE avg_monthly_workouts = 0) AS zero_avg_workouts,
    ROUND(COUNT(*) FILTER (WHERE avg_monthly_workouts = 0)::NUMERIC / COUNT(*), 4)
                                               AS pct_zero_avg_workouts
FROM peloton.customer_usage_summary
GROUP BY churned_flag;


-- ── 6. SUPPORT TICKET ANALYSIS ───────────────────────────────
-- Average monthly support by churned status and cancel reason
SELECT
    cb.cancel_reason,
    cb.churned_flag,
    COUNT(*)                                   AS n,
    ROUND(AVG(cus.avg_monthly_workouts)::NUMERIC, 2) AS avg_workouts,
    ROUND(AVG(cus.avg_monthly_support)::NUMERIC, 3)  AS avg_support,
    ROUND(AVG(cus.any_support_contact)::NUMERIC, 3)  AS pct_any_support
FROM peloton.customer_base cb
JOIN peloton.customer_usage_summary cus ON cb.customer_id = cus.customer_id
WHERE cb.churned_flag = 1
  AND cb.cancel_reason != 'unknown'
GROUP BY cb.cancel_reason, cb.churned_flag
ORDER BY avg_workouts;
-- Key expected finding: technical_issues group pct_any_support = 1.000 (100%)
