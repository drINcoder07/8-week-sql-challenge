-- DATA INSPECTION

SELECT *
FROM pizza_runner.runners;


SELECT *
FROM pizza_runner.customer_orders;


SELECT *
FROM pizza_runner.runner_orders;


SELECT *
FROM pizza_runner.pizza_names;


SELECT *
FROM pizza_runner.pizza_toppings;

-- Cleaning data

CREATE
TEMPORARY VIEW cleaned_customer_orders AS WITH cleaned_values AS
  (SELECT order_id,
          customer_id,
          pizza_id,
          CASE
              WHEN exclusions = ''
                   OR exclusions = 'null' THEN NULL
              ELSE exclusions
          END AS exclusions,
          CASE
              WHEN extras = ''
                   OR extras = 'null' THEN NULL
              ELSE extras
          END AS extras,
          order_time
   FROM pizza_runner.customer_orders)
SELECT order_id,
       customer_id,
       pizza_id,
       SPLIT_PART(exclusions, ', ', 1) AS exclusion_1,
       SPLIT_PART(exclusions, ', ', 2) AS exclusion_2,
       SPLIT_PART(extras, ', ', 1) AS extras_1,
       SPLIT_PART(extras, ', ', 2) AS extras_2,
       order_time
FROM cleaned_values;


CREATE
TEMPORARY VIEW cleaned_runner_orders AS WITH cleaned_values AS
  (SELECT order_id,
          runner_id,
          CASE
              WHEN pickup_time = 'null' THEN NULL
              ELSE pickup_time
          END AS pickup_time,
          REGEXP_REPLACE(distance, '[[:alpha:]]', '', 'g') AS distance,
          REGEXP_REPLACE(duration, '[[:alpha:]]', '', 'g') AS duration,
          CASE
              WHEN cancellation = ''
                   OR cancellation = 'null' THEN NULL
              else cancellation
          END AS cancellation
   FROM pizza_runner.runner_orders)
SELECT order_id,
       runner_id,
       pickup_time,
       (CASE
            WHEN distance = '' THEN '0'
            ELSE distance
        END)::decimal AS distance,
       (CASE
            WHEN duration = '' THEN '0'
            ELSE duration
        END)::decimal AS duration,
       cancellation
FROM cleaned_values;


SELECT *
from cleaned_customer_orders;


SELECT *
from cleaned_runner_orders;

-- CASE STUDY QUESTIONS
-- A. Pizza Metrics
-- How many pizzas were ordered?

SELECT COUNT(*) AS total_pizzas
FROM cleaned_customer_orders;

-- How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) AS unique_customer_orders
FROM cleaned_customer_orders;

-- How many successful orders were delivered by each runner?

SELECT COUNT(*) AS successful_orders
FROM cleaned_runner_orders
WHERE cancellation IS NULL;

-- How many of each type of pizza was delivered?

SELECT c.pizza_id,
       n.pizza_name,
       COUNT(c.*) AS total_orders
FROM cleaned_customer_orders c
LEFT JOIN pizza_runner.pizza_names n ON c.pizza_id = n.pizza_id
GROUP BY c.pizza_id,
         n.pizza_name;

-- How many Vegetarian and Meatlovers were ordered by each customer?

SELECT c.customer_id,
       n.pizza_name,
       COUNT(C.*) as total_orders
FROM cleaned_customer_orders c
LEFT JOIN pizza_runner.pizza_names n ON c.pizza_id = n.pizza_id
GROUP BY c.customer_id,
         n.pizza_name;

-- What was the maximum number of pizzas delivered in a single order?
WITH cte AS
  (SELECT order_id,
          COUNT(*) AS pizzas_ordered
   FROM cleaned_customer_orders
   GROUP BY order_id)
SELECT MAX(pizzas_ordered)
FROM cte;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
 -- How many pizzas were delivered that had both exclusions and extras?

SELECT COUNT(*) AS pizzas_with_both_exclusions_and_extras
FROM cleaned_customer_orders
WHERE (exclusion_1 IS NOT NULL
       OR exclusion_2 IS NOT NULL)
  AND (extras_1 IS NOT NULL
       OR extras_2 IS NOT NULL);

-- What was the total volume of pizzas ordered for each hour of the day?

SELECT EXTRACT(HOUR
               FROM order_time) AS hour_of_day,
       COUNT(*) AS total_pizzas
FROM cleaned_customer_orders
GROUP BY 1;

-- What was the volume of orders for each day of the week?

SELECT TO_CHAR(order_time, 'Day') AS day_of_week,
       COUNT(*) AS total_pizzas
FROM cleaned_customer_orders
GROUP BY 1;

