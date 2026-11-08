-- ============================================================
-- 04_customer_segmentation.sql
-- Peloton Subscription Churn Analysis
-- Purpose: Churn rates across all subscription characteristics
-- Depends on: peloton.customer_base (02_churn_definition.sql)
-- ============================================================


-- ── 1. CHURN BY PLAN TYPE ─────────────────────────────────────
SELECT
    plan_type,
    COUNT(*)                          AS n,
    SUM(churned_flag)                 AS churned,
    ROUND(SUM(churned_flag)::NUMERIC / COUNT(*), 4) AS churn_rate
FROM peloton.customer_base
GROUP BY plan_type
ORDER BY churn_rate DESC;
-- Expected: monthly ≈ 51.2%, annual ≈ 26.4% (Δ = 24.8pp)


-- ── 2. CHURN BY PLAN TIER ─────────────────────────────────────
SELECT
    plan_tier,
    COUNT(*)                          AS n,
    SUM(churned_flag)                 AS churned,
    ROUND(SUM(churned_flag)::NUMERIC / COUNT(*), 4) AS churn_rate
FROM peloton.customer_base
GROUP BY plan_tier
ORDER BY churn_rate DESC;
-- Expected: basic ≈ 42.1%, plus ≈ 41.5%, premium ≈ 43.4% — negligible difference


-- ── 3. PRICE POINTS PER PLAN ──────────────────────────────────
SELECT
    plan_type,
    plan_tier,
    monthly_price,
    COUNT(*) AS n,
    ROUND(SUM(churned_flag)::NUMERIC / COUNT(*), 4) AS churn_rate
FROM peloton.customer_base
GROUP BY plan_type, plan_tier, monthly_price
ORDER BY plan_type, plan_tier, monthly_price;


-- ── 4. CHURN BY ACQUISITION CHANNEL ──────────────────────────
SELECT
    acquisition_channel,
    COUNT(*)                          AS n,
    SUM(churned_flag)                 AS churned,
    ROUND(SUM(churned_flag)::NUMERIC / COUNT(*), 4) AS churn_rate
FROM peloton.customer_base
GROUP BY acquisition_channel
ORDER BY churn_rate DESC;
-- Expected: promo_offer ≈ 50.8% (highest); referral ≈ 33.8% (lowest)


-- ── 5. CHURN BY PRIMARY DEVICE ────────────────────────────────
SELECT
    primary_device,
    COUNT(*)                          AS n,
    SUM(churned_flag)                 AS churned,
    ROUND(SUM(churned_flag)::NUMERIC / COUNT(*), 4) AS churn_rate
FROM peloton.customer_base
GROUP BY primary_device
ORDER BY churn_rate DESC;
-- Expected: android ≈ 45.0% (highest); ios ≈ 40.4%, web ≈ 40.4%


-- ── 6. CHURN BY AGE GROUP ─────────────────────────────────────
SELECT
    age_group,
    COUNT(*)                          AS n,
    SUM(churned_flag)                 AS churned,
    ROUND(SUM(churned_flag)::NUMERIC / COUNT(*), 4) AS churn_rate
FROM peloton.customer_base
GROUP BY age_group
ORDER BY churn_rate DESC;
-- Expected: 55+ group lowest churn (38.9%); other groups ~42–43%


-- ── 7. CANCELLATION REASON DISTRIBUTION ─────────────────────
-- Among churned customers with known reasons only
SELECT
    cancel_reason,
    COUNT(*)                          AS n,
    ROUND(COUNT(*)::NUMERIC / (
        SELECT COUNT(*) FROM peloton.customer_base
        WHERE churned_flag = 1 AND cancel_reason != 'unknown'
    ), 4) AS pct_of_known_reasons,
    ROUND(COUNT(*)::NUMERIC / (
        SELECT COUNT(*) FROM peloton.customer_base WHERE churned_flag = 1
    ), 4) AS pct_of_all_churners
FROM peloton.customer_base
WHERE churned_flag = 1
GROUP BY cancel_reason
ORDER BY n DESC;


-- ── 8. MULTI-DIMENSIONAL: PLAN TYPE × ACQUISITION CHANNEL ────
SELECT
    plan_type,
    acquisition_channel,
    COUNT(*)                          AS n,
    SUM(churned_flag)                 AS churned,
    ROUND(SUM(churned_flag)::NUMERIC / COUNT(*), 4) AS churn_rate
FROM peloton.customer_base
GROUP BY plan_type, acquisition_channel
ORDER BY plan_type, churn_rate DESC;
-- Useful for: identifying whether promo churn is driven by plan type overlap
