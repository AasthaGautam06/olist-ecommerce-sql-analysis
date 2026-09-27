-- =====================================================
-- TIER 3: ADVANCED ANALYSIS
-- Window functions, cohort analysis, segmentation,
-- and advanced business metrics
-- =====================================================

-- =====================================================
-- Q17. New vs Returning Customers by Month
-- How many new vs returning customers were there each month?
-- Identify each customer's first order using customer_unique_id.
-- =====================================================
WITH first_purchase AS(
SELECT c.customer_unique_id, MIN(o.order_purchase_timestamp) AS first_purchase_date
FROM orders o
JOIN customers c 
	ON o.customer_id = c.customer_id
GROUP BY c.customer_unique_id
),

customer_orders AS(
	SELECT c.customer_unique_id, DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m' ) AS month, 
    
    CASE WHEN DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m' )  = DATE_FORMAT(fp.first_purchase_date, '%Y-%m' )
		THEN 'New'
        ELSE 'Returning'
	END AS customer_type 
FROM orders o 
JOIN customers c 
	ON o.customer_id = c.customer_id
JOIN first_purchase fp
	ON c.customer_unique_id = fp.customer_unique_id
)

SELECT month, customer_type, COUNT(DISTINCT customer_unique_id) AS customer_count 
FROM customer_orders
GROUP BY month, customer_type
ORDER BY month, customer_type;
-- Results:
-- New customers made up the large majority of active customers each month.
-- Returning customer activity gradually increased as the marketplace matured,
-- reaching 192 returning customers in May 2018.
-- In May 2018, there were 6,622 new customers compared with 192 returning
-- customers, showing that customer activity was still heavily driven by
-- first-time buyers.
-- The final months of the dataset contain very little activity and should
-- therefore be interpreted cautiously.

-- =====================================================
-- Q18. Cohort Retention
-- Group customers by acquisition month and measure
-- repeat-purchase behavior in subsequent months.
-- =====================================================
WITH customer_cohorts AS (
    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_purchase_date
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),

customer_activity AS (
    SELECT
        cc.customer_unique_id,
        DATE_FORMAT(cc.first_purchase_date, '%Y-%m') AS acquisition_month,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
        TIMESTAMPDIFF(
            MONTH,
            DATE_FORMAT(cc.first_purchase_date, '%Y-%m-01'),
            DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')
        ) AS months_since_acquisition
    FROM customer_cohorts cc
    JOIN customers c
        ON cc.customer_unique_id = c.customer_unique_id
    JOIN orders o
        ON c.customer_id = o.customer_id
),

cohort_counts AS (
    SELECT
        acquisition_month,
        months_since_acquisition,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM customer_activity
    GROUP BY
        acquisition_month,
        months_since_acquisition
),

cohort_sizes AS (
    SELECT
        acquisition_month,
        months_since_acquisition,
        active_customers,
        MAX(
            CASE
                WHEN months_since_acquisition = 0
                THEN active_customers
            END
        ) OVER (
            PARTITION BY acquisition_month
        ) AS cohort_size
    FROM cohort_counts
)

SELECT
    acquisition_month,
    months_since_acquisition,
    active_customers,
    cohort_size,
    ROUND(
        active_customers * 100.0 / cohort_size,
        2
    ) AS retention_rate
FROM cohort_sizes
ORDER BY
    acquisition_month,
    months_since_acquisition;
    -- Results:
-- Customer retention was very low across most acquisition cohorts.
-- For the larger cohorts, Month 1 retention generally remained below 1%,
-- indicating that relatively few first-time customers made another
-- purchase in the following month.
-- For example, the July 2018 cohort had a Month 1 retention rate of 0.72%,
-- while the September and October 2017 cohorts had Month 1 retention
-- rates of 0.68% and 0.69%, respectively.
-- Retention generally remained below 1% in subsequent months as well,
-- suggesting that marketplace activity was heavily driven by new customers
-- rather than repeat purchasing.
-- Very small cohorts and the sparse final months of the dataset should
-- be interpreted cautiously.

-- =====================================================
-- Q19. Cumulative (Running) Revenue Over Time
-- Calculate monthly revenue and the cumulative revenue
-- generated through each month.
-- =====================================================

WITH monthly_revenue AS(
	SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month, SUM(oi.price) AS revenue 
    FROM orders o
    JOIN order_items oi
		ON o.order_id = oi.order_id
	WHERE o.order_status = 'delivered'
	GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') 
)

SELECT month, ROUND(revenue, 2) AS monthly_revenue, 
	ROUND(SUM(revenue) OVER( ORDER by month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS cumulative_revenue
FROM monthly_revenue
ORDER BY month;
-- Results:
-- Cumulative revenue increased from $134.97 in September 2016
-- to $13,221,498.11 by August 2018.
-- Revenue accumulation accelerated substantially throughout 2017
-- and continued steadily through the first eight months of 2018.
-- By December 2017, cumulative revenue had surpassed $6.0 million,
-- increasing to approximately $13.2 million by August 2018.
-- The final cumulative revenue matches the total delivered-order GMV
-- calculated in the seller concentration analysis.

-- =====================================================
-- Q20. Top 3 Product Categories per State
-- Rank product categories within each customer state
-- and identify the top three categories in each state.
-- =====================================================
WITH category_revenue AS (
    SELECT
        c.customer_state AS customer_state,
        ct.product_category_name_english AS category,
        SUM(oi.price) AS revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_state,
        ct.product_category_name_english
),

ranked_categories AS (
    SELECT
        customer_state,
        category,
        revenue,
        RANK() OVER (
            PARTITION BY customer_state
            ORDER BY revenue DESC
        ) AS categories_ranked
    FROM category_revenue
)

SELECT
    customer_state,
    category,
    ROUND(revenue, 2) AS revenue,
    categories_ranked
FROM ranked_categories
WHERE categories_ranked <= 3
ORDER BY
    customer_state,
    categories_ranked;
    -- Results:
-- Product category rankings varied across customer states, showing
-- regional differences in purchasing patterns.
-- Health & Beauty, Watches & Gifts, and Sports & Leisure appeared
-- frequently among the top three revenue-generating categories.
-- In São Paulo (SP), the highest-revenue category was Bed & Bath Table
-- at $472,238.07, followed by Health & Beauty at $453,916.48
-- and Watches & Gifts at $421,546.60.
-- Other states showed different leading categories; for example,
-- Sports & Leisure ranked first in Paraná (PR) and Santa Catarina (SC),
-- while Watches & Gifts ranked first in Rio de Janeiro (RJ).
-- These results suggest that the category mix differs across regions.

-- =====================================================
-- Q21. RFM Customer Segmentation
-- Score customers on Recency, Frequency, and Monetary
-- value using NTILE and assign customer segments.
-- =====================================================
WITH customer_rfm AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price) AS monetary
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

rfm_metrics AS (
    SELECT
        customer_unique_id,
        DATEDIFF(
            DATE_ADD(
                (SELECT MAX(order_purchase_timestamp) FROM orders),
                INTERVAL 1 DAY
            ),
            last_purchase_date
        ) AS recency,
        frequency,
        monetary
    FROM customer_rfm
),

rfm_scores AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,

        NTILE(5) OVER (
            ORDER BY recency DESC
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY monetary ASC
        ) AS monetary_score

    FROM rfm_metrics
),

rfm_segments AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        ROUND(monetary, 2) AS monetary,
        recency_score,
        frequency_score,
        monetary_score,

        CASE
            WHEN recency_score >= 4
                 AND frequency_score >= 4
                 AND monetary_score >= 4
                THEN 'Champions'

            WHEN frequency_score >= 4
                 AND monetary_score >= 3
                THEN 'Loyal Customers'

            WHEN recency_score <= 2
                 AND frequency_score >= 3
                THEN 'At Risk'

            WHEN recency_score >= 4
                 AND frequency_score <= 2
                THEN 'New Customers'

            ELSE 'Other'
        END AS customer_segment

    FROM rfm_scores
)

SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(recency), 2) AS avg_recency,
    ROUND(AVG(frequency), 2) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_monetary
FROM rfm_segments
GROUP BY customer_segment
ORDER BY customer_count DESC;
-- Results:
-- New Customers were the largest RFM segment with 31,703 customers,
-- followed by Loyal Customers (21,328) and At Risk customers (21,061).
-- Champions represented a much smaller group of 1,615 customers but had
-- the highest average purchase frequency (1.69 orders) and the highest
-- average monetary value (298.47).
-- At Risk customers had the highest average recency at 476.62 days,
-- indicating that they had gone substantially longer without purchasing.
-- Overall purchase frequency remained low across all segments, suggesting
-- that repeat purchasing was relatively uncommon in the marketplace.
-- Because many customers made only one purchase, NTILE may assign customers
-- with the same frequency to different frequency scores.

-- =====================================================
-- Q22. Seller Scorecard
-- Create a seller scorecard combining revenue,
-- average review score, average delivery time,
-- and cancellation rate in one ranked table.
-- =====================================================
WITH seller_orders AS (
	SELECT DISTINCT oi.seller_id, o.order_id, o.order_status, o.order_purchase_timestamp, o.order_delivered_customer_date 
    FROM order_items oi
    JOIN orders o
		ON oi.order_id = o.order_id
), 

seller_revenue AS (
	SELECT oi.seller_id, 
		SUM( CASE WHEN o.order_status = 'delivered'
				THEN oi.price
                ELSE 0
			END
		) AS revenue
	FROM order_items oi
    JOIN orders o
		ON oi.order_id = o.order_id
	GROUP BY oi.seller_id
),

seller_reviews AS(
	SELECT so.seller_id, AVG(r.review_score) AS avg_review_score 
    FROM seller_orders so
    JOIN order_reviews r
		ON so.order_id = r.order_id
	GROUP BY so.seller_id
), 

seller_delivery AS(
	SELECT seller_id, AVG(DATEDIFF( order_delivered_customer_date, order_purchase_timestamp)) AS avg_delivery_days
    FROM seller_orders
    WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL
    GROUP BY seller_id
), 

seller_cancellations AS(
	SELECT seller_id,
    AVG(CASE WHEN order_status = 'canceled'
			THEN 1
            ELSE 0
		END) * 100 AS cancellation_rate 
	FROM seller_orders
    GROUP BY seller_id
), 

seller_metrics AS(
	SELECT s.seller_id, sr.revenue, rv.avg_review_score, sd.avg_delivery_days, sc.cancellation_rate 
    FROM sellers s
    JOIN seller_revenue sr 
		ON s.seller_id = sr.seller_id
	LEFT JOIN seller_reviews rv 
		ON s.seller_id = rv.seller_id 
	LEFT JOIN seller_delivery sd
		ON s.seller_id = sd.seller_id 
	LEFT JOIN seller_cancellations sc
		ON s.seller_id = sc.seller_id
), 

seller_ranks AS(
	SELECT seller_id, revenue, avg_review_score, avg_delivery_days, cancellation_rate, 
    RANK() OVER(ORDER BY revenue DESC) AS revenue_rank, 
    RANK() OVER(ORDER BY avg_review_score DESC) AS review_rank,
    RANK() OVER(ORDER BY avg_delivery_days ASC) AS delivery_rank, 
    RANK() OVER(ORDER BY cancellation_rate ASC) AS cancellation_rank
    FROM seller_metrics
),

seller_scores AS (
	SELECT *, (revenue_rank + review_rank + delivery_rank + cancellation_rank)/ 4.0 AS overall_score
    FROM seller_ranks
)

SELECT 
	seller_id, 
    ROUND(revenue,2) AS revenue, 
    ROUND(avg_review_score, 2) AS avg_review_score, 
    ROUND(avg_delivery_days, 2) AS avg_delivery_days, 
	ROUND(cancellation_rate, 2) AS cancellation_rate, 
    revenue_rank, 
    review_rank,
    delivery_rank, 
    cancellation_rank, 
    ROUND(overall_score, 2) AS overall_score, 
    RANK () OVER(ORDER BY overall_score ASC) AS overall_rank
    
FROM seller_scores
ORDER BY overall_rank;
-- Results:
-- The seller scorecard combined revenue, average review score,
-- average delivery time, and cancellation rate into an overall ranking.
-- The highest-ranked seller generated $15,633.40 in revenue,
-- had an average review score of 4.67, an average delivery time
-- of 5.71 days, and a 0% cancellation rate.
-- The top-ranked sellers generally combined strong customer reviews
-- and relatively fast delivery with no cancellations.
-- All of the top 25 sellers shown had a 0% cancellation rate,
-- so revenue, review scores, and delivery speed provided greater
-- differentiation among these sellers.
-- The overall ranking gives equal weight to the four component ranks,
-- so it should be interpreted as one possible seller-performance
-- scoring methodology rather than a definitive measure of seller quality.

-- =====================================================
-- Q23. Delivery-Time p50 and p90 per State
-- Calculate the median (p50) and 90th percentile (p90)
-- of delivery time for each customer state.
-- =====================================================

WITH delivery_times AS (
	SELECT c.customer_state, o.order_id, DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS delivery_days 
    FROM orders o 
    JOIN customers c 
		ON o.customer_id = c.customer_id
	WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
), 

ranked_deliveries AS (
	SELECT customer_state, delivery_days, 
		ROW_NUMBER() OVER(PARTITION BY customer_state ORDER BY delivery_days) AS row_num, 
        COUNT(*) OVER(PARTITION BY customer_state) AS total_orders 
	FROM delivery_times
)

SELECT customer_state, 
	MAX( CASE WHEN row_num = CEIL(0.5 * total_orders)
			THEN delivery_days
		END
        ) AS p50_delivery_days, 
	MAX( CASE WHEN row_num = CEIL(0.9 * total_orders)
			THEN delivery_days
		END
        ) AS p90_delivery_days
FROM ranked_deliveries 
GROUP BY customer_state
ORDER BY p90_delivery_days DESC;

-- Results:
-- Delivery-time percentiles varied substantially across customer states.
-- Roraima (RR) had the longest delivery times, with a p50 of 25 days
-- and a p90 of 53 days.
-- Alagoas (AL) also showed relatively slow upper-end performance,
-- with a p50 of 22 days and a p90 of 40 days.
-- In contrast, São Paulo (SP) had the fastest delivery performance,
-- with a p50 of 7 days and a p90 of 16 days.
-- Minas Gerais (MG) and Paraná (PR) also performed relatively well,
-- with p50 delivery times of 10 days and p90 times of 20 days.
-- The large differences in p90 across states highlight substantial
-- regional variation in slower-end delivery performance.

-- =====================================================
-- Q24. Revenue Pareto Analysis
-- Calculate the cumulative percentage of revenue by
-- product category and determine how few categories
-- are needed to generate approximately 80% of revenue.
-- =====================================================
WITH category_revenue AS(
	SELECT ct.product_category_name_english AS category, SUM(oi.price) AS revenue
    FROM orders o 
    JOIN order_items oi 
		ON o.order_id = oi.order_id
	JOIN products p
		ON oi.product_id = p.product_id
	JOIN category_translation ct
		ON p.product_category_name = ct.product_category_name
	WHERE o.order_status = 'delivered'
GROUP BY ct.product_category_name_english
), 

revenue_pareto AS(
	SELECT category, revenue, 
		SUM(revenue) OVER( ORDER BY revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue, 
        SUM(revenue) OVER() AS total_revenue
	FROM category_revenue
)

SELECT category, ROUND(revenue, 2) AS revenue, ROUND(cumulative_revenue, 2) AS cumulative_revenue, ROUND(cumulative_revenue /total_revenue *100, 2) AS cumulative_revenue_pct
FROM revenue_pareto 
ORDER BY revenue DESC;

-- Results:
-- Revenue was concentrated among a relatively small group of product categories.
-- The top 17 categories generated 80.76% of total delivered-order revenue,
-- crossing the 80% threshold for the first time.
-- The first 16 categories accounted for 79.09%, with Computers increasing
-- the cumulative share to 80.76%.
-- Health & Beauty was the largest individual category, contributing 9.45%
-- of revenue, while the top five categories together generated 40.37%.
-- These results show that a subset of categories accounts for the majority
-- of marketplace revenue, although the distribution is not as concentrated
-- as a strict 80/20 pattern.

-- =====================================================
-- Q25. Category Affinity Analysis
-- Identify which product category pairs are most
-- frequently purchased together in the same order.
-- =====================================================
WITH category_pairs AS (
    SELECT
        oi1.order_id,

        LEAST(
            ct1.product_category_name_english,
            ct2.product_category_name_english
        ) AS category_1,

        GREATEST(
            ct1.product_category_name_english,
            ct2.product_category_name_english
        ) AS category_2

    FROM order_items oi1

    JOIN order_items oi2
        ON oi1.order_id = oi2.order_id
        AND oi1.order_item_id < oi2.order_item_id

    JOIN products p1
        ON oi1.product_id = p1.product_id

    JOIN products p2
        ON oi2.product_id = p2.product_id

    JOIN category_translation ct1
        ON p1.product_category_name = ct1.product_category_name

    JOIN category_translation ct2
        ON p2.product_category_name = ct2.product_category_name

    WHERE p1.product_category_name <> p2.product_category_name
)

SELECT
    category_1,
    category_2,
    COUNT(DISTINCT order_id) AS orders_together
FROM category_pairs
GROUP BY
    category_1,
    category_2
ORDER BY
    orders_together DESC;
    -- Results:
-- Bed & Bath Table and Furniture Decor were the most frequently
-- purchased category pair, appearing together in 70 distinct orders.
-- Bed & Bath Table and Home Comfort ranked second with 43 orders,
-- followed by Furniture Decor and Housewares with 24 orders.
-- Other notable combinations included Baby and Cool Stuff with 20 orders,
-- Baby and Toys with 19 orders, and Health & Beauty and Perfumery
-- with 12 orders.
-- The sharp decline after the leading pairs suggests that cross-category
-- purchasing was relatively concentrated among a small number of
-- category combinations.
-- These category affinities could help identify potential opportunities
-- for product recommendations, cross-selling, or bundled promotions.