-- ============================================================
-- 01_data_quality.sql
-- Peloton Subscription Churn Analysis
-- Purpose: Systematic data-quality audit of raw tables
-- Database: PostgreSQL
-- ============================================================

-- ASSUMPTIONS:
--   Raw tables loaded as:
--     peloton.subscriptions  (from subscriptions.csv)
--     peloton.usage_raw      (from usage.csv)
--
--   Run this script BEFORE any cleaning to establish a baseline.
-- ============================================================


-- ── 1. ROW COUNTS ────────────────────────────────────────────
SELECT 'subscriptions' AS table_name, COUNT(*) AS row_count FROM peloton.subscriptions
UNION ALL
SELECT 'usage_raw',                   COUNT(*) FROM peloton.usage_raw;
-- Expected: subscriptions = 4,200 | usage_raw = 30,685


-- ── 2. MISSING VALUES: SUBSCRIPTIONS ─────────────────────────
SELECT
    COUNT(*)                                              AS total_rows,
    COUNT(*) FILTER (WHERE customer_id    IS NULL)       AS null_customer_id,
    COUNT(*) FILTER (WHERE signup_date    IS NULL)       AS null_signup_date,
    COUNT(*) FILTER (WHERE plan_type      IS NULL)       AS null_plan_type,
    COUNT(*) FILTER (WHERE plan_tier      IS NULL)       AS null_plan_tier,
    COUNT(*) FILTER (WHERE monthly_price  IS NULL)       AS null_monthly_price,
    COUNT(*) FILTER (WHERE acquisition_channel IS NULL)  AS null_acq_channel,
    COUNT(*) FILTER (WHERE primary_device IS NULL)       AS null_primary_device,
    COUNT(*) FILTER (WHERE age_group      IS NULL)       AS null_age_group,
    COUNT(*) FILTER (WHERE churned        IS NULL)       AS null_churned,
    COUNT(*) FILTER (WHERE churn_date     IS NULL)       AS null_churn_date,
    COUNT(*) FILTER (WHERE cancel_reason  IS NULL)       AS null_cancel_reason
FROM peloton.subscriptions;
-- Expected: null_churn_date = 2432 (active customers), null_cancel_reason = 2814


-- ── 3. MISSING VALUES: USAGE ──────────────────────────────────
SELECT
    COUNT(*)                                              AS total_rows,
    COUNT(*) FILTER (WHERE customer_id          IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE month                IS NULL) AS null_month,
    COUNT(*) FILTER (WHERE workouts_completed   IS NULL) AS null_workouts,
    COUNT(*) FILTER (WHERE minutes_active       IS NULL) AS null_minutes,
    COUNT(*) FILTER (WHERE classes_booked       IS NULL) AS null_classes,
    COUNT(*) FILTER (WHERE support_tickets      IS NULL) AS null_support
FROM peloton.usage_raw;
-- Expected: null_minutes = 506; all others = 0


-- ── 4. DUPLICATE RECORDS ──────────────────────────────────────
-- Duplicate customer_id in subscriptions (expected: 0)
SELECT COUNT(*) AS duplicate_customer_ids
FROM (
    SELECT customer_id, COUNT(*) AS n
    FROM peloton.subscriptions
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) dups;

-- Duplicate (customer_id, month) in usage (expected: 160)
SELECT COUNT(*) AS duplicate_customer_month_pairs
FROM (
    SELECT customer_id, month, COUNT(*) AS n
    FROM peloton.usage_raw
    GROUP BY customer_id, month
    HAVING COUNT(*) > 1
) dups;

-- Are duplicate usage rows fully identical? (expected: yes — export artifact)
SELECT
    COUNT(*) AS total_usage_rows,
    COUNT(DISTINCT (customer_id, month, workouts_completed,
                    minutes_active, classes_booked, support_tickets)) AS distinct_full_rows
FROM peloton.usage_raw;


-- ── 5. CONSISTENCY: plan_tier CAPITALISATION ──────────────────
SELECT plan_tier, COUNT(*) AS n
FROM peloton.subscriptions
GROUP BY plan_tier
ORDER BY plan_tier;
-- Expected: mix of 'basic'/'Basic', 'plus'/'Plus', 'premium'/'Premium'


-- ── 6. CONSISTENCY: ALL CATEGORICAL COLUMNS ──────────────────
SELECT plan_type,          COUNT(*) FROM peloton.subscriptions GROUP BY 1 ORDER BY 1;
SELECT acquisition_channel,COUNT(*) FROM peloton.subscriptions GROUP BY 1 ORDER BY 1;
SELECT primary_device,     COUNT(*) FROM peloton.subscriptions GROUP BY 1 ORDER BY 1;
SELECT age_group,          COUNT(*) FROM peloton.subscriptions GROUP BY 1 ORDER BY 1;
SELECT churned,            COUNT(*) FROM peloton.subscriptions GROUP BY 1 ORDER BY 1;
SELECT cancel_reason,      COUNT(*) FROM peloton.subscriptions GROUP BY 1 ORDER BY 1 NULLS FIRST;


-- ── 7. VALIDITY: DATE LOGIC ───────────────────────────────────
-- churn_date before signup_date (expected: 0)
SELECT COUNT(*) AS churn_before_signup
FROM peloton.subscriptions
WHERE churn_date < signup_date;

-- churned=yes without a churn_date (expected: 0)
SELECT COUNT(*) AS churned_no_date
FROM peloton.subscriptions
WHERE churned = 'yes' AND churn_date IS NULL;

-- churned=no with a churn_date (expected: 0)
SELECT COUNT(*) AS active_has_date
FROM peloton.subscriptions
WHERE churned = 'no' AND churn_date IS NOT NULL;

-- churned=no with a cancel_reason (expected: 0)
SELECT COUNT(*) AS active_has_reason
FROM peloton.subscriptions
WHERE churned = 'no' AND cancel_reason IS NOT NULL;

-- Zero-tenure customers (churn_date = signup_date)
SELECT COUNT(*) AS zero_tenure_customers
FROM peloton.subscriptions
WHERE churn_date = signup_date;


-- ── 8. VALIDITY: NUMERIC RANGES ───────────────────────────────
SELECT
    MIN(monthly_price)  AS price_min,
    MAX(monthly_price)  AS price_max,
    COUNT(DISTINCT monthly_price) AS distinct_price_points
FROM peloton.subscriptions;

SELECT
    MIN(workouts_completed) AS workouts_min, MAX(workouts_completed) AS workouts_max,
    MIN(minutes_active)     AS minutes_min,  MAX(minutes_active)     AS minutes_max,
    MIN(classes_booked)     AS classes_min,  MAX(classes_booked)     AS classes_max,
    MIN(support_tickets)    AS support_min,  MAX(support_tickets)    AS support_max
FROM peloton.usage_raw;
-- Expected: no negative values anywhere


-- ── 9. VALIDITY: USAGE AFTER CHURN (expected: 0) ─────────────
SELECT COUNT(*) AS post_churn_usage_rows
FROM peloton.usage_raw u
JOIN peloton.subscriptions s ON u.customer_id = s.customer_id
WHERE s.churned = 'yes'
  AND TO_DATE(u.month, 'YYYY-MM') > DATE_TRUNC('month', s.churn_date);


-- ── 10. REFERENTIAL INTEGRITY ─────────────────────────────────
-- IDs in usage not in subscriptions (expected: 0)
SELECT COUNT(DISTINCT u.customer_id) AS orphan_usage_ids
FROM peloton.usage_raw u
LEFT JOIN peloton.subscriptions s ON u.customer_id = s.customer_id
WHERE s.customer_id IS NULL;

-- IDs in subscriptions not in usage (expected: 0)
SELECT COUNT(DISTINCT s.customer_id) AS missing_usage_ids
FROM peloton.subscriptions s
LEFT JOIN peloton.usage_raw u ON s.customer_id = u.customer_id
WHERE u.customer_id IS NULL;


-- ── 11. DATE RANGES ───────────────────────────────────────────
SELECT
    MIN(signup_date) AS signup_min,
    MAX(signup_date) AS signup_max,
    MIN(churn_date)  AS churn_min,
    MAX(churn_date)  AS churn_max
FROM peloton.subscriptions;
-- Expected: signup 2024-07-01 to 2025-10-30 | churn 2024-07-02 to 2025-12-31

SELECT
    MIN(TO_DATE(month, 'YYYY-MM')) AS usage_month_min,
    MAX(TO_DATE(month, 'YYYY-MM')) AS usage_month_max
FROM peloton.usage_raw;
-- Expected: 2024-07 to 2025-12
