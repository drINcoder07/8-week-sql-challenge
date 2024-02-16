-- LINK TO Week 1: https://8weeksqlchallenge.com/case-study-1/
 -- DATA INSPECTION

SELECT *
FROM dannys_diner.sales;


SELECT *
FROM dannys_diner.menu;


SELECT *
FROM dannys_diner.members;

-- CASE STUDY QUESTIONS:
-- What is the total amount each customer spent at the restaurant?

SELECT s.customer_id,
       SUM(m.price) AS total_amount
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- How many days has each customer visited the restaurant?

SELECT customer_id,
       COUNT(DISTINCT order_date)
FROM dannys_diner.sales
GROUP BY customer_id;

-- What was the first item from the menu purchased by each customer?
WITH customers_and_items AS
   (SELECT s.customer_id,
           s.order_date,
           m.product_name
    FROM dannys_diner.sales s
    LEFT JOIN dannys_diner.menu m ON s.product_id = m.product_id),
     customers_and_items_arranged AS
   (SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id
                              ORDER BY order_date)
    FROM customers_and_items)
SELECT customer_id,
       product_name
FROM customers_and_items_arranged
WHERE row_number = 1;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT m.product_name,
       count(*) AS purchase_count
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY purchase_count DESC
LIMIT 1;

-- Which item was the most popular for each customer?
WITH cte AS
   (SELECT s.customer_id,
           m.product_name,
           COUNT(*) AS purchase_count
    FROM dannys_diner.sales s
    LEFT JOIN dannys_diner.menu m ON s.product_id = m.product_id
    GROUP BY s.customer_id,
             m.product_name),
     cte_2 AS
   (SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id
                              ORDER BY purchase_count DESC)
    FROM cte)
SELECT customer_id,
       product_name
FROM cte_2
WHERE row_number = 1;

-- Which item was purchased first by the customer after they became a member?
WITH cte AS
   (SELECT s.*,
           m.join_date
    FROM dannys_diner.sales s
    LEFT JOIN dannys_diner.members m ON s.customer_id = m.customer_id),
     cte_2 AS
   (SELECT *
    FROM cte
    WHERE order_date >= join_date),
     cte_3 AS
   (SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id
                              ORDER BY order_date)
    FROM cte_2)
SELECT c.customer_id,
       m.product_name
FROM cte_3 c
LEFT JOIN dannys_diner.menu m ON c.product_id = m.product_id
WHERE c.row_number = 1;

-- Which item was purchased just before the customer became a member?
WITH cte AS
   (SELECT s.*,
           m.join_date
    FROM dannys_diner.sales s
    LEFT JOIN dannys_diner.members m ON s.customer_id = m.customer_id),
     cte_2 AS
   (SELECT *
    FROM cte
    WHERE order_date < join_date
       OR join_date IS NULL),
     cte_3 AS
   (SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id
                              ORDER BY order_date DESC)
    FROM cte_2)
SELECT c.customer_id,
       m.product_name
FROM cte_3 c
LEFT JOIN dannys_diner.menu m ON c.product_id = m.product_id
WHERE c.row_number = 1;

-- What is the total items and amount spent for each member before they became a member?
WITH cte AS
   (SELECT s.*,
           m.join_date
    FROM dannys_diner.sales s
    LEFT JOIN dannys_diner.members m ON s.customer_id = m.customer_id),
     cte_2 AS
   (SELECT *
    FROM cte
    WHERE order_date < join_date
       OR join_date IS NULL)
SELECT c.customer_id,
       COUNT(c.product_id) AS total_items,
       SUM(m.price) AS total_amount
FROM cte_2 c
LEFT JOIN dannys_diner.menu m ON c.product_id = m.product_id
GROUP BY c.customer_id;

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH cte AS
   (SELECT s.*,
           m.join_date
    FROM dannys_diner.sales s
    LEFT JOIN dannys_diner.members m ON s.customer_id = m.customer_id),
     cte_2 AS
   (SELECT *
    FROM cte
    WHERE order_date < join_date
       OR join_date IS NULL),
     cte_3 AS
   (SELECT c.customer_id,
           m.product_name,
           m.price
    FROM cte_2 c
    LEFT JOIN dannys_diner.menu m ON c.product_id = m.product_id)
SELECT customer_id,
       SUM(CASE
               WHEN product_name = 'sushi' THEN 2*price*10
               ELSE price*10
           END) AS total_points
FROM cte_3
GROUP BY customer_id;

-- In the first week after a customer joins the program (including their join date)
-- they earn 2x points on all items, not just sushi -
-- how many points do customer A and B have at the end of January?
 WITH cte AS
   (SELECT s.*,
           m.join_date
    FROM dannys_diner.sales s
    LEFT JOIN dannys_diner.members m ON s.customer_id = m.customer_id),
      cte_2 AS
   (SELECT c.customer_id,
           c.order_date,
           m.product_name,
           m.price,
           c.join_date
    FROM cte c
    LEFT JOIN dannys_diner.menu m ON c.product_id = m.product_id
    WHERE order_date >= join_date),
      cte_3 AS
   (SELECT customer_id,
           order_date,
           join_date,
           product_name,
           price,
           CASE
               WHEN product_name = 'sushi'
                    OR order_date <= join_date + INTERVAL '7 DAYS' THEN 2*price*10
               ELSE price*10
           END AS points
    FROM cte_2
    WHERE order_date <= '2021-01-31')
SELECT customer_id,
       SUM(points) AS total_points
FROM cte_3
GROUP BY customer_id;

-- BONUS QUESTIONS
 WITH cte AS
   (SELECT s.customer_id,
           s.order_date,
           e.product_name,
           e.price,
           CASE
               WHEN s.order_date >= m.join_date THEN 'Y'
               ELSE 'N'
           END AS member
    FROM dannys_diner.sales s
    LEFT JOIN dannys_diner.members m ON s.customer_id = m.customer_id
    LEFT JOIN dannys_diner.menu e ON s.product_id = e.product_id
    ORDER BY s.customer_id,
             s.order_date),
      cte_2 AS
   (SELECT *,
           RANK() OVER(PARTITION BY customer_id
                       ORDER BY order_date) AS ranking
    FROM cte
    WHERE member = 'Y'),
      cte_3 AS
   (SELECT *,
           0 AS ranking
    FROM cte
    WHERE member = 'N'),
      cte_4 AS
   (SELECT *
    FROM cte_2
    UNION ALL SELECT *
    from cte_3)
SELECT customer_id,
       order_date,
       product_name,
       price,
       member,
       CASE
           WHEN ranking = 0 THEN NULL
           ELSE ranking
       END AS ranking
FROM cte_4
ORDER BY customer_id,
         order_date;