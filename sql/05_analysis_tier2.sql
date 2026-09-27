-- =====================================================
-- TIER 2: INTERMEDIATE ANALYSIS
-- Multi-joins, CTEs, conditional aggregation, and dates
-- =====================================================
-- =====================================================
-- Q9. Month-over-Month Revenue Growth
-- What is the month-over-month revenue growth percentage?
-- Use the LAG() window function to compare each month
-- with the previous month.
-- =====================================================
WITH monthly_revenue AS( 
	SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month, SUM(oi.price) AS revenue 
    FROM orders o
    JOIN order_items oi
		ON o.order_id = oi.order_id
	WHERE o.order_status = 'delivered'
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
    ),
    
    revenue_with_lag AS(
		SELECT month, revenue, LAG(revenue, 1) OVER( ORDER BY month) AS previous_month_revenue
        FROM monthly_revenue
    )
SELECT month,ROUND(revenue, 2) AS revenue, ROUND(previous_month_revenue,2) AS previous_month_revenue, 
	ROUND((((revenue -  previous_month_revenue) * 100)/  previous_month_revenue) , 2) AS monthly_growth_percentage 
FROM revenue_with_lag
ORDER BY month;
-- Results:
-- Revenue showed substantial month-to-month growth during much of 2017,
-- including a 52.37% increase in November 2017.
-- Revenue then declined 26.50% in December 2017 before rebounding
-- 27.36% in January 2018.
-- Revenue growth was more stable in 2018, with smaller increases and declines.
-- Early months contain sparse data and a missing November 2016,
-- so their extreme growth rates should be interpreted cautiously.

-- =====================================================
-- Q10. Average Delivery Time
-- What is the average delivery time in days
-- (delivered date - purchase date), overall and by state?
-- =====================================================
SELECT ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)),2) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered'
    AND order_delivered_customer_date IS NOT NULL;
    
SELECT c.customer_state, ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)),2) AS avg_delivery_days
FROM orders o 
JOIN customers c 
	ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;
-- Results:
-- The overall average delivery time for delivered orders was 12.50 days.
-- Delivery times varied substantially by customer state.
-- Roraima (RR) had the longest average delivery time at 29.34 days,
-- followed by Amapá (AP) at 27.18 days and Amazonas (AM) at 26.36 days.
-- São Paulo (SP) had the shortest average delivery time at 8.70 days.

-- =====================================================
-- Q11. On-Time vs Late Delivery Rate
-- What percentage of orders were delivered on time vs late?
-- What is the late-delivery rate by customer state?
-- =====================================================
SELECT COUNT(*) AS total_deliveries, 
SUM( 
CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date 
	THEN 1
    ELSE 0
END
) AS on_time_deliverables,

SUM(
CASE WHEN  order_delivered_customer_date > order_estimated_delivery_date 
	THEN 1 
    ELSE 0
END
) AS late_deliverables, 

ROUND(100.0* SUM(
            CASE WHEN order_delivered_customer_date > order_estimated_delivery_date 
                THEN 1 
                ELSE 0 
            END
        ) / COUNT(*),
        2) AS late_percentage 
FROM orders 
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL AND order_estimated_delivery_date IS NOT NULL;

-- Part 2: Late delivery rate by customer state

SELECT
    c.customer_state,
    COUNT(*) AS total_deliveries,

    SUM(
        CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_deliveries,

    ROUND(
        100.0 * SUM(
            CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS late_percentage

FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY late_percentage DESC;

-- Results:
-- Of 96,470 delivered orders with valid delivery dates, 88,644 were
-- delivered on time and 7,826 were delivered late.
-- Overall, 91.89% of deliveries were on time and 8.11% were late.
-- Late-delivery rates varied substantially by customer state.
-- Alagoas (AL) had the highest late-delivery rate at 23.93%,
-- followed by Maranhão (MA) at 19.67%.
-- Rondônia (RO) had the lowest late-delivery rate at 2.88%.
-- State-level rates should be interpreted alongside delivery volume,
-- since some states contain relatively few orders.

-- =====================================================
-- Q12. Late Delivery and Review Scores
-- Does late delivery lower review scores?
-- Compare the average review score for on-time vs late orders.
-- =====================================================

SELECT CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
	THEN 'On Time' 
ELSE 'LATE'
END AS delivery_status, COUNT(*) AS review_count, ROUND(AVG(r.review_score),2) AS avg_review_score

FROM orders o 
JOIN order_reviews r
	ON o.order_id = r.order_id
WHERE  o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_status;

-- Results:
-- On-time deliveries had an average review score of 4.29.
-- Late deliveries had an average review score of 2.57.
-- Late deliveries received review scores that were 1.72 points lower
-- on average than on-time deliveries.
-- This shows a strong association between late delivery and lower
-- customer review scores.

-- =====================================================
-- Q13. Seller Revenue and GMV Concentration
-- Who are the top sellers by revenue?
-- What share of GMV comes from the top 10% of sellers?
-- =====================================================
SELECT s.seller_id, s.seller_city, s.seller_state, ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN orders o 
	ON oi.order_id = o.order_id
JOIN sellers s
	ON oi.seller_id = s.seller_id 
WHERE o.order_status = 'delivered'
GROUP BY  s.seller_id, s.seller_city, s.seller_state
ORDER BY revenue DESC
LIMIT 10;

WITH seller_revenue AS (
    SELECT 
        oi.seller_id, 
        SUM(oi.price) AS revenue
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
),

seller_groups AS (
    SELECT 
        seller_id, 
        revenue, 
        NTILE(10) OVER (ORDER BY revenue DESC) AS seller_decile
    FROM seller_revenue
)

SELECT 
    ROUND(SUM(revenue), 2) AS total_gmv,

    ROUND(
        SUM(
            CASE 
                WHEN seller_decile = 1 THEN revenue
                ELSE 0
            END
        ),
        2
    ) AS top_10_percent_gmv,

    ROUND(
        100.0 * SUM(
            CASE 
                WHEN seller_decile = 1 THEN revenue
                ELSE 0
            END
        ) / SUM(revenue),
        2
    ) AS top_10_percent_gmv_share

FROM seller_groups;

-- Results:
-- The highest-revenue seller generated $226,987.93 in merchandise revenue.
-- Eight of the top 10 revenue-generating sellers were located in São Paulo (SP).
-- Total GMV from delivered orders was $13,221,498.11.
-- The top 10% of sellers generated $8,873,076.37, accounting for
-- 67.11% of total GMV.
-- This indicates that GMV is highly concentrated among the marketplace's
-- highest-revenue sellers.

-- =====================================================
-- Q14. Freight Cost as a Percentage of Item Price
-- What is freight cost as a percentage of item price?
-- Compare this percentage by product category and customer state.
-- =====================================================
SELECT ct.product_category_name_english AS category, ROUND(SUM(oi.price),2) AS total_item_value, ROUND(SUM(oi.freight_value),2) AS total_freight, 
ROUND((SUM(oi.freight_value)*100.0) / SUM(oi.price), 2) AS freight_percentage 
FROM order_items oi
JOIN orders o
	ON oi.order_id = o.order_id
JOIN products p 
	ON oi.product_id = p.product_id
JOIN category_translation ct
	ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'

GROUP BY ct.product_category_name_english
ORDER BY freight_percentage DESC;

SELECT
    c.customer_state,

    ROUND(SUM(oi.price), 2) AS total_item_value,

    ROUND(SUM(oi.freight_value), 2) AS total_freight,

    ROUND(
        (SUM(oi.freight_value) * 100.0) / SUM(oi.price),
        2
    ) AS freight_percentage

FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN customers c
    ON o.customer_id = c.customer_id

WHERE o.order_status = 'delivered'

GROUP BY c.customer_state
ORDER BY freight_percentage DESC;

-- Results:
-- Freight costs varied substantially across product categories.
-- Home Comfort 2 had the highest freight-to-item-value ratio at 53.97%,
-- followed by Flowers at 44.04%, while Computers had the lowest at 4.42%.
-- Some categories with very high freight percentages had relatively low
-- merchandise value, so these percentages should be interpreted alongside volume.
--
-- Freight burden also varied by customer state.
-- Roraima (RR) had the highest freight-to-item-value ratio at 28.08%,
-- followed by Maranhão (MA) at 26.32%.
-- São Paulo (SP) had the lowest freight-to-item-value ratio at 13.85%.
-- Overall, the results show meaningful variation in shipping costs across
-- both product categories and customer locations.

-- =====================================================
-- Q15. Review Scores by Product Category
-- What is the average review score by product category?
-- Which categories are the best- and worst-rated?
-- =====================================================

WITH category_reviews AS (
	SELECT ct.product_category_name_english AS category, COUNT(*) AS review_count, AVG(r.review_score) AS avg_review_score
    FROM order_reviews r
    JOIN order_items oi
		ON r.order_id = oi.order_id
	 JOIN products p
        ON oi.product_id = p.product_id
    JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name
	GROUP BY ct.product_category_name_english
)

SELECT category, review_count, ROUND(avg_review_score, 2) AS avg_review_score,
RANK() OVER( ORDER BY avg_review_score DESC) AS best_rating_rank, 
RANK() OVER( ORDER BY avg_review_score ASC) AS worst_rating_rank
FROM category_reviews
ORDER BY avg_review_score DESC;

-- Results:
-- CDS/DVDs/Musicals had the highest average review score at 4.64,
-- while Security and Services had the lowest at 2.50.
-- However, these categories had only 14 and 2 review records,
-- respectively, so their rankings are based on very small samples.
--
-- Among categories with more substantial review volume,
-- Books General Interest performed strongly with an average score
-- of 4.45 across 549 review records.
-- Office Furniture stood out on the lower end with an average
-- score of 3.49 across 1,687 review records.
-- Review counts should therefore be considered alongside average
-- scores when comparing category performance.

-- =====================================================
-- Q16. Order Value and Payment Installments
-- Does order value rise with the number of installments?
-- =====================================================
WITH order_values AS(
SELECT oi.order_id, SUM(oi.price) AS order_values
FROM order_items oi
JOIN orders o
	ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.order_id
), 

payment_installments AS(
SELECT order_id, MAX(payment_installments) AS installments 
FROM order_payments 
GROUP BY order_id
)
SELECT pi.installments, COUNT(*) AS order_count, ROUND(AVG(ov.order_values),2) AS avg_order_value
FROM order_values ov 
JOIN payment_installments pi 
	ON ov.order_id = pi.order_id
GROUP BY pi.installments
ORDER BY pi.installments;

-- Results:
-- Average order value generally increased as the number of payment
-- installments increased.
-- Orders paid in 1 installment averaged $99.94, compared with
-- $107.77 for 2 installments, $121.49 for 3, $141.25 for 4,
-- $158.93 for 5, and $183.11 for 6 installments.
-- The relationship was not perfectly linear at higher installment counts.
-- Many of these groups contained relatively few orders, making their
-- average order values more volatile.
-- Overall, the results show an association between higher installment
-- counts and larger order values, particularly among the most common
-- installment options.