# Customer-Market-Analysis-

## Table of Contents

- [Project Overview](Project-overview)
- [Data Sources](#data-sources)
- [Recommendations](Recommendations)

### Project Overview

The Customer Market Analysis project aims to provide a comprehensive understanding of customer behavior, preferences, and purchasing patterns. By analyzing customer data, this project seeks to uncover actionable insights that can drive marketing strategies, improve customer engagement, and optimize product offerings.

#### Key Objectives
- Segmentation: Classify customers into distinct segments based on their age, purchase frequency, and monetary value.
- Purchase Behavior: Identify the most frequently purchased products within each customer segment.
- Trend Analysis: Analyze trends in customer purchasing patterns over time.
- Market Insights: Provide actionable insights to improve marketing strategies and product recommendations.

![Screenshot (156)-](https://github.com/user-attachments/assets/525cbc07-e984-402e-92ea-d71536b3eff6)

### Data Sources
- Customer Data: Includes customer demographics (e.g., age, gender) and purchase history.
- Product Data: Contains details about products purchased, such as product IDs and names.
The primary dataset used for this analysis is the "customers.csv" file.

### Tools
- Programming Languages: SQL
- Database: MySQL
- Visualization Tools: Tableau

### Analysis Techniques
- Data Cleaning & Preparation:
  Handle missing values, correct data formats, and ensure data consistency.
- Segmentation Analysis:
  Group customers based on age ranges and other relevant factors.
- Frequency Analysis:
  Calculate the frequency of product purchases and identify the most popular products within each age group.
- Trend Analysis:
  Examine purchasing trends over time and across different customer segments.
- Visualization:
- Create visualizations to present key findings and insights clearly.
   

### Data Analysis
Include some interesting code/features worked with

##### Customer Demographics
```sql
SELECT 
	Gender,
	COUNT(DISTINCT CustomerName) TotalCustomer
FROM ecommerce_customer_data_custom_ratios 
GROUP BY Gender;
```
```sql
SELECT 
	gender, 
	COUNT(*) as TotalOrdersByGender,
  SUM(Quantity) TotalQuantityByGender,
  AVG(TotalPurchaseAmount) TotalPurchaseByGender
FROM ecommerce_customer_data_custom_ratios 
GROUP BY gender;
```
```sql
SELECT 
	CustomerAge,
	COUNT(DISTINCT CustomerName) TotalCustomer
FROM ecommerce_customer_data_custom_ratios 
GROUP BY CustomerAge
ORDER BY 2 DESC;
```
```sql
WITH total_overall_orders AS (
    SELECT 
        COUNT(*) AS overall_total
    FROM ecommerce_customer_data_custom_ratios
)
SELECT
    CASE
        WHEN CustomerAge < 25 THEN '< 25'
        WHEN CustomerAge BETWEEN 25 AND 34 THEN '25-34'
        WHEN CustomerAge BETWEEN 35 AND 44 THEN '35-44'
        WHEN CustomerAge BETWEEN 45 AND 54 THEN '45-54'
        WHEN CustomerAge >= 55 THEN '55+'
        ELSE 'Unknown'
    END AS age_group,
    COUNT(*) AS total_orders,
    CONCAT(ROUND((COUNT(*) * 100.0 / op.overall_total), 2), '%') AS percentage_contribution
FROM ecommerce_customer_data_custom_ratios
CROSS JOIN total_overall_orders op  -- Menggabungkan hasil CTE dengan tabel utama
GROUP BY age_group, op.overall_total;
```
##### Purchase Behavior
```sql
SELECT 
	CustomerName, 
	COUNT(*) purchase_count, 
	SUM(TotalPurchaseAmount) total_spent
FROM ecommerce_customer_data_custom_ratios
GROUP BY CustomerName
ORDER BY purchase_count DESC;
```
```sql
SELECT
	PurchaseDate,
	ProductCategory,
	COUNT(*) OVER(PARTITION BY ProductCategory) product_spent,
  SUM(Quantity) OVER(PARTITION BY ProductCategory) total_quantity
FROM ecommerce_customer_data_custom_ratios
WHERE CustomerName ='Michael Smith'
ORDER BY product_spent DESC;
```
```sql
SELECT
	ProductCategory,
  COUNT(*) OVER(PARTITION BY ProductCategory) TotalOrdersByProductCategory,
	SUM(Quantity) OVER(PARTITION BY ProductCategory) TotalQuantityByProductCategory,
	SUM(TotalPurchaseAmount) OVER(PARTITION BY ProductCategory) TotalAmountByProductCategory
FROM ecommerce_customer_data_custom_ratios
ORDER BY 2 DESC, 3 DESC;
```
##### Customer Retention and Churn
```sql
SELECT CustomerName,
 COUNT(*) purchase_count
FROM ecommerce_customer_data_custom_ratios
GROUP BY CustomerName
HAVING COUNT(*) > 1;
```
```sql
WITH rfm AS (
    SELECT CustomerName,
    COUNT(CustomerID) as frequency
    FROM ecommerce_customer_data_custom_ratios
    GROUP BY CustomerName
)
SELECT 
    CONCAT(ROUND((COUNT(CASE WHEN frequency > 1 THEN 1 END) * 100.0 / COUNT(*)), 2), '%') AS repeat_purchase_percentage
FROM rfm;
```

##### Customer Segmentation
```sql
SELECT CustomerName,
       MAX(PurchaseDate) last_purchase,
       COUNT(PurchaseDate) frequency,
       SUM(PurchaseDate) monetary
FROM ecommerce_customer_data_custom_ratios
GROUP BY CustomerName
ORDER BY frequency DESC, monetary DESC;
```
```sql
WITH rfm AS 
(
SELECT
	CustomerName,
	SUM(TotalPurchaseAmount) MonetaryValue,
	AVG(TotalPurchaseAmount) AvgMonetaryValue,
	COUNT(CustomerID) Frequency,
	MAX(PurchaseDate) LastPurchaseDate,
	( SELECT MAX(PurchaseDate) FROM ecommerce_customer_data_custom_ratios) MaxPurchaseDate,
	DATEDIFF(( SELECT MAX(PurchaseDate) FROM ecommerce_customer_data_custom_ratios), MAX(PurchaseDate)) Recency
FROM ecommerce_customer_data_custom_ratios
GROUP BY CustomerName
),
rfm_calc AS
(
SELECT r.*,
NTILE(4) OVER (ORDER BY Recency DESC) fm_recency,
NTILE(4) OVER (ORDER BY Frequency) rfm_frequency,
NTILE(4) OVER (ORDER BY AvgMonetaryValue) rfm_monetary
FROM rfm r
)
SELECT c.*
FROM rfm_calc c;
```
###### Segmenting based on RFM values
```sql
WITH rfm AS (
    SELECT CustomerName,
           MAX(PurchaseDate) as last_purchase,
           COUNT(CustomerID) as frequency,
           SUM(TotalPurchaseAmount) as monetary
    FROM ecommerce_customer_data_custom_ratios
    GROUP BY CustomerName
),
segmented_customers AS (
    SELECT CustomerName,
           CASE
               WHEN DATEDIFF('2023-12-09', last_purchase) <= 30 THEN 'Active'
               WHEN DATEDIFF('2023-12-09', last_purchase) <= 90 THEN 'Lapsed'
               ELSE 'Inactive'
           END as recency_segment,
           CASE
               WHEN frequency >= 10 THEN 'Frequent'
               WHEN frequency >= 5 THEN 'Regular'
               ELSE 'Infrequent'
           END as frequency_segment,
           CASE
               WHEN monetary >= 2000 THEN 'High Value'
               WHEN monetary >= 1000 THEN 'Medium Value'
               ELSE 'Low Value'
           END as monetary_segment
    FROM rfm
)
SELECT 
    COUNT(CASE WHEN recency_segment = 'Active' AND frequency_segment = 'Frequent' AND monetary_segment = 'High Value' THEN 1 END) as active_frequent_high_value_customers
FROM segmented_customers;
```
##### Product Preferences
```sql
SELECT 
	productCategory,
	COUNT(*) OVER(PARTITION BY productCategory) purchase_count
FROM ecommerce_customer_data_custom_ratios
ORDER BY purchase_count DESC;
```
```sql
SELECT 
	CustomerName, 
	productCategory, 
	COUNT(*) purchase_count
FROM ecommerce_customer_data_custom_ratios
GROUP BY CustomerName,  productCategory
ORDER BY purchase_count DESC;
```
```sql
WITH cte AS
(
SELECT 
	YEAR(purchasedate) YEAR, 
	productcategory,
	SUM(totalpurchaseamount) total_amount
FROM ecommerce_customer_data_custom_ratios
GROUP BY productcategory, YEAR(purchasedate)
)
(SELECT *, 
	DENSE_RANK() OVER (PARTITION BY YEAR ORDER BY total_amount DESC) AS Ranking
FROM cte
);
```



### Findings and Recommendation
**1. Gender Influence on Total Orders**
   - Observation: Gender does not significantly impact the total number of customer orders. Both males and females have similar 
      purchase ratios.
   - Insight: Marketing strategies and promotions should not be gender-specific if targeting purchase frequency. Focus may be 
     better placed on other factors.
     
**2. Age Group Distribution**
   - Observation: Customers aged 55 and above represent the largest segment, accounting for 30.20% of total customers.
   - Insight: This age group is a significant market segment. Targeted marketing efforts and product offerings should consider 
     the preferences and needs of older customers.

**3. Product Ordering Trends**
   - Observation: Clothing is the most frequently ordered product. Based on annual sales, Books and Clothing alternately occupy 
     the top positions, while Home and Electronics consistently rank at the bottom.
   - Insight: Clothing should be a focus for promotions and stock management. Diversifying strategies to boost the sales of 
     Home and Electronics might be beneficial.

**4. Repeat Purchase Rate**
   - Observation: 97.12% of customers make repeat purchases (more than once).
   - Insight: High customer retention indicates strong loyalty and satisfaction. Retention strategies and loyalty programs 
     should be maintained and potentially enhanced.
     
**5. High-Frequency Customers**
   - Observation: There are 46 customers who have made more than 50 transactions.
   - Insight: These high-frequency customers are likely valuable and can be key targets for personalized offers and engagement 
     strategies.

**6. Active, Frequent, High-Value Customers**
   - Observation: Out of a total of 39,920 customers, 573 are categorized as active, frequent, and high-value.
   - Insight: This subset represents a significant portion of total revenue. Focusing on these customers with targeted 
     marketing, exclusive offers, and premium services can drive further growth.



