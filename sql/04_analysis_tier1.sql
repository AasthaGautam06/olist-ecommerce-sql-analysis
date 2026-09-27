-- =====================================================
-- Tier 1: Foundation Analysis
-- =====================================================

-- =====================================================
-- Q1. Dataset Overview
-- How many orders, distinct customers, sellers, and
-- products are in the data, and what date range
-- does the dataset cover?
-- =====================================================
SELECT 'Orders' AS metric, COUNT(*) AS total_count
FROM orders

UNION ALL

SELECT 'Distinct Customers', COUNT(DISTINCT customer_unique_id)
FROM customers

UNION ALL

SELECT 'Sellers', COUNT(*)
FROM sellers

UNION ALL

SELECT 'Products', COUNT(*)
FROM products;

SELECT
    MIN(order_purchase_timestamp) AS earliest_purchase,
    MAX(order_purchase_timestamp) AS latest_purchase
FROM orders;

-- Results:
-- Orders: 99,441
-- Distinct customers: 96,096
-- Sellers: 3,095
-- Products: 32,951
-- Purchase date range: September 4, 2016 to October 17, 2018.

-- =====================================================
-- Q2. Order Status Distribution
-- What is the distribution of order_status?
-- What share of orders are actually delivered?
-- =====================================================
SELECT order_status, COUNT(*) AS order_count FROM orders GROUP BY order_status ORDER BY order_count DESC;
SELECT ROUND(100.0 * SUM(order_status = "delivered") / COUNT(*), 2) AS delivered_percentage FROM orders;

-- Results:
-- Delivered was the most common order status with 96,478 orders.
-- 97.02% of all orders in the dataset were delivered.

-- =====================================================
-- Q3. Monthly Orders and Revenue Over Time
-- What is the monthly trend in orders and revenue?
-- =====================================================
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY month;
-- Results:
-- Monthly order volume and revenue generally increased throughout 2017
-- and remained at high levels throughout 2018.
-- November 2017 had the highest order volume with 7,289 delivered orders.
-- May 2018 generated the highest monthly revenue at $977,544.69.
-- Early 2016 contains very few orders, so those months should be interpreted
-- cautiously when evaluating the overall trend.

-- =====================================================
-- Q4. Top Product Categories
-- What are the top 10 product categories by revenue and order count?
-- Use the English category names from the translation table.
-- =====================================================
SELECT * FROM products;

SELECT ct.product_category_name_english AS category, COUNT(DISTINCT oi.order_id) AS order_count, ROUND(SUM(oi.price),2) AS revenue 
FROM products p
JOIN category_translation ct
	ON p.product_category_name  = ct.product_category_name
JOIN order_items oi 
	ON p.product_id = oi.product_id
GROUP BY ct.product_category_name_english
ORDER BY revenue DESC
LIMIT 10;

-- Results:
-- Health & Beauty generated the highest revenue at $1,258,681.34.
-- Watches & Gifts ranked second in revenue at $1,205,005.68.
-- Bed, Bath & Table had the highest order count among the top 10
-- revenue-generating categories, with 9,417 orders.

-- =====================================================
-- Q5. Average Order Value and Items per Order
-- What is the average order value (AOV)?
-- What is the average number of items per order?
-- =====================================================
SELECT ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS average_order_value
FROM orders o 
JOIN order_items oi 
	ON o.order_id = oi.order_id 
WHERE o.order_status = 'delivered';

SELECT ROUND(COUNT(*) / COUNT(DISTINCT o.order_id),2) AS average_items_per_order
FROM orders o
JOIN order_items oi
	ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';
-- Results:
-- The average delivered order generated $137.04 in merchandise revenue.
-- Delivered orders contained an average of 1.14 items per order.

-- =====================================================
-- Q6. Payment Type and Installment Analysis
-- What is the payment-type mix?
-- What is the average number of installments by payment type?
-- =====================================================
SELECT DISTINCT payment_type FROM order_payments;
SELECT payment_type, COUNT(*) AS payment_count, ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS payment_percentage, ROUND(AVG(payment_installments), 2) AS avg_installments
FROM order_payments 
GROUP BY payment_type
ORDER BY payment_count DESC;
-- Results:
-- Credit cards were the dominant payment method, accounting for 73.92% of payments.
-- Boleto was the second most common payment method at 19.04%.
-- Credit card payments averaged 3.51 installments, while boleto, voucher,
-- and debit card payments averaged 1 installment.

-- =====================================================
-- Q7. Orders and Revenue by Customer State
-- Which customer states generate the most orders and revenue?
-- =====================================================
SELECT c.customer_state, COUNT(DISTINCT o.order_id) AS order_count, ROUND(SUM(oi.price),2) AS revenue 
FROM customers c 
JOIN orders o 
	ON c.customer_id = o.customer_id
JOIN order_items oi
	ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state 
ORDER BY revenue DESC; 
-- Results:
-- São Paulo (SP) generated the most activity with 40,501 delivered orders
-- and $5,067,633.16 in merchandise revenue.
-- Rio de Janeiro (RJ) ranked second with 12,350 orders and $1,759,651.13
-- in revenue, followed by Minas Gerais (MG) with 11,354 orders
-- and $1,552,481.83 in revenue.
-- Order volume and revenue are heavily concentrated in SP compared with
-- the other Brazilian states.

-- =====================================================
-- Q8. Review Score Analysis
-- What is the overall average review score?
-- What is the distribution of review scores from 1 to 5?
-- =====================================================
SELECT
    ROUND(AVG(review_score), 2) AS average_review_score
FROM order_reviews;

SELECT review_score, COUNT(*) AS review_count
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

-- Results:
-- The overall average review score was 4.09 out of 5.
-- Five-star reviews were the most common, with 57,327 reviews.
-- Four-star reviews were the second most common, with 19,142 reviews.
-- Lower ratings were substantially less common than positive ratings.