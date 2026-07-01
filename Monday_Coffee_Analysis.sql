-- Monday Coffee 

SELECT * FROM city; 
SELECT * FROM products; 
SELECT * FROM customers; 
SELECT * FROM sales; 

--Reports & Data Analysis

-- Q.1 Coffee Consumers Count
How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
	city_name,
	ROUND(
	(population * 0.25)/1000000,2) as 
	coffee_consumer_in_millions,
	city_rank
 	FROM city
	 ORDER BY 2 DESC;

-- Q.2 Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
	ct.city_name,
	SUM(s.total) as Total_revenue
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ct
	ON ct.city_id = c.city_id
	WHERE 
	EXTRACT(year from s.sale_date) = 2023
	AND
	EXTRACT(quarter from s.sale_date) = 4
	GROUP BY 1
	ORDER BY 2 DESC; 

-- Q.3 Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products as p
JOIN sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;


-- Q.4 Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT 
	ct.city_name,
	SUM(s.total) AS total_revenue,
	COUNT(DISTINCT c.customer_id) as total_cx,
	ROUND((SUM(s.total)/COUNT(DISTINCT c.customer_id))::numeric,2) as avg_sales_per_customer
FROM sales as s
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ct
ON ct.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;

 
-- Q.5 City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.

WITH city_table
AS
(SELECT 
	city_name,
	ROUND((population * 0.25)/1000000,2) as estimated_coffee_cx_in_millions
	FROM city ),

customer_table
AS 
	(SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC)

	SELECT 
		customer_table.city_name,
		city_table.estimated_coffee_cx_in_millions as coffee_consumers_in_millions,
		customer_table.unique_cx
		FROM city_table 
		JOIN customer_table 
		ON city_table .city_name = customer_table.city_name
-- OR


SELECT
    ci.city_name,
    COUNT(DISTINCT c.customer_id) as unique_cx,
    ROUND(
        SUM((ci.population * 0.25)/1000000)
    , 2) as coffee_consumers_in_millions
FROM city as ci
LEFT JOIN
    customers as c
ON c.city_id = ci.city_id
GROUP BY 1
ORDER BY 2 DESC;

		

-- Q.6 Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

WITH CTE 
AS
(SELECT 
	ci.city_name,
	p.product_name,
	COUNT(s.sale_id) as total_orders,
	DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id)DESC) as rank
	FROM sales as s
	JOIN products  as p
	ON s.product_id = p.product_id
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1,2)

	SELECT * FROM CTE
	WHERE 
		rank <= 3


-- Q.7 Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
	FROM city as ci
LEFT JOIN customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE
	product_id BETWEEN 1 AND 14
GROUP BY 1
ORDER BY 1,2 DESC


-- Q.8 Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

SELECT 
    ci.city_name,
    ci.estimated_rent,
    ROUND((SUM(s.total) / COUNT(DISTINCT s.customer_id))::numeric, 2) AS avg_sale_per_cx,
    ROUND((ci.estimated_rent / COUNT(DISTINCT s.customer_id))::numeric, 2) AS avg_rent_per_cx
FROM sales AS s
JOIN customers AS c
    ON c.customer_id = s.customer_id
JOIN city AS ci
    ON ci.city_id = c.city_id
GROUP BY ci.city_name, ci.estimated_rent
ORDER BY avg_sale_per_cx DESC;

-----------------------------------------------
WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) AS total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
			(SUM(s.total)/COUNT(DISTINCT s.customer_id))::numeric
			,2) 
			as avg_sales_per_cx
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),

city_rent
AS
(
	SELECT 
		city_name,
		estimated_rent
		FROM city
)

SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sales_per_cx
	ROUND(
		cr.estimated_rent ::numeric/ct.total_cx ::numeric
	,2) as avg_rent_per_cx
	
	FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name


-- Q.9 Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different 
-- time periods (monthly).
-- by each city

WITH city_growth
AS
(SELECT 
	ci.city_name,
	EXTRACT(month FROM sale_date) as month,
	EXTRACT(year FROM sale_date) as year,
	SUM(s.total) as total_sales
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1,2,3
	ORDER BY 1,3,2
	),

growth_ratio as	
(
SELECT 
	city_name,
	month,
	year,
	total_sales as cr_month_sale,
	LAG(total_sales, 1) OVER(PARTITION BY city_name ORDER BY year,month) as last_month_sales
	FROM city_growth
) 


SELECT 
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sales,
	ROUND((cr_month_sale - last_month_sales)::numeric / last_month_sales::numeric * 100,2)   as ratio
	from growth_ratio
	WHERE
	   last_month_sales IS NOT NULL


-- Q.10 Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, 
-- total customers, estimated coffee consumer

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) AS total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
			(SUM(s.total)/COUNT(DISTINCT s.customer_id))::numeric
			,2) 
			as avg_sales_per_cx
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1

),

city_rent
AS
(
	SELECT 
		city_name,
		estimated_rent,
		ROUND((population *.25) / 1000000,3) as estimated_coffee_consumers_in_millions
		FROM city
)

SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumers_in_millions,
	ct.avg_sales_per_cx,
	ROUND(
		cr.estimated_rent ::numeric/ct.total_cx ::numeric
	,2) as avg_rent_per_cx
	FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC


/*

Recommendation (Summary)

Pune
	* Avg rent per customer is very low
	* Highest total revenue
	* Avg sale per customer is high

Delhi
	* Largest coffee consumer base (7.7M)
	* High total customers (68)
	* Avg rent per customer = 330 (still reasonable)

Jaipur
	* Highest customer count (69)
	* Very low avg rent per customer (156)
	* Strong avg sale per customer (11.6k)


Overall:

	=> Prioritize Pune for immediate focus (best balance of revenue and efficiency).
	
	=> Consider Delhi for scale advantages.
	
	=> Explore Jaipur for cost‑efficient growth.











