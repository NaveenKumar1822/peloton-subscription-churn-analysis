-- ============================================================
-- 02_churn_definition.sql
-- Peloton Subscription Churn Analysis
-- Purpose: Define churn, build clean base table, compute
--          cumulative and monthly churn rates
-- ============================================================

-- ── 1. CREATE CLEANED SUBSCRIPTIONS BASE TABLE ───────────────
-- Applies: plan_tier normalisation; cancel_reason recoding;
--          observation_end_date; binary churn flag
DROP TABLE IF EXISTS peloton.customer_base;

CREATE TABLE peloton.customer_base AS
SELECT
    customer_id,
    signup_date,
    plan_type,
    LOWER(TRIM(plan_tier))            AS plan_tier,
    monthly_price,
    acquisition_channel,
    primary_device,
    age_group,
    churned,
    CASE WHEN churned = 'yes' THEN 1 ELSE 0 END AS churned_flag,
    churn_date,
    CASE
        WHEN churned = 'no'  THEN 'not_applicable'
        WHEN churned = 'yes' AND cancel_reason IS NULL THEN 'unknown'
        ELSE cancel_reason
    END                               AS cancel_reason,
    -- Observation end: churn date if churned, else analysis cutoff
    CASE
        WHEN churned = 'yes' THEN churn_date
        ELSE DATE '2025-12-31'
    END                               AS observation_end_date,
    -- Tenure: completed 30-day months (documented approximation)
    (CASE
        WHEN churned = 'yes' THEN churn_date
        ELSE DATE '2025-12-31'
    END - signup_date) / 30           AS tenure_months,
    -- Flag same-day cancellations
    CASE
        WHEN churned = 'yes' AND churn_date = signup_date THEN TRUE
        ELSE FALSE
    END                               AS zero_tenure
FROM peloton.subscriptions;

-- Validate row count
SELECT COUNT(*) AS customer_base_rows FROM peloton.customer_base;
-- Expected: 4,200


-- ── 2. ADD TENURE BAND ───────────────────────────────────────
ALTER TABLE peloton.customer_base ADD COLUMN tenure_band TEXT;

UPDATE peloton.customer_base
SET tenure_band = CASE
    WHEN tenure_months <= 1  THEN '0-1 month'
    WHEN tenure_months <= 3  THEN '2-3 months'
    WHEN tenure_months <= 6  THEN '4-6 months'
    WHEN tenure_months <= 12 THEN '7-12 months'
    ELSE '13+ months'
END;


-- ── 3. CUMULATIVE CHURN RATE ─────────────────────────────────
SELECT
    COUNT(*)                                              AS total_customers,
    SUM(churned_flag)                                     AS churned,
    COUNT(*) - SUM(churned_flag)                          AS active_censored,
    ROUND(SUM(churned_flag)::NUMERIC / COUNT(*), 4)       AS cumulative_churn_rate
FROM peloton.customer_base;
-- Expected: total=4200, churned=1768, rate≈0.4210


-- ── 4. MONTHLY CHURN RATE ─────────────────────────────────────
-- Denominator: customers active at START of each month
-- (signed up strictly before month start AND not yet churned)
-- Excludes same-month signups from denominator per approved methodology
WITH month_series AS (
    SELECT generate_series(
        '2024-08-01'::DATE,   -- first month with a valid denominator
        '2025-12-01'::DATE,
        INTERVAL '1 month'
    )::DATE AS month_start
),
monthly_stats AS (
    SELECT
        m.month_start,
        -- Denominator: active at start of month
        COUNT(s.customer_id) FILTER (
            WHERE s.signup_date < m.month_start
              AND (s.churn_date IS NULL OR s.churn_date >= m.month_start)
        ) AS active_at_start,
        -- Numerator: churned during this month
        COUNT(s.customer_id) FILTER (
            WHERE s.churn_date >= m.month_start
              AND s.churn_date <  m.month_start + INTERVAL '1 month'
        ) AS churns_in_month
    FROM month_series m
    CROSS JOIN peloton.subscriptions s
    GROUP BY m.month_start
)
SELECT
    TO_CHAR(month_start, 'YYYY-MM')                              AS month,
    active_at_start,
    churns_in_month,
    ROUND(churns_in_month::NUMERIC / NULLIF(active_at_start, 0), 4) AS monthly_churn_rate
FROM monthly_stats
WHERE active_at_start > 0
ORDER BY month_start;
-- Cross-validate against Python output: mean rate ≈ 6.7%


-- ── 5. CHURN RATE SUMMARY BY STATUS ─────────────────────────
SELECT
    churned                           AS status,
    COUNT(*)                          AS n,
    ROUND(COUNT(*)::NUMERIC / 4200, 4) AS pct_of_total,
    MIN(tenure_months)                AS min_tenure_months,
    ROUND(AVG(tenure_months), 1)      AS avg_tenure_months,
    MAX(tenure_months)                AS max_tenure_months
FROM peloton.customer_base
GROUP BY churned
ORDER BY churned;
