WITH q01 AS (
  SELECT
    customer.*,
    sales_ymd,
    sales_epoch,
    store_cd,
    receipt_no,
    receipt_sub_no,
    product_cd,
    quantity,
    amount
  FROM customer
  INNER JOIN receipt
    ON (customer.customer_id = receipt.customer_id)
),
q02 AS (
  SELECT
    customer_id,
    customer_name,
    CASE
WHEN (gender_cd IN ('0')) THEN '00'
WHEN (gender_cd IN ('1')) THEN '01'
ELSE '99'
END AS gender_cd,
    gender,
    birth_day,
    age,
    postal_cd,
    address,
    application_store_cd,
    application_date,
    status_cd,
    sales_ymd,
    sales_epoch,
    store_cd,
    receipt_no,
    receipt_sub_no,
    product_cd,
    quantity,
    amount,
    CAST((FLOOR(age / 10.0) * 10.0) AS INTEGER) AS age_range
  FROM q01
),
q03 AS (
  SELECT DISTINCT age_range
  FROM q02 q01
  GROUP BY gender_cd, age_range
),
q04 AS (
  SELECT
    customer.*,
    sales_ymd,
    sales_epoch,
    store_cd,
    receipt_no,
    receipt_sub_no,
    product_cd,
    quantity,
    amount
  FROM customer
  INNER JOIN receipt
    ON (customer.customer_id = receipt.customer_id)
),
q05 AS (
  SELECT
    customer_id,
    customer_name,
    CASE
WHEN (gender_cd IN ('0')) THEN '00'
WHEN (gender_cd IN ('1')) THEN '01'
ELSE '99'
END AS gender_cd,
    gender,
    birth_day,
    age,
    postal_cd,
    address,
    application_store_cd,
    application_date,
    status_cd,
    sales_ymd,
    sales_epoch,
    store_cd,
    receipt_no,
    receipt_sub_no,
    product_cd,
    quantity,
    amount,
    CAST((FLOOR(age / 10.0) * 10.0) AS INTEGER) AS age_range
  FROM q04 q01
),
q06 AS (
  SELECT DISTINCT gender_cd
  FROM q05 q01
  GROUP BY gender_cd, age_range
),
q07 AS (
  SELECT age_range, gender_cd
  FROM q03 LHS
  CROSS JOIN q06 RHS
),
q08 AS (
  SELECT
    customer.*,
    sales_ymd,
    sales_epoch,
    store_cd,
    receipt_no,
    receipt_sub_no,
    product_cd,
    quantity,
    amount
  FROM customer
  INNER JOIN receipt
    ON (customer.customer_id = receipt.customer_id)
),
q09 AS (
  SELECT
    customer_id,
    customer_name,
    CASE
WHEN (gender_cd IN ('0')) THEN '00'
WHEN (gender_cd IN ('1')) THEN '01'
ELSE '99'
END AS gender_cd,
    gender,
    birth_day,
    age,
    postal_cd,
    address,
    application_store_cd,
    application_date,
    status_cd,
    sales_ymd,
    sales_epoch,
    store_cd,
    receipt_no,
    receipt_sub_no,
    product_cd,
    quantity,
    amount,
    CAST((FLOOR(age / 10.0) * 10.0) AS INTEGER) AS age_range
  FROM q08 q01
),
q10 AS (
  SELECT gender_cd, age_range, SUM(amount) AS sum_amount
  FROM q09 q01
  GROUP BY gender_cd, age_range
),
q11 AS (
  SELECT
    COALESCE(LHS.age_range, RHS.age_range) AS age_range,
    COALESCE(LHS.gender_cd, RHS.gender_cd) AS gender_cd,
    sum_amount
  FROM q07 LHS
  FULL JOIN q10 RHS
    ON (LHS.age_range = RHS.age_range AND LHS.gender_cd = RHS.gender_cd)
)
SELECT age_range, gender_cd, COALESCE(sum_amount, 0.0) AS sum_amount
FROM q11 q01
ORDER BY gender_cd, age_range
