-- SCHEMAS 
SELECT * FROM monday_coffee.sales;
SELECT * FROM monday_coffee.products;
SELECT * FROM monday_coffee.customers;
SELECT * FROM monday_coffee.city;

use monday_coffee;

-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
select city_name, round((population * 0.25)/1000000,2) as population_in_millions, city_rank 
from city 
order by population_in_millions desc;

-- Total Revenue from Coffee Sales
select sum(total) as total_revenue 
from sales 
where extract(quarter from sale_date) = 4 
and
extract(year from sale_date) = 2023;

-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT 
ci.city_name,
SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
EXTRACT(YEAR FROM s.sale_date)  = 2023
AND
EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- Sales Count for Each Product
select p.product_name, count(p.product_id) as sales_count_for_each_product 
from products as p 
left join sales as s 
on p.product_id = s.product_id
group by p.product_name
order by sales_count_for_each_product desc;

-- How many units of each coffee product have been sold?
select p.product_name, count(s.sale_id) as unit_sold 
from products as p
join sales as s
on p.product_id = s.product_id
group by p.product_name
order by unit_sold desc
;

-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- Return city_name, total current cx, estimated coffee consumers (25%)
WITH city_table as 
(
SELECT city_name, ROUND((population * 0.25)/1000000, 2) as coffee_consumers
FROM city
),
customers_table
AS
(
SELECT 
ci.city_name,
COUNT(DISTINCT c.customer_id) as unique_cx
FROM sales as s
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY ci.city_name
)
SELECT 
customers_table.city_name,
city_table.coffee_consumers as coffee_consumer_in_millions,
customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name;

-- What are the top 3 selling products in each city based on sales volume?
select * 
from
(
select ci.city_name, p.product_name, count(s.sale_id) as total_selling_product,
dense_rank() over(partition by ci.city_name order by count(s.sale_id) desc) as city_rank
from products as p
join sales as s
on p.product_id = s.product_id
join customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id = c.city_id
group by ci.city_name, p.product_name
) as t1
where city_rank <= 3
;

-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
select ci.city_name, count(distinct c.customer_name) as total_customers
from city as ci
left join customers as c
on c.city_id = ci.city_id
join sales as s
on s.customer_id = c.customer_id
where s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by ci.city_name
;


-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
with city_table as
(
select city_name, estimated_rent
from city
),
city_rank as
(
select ci.city_name, COUNT(DISTINCT s.customer_id) as total_cx,
count(distinct c.customer_id) as unique_customer, round(sum(s.total)/count(distinct c.customer_id),2) as avg_sale
from city as ci
join customers as c
on ci.city_id = c.city_id
join sales as s
on s.customer_id = c.customer_id
group by ci.city_name
order by avg_sale desc
)
select ct.city_name, ct.estimated_rent, cr.avg_sale, cr.unique_customer,
round(ct.estimated_rent / cr.total_cx, 2) as avg_rent
from city_table as ct
join city_rank as cr
on ct.city_name = cr.city_name
;

-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
WITH city_table
AS
(
	SELECT ci.city_name,
SUM(s.total) as total_revenue,
COUNT(DISTINCT s.customer_id) as total_cx,
ROUND(SUM(s.total) /COUNT(DISTINCT s.customer_id) ,2) as avg_sale_pr_cx
		
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
estimated_rent,
ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
FROM city
)
SELECT 
cr.city_name,
total_revenue,
cr.estimated_rent as total_rent,
ct.total_cx,
estimated_coffee_consumer_in_millions,
ct.avg_sale_pr_cx,
ROUND(cr.estimated_rent /ct.total_cx, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;
