1. Customer Demographics
	
-- Total customer by gender
SELECT 
	Gender,
	COUNT(DISTINCT CustomerName) TotalCustomer
FROM ecommerce_customer_data_custom_ratios 
GROUP BY Gender;

-- Total orders, quantity and avergae purchase amount by gender
SELECT 
	gender, 
	COUNT(*) as TotalOrdersByGender,
	SUM(Quantity) TotalQuantityByGender,
	AVG(TotalPurchaseAmount) TotalPurchaseByGender
FROM ecommerce_customer_data_custom_ratios 
GROUP BY gender;

-- Total customer by age
SELECT 
	CustomerAge,
	COUNT(DISTINCT CustomerName) TotalCustomer
FROM ecommerce_customer_data_custom_ratios 
GROUP BY CustomerAge
ORDER BY 2 DESC;

-- Total orders of each age groups and their percentage contribution
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
CROSS JOIN total_overall_orders op  -- Combining the results of the CTE with the main table
GROUP BY age_group, op.overall_total;

2. Purchase Behavior

-- Total orders and amount of purchase by every customer
SELECT 
	CustomerName, 
	COUNT(*) purchase_count, 
	SUM(TotalPurchaseAmount) total_spent
FROM ecommerce_customer_data_custom_ratios
GROUP BY CustomerName
ORDER BY purchase_count DESC;

-- Total orders by product and their quantity orders for customer 'Michael Smith'
SELECT
	PurchaseDate,
	ProductCategory,
	COUNT(*) OVER(PARTITION BY ProductCategory) product_spent,
  SUM(Quantity) OVER(PARTITION BY ProductCategory) total_quantity
FROM ecommerce_customer_data_custom_ratios
WHERE CustomerName ='Michael Smith'
ORDER BY product_spent DESC;

-- Find top total orders, quantity and sales by product category
SELECT
	ProductCategory,
        COUNT(*) OVER(PARTITION BY ProductCategory) TotalOrdersByProductCategory,
	SUM(Quantity) OVER(PARTITION BY ProductCategory) TotalQuantityByProductCategory,
	SUM(TotalPurchaseAmount) OVER(PARTITION BY ProductCategory) TotalAmountByProductCategory
FROM ecommerce_customer_data_custom_ratios
ORDER BY 2 DESC, 3 DESC;

3. Product Preferences

-- Total orders for each product category from highest to lowest
SELECT 
	productCategory,
	COUNT(*) OVER(PARTITION BY productCategory) purchase_count
FROM ecommerce_customer_data_custom_ratios
ORDER BY purchase_count DESC;

SELECT 
	CustomerName, 
	productCategory, 
	COUNT(*) purchase_count
FROM ecommerce_customer_data_custom_ratios
GROUP BY CustomerName,  productCategory
ORDER BY purchase_count DESC;

-- Rank total sales by year and product category
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

4. Sales Trends
-- Daily Sales Trends
SELECT 
SUBSTRING(PurchaseDate, 9,2) DATE, 
SUM(TotalPurchaseAmount) total_purchase_by_date
FROM ecommerce_customer_data_custom_ratios
GROUP BY DATE
ORDER BY DATE;

-- Monthly Sales Trends
SELECT
	SUBSTRING(PurchaseDate, 1,7) MONTH,
    COUNT(*) total_orders,
    SUM(Quantity) total_quantity,
    SUM(TotalPurchaseAmount) total_sales
FROM ecommerce_customer_data_custom_ratios
GROUP BY MONTH
ORDER BY MONTH;


-- Month-over-month sales performance between the current and previous year by finding the percentage change
SELECT
*,
CurrentMonthSales - PreviousMonthSales AS MoM_Sales_Change,
ROUND((CurrentMonthSales - PreviousMonthSales)/PreviousMonthSales*100, 2) AS MoM_Sales_Percentage,
FROM (
SELECT
    SUBSTRING(PurchaseDate, 1,7) MONTH,
    SUM(TotalPurchaseAmount) CurrentMonthSales,
    LAG(SUM(TotalPurchaseAmount)) OVER (ORDER BY SUBSTRING(PurchaseDate, 1,7)) PreviousMonthSales
FROM ecommerce_customer_data_custom_ratios
GROUP BY SUBSTRING(PurchaseDate, 1,7)
)t;


4. Customer Retention and Churn

-- Customers who make more than one purchase
SELECT CustomerName,
 COUNT(*) purchase_count
FROM ecommerce_customer_data_custom_ratios
GROUP BY CustomerName
HAVING COUNT(*) > 1;

-- Percentage of customers who make more than one purchase
WITH rfm AS (
    SELECT CustomerName,
    COUNT(CustomerID) as frequency
    FROM ecommerce_customer_data_custom_ratios
    GROUP BY CustomerName
)
SELECT 
    CONCAT(ROUND((COUNT(CASE WHEN frequency > 1 THEN 1 END) * 100.0 / COUNT(*)), 2), '%') AS repeat_purchase_percentage
FROM rfm;


5. Customer Segmentation
	
-- Find the last purchase, total of orders total purchase amount by customer
SELECT CustomerName,
       MAX(PurchaseDate) last_purchase,
       COUNT(PurchaseDate) frequency,
       SUM(PurchaseDate) monetary
FROM ecommerce_customer_data_custom_ratios
GROUP BY CustomerName
ORDER BY frequency DESC, monetary DESC;

-- Use the NTILE function to categorize customers based on recency, total number of orders (frequency)
   and purchase amount by customer (monetary)
	   
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


---- Segmenting based on RFM values

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


6. Cohort Analysis

WITH cohorts AS (
    SELECT 
        CustomerID,
        DATE_FORMAT(MIN(PurchaseDate), '%Y-%m') AS cohort_month
    FROM ecommerce_customer_data_custom_ratios
    GROUP BY CustomerID
),
retention AS (
    SELECT 
        c.cohort_month,
        DATE_FORMAT(p.PurchaseDate, '%Y-%m') AS purchase_month,
        COUNT(DISTINCT p.CustomerID) AS total_customers
    FROM cohorts c
    JOIN ecommerce_customer_data_custom_ratios p
    ON c.CustomerID = p.CustomerID
    GROUP BY c.cohort_month, purchase_month
),
initial_customers AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT CustomerID) AS initial_count
    FROM cohorts
    GROUP BY cohort_month
)
SELECT 
    r.cohort_month,
    r.purchase_month,
    r.total_customers,
    ic.initial_count,
    ROUND((r.total_customers / ic.initial_count) * 100, 2) AS retention_rate
FROM retention r
JOIN initial_customers ic
ON r.cohort_month = ic.cohort_month
ORDER BY r.cohort_month, r.purchase_month;
