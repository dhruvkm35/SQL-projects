SELECT * FROM pizza_db.dbo.pizzas
SELECT * FROM pizza_db.dbo.pizza_types

SELECT * FROM pizza_db.dbo.orders
SELECT * FROM pizza_db.dbo.order_details


/*
Basic:
Retrieve the total number of orders placed.
Calculate the total revenue generated from pizza sales.
Identify the highest-priced pizza.
Identify the most common pizza size ordered.
List the top 5 most ordered pizza types along with their quantities.

Intermediate:
Join the necessary tables to find the total quantity of each pizza category ordered.
Determine the distribution of orders by hour of the day.
Join relevant tables to find the category-wise distribution of pizzas.
Group the orders by date and calculate the average number of pizzas ordered per day.
Determine the top 3 most ordered pizza types based on revenue.

Advanced:
Calculate the percentage contribution of each pizza type to total revenue.
Analyze the cumulative revenue generated over time.
Determine the top 3 most ordered pizza types based on revenue for each pizza category.
*/

-- 1.Retrieve the total number of orders placed.
SELECT 
	COUNT(order_id) AS [Total number of orders]
FROM pizza_db.dbo.orders

-- 2.Calculate the total revenue generated from pizza sales.
SELECT 
	CONCAT(ROUND(SUM(od.quantity * p.price)/1000,2),'K') AS Total_revenue
FROM pizza_db.dbo.order_details AS od
JOIN pizza_db.dbo.pizzas AS p
ON od.pizza_id = p.pizza_id


-- 3.Identify the highest-priced pizza.
SELECT TOP 1
	pt.name,
	ROUND(p.price,2) AS price
FROM pizza_db.dbo.pizzas as p
 join  pizza_db.dbo.pizza_types as pt
 on pt.pizza_type_id = p.pizza_type_id
ORDER BY p.price DESC

--4. Identify the most common pizza size ordered.

SELECT
	p.size,
	COUNT(od.order_details_id) AS order_count
FROM pizza_db.dbo.pizzas  AS p
join pizza_db.dbo.order_details	 AS od
ON p.pizza_id = od.pizza_id
GROUP BY p.size
ORDER BY order_count DESC

--List the top 5 most ordered pizza types along with their quantities.

SELECT TOP 5
	pty.name,
	SUM(od.quantity) AS Total_quantity_sold
FROM pizza_db.dbo.order_details AS od 
 JOIN pizza_db.dbo.pizzas AS p
	ON od.pizza_id = p.pizza_id
 JOIN pizza_db.dbo.pizza_types AS pty
	ON pty.pizza_type_id = p.pizza_type_id
GROUP BY pty.name
ORDER BY Total_quantity_sold DESC


-- 6.Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT 
	pty.category,
	SUM(OD.quantity) AS Total_quantity_sold
FROM pizza_db.dbo.order_details AS OD
 JOIN pizza_db.dbo.pizzas AS P 
	ON P.pizza_id = OD.pizza_id
 JOIN pizza_db.dbo.pizza_types AS pty
	ON pty.pizza_type_id = P.pizza_type_id
GROUP BY pty.category
ORDER BY Total_quantity_sold DESC

-- 7.Determine the distribution of orders by hour of the day.
SELECT
	DATEPART(HOUR,time) AS [hours],
	COUNT(order_id) AS Order_count
FROM pizza_db.dbo.orders
GROUP BY DATEPART(HOUR,time)
ORDER BY DATEPART(HOUR,time)


-- 8.Join relevant tables to find the category-wise distribution of pizzas.
SELECT 
	category , 
	COUNT(name) AS [distribution] 
from pizza_db.dbo.pizza_types
GROUP BY category

-- 9.Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT AVG(quantity) [Avg pizzas order per day] FROM
	(SELECT 
		O.date, 
		SUM(quantity) AS quantity
	FROM pizza_db.dbo.orders AS O
	 JOIN pizza_db.dbo.order_details OD
		ON O.order_id = OD.order_id
	GROUP BY O.date) AS Total_quantity

-- 10.Determine the top 3 most ordered pizza types based on revenue.
SELECT TOP 3 
	pty.name ,
	SUM(OD.quantity*P.price) AS Total_revenue 
FROM pizza_db.dbo.pizza_types AS pty
 JOIN pizza_db.dbo.pizzas AS P
	ON pty.pizza_type_id = P.pizza_type_id
 JOIN pizza_db.dbo.order_details AS od
	ON p.pizza_id = od.pizza_id
GROUP BY pty.name
ORDER BY Total_revenue DESC

--11.Calculate the percentage contribution of each pizza category to total revenue.
SELECT 
	pty.category,
	CONCAT(ROUND(SUM(p.price * OD.quantity)  / (SELECT SUM(p.price * OD.quantity) 
									FROM pizza_db.dbo.order_details  AS OD
									JOIN pizza_db.dbo.pizzas AS p
									ON OD.pizza_id = p.pizza_id) *100,2),'%') percentage_of_each_pizza_category
	FROM pizza_db.dbo.order_details AS OD
JOIN pizza_db.dbo.pizzas AS p  
ON OD.pizza_id = p.pizza_id
JOIN pizza_db.dbo.pizza_types AS pty
ON p.pizza_type_id = pty.pizza_type_id
GROUP BY pty.category

--12.Calculate the percentage contribution of each pizza type to total revenue.
SELECT 
	pty.name , 
	CONCAT(ROUND(SUM(p.price * OD.quantity) / (SELECT SUM(p.price * OD.quantity)
												FROM pizza_db.dbo.order_details  AS OD
												JOIN pizza_db.dbo.pizzas AS p
											ON OD.pizza_id = p.pizza_id)*100,2),'%') 
											AS percentage_of_each_pizza_type
FROM pizza_db.dbo.order_details AS OD
JOIN pizza_db.dbo.pizzas AS p
ON OD.pizza_id = p.pizza_id
JOIN pizza_db.dbo.pizza_types AS pty
ON p.pizza_type_id = pty.pizza_type_id
GROUP BY pty.name
ORDER BY percentage_of_each_pizza_type DESC

--13.Analyze the cumulative revenue generated over time.
WITH Daily_revenue AS
	(SELECT 
		O.date,
		SUM(p.price * OD.quantity) AS total_revenue
	FROM pizza_db.DBO.orders AS O
	JOIN pizza_db.dbo.order_details AS OD
	ON O.order_id = OD.order_id
	JOIN pizza_db.dbo.pizzas AS p
	ON p.pizza_id = OD.pizza_id
	GROUP BY O.date
)
SELECT date ,
ROUND(SUM(total_revenue) OVER(ORDER BY date),2) AS Cumulative_revenue
from Daily_revenue;

--14.Determine the top 3 most ordered pizza types based on revenue for each pizza category.
WITH cte AS
	(SELECT
		pty.category,
		pty.name,
		ROUND(SUM(p.price * OD.quantity),2) AS Total_revenue
	FROM pizza_db.dbo.order_details AS OD
	JOIN pizza_db.dbo.pizzas AS p
	ON OD.pizza_id = OD.pizza_id
	JOIN pizza_db.dbo.pizza_types AS pty
	ON pty.pizza_type_id = p.pizza_type_id
	GROUP BY pty.category , pty.name
),
Ranked AS
(
SELECT *,
DENSE_RANK() OVER(PARTITION BY category ORDER BY  Total_revenue DESC) AS Rank_of_pizza
FROM cte
)
SELECT * FROM Ranked
WHERE Rank_of_pizza <= 3