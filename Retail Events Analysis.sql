-- Project Name : Analyse Promotions and Provide Tangible Insights to Sales Director

-- Project Domain: FMCG Function: Sales / Promotions

-- Problem Statement :
-- AtliQ Mart is a retail giant with over 50 supermarkets in the southern region of India. All
-- their 50 stores ran a massive promotion during the Diwali 2023 and Sankranti 2024
-- (festive time in India) on their AtliQ branded products. Now the sales director wants to
-- understand which promotions did well and which did not so that they can make
-- informed decisions for their next promotional period.

USE retail_events_db;

-- Q.1)Provide alist of products with a base price greater than 500 and that are featured
-- in promo type of 'BOGOF' (Buy One Get One Free). This information will help us
-- identify high-value products that are currently being heavily discounted, which
-- can be useful for evaluating our pricing and promotion strategies.

SELECT product_name,sum(base_price) AS base_price
FROM dim_products p 
JOIN fact_events e ON p.product_code=e.product_code
WHERE base_price > 500 AND promo_type="BOGOF"
GROUP BY product_name;

-- Q.2)Generate a report that provides an overview of the number of stores in each city.
-- The results will be sorted in descending order of store counts, allowing us to
-- identify the cities with the highest store presence.The report includes two
-- essential fields: city and store count, which will assist in optimizing our retail
-- operations.

SELECT city,COUNT(DISTINCT store_id) as store_count
FROM dim_stores
GROUP BY city
ORDER BY store_count DESC;

-- Q.3)Generate a report that displays each campaign along with the total revenue
-- generated before and after the campaign? The report includes three key fields:
-- campaign_name, total_revenue(before_promotion),
-- total_revenue(after_promotion). This report should help in evaluating the financial
-- impact of our promotional campaigns. (Display the values in millions)

SELECT c.campaign_name,
      ROUND(SUM(base_price*quantity_sold_before_promo)/1000000,2) AS total_revenue_before_promo_mln,
      SUM(CASE 
          WHEN promo_type="50% OFF" THEN ROUND((base_price*0.5*quantity_sold_after_promo)/1000000,2)
          WHEN promo_type="25% OFF" THEN ROUND((base_price*0.75*quantity_sold_after_promo)/1000000,2) 
          WHEN promo_type="33% OFF" THEN ROUND((base_price*0.67*quantity_sold_after_promo)/1000000,2)
          WHEN promo_type="500 Cashback" THEN ROUND(((base_price*quantity_sold_after_promo)-500)/1000000,2)
          WHEN promo_type="BOGOF" THEN ROUND((quantity_sold_after_promo*2*base_price*0.5)/1000000,2)
	  END) AS total_revenue_after_promo_mln
FROM fact_events e
JOIN dim_campaigns c ON e.campaign_id=c.campaign_id
GROUP BY c.campaign_name;

-- Q.4)Produce a report that calculates the Incremental Sold Quantity (ISU%) for each
-- category during the Diwali campaign. Additionally, provide rankings for the
-- categories based on their ISU%. The report will include three key fields:
-- category, isu%, and rank order. This information will assist in assessing the
-- category-wise success and impact of the Diwali campaign on incremental sales.

WITH IR_PCT AS (
SELECT category,SUM((quantity_sold_after_promo-quantity_sold_before_promo)/quantity_sold_before_promo) AS IR_Percentage
FROM dim_products p
JOIN fact_events e ON e.product_code=p.product_code
GROUP BY category)
SELECT *,
	   RANK() OVER(ORDER BY IR_Percentage DESC) as rnk
FROM IR_PCT;

-- Q.5)Create a report featuring the Top 5 products, ranked by Incremental Revenue
-- Percentage (IR%), across all campaigns. The report will provide essential
-- information including product name, category, and ir%. This analysis helps
-- identify the most successful products in terms of incremental revenue across our
-- campaigns, assisting in product optimization

WITH total_revenue AS (
SELECT product_name,category,
	   ROUND(SUM(base_price*quantity_sold_before_promo)/1000000,2) AS total_revenue_before_promo_mln,
       SUM(CASE 
          WHEN promo_type="50% OFF" THEN ROUND((base_price*0.5*quantity_sold_after_promo)/1000000,2)
          WHEN promo_type="25% OFF" THEN ROUND((base_price*0.75*quantity_sold_after_promo)/1000000,2) 
          WHEN promo_type="33% OFF" THEN ROUND((base_price*0.67*quantity_sold_after_promo)/1000000,2)
          WHEN promo_type="500 Cashback" THEN ROUND(((base_price*quantity_sold_after_promo)-500)/1000000,2)
          WHEN promo_type="BOGOF" THEN ROUND((quantity_sold_after_promo*2*base_price*0.5)/1000000,2)
	   END) AS total_revenue_after_promo_mln
FROM dim_products p
JOIN fact_events e ON p.product_code=e.product_code
GROUP BY product_name,category)
SELECT product_name,category,
         CONCAT(ROUND((total_revenue_after_promo_mln-total_revenue_before_promo_mln)*100/total_revenue_before_promo_mln,2),"%") AS IR_Percentage
FROM total_revenue;






