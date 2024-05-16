use [order data];
CREATE TABLE df_order (
    order_id INT PRIMARY KEY,
    order_date DATE,
    ship_mode VARCHAR(255),
    segment VARCHAR(255),
    country VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    postal_code INT,
    region VARCHAR(255),
    category VARCHAR(255),
    sub_category VARCHAR(255),
    product_id VARCHAR(255),
    quantity INT,
    discount DECIMAL(10, 2),
    sale_price DECIMAL(10, 2),
    profit DECIMAL(10, 2)
);




--find top 10 highest reveue generating products 
      
SELECT top 10 product_id, SUM(sale_price * quantity) AS total_revenue
FROM df_order
GROUP BY product_id
ORDER BY total_revenue DESC;

--find top 5 highest selling products in each region

WITH ranked_products AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY region ORDER BY total_quantity_sold DESC) AS rank
    FROM (
        SELECT region, product_id, SUM(quantity) AS total_quantity_sold
        FROM df_order
        GROUP BY region, product_id
    ) AS region_product_sales
)
SELECT  region, product_id, total_quantity_sold
FROM ranked_products
WHERE rank <= 5;



--find month over month growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023
with cte as (
select year(order_date) as order_year,month(order_date) as order_month,
sum(sale_price) as sales
from df_order
group by year(order_date),month(order_date)
	)
select order_month
, sum(case when order_year=2022 then sales else 0 end) as sales_2022
, sum(case when order_year=2023 then sales else 0 end) as sales_2023
from cte 
group by order_month
order by order_month


--better solution   
 with cte as(
 select DATEPART(YEAR, order_date) AS order_year,DATEPART(MONTH, order_date) AS order_month,(sale_price ) as sales
 from df_order
 )
 select *
 from cte
 PIVOT  
(   SUM(sales)  
    FOR [order_year] IN ( [2022], [2023])  
) AS sales_per_year
ORDER BY order_month;



--for each category which month had highest sales
 with cte as(
 SELECT *,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales DESC) AS rank
    FROM (
		select category,DATEPART(YEAR, order_date) AS order_year, DATEPART(MONTH, order_date) AS order_month, Sum (sale_price) as sales
		from df_order
		group by category,DATEPART(YEAR, order_date), DATEPART(MONTH, order_date)
	) AS category_sales
)
SELECT  category,order_year,order_month,sales
FROM cte
WHERE rank <= 1;



--which sub category had highest growth by profit in 2023 compare to 2022
with cte as(
		select category,sub_category,DATEPART(YEAR, order_date) AS order_year, sale_price
		from df_order
		--group by category,sub_category, DATEPART(YEAR, order_date)	
)
, cte2 as(
 select *
 from cte
 PIVOT  
(  SUM (sale_price)
    FOR [order_year] IN ( [2022],[2023]) 
) AS sales_per_sub_category

)
select TOP 1 *, ( (cte2.[2023]-cte2.[2022])) as growth
from cte2
order by growth DESC;

-- Other solution 
with cte as (
select sub_category,year(order_date) as order_year,
sum(sale_price) as sales
from df_order
group by sub_category,year(order_date)
--order by year(order_date),month(order_date)
	)
, cte2 as (
select sub_category
, sum(case when order_year=2022 then sales else 0 end) as sales_2022
, sum(case when order_year=2023 then sales else 0 end) as sales_2023
from cte 
group by sub_category
)
select top 1 *
,(sales_2023-sales_2022)
from  cte2
order by (sales_2023-sales_2022) desc