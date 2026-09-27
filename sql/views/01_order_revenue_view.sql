-- =====================================================
-- ORDER REVENUE VIEW
-- Creates a reusable order-level revenue dataset
-- for use across multiple analyses.
-- =====================================================

CREATE OR REPLACE VIEW order_revenue AS

SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    SUM(oi.price) AS order_revenue
FROM orders o
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp;