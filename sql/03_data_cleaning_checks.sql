USE olist;

-- =====================================================
-- 1. Row Count Validation
-- =====================================================
-- Count the number of records loaded into each table
-- to confirm that all nine Olist datasets were imported.

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'category_translation', COUNT(*) FROM category_translation
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews;

-- Results:
-- customers:             99,441 rows
-- sellers:                3,095 rows
-- products:              32,951 rows
-- category_translation:      71 rows
-- geolocation:         1,000,163 rows
-- orders:                 99,441 rows
-- order_items:           112,650 rows
-- order_payments:        103,886 rows
-- order_reviews:          99,223 rows


-- =====================================================
-- 2. Duplicate Check
-- =====================================================
-- Check whether any order_id appears more than once.
-- order_id should uniquely identify each order.

SELECT 
    order_id, 
    COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Result: No duplicate order_id values found.


-- =====================================================
-- 3. Orphan Checks: Order Items
-- =====================================================
-- Check that every order, product, and seller referenced
-- in order_items has a corresponding record in its parent table.


-- Check for order_items referencing orders that do not exist.

SELECT COUNT(*) AS missing_orders
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Result: 0 missing orders.


-- Check for order_items referencing products that do not exist.

SELECT COUNT(*) AS missing_products
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Result: 0 missing products.


-- Check for order_items referencing sellers that do not exist.

SELECT COUNT(*) AS missing_sellers
FROM order_items oi
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- Result: 0 missing sellers.