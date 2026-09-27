USE olist;
-- =====================================================
-- Load Sellers
-- =====================================================

-- IMPORTANT:
-- Update the file paths below to match the location of the
-- Olist CSV files on your local machine before running this script.

LOAD DATA LOCAL INFILE 'C:/path/to/olist-ecommerce-sql-analysis/data/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
SELECT COUNT(*) AS seller_count
FROM sellers;
-- =====================================================
-- Load Products
-- =====================================================
LOAD DATA LOCAL INFILE 'C:/path/to/olist-ecommerce-sql-analysis/data/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    product_id,
    product_category_name,
    @product_name_lenght,
    @product_description_lenght,
    @product_photos_qty,
    @product_weight_g,
    @product_length_cm,
    @product_height_cm,
    @product_width_cm
)
SET
    product_name_lenght = NULLIF(@product_name_lenght, ''),
    product_description_lenght = NULLIF(@product_description_lenght, ''),
    product_photos_qty = NULLIF(@product_photos_qty, ''),
    product_weight_g = NULLIF(@product_weight_g, ''),
    product_length_cm = NULLIF(@product_length_cm, ''),
    product_height_cm = NULLIF(@product_height_cm, ''),
    product_width_cm = NULLIF(@product_width_cm, '');

-- =====================================================
-- Load Category Translation
-- =====================================================

LOAD DATA LOCAL INFILE 'C:/path/to/olist-ecommerce-sql-analysis/data/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- =====================================================
-- Load Geolocation
-- =====================================================

LOAD DATA LOCAL INFILE 'C:/path/to/olist-ecommerce-sql-analysis/data/olist_geolocation_dataset.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- =====================================================
-- Load Orders
-- =====================================================

LOAD DATA LOCAL INFILE 'C:/path/to/olist-ecommerce-sql-analysis/data/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    order_id,
    customer_id,
    order_status,
    @purchase,
    @approved,
    @carrier,
    @delivered,
    @estimated
)
SET
    order_purchase_timestamp = NULLIF(@purchase, ''),
    order_approved_at = NULLIF(@approved, ''),
    order_delivered_carrier_date = NULLIF(@carrier, ''),
    order_delivered_customer_date = NULLIF(@delivered, ''),
    order_estimated_delivery_date = NULLIF(@estimated, '');
    
  -- =====================================================
-- Load Order Items
-- =====================================================

LOAD DATA LOCAL INFILE 'C:/path/to/olist-ecommerce-sql-analysis/data/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;  

-- =====================================================
-- Load Order Payments
-- =====================================================

LOAD DATA LOCAL INFILE 'C:/path/to/olist-ecommerce-sql-analysis/data/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- =====================================================
-- Load Order Reviews
-- =====================================================

LOAD DATA LOCAL INFILE 'C:/path/to/olist-ecommerce-sql-analysis/data/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    review_id,
    order_id,
    review_score,
    @review_comment_title,
    @review_comment_message,
    @review_creation_date,
    @review_answer_timestamp
)
SET
    review_comment_title = NULLIF(@review_comment_title, ''),
    review_comment_message = NULLIF(@review_comment_message, ''),
    review_creation_date = NULLIF(@review_creation_date, ''),
    review_answer_timestamp = NULLIF(@review_answer_timestamp, '');

-- =====================================================
-- Add Indexes
-- =====================================================

CREATE INDEX idx_orders_customer
ON orders(customer_id);

CREATE INDEX idx_orders_purchase
ON orders(order_purchase_timestamp);

CREATE INDEX idx_items_order
ON order_items(order_id);

CREATE INDEX idx_items_product
ON order_items(product_id);

CREATE INDEX idx_items_seller
ON order_items(seller_id);

CREATE INDEX idx_payments_order
ON order_payments(order_id);

CREATE INDEX idx_reviews_order
ON order_reviews(order_id);

CREATE INDEX idx_products_category
ON products(product_category_name);

