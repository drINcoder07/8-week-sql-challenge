-- DATA INSPECTION

SELECT *
FROM pizza_runner.runners;


SELECT *
FROM pizza_runner.customer_orders;


SELECT *
FROM pizza_runner.runner_orders;

-- Cleaning data

CREATE
TEMPORARY VIEW runner_orders_cleaned AS WITH CTE AS
  (SELECT order_id,
          runner_id,
          REPLACE(pickup_time, 'null', '') AS pickup_time,
          REPLACE(distance, 'null', '0') AS distance,
          REPLACE(duration, 'null', '0') AS duration,
          REPLACE(cancellation, 'null', '') AS cancellation
   FROM pizza_runner.runner_orders)
SELECT order_id,
       runner_id,
       pickup_time,
       REGEXP_REPLACE(distance, '[[:alpha:]]', '', 'g')::DECIMAL AS distance,
       REGEXP_REPLACE(distance, '[[:alpha:]]', '', 'g')::DECIMAL AS duration,
       cancellation
FROM CTE;


SELECT *
FROM pizza_runner.pizza_names;


SELECT *
FROM pizza_runner.pizza_toppings;

-- CASE STUDY QUESTIONS
-- A. Pizza Metrics
-- How many pizzas were ordered?

SELECT COUNT(*) AS total_pizzas
FROM pizza_runner.customer_orders;-- there are 14 orders of pizza

-- How many unique customer orders were made?

SELECT COUNT(DISTINCT customer_id) AS unique_customer_orders
FROM pizza_runner.customer_orders;-- there are 5 unique customer orders made

-- How many successful orders were delivered by each runner?

SELECT *
FROM pizza_runner.runner_orders
WHERE cancellation IS NULL
  OR cancellation = 'null'
  OR cancellation = '' ; -- How many of each type of pizza was delivered?
-- How many Vegetarian and Meatlovers were ordered by each customer?
-- What was the maximum number of pizzas delivered in a single order?
-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- How many pizzas were delivered that had both exclusions and extras?
-- What was the total volume of pizzas ordered for each hour of the day?
-- What was the volume of orders for each day of the week?