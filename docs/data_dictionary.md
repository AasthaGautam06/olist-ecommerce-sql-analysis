# Data Dictionary

This document describes the primary tables and fields used in the Olist
Brazilian E-Commerce SQL analysis.

## customers

Contains customer information associated with each order.

| Column | Description |
|---|---|
| customer_id | Unique customer identifier associated with an order |
| customer_unique_id | Identifier used to recognize the same customer across multiple orders |
| customer_zip_code_prefix | Customer ZIP code prefix |
| customer_city | Customer city |
| customer_state | Customer state abbreviation |

**Primary Key:** `customer_id`

> `customer_unique_id` is used for customer-level and retention analysis because
> the same customer may have multiple `customer_id` values across different orders.

---

## sellers

Contains information about marketplace sellers.

| Column | Description |
|---|---|
| seller_id | Unique seller identifier |
| seller_zip_code_prefix | Seller ZIP code prefix |
| seller_city | Seller city |
| seller_state | Seller state abbreviation |

**Primary Key:** `seller_id`

---

## products

Contains product attributes and category information.

| Column | Description |
|---|---|
| product_id | Unique product identifier |
| product_category_name | Product category name in Portuguese |
| product_name_lenght | Length of the product name |
| product_description_lenght | Length of the product description |
| product_photos_qty | Number of product photos |
| product_weight_g | Product weight in grams |
| product_length_cm | Product length in centimeters |
| product_height_cm | Product height in centimeters |
| product_width_cm | Product width in centimeters |

**Primary Key:** `product_id`

---

## category_translation

Translates product category names from Portuguese to English.

| Column | Description |
|---|---|
| product_category_name | Product category name in Portuguese |
| product_category_name_english | English translation of the category |

**Primary Key:** `product_category_name`

---

## geolocation

Contains geographic coordinates associated with Brazilian ZIP code prefixes.

| Column | Description |
|---|---|
| geolocation_zip_code_prefix | ZIP code prefix |
| geolocation_lat | Latitude |
| geolocation_lng | Longitude |
| geolocation_city | City |
| geolocation_state | State abbreviation |

> Multiple geographic records can exist for the same ZIP code prefix.

---

## orders

Contains one row per order and tracks order status and timestamps throughout the
order lifecycle.

| Column | Description |
|---|---|
| order_id | Unique order identifier |
| customer_id | Customer associated with the order |
| order_status | Current/final recorded order status |
| order_purchase_timestamp | Date and time the order was placed |
| order_approved_at | Date and time the order was approved |
| order_delivered_carrier_date | Date and time the order was delivered to the carrier |
| order_delivered_customer_date | Date and time the order reached the customer |
| order_estimated_delivery_date | Estimated customer delivery date |

**Primary Key:** `order_id`

**Foreign Key:** `customer_id` → `customers.customer_id`

---

## order_items

Contains the individual products included in each order.

| Column | Description |
|---|---|
| order_id | Order identifier |
| order_item_id | Sequential item number within the order |
| product_id | Product purchased |
| seller_id | Seller responsible for the item |
| shipping_limit_date | Seller shipping deadline |
| price | Item price |
| freight_value | Freight charge associated with the item |

**Primary Key:** (`order_id`, `order_item_id`)

**Foreign Keys:**
- `order_id` → `orders.order_id`
- `product_id` → `products.product_id`
- `seller_id` → `sellers.seller_id`

---

## order_payments

Contains payment information for each order. An order can contain multiple
payment records.

| Column | Description |
|---|---|
| order_id | Order identifier |
| payment_sequential | Sequence number when multiple payments are used |
| payment_type | Payment method |
| payment_installments | Number of payment installments |
| payment_value | Payment amount |

**Primary Key:** (`order_id`, `payment_sequential`)

**Foreign Key:** `order_id` → `orders.order_id`

---

## order_reviews

Contains customer review information associated with orders.

| Column | Description |
|---|---|
| review_id | Review identifier |
| order_id | Order being reviewed |
| review_score | Customer rating from 1 to 5 |
| review_comment_title | Review title |
| review_comment_message | Written review |
| review_creation_date | Date the review was created |
| review_answer_timestamp | Date and time the review was submitted/answered |

**Foreign Key:** `order_id` → `orders.order_id`

> Some orders contain multiple review records. Analyses requiring one review per
> order should account for this explicitly.

---

## Key Relationships

The main analytical relationships are:

- `customers` → `orders` through `customer_id`
- `orders` → `order_items` through `order_id`
- `orders` → `order_payments` through `order_id`
- `orders` → `order_reviews` through `order_id`
- `order_items` → `products` through `product_id`
- `order_items` → `sellers` through `seller_id`
- `products` → `category_translation` through `product_category_name`

Because `order_items`, `order_payments`, and `order_reviews` can each contain
multiple rows per order, joining multiple child tables directly can create
row multiplication and inflate aggregate metrics. When multiple child tables
are needed, they are first aggregated to the appropriate grain before being
joined.