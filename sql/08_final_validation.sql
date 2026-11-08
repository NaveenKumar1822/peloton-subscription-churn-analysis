-- ============================================================
-- 08_final_validation.sql
-- Peloton Subscription Churn Analysis
-- Purpose: Cross-validate Python notebook results using SQL.
--          All numbers here should match the notebook output.
-- Depends on: all previous SQL tables
-- ============================================================


-- ── 1. ROW COUNT CROSS-VALIDATION ────────────────────────────
-- These numbers must match Python output exactly
SELECT 'customer_base'           AS table_name, COUNT(*) AS rows FROM peloton.customer_base
UNION ALL
SELECT 'usage_clean',                           COUNT(*)         FROM peloton.usage_clean
UNION ALL
SELECT 'customer_usage_summary',                COUNT(*)         FROM peloton.customer_usage_summary
UNION ALL
SELECT 'first_month_usage',                     COUNT(*)         FROM peloton.first_month_usage;
-- Expected: 4200 | 30525 | 4200 | 4200


-- ── 2. OVERALL CHURN — CROSS-VALIDATE WITH PYTHON ────────────
SELECT
    SUM(churned_flag)                                     AS churned,
    COUNT(*) - SUM(churned_flag)                          AS active,
    COUNT(*)                                              AS total,
    ROUND(SUM(churned_flag)::NUMERIC / COUNT(*), 4)       AS churn_rate
FROM peloton.customer_base;
-- Expected: churned=1768, active=2432, total=4200, rate=0.4210


-- ── 3. ZERO-TENURE CUSTOMERS ─────────────────────────────────
SELECT COUNT(*) AS zero_tenure_customers FROM peloton.customer_base WHERE zero_tenure = TRUE;
-- Expected: 7


-- ── 4. PLAN TYPE CHURN RATES ─────────────────────────────────
SELECT plan_type, COUNT(*) AS n,
       ROUND(AVG(churned_flag::NUMERIC), 4) AS churn_rate
FROM peloton.customer_base GROUP BY plan_type ORDER BY plan_type;
-- Expected: annual ≈ 0.2638, monthly ≈ 0.5118


-- ── 5. ACQUISITION CHANNEL CHURN RATES ───────────────────────
SELECT acquisition_channel,
       COUNT(*) AS n,
       ROUND(AVG(churned_flag::NUMERIC), 4) AS churn_rate
FROM peloton.customer_base
GROUP BY acquisition_channel ORDER BY churn_rate DESC;
-- Expected: promo_offer = 0.5079 (highest); referral = 0.3381 (lowest)


-- ── 6. ENGAGEMENT MEDIANS ─────────────────────────────────────
SELECT
    churned_flag,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_monthly_workouts)::NUMERIC, 2)
        AS median_workouts,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_monthly_minutes)::NUMERIC, 2)
        AS median_minutes
FROM peloton.customer_usage_summary
GROUP BY churned_flag ORDER BY churned_flag;
-- Expected: active workouts ≈ 4.12, churned ≈ 2.00
-- Expected: active minutes ≈ 123.26, churned ≈ 62.14


-- ── 7. FIRST-MONTH ZERO-WORKOUT RATES ────────────────────────
SELECT
    churned_flag,
    ROUND(COUNT(*) FILTER (WHERE fm_workouts = 0)::NUMERIC / COUNT(*), 4)
        AS pct_zero_fm_workouts
FROM peloton.first_month_usage
GROUP BY churned_flag ORDER BY churned_flag;
-- Expected: active ≈ 0.065, churned ≈ 0.129


-- ── 8. CANCEL REASON COVERAGE ────────────────────────────────
SELECT
    CASE WHEN cancel_reason = 'unknown' THEN 'unknown' ELSE 'known' END AS reason_known,
    COUNT(*) AS n,
    ROUND(COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM peloton.customer_base WHERE churned_flag = 1), 4) AS pct
FROM peloton.customer_base
WHERE churned_flag = 1
GROUP BY 1;
-- Expected: known ≈ 78.4%, unknown ≈ 21.6%


-- ── 9. PROMO WITHIN PLAN TYPE VALIDATION ─────────────────────
SELECT
    plan_type,
    CASE WHEN acquisition_channel = 'promo_offer' THEN 'promo' ELSE 'non-promo' END AS ch_group,
    COUNT(*) AS n,
    ROUND(AVG(churned_flag::NUMERIC), 4) AS churn_rate
FROM peloton.customer_base
GROUP BY plan_type, ch_group
ORDER BY plan_type, ch_group;
-- Expected: monthly/promo ≈ 0.6330; monthly/non-promo ≈ 0.4769


-- ── 10. ANNUAL RENEWAL WINDOW ────────────────────────────────
SELECT
    ROUND(COUNT(*) FILTER (WHERE tenure_months BETWEEN 10 AND 14)::NUMERIC / COUNT(*), 4)
        AS pct_annual_churners_in_renewal_window
FROM peloton.customer_base
WHERE plan_type = 'annual' AND churned_flag = 1;
-- Expected: ≈ 0.7586 (75.9%)


-- ── 11. TECHNICAL ISSUES — SUPPORT CORROBORATION ─────────────
SELECT
    cb.cancel_reason,
    COUNT(*)                                             AS n,
    ROUND(AVG(cus.any_support_contact::NUMERIC), 4)     AS pct_any_support_contact
FROM peloton.customer_base cb
JOIN peloton.customer_usage_summary cus ON cb.customer_id = cus.customer_id
WHERE cb.churned_flag = 1
  AND cb.cancel_reason IN ('technical_issues', 'not_using_enough', 'too_expensive')
GROUP BY cb.cancel_reason
ORDER BY cb.cancel_reason;
-- Expected: technical_issues pct_any_support = 1.0000 (100%)
-- Expected: not_using_enough has lowest avg_workouts of all reason groups


-- ── 12. FINAL SIGN-OFF CHECKLIST ─────────────────────────────
-- Run this last; confirms all expected values match within rounding tolerance
WITH checks AS (
    SELECT 'total_customers'              AS check_name, COUNT(*)::TEXT AS actual, '4200'   AS expected FROM peloton.customer_base
    UNION ALL
    SELECT 'total_churned',   SUM(churned_flag)::TEXT,  '1768'  FROM peloton.customer_base
    UNION ALL
    SELECT 'usage_clean_rows', COUNT(*)::TEXT,           '30525' FROM peloton.usage_clean
    UNION ALL
    SELECT 'zero_tenure',     COUNT(*)::TEXT,            '7'     FROM peloton.customer_base WHERE zero_tenure
    UNION ALL
    SELECT 'fm_churners',     COUNT(*)::TEXT,            '151'   FROM peloton.first_month_usage WHERE first_month_churner
)
SELECT
    check_name,
    actual,
    expected,
    CASE WHEN actual = expected THEN 'PASS' ELSE 'FAIL' END AS status
FROM checks
ORDER BY check_name;
