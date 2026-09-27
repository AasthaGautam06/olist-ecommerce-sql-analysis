CREATE DATABASE IF NOT EXISTS olist
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE olist;

CREATE DATABASE IF NOT EXISTS olist
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

USE olist;

-- Parents first ------------------------------------------

CREATE TABLE customers (
  customer_id VARCHAR(32) PRIMARY KEY,
  customer_unique_id VARCHAR(32),
  customer_zip_code_prefix INT,
  customer_city VARCHAR(64),
  customer_state CHAR(2)
);

CREATE TABLE sellers (
  seller_id VARCHAR(32) PRIMARY KEY,
  seller_zip_code_prefix INT,
  seller_city VARCHAR(64),
  seller_state CHAR(2)
);

CREATE TABLE products (
  product_id VARCHAR(32) PRIMARY KEY,
  product_category_name VARCHAR(64),
  product_name_lenght INT,
  product_description_lenght INT,
  product_photos_qty INT,
  product_weight_g INT,
  product_length_cm INT,
  product_height_cm INT,
  product_width_cm INT
);

CREATE TABLE category_translation (
  product_category_name VARCHAR(64) PRIMARY KEY,
  product_category_name_english VARCHAR(64)
);

CREATE TABLE geolocation (
  geolocation_zip_code_prefix INT,
  geolocation_lat DECIMAL(11,8),
  geolocation_lng DECIMAL(11,8),
  geolocation_city VARCHAR(64),
  geolocation_state CHAR(2)
);

-- Children -----------------------------------------------

CREATE TABLE orders (
  order_id VARCHAR(32) PRIMARY KEY,
  customer_id VARCHAR(32),
  order_status VARCHAR(20),
  order_purchase_timestamp DATETIME,
  order_approved_at DATETIME,
  order_delivered_carrier_date DATETIME,
  order_delivered_customer_date DATETIME,
  order_estimated_delivery_date DATETIME,
  CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
  order_id VARCHAR(32),
  order_item_id INT,
  product_id VARCHAR(32),
  seller_id VARCHAR(32),
  shipping_limit_date DATETIME,
  price DECIMAL(10,2),
  freight_value DECIMAL(10,2),
  PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
  order_id VARCHAR(32),
  payment_sequential INT,
  payment_type VARCHAR(20),
  payment_installments INT,
  payment_value DECIMAL(10,2),
  PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE order_reviews (
  review_id VARCHAR(32),
  order_id VARCHAR(32),
  review_score INT,
  review_comment_title VARCHAR(255),
  review_comment_message TEXT,
  review_creation_date DATETIME,
  review_answer_timestamp DATETIME
);