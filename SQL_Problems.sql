-- Business Problems
--TABLES INCLUDE CATERGORY, PRODUCT, SALES, STORES, WARRANTY 


-- 1.Find each country and number of stores
SELECT DISTINCT(s.country), COUNT(s.store_id)
FROM STORES AS s
GROUP BY s.country
ORDER BY s.country;

--2. What is the total number of units sold by each store?
SELECT * FROM STORES;


SELECT s1.store_id,s2.store_name, SUM(s1.quantity) AS Total_Units
FROM SALES AS s1
INNER JOIN STORES AS s2
ON s1.store_id = s2.store_id
GROUP BY s1.store_id,s2.store_name
ORDER BY Total_Units desc;

--3. How many sales occurred in December 2023?
SELECT * FROM SALES;

SELECT SUM(s.quantity)
FROM SALES AS s
WHERE s.sale_date BETWEEN '2023-12-01' AND '2023-12-31';

--4. How many stores have never had a warranty claim filed against any of their products?

SELECT store_id,store_name 
FROM STORES
WHERE store_id NOT IN (
		SELECT DISTINCT(s1.store_id)
		FROM WARRANTY AS w
		INNER JOIN SALES AS s1
		ON w.sale_id = s1.sale_id
);


SELECT * FROM SALES;
SELECT * FROM STORES;

--5. What percentage of warranty claims are marked as "Warranty Void"?
SELECT ROUND(COUNT(claim_id)/(SELECT COUNT(*) FROM warranty)::numeric * 100, 2) as warranty_void_percentage
FROM warranty
WHERE repair_status = 'Warranty Void'

--6. Which store had the highest total units sold in the last year?
SELECT s1.store_id,s2.store_name, SUM(s1.quantity) AS Total_Units
FROM SALES AS s1
INNER JOIN STORES AS s2
ON s1.store_id = s2.store_id
WHERE s1.sale_date >= CURRENT_DATE - INTERVAL '2 Year'
GROUP BY s1.store_id,s2.store_name
ORDER BY Total_Units desc
LIMIT 1;

--7. Count the number of unique products sold in the last year.

SELECT p.product_id,p.product_name,COUNT(*) AS Total_sold
FROM PRODUCTS AS p
INNER JOIN SALES AS s
ON p.product_id = s.product_id
WHERE s.sale_date >= CURRENT_DATE - INTERVAL '2 Year'
GROUP BY p.product_id,p.product_name;

--8. What is the average price of products in each category?

SELECT DISTINCT(p.category_id), AVG(p.price) AS AVG_PRICE
FROM PRODUCTS AS p
GROUP BY p.category_id
ORDER BY 1;

--9. How many warranty claims were filed in 2020?
SELECT COUNT(*)
FROM WARRANTY AS w
WHERE w.claim_date BETWEEN '2020-01-01' AND '2020-12-31';

--10. Identify each store and best selling day based on highest qty sold

SELECT *
FROM
(
SELECT s1.store_name, 
	   EXTRACT (DOW FROM s2.sale_date) AS day_of_week, 
	   SUM(s2.quantity) AS total_sales,
	   RANK() OVER (PARTITION BY s1.store_name ORDER BY COUNT(s2.sale_id) DESC) AS RANK
FROM STORES AS s1
INNER JOIN SALES AS s2
ON s1.store_id = s2.store_id
GROUP BY 1,2
) AS t1
WHERE RANK = 1;


--11. Identify least selling product of each country for each year based on total unit sold

SELECT * FROM PRODUCTS;
SELECT * FROM STORES;

WITH least_selling_product
AS
(
SELECT s2.country, 
       p.product_name, 
	   TO_CHAR(s1.sale_date,'YYYY') AS YEAR,
	   SUM(s1.quantity) AS total_sold,
	   RANK() OVER(PARTITION BY s2.country,TO_CHAR(s1.sale_date,'YYYY') ORDER BY SUM(s1.quantity) ASC) AS RANK
FROM PRODUCTS AS p
INNER JOIN SALES AS s1 
ON p.product_id = s1.product_id
INNER JOIN STORES AS s2
ON s1.store_id = s2.store_id
GROUP BY 1,2,3
order by 1,3,4 ASC
)
SELECT * 
FROM least_selling_product
WHERE RANK = 1;


--12. How many warranty claims were filed within 180 days of a product sale?

SELECT COUNT(*)
FROM 
(
SELECT s.sale_date, w.claim_date, s.sale_id , s.sale_date - w.claim_date AS days_within_warranty_claim
FROM WARRANTY AS w
INNER JOIN SALES AS s
ON w.sale_id = s.sale_id
WHERE w.claim_date - s.sale_date < 180
order by 1,2,4 ASC
) AS T1

--13. How many warranty claims have been filed for products launched in the last two years?

--PRODUCTS LAUNCHED IN LAST TWO YEARS (11)
SELECT p.product_name,p.launch_date
FROM PRODUCTS AS p
WHERE p.launch_date > CURRENT_DATE - INTERVAL '3 Year';

-- ENTIRE QUERY
SELECT p.product_name,p.launch_date,s.sale_id
FROM PRODUCTS AS p
INNER JOIN SALES AS s
ON p.product_id = s.product_id
INNER JOIN STORES AS s1
ON s.store_id = s1.store_id
WHERE p.launch_date > CURRENT_DATE - INTERVAL '3 Year' 
AND s.sale_id IN 
(
	SELECT sale_id 
	FROM WARRANTY 
)
GROUP BY 1,2,3;

-- 14. List the months in the last 3 years where sales exceeded 5000 units from usa.

SELECT TO_CHAR(s.sale_date,'YYYY-MM'), s1.country, sum(s.quantity)
FROM SALES AS s
INNER JOIN STORES AS s1
ON s.store_id = s1.store_id
WHERE s1.country = 'USA' AND s.sale_date > CURRENT_DATE - INTERVAL '4 Year'
GROUP BY 2,1
HAVING sum(s.quantity) > 5000
ORDER BY 1,3 ASC;

--15. Which product category had the most warranty claims filed in the last 2 years?

SELECT * FROM CATEGORY;

SELECT s.product_id, p.product_name, c.category_name, COUNT(w.sale_id)  
FROM WARRANTY AS w
LEFT JOIN SALES AS s
ON w.sale_id = s.sale_id
INNER JOIN PRODUCTS AS p
ON s.product_id = p.product_id
JOIN CATEGORY AS c
ON p.category_id = c.category_id
WHERE w.claim_date > CURRENT_DATE - INTERVAL '3 Year'
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 1


--16. Determine the percentage chance of receiving claims after each purchase for each country

--first lets find out warranty claims against each country

SELECT s1.country,
COUNT(w.repair_status) AS total_claim_by_country,
SUM(s2.quantity) AS total_sales,
ROUND(100.0 * COUNT(w.repair_status) / SUM(s2.quantity),2) AS percent_share
FROM STORES AS s1
JOIN SALES AS s2
ON s1.store_id = s2.store_id
LEFT JOIN WARRANTY AS w
ON s2.sale_id = w.sale_id 
GROUP BY 1
ORDER BY 4 DESC;


--17. Analyze each stores year by year growth ratio by total orders and total sales done 

SELECT * FROM PRODUCTS;

WITH growth_ratio 
AS 
(
SELECT s1.store_name, 
	   TO_CHAR(s2.sale_date, 'YYYY'),
	   SUM(s2.quantity) AS total_orders, 
	   SUM(p.price) AS current_yr_sale,
	   LAG(SUM(p.price),1) OVER(PARTITION BY s1.store_name ORDER BY TO_CHAR(s2.sale_date, 'YYYY')) AS prev_yr_sale
FROM STORES AS s1
INNER JOIN SALES AS s2
on s1.store_id = s2.store_id
RIGHT JOIN PRODUCTS AS p
ON s2.product_id = p.product_id
GROUP BY 1,2
)
SELECT *,
       ROUND((current_yr_sale::numeric-prev_yr_sale::numeric)/prev_yr_sale::numeric*100,2)
FROM growth_ratio 

--18. What is the correlation between product price and warranty claims for products sold in the last five years? (Segment based on diff price)

select * from warranty

SELECT 
	   CASE 
	       WHEN p.price < 500 THEN 'Less Expensive Product'
		   WHEN p.price BETWEEN 500 AND 1000 THEN 'Mid Range Product'
		   ELSE 'High End Product'
	   END AS Product_Catergory,
	   count(w.claim_id) AS warranty_claims
FROM WARRANTY AS w
LEFT JOIN SALES AS s
ON w.sale_id = s.sale_id 
JOIN PRODUCTS AS p
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 ASC;

--19. Identify the store with the highest percentage of "Paid Repaired" claims in relation to total claims filed overall across stores

WITH paid_claim_by_store 
AS
(
SELECT s1.store_name, 
       COUNT(w.repair_status) AS total_paid_repaired_claims,
	   (
		   SELECT COUNT(w.repair_status)
		   FROM STORES AS s1
		   LEFT JOIN SALES AS s2
		   ON s1.store_id = s2.store_id
		   JOIN WARRANTY AS w
		   ON s2.sale_id = w.sale_id 
	   ) AS total_claims
FROM STORES AS s1
LEFT JOIN SALES AS s2
ON s1.store_id = s2.store_id
JOIN WARRANTY AS w
ON s2.sale_id = w.sale_id 
WHERE w.repair_status = 'Paid Repaired'
GROUP BY 1
ORDER BY 2 DESC
) 
SELECT *,
       ROUND(total_paid_repaired_claims::numeric/total_claims::numeric * 100,2) AS percent_of_total_claims
FROM paid_claim_by_store
ORDER BY 4 DESC;


--19. Identify the store with the highest percentage of "Paid Repaired" claims in relation to total claims filed for that store itself 


WITH paid_claim_by_store 
AS
(
	SELECT s1.store_name, 
	COUNT(w.repair_status) AS total_paid_repaired_claims
	FROM STORES AS s1
	LEFT JOIN SALES AS s2
	ON s1.store_id = s2.store_id
	JOIN WARRANTY AS w
	ON s2.sale_id = w.sale_id 
	WHERE w.repair_status = 'Paid Repaired'
	GROUP BY 1
	ORDER BY 1 ASC
), total_claims_by_store
AS
(
    SELECT s1.store_name, 
	COUNT(w.repair_status) AS total_claims
	FROM STORES AS s1
	LEFT JOIN SALES AS s2
	ON s1.store_id = s2.store_id
	JOIN WARRANTY AS w
	ON s2.sale_id = w.sale_id 
	GROUP BY 1
	ORDER BY 1 ASC
)

SELECT p.store_name, 
       p.total_paid_repaired_claims, 
	   t.total_claims, 
	   ROUND(p.total_paid_repaired_claims::numeric/t.total_claims::numeric*100,2) AS percent_of_paid_repaired_claims
FROM paid_claim_by_store AS p
JOIN total_claims_by_store AS t
ON p.store_name = t.store_name
ORDER BY 4 DESC;


-- 20.Write SQL query to calculate the monthly running total of sales for each store over the past four years and compare the trends across this period?

WITH growth_ratio 
AS 
(
SELECT s1.store_name, 
	   TO_CHAR(s2.sale_date, 'YYYY-MM'),
	   -- SUM(s2.quantity) AS total_orders, 
	   SUM(p.price * s2.quantity) AS total_revenue_current_month,
	   LAG(SUM(p.price * s2.quantity),1) OVER(PARTITION BY s1.store_name ORDER BY TO_CHAR(s2.sale_date, 'YYYY-MM')) AS prev_yr_sale
FROM STORES AS s1 
LEFT JOIN SALES AS s2
on s1.store_id = s2.store_id
JOIN PRODUCTS AS p
ON s2.product_id = p.product_id
GROUP BY 1,2
)
SELECT *,
       ROUND((total_revenue_current_month::numeric-prev_yr_sale::numeric)/prev_yr_sale::numeric*100,2)
FROM growth_ratio


--21.Analyze sales trends of product over time, segmented into key time periods: from launch to 6 months, 6-12 months, 12-18 months, and beyond 18 months?


SELECT p.product_name, 
       CASE 
	       WHEN s.sale_date BETWEEN p.launch_date AND p.launch_date + INTERVAL '6 months' THEN '0-6 Months'
		   WHEN s.sale_date > p.launch_date + INTERVAL '6 months' AND s.sale_date <= p.launch_date + INTERVAL '12 months' THEN '6-12 Months'
		   WHEN s.sale_date > p.launch_date + INTERVAL '12 months' AND s.sale_date <= p.launch_date + INTERVAL '18 months' THEN '12-18 Months'
		   ELSE '18+ Months'
		END AS time_segment,
       SUM(p.price * s.quantity) AS total_revenue
FROM PRODUCTS AS p
LEFT JOIN SALES AS s
ON p.product_id = s.product_id
GROUP BY 1,2
ORDER BY 1;

SELECT *
FROM PRODUCTS AS p
LEFT JOIN SALES AS s
ON p.product_id = s.product_id



















