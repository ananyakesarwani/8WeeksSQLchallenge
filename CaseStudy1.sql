USE dannys_diner;
-- 1.What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(menu.price) as total_spent 
FROM sales INNER JOIN menu
	ON sales.product_id = menu.product_id
GROUP BY customer_id;

-- 2.How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS days_visited
FROM sales
GROUP BY customer_id;

-- 3.What was the first item from the menu purchased by each customer?
WITH date_rank AS 
(
	SELECT customer_id , order_date, product_id,
    DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS order_rank
     FROM sales
)
SELECT customer_id, order_date, M.product_name 
FROM date_rank
INNER JOIN menu M
	ON date_rank.product_id = M.product_id
WHERE order_rank = 1
GROUP BY customer_id, M.product_name;

-- 4.What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT  M.product_name, COUNT(S.product_id) AS num_purchase
FROM sales S INNER JOIN menu M
	ON S.product_id = M.product_id
GROUP BY S.product_id
ORDER BY num_purchase DESC
LIMIT 1;

-- 5.Which item was the most popular for each customer?
WITH order_rank_cte AS 
(
	SELECT customer_id, product_id, COUNT(product_id) AS times_ordered,
    DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) AS order_rank
	FROM sales
    GROUP BY customer_id, product_id
)
SELECT customer_id, menu.product_name AS favorite_product, times_ordered
FROM order_rank_cte INNER JOIN menu
	ON order_rank_cte.product_id = menu.product_id
WHERE order_rank = 1
ORDER BY customer_id;

-- 7.Which item was purchased first by the customer after they became a member?
SELECT sales.customer_id, order_date, menu.product_name
FROM sales INNER JOIN members
	ON sales.customer_id = members.customer_id
INNER JOIN menu
	ON sales.product_id = menu.product_id
WHERE order_date >= members.join_date
GROUP BY sales.customer_id;

-- 8.Which item was purchased just before the customer became a member?
SELECT sales.customer_id, order_date, menu.product_name
FROM sales INNER JOIN members
	ON sales.customer_id = members.customer_id
INNER JOIN menu
	ON sales.product_id = menu.product_id
WHERE order_date < members.join_date
GROUP BY sales.customer_id;
-- 9.What is the total items and amount spent for each member before they became a member?
SELECT sales.customer_id, order_date, SUM(menu.price) AS amount_spent
FROM sales INNER JOIN members
	ON sales.customer_id = members.customer_id
INNER JOIN menu
	ON sales.product_id = menu.product_id
WHERE order_date < members.join_date
GROUP BY sales.customer_id;

-- 10.If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- how many points would each customer have?

SELECT customer_id, SUM(menu.price) AS amount_spent, 
SUM(IF(menu.product_name = 'sushi',menu.price*10*2, menu.price*10)) AS points
FROM sales INNER JOIN menu
	ON sales.product_id = menu.product_id
GROUP BY customer_id;
    
-- 11.In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH joining_week_cte AS
(
	SELECT sales.customer_id, order_date
    FROM sales INNER JOIN members
		ON sales.customer_id = members.customer_id
	WHERE DATE(order_date) >= DATE(join_date) AND DATE(order_date) <= DATE(join_date+6)
) 
SELECT customer_id, 
SUM(IF(order_date IN (SELECT order_date from joining_week_cte),
		menu.price*2*10, 
			IF(menu.product_name = 'sushi',menu.price*2*10, menu.price*10))) AS points
FROM sales INNER JOIN menu
	ON sales.product_id = menu.product_id
WHERE order_date <= '2021-01-31'
GROUP BY customer_id;