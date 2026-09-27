# Olist E-Commerce Analysis — Key Findings

This document summarizes the key business insights from the Olist Brazilian
E-Commerce SQL analysis. The analysis covers marketplace revenue, delivery
performance, customer retention, seller performance, and product purchasing
patterns.

---

## 1. Marketplace revenue grew substantially over the analysis period

Cumulative delivered-order revenue reached approximately **$13.22 million by
August 2018**. Monthly revenue grew substantially throughout 2017 and remained
high during the first eight months of 2018. November 2017 was a particularly
strong month, with revenue increasing **52.37% month over month**.

**Business takeaway:** The marketplace experienced substantial revenue growth,
although month-to-month performance became more variable as the marketplace
matured.

**Caveat:** The earliest months contain very little data, including a missing
November 2016, so early month-over-month growth rates are not representative of
normal marketplace performance.

---

## 2. Revenue is concentrated among a subset of product categories

The top **17 product categories generated 80.76% of delivered-order revenue**.
The first 16 categories accounted for 79.09%, with Computers bringing the
cumulative share above the 80% threshold.

Health & Beauty was the largest individual category, contributing **9.45% of
revenue**, while the top five categories together generated **40.37%**.

**Business takeaway:** A relatively small subset of categories drives the
majority of marketplace revenue, making these categories especially important
for merchandising and seller strategy.

**Caveat:** Although this is a Pareto-style concentration analysis, the results
do not follow a strict 80/20 distribution.

---

## 3. Delivery performance varies substantially by customer state

Across delivered orders, the overall average delivery time was approximately
**12.5 days**, but delivery performance differed considerably across states.

São Paulo (SP) had a median delivery time of **7 days** and a p90 of **16 days**.
In contrast, Roraima (RR) had a median of **25 days** and a p90 of **53 days**.

Overall, **91.89% of delivered orders arrived on or before the estimated
delivery date**, while 8.11% arrived late.

**Business takeaway:** Delivery reliability is strong overall, but customers in
some states experience substantially longer delivery times and greater
slow-end delivery risk.

**Caveat:** Eight delivered orders were missing an actual delivery timestamp
and were excluded from delivery-time calculations.

---

## 4. Late deliveries are associated with substantially lower review scores

Orders delivered on time had an average review score of **4.29**, compared with
only **2.57** for late deliveries, a difference of **1.72 points**.

**Business takeaway:** Delivery performance is strongly associated with
customer satisfaction, making late-delivery reduction a potential area of
operational focus.

**Caveat:** This analysis shows an association, not causation. In addition,
some orders contain multiple review records, so the averages represent review
records rather than a strict one-review-per-order measure.

---

## 5. Customer activity is driven primarily by first-time buyers

New customers represented the large majority of active customers each month.
For example, May 2018 had **6,622 new customers compared with only 192 returning
customers**.

Cohort analysis reinforced this pattern. For larger acquisition cohorts,
Month 1 retention generally remained **below 1%**, and repeat purchasing
remained low in subsequent months.

**Business takeaway:** Marketplace activity depends heavily on customer
acquisition rather than repeat purchasing, suggesting an opportunity to improve
customer retention and repeat-order behavior.

**Caveat:** The final months of the dataset contain very little activity and
should be interpreted cautiously. The new-versus-returning and cohort analyses
also use order activity regardless of final order status.

---

## 6. Seller revenue is highly concentrated

The top **10% of sellers generated 67.11% of delivered-order GMV**, accounting
for approximately **$8.87 million** of the roughly **$13.22 million** total.

Eight of the ten highest-revenue sellers were located in São Paulo (SP).

**Business takeaway:** Marketplace revenue depends heavily on a relatively
small group of sellers, making high-performing seller relationships important
to overall marketplace performance.

**Caveat:** Revenue concentration measures sales contribution only and should
not be interpreted as a complete measure of seller quality.

---

## 7. RFM analysis highlights a small group of high-value customers

The RFM segmentation identified **1,615 Champions**, compared with 31,703
customers in the New Customers segment, 21,328 Loyal Customers, and 21,061
At Risk customers.

Champions had the highest average purchase frequency at **1.69 orders** and the
highest average monetary value at **$298.47**. At Risk customers had an average
recency of **476.62 days**.

**Business takeaway:** Although repeat purchasing is uncommon overall, the
Champion segment represents a smaller group of comparatively frequent and
high-value customers who may be particularly important for retention efforts.

**Caveat:** Because many customers made only one purchase, NTILE can assign
customers with identical purchase frequencies to different frequency scores.
The RFM segment definitions are analytical rules created for this project
rather than predefined Olist customer segments.

---

## 8. Certain product categories show meaningful purchase affinity

Bed & Bath Table and Furniture Decor were the most frequently purchased
cross-category combination, appearing together in **70 distinct orders**.
Bed & Bath Table and Home Comfort ranked second with **43 orders**, followed by
Furniture Decor and Housewares with **24 orders**.

Other notable combinations included Baby and Toys with **19 orders** and
Health & Beauty and Perfumery with **12 orders**.

**Business takeaway:** Frequently co-purchased categories could provide
opportunities for cross-selling, product recommendations, or bundled
promotions.

**Caveat:** This analysis measures co-occurrence within orders and does not
establish that purchasing one category causes customers to purchase another.
It also measures absolute pair frequency rather than a normalized affinity
metric such as lift or confidence.

---

## Overall Takeaways

The Olist marketplace showed strong revenue growth and high overall on-time
delivery performance, but the analysis also identified several areas of
concentration and potential improvement. Revenue is concentrated among a
subset of categories and sellers, while customer activity remains heavily
dependent on first-time buyers. Delivery performance varies substantially by
region and is strongly associated with review scores. Together, these findings
suggest that customer retention, regional delivery performance, seller
management, and category-level merchandising are important areas for deeper
marketplace analysis.