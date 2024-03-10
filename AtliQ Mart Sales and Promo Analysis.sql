USE atliqmart;

-- Calling the products, campaigns, stores and events tables.

SELECT 
    *
FROM
    atliqmart.dim_products;

SELECT 
    *
FROM
    atliqmart.dim_campaigns;

SELECT 
    *
FROM
    atliqmart.dim_stores;

SELECT 
    *
FROM
    atliqmart.fact_events;
    
-- Updating the product_name column

UPDATE dim_products 
SET 
    product_name = REPLACE(REPLACE(product_name, '_', ''),
        'Atliq',
        '')
WHERE
    product_name LIKE '%Atliq%';


-- Total Unique Category Present

SELECT 
    COUNT(DISTINCT (category)) AS `Total Unique Category`
FROM
    atliqmart.dim_products;

-- 1. Provide a list of products with a base price greater than 500 and that are featured
-- in promo type of 'BOGOF' (Buy One Get One Free). This information will help us identify high-value 
-- products that are currently being heavily discounted, which can be useful for evaluating our pricing and 
-- promotion strategies.

SELECT DISTINCT
    E.base_price, P.product_name
FROM
    fact_events E
        LEFT JOIN
    dim_products P ON P.product_code = E.product_code
WHERE
    E.promo_type = 'BOGOF'
        AND E.base_price > 500;
        
-- 2. Generate a report that provides an overview of the number of stores in each city. 
-- The results will be sorted in descending order of store counts, allowing us to identify the 
-- cities with the highest store presence. The report includes two essential fields: city and store count, 
-- which will assist in optimizing our retail operations.

SELECT 
    COUNT(store_id) AS `Total Store`, city AS `City`
FROM
    dim_stores
GROUP BY city
ORDER BY `Total Store` DESC;

-- 3. Generate a report that displays each campaign along with the total revenue generated before and after the campaign? 
-- The report includes three key fields: campaign_name, total_revenue(before_promotion), total_revenue(after_promotion). 
-- This report should help in evaluating the financial impact of our promotional campaigns. (Display the values in millions)

SELECT 
    C.campaign_name AS `Campaign Name`, 
    FORMAT(SUM(E.`quantity_sold(after_promo)` * E.base_price) / 1000000, 2) AS `Total Revenue After Promo (Millions)`,
    FORMAT(SUM(E.`quantity_sold(before_promo)` * E.base_price) / 1000000, 2) AS `Total Revenue Before Promo (Millions)`
FROM 
    fact_events E
LEFT JOIN 
    dim_campaigns C ON E.campaign_id = C.campaign_id
GROUP BY 
    C.campaign_name;

-- 4. Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign. 
-- Additionally, provide rankings for the categories based on their ISU%. The report will include three key fields: category, 
-- isu%, and rank order. This information will assist in assessing the category-wise success and impact of the Diwali campaign 
-- on incremental sales. Note: ISU% (Incremental Sold Quantity Percentage) is calculated as the percentage increase/decrease in 
-- quantity sold (after promo) compared to quantity sold (before promo)

WITH category_incremental_sales AS (
    SELECT 
        P.category,
        (SUM(E.`quantity_sold(after_promo)`) - SUM(E.`quantity_sold(before_promo)`)) / SUM(E.`quantity_sold(before_promo)`) * 100 AS isu_percentage
    FROM 
        fact_events E
    INNER JOIN 
        dim_campaigns C ON E.campaign_id = C.campaign_id
    INNER JOIN 
        dim_products P ON E.product_code = P.product_code
    WHERE 
        C.campaign_name = 'Diwali'
    GROUP BY 
        P.category
)
SELECT 
    category,
    isu_percentage,
    RANK() OVER (ORDER BY isu_percentage DESC) AS rank_order
FROM 
    category_incremental_sales
ORDER BY 
    rank_order;
    
-- 5. Create a report featuring the Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns. 
-- The report will provide essential information including product name, category, and ir%. 
-- This analysis helps identify the most successful products in terms of incremental revenue across our campaigns, assisting in product optimization.

WITH product_incremental_revenue AS (
    SELECT 
        P.product_name,
        P.category,
        (SUM(E.`quantity_sold(after_promo)` * E.base_price) - SUM(E.`quantity_sold(before_promo)` * E.base_price)) / SUM(E.`quantity_sold(before_promo)` * E.base_price) * 100 AS ir_percentage
    FROM 
        fact_events E
    INNER JOIN 
        dim_products P ON E.product_code = P.product_code
    GROUP BY 
        P.product_name, P.category
)
SELECT 
    product_name,
    category,
    ir_percentage,
    RANK() OVER (ORDER BY ir_percentage DESC) AS rank_order
FROM 
    product_incremental_revenue
ORDER BY 
    rank_order
LIMIT 5;