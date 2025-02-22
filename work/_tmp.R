WITH q01 AS (
  SELECT
    customer_id,
    sales_ymd,
    amount,
    EXTRACT(year FROM strptime(CAST(sales_ymd AS TEXT), '%Y%m%d')) AS sales_year
  FROM receipt
),
q02 AS (
  SELECT customer.customer_id AS customer_id, sales_ymd, amount, sales_year
  FROM q01 LHS
  RIGHT JOIN customer
    ON (LHS.customer_id = customer.customer_id)
),
q03 AS (
  SELECT
    q01.*,
    CASE WHEN (sales_year = 2019) THEN amount WHEN NOT (sales_year = 2019) THEN 0.0 END AS amount_2019
  FROM q02 q01
),
q04 AS (
  SELECT
    customer_id,
    SUM(amount) AS sales_amount,
    SUM(amount_2019) AS sales_amount_2019
  FROM q03 q01
  GROUP BY customer_id
),
q05 AS (
  SELECT
    customer_id,
    COALESCE(sales_amount, 0.0) AS sales_amount,
    COALESCE(sales_amount_2019, 0.0) AS sales_amount_2019
  FROM q04 q01
)
SELECT
  q01.*,
  CASE WHEN (sales_amount = 0.0) THEN 0.0 WHEN NOT (sales_amount = 0.0) THEN (sales_amount_2019 / sales_amount) END AS sales_rate
FROM q05 q01
