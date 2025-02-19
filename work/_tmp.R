n_lag = 3L

df_sales_by_date_with_lag = df_receipt %>% 
  summarise(amount = sum(amount), .by = "sales_ymd") %>% 
  arrange(sales_ymd) %>% 
  mutate(
    lag_ymd = lag(sales_ymd, n = n_lag, default = -1)
  )

df_sales_by_date_with_lag

.by = join_by(
    between(y$sales_ymd, x$lag_ymd, x$sales_ymd, bounds = "[)")
  )

df_result = df_sales_by_date_with_lag %>% 
  inner_join(df_sales_by_date_with_lag, by = .by, suffix = c("", ".y")) %>% 
  select(sales_ymd, amount, lag_sales_ymd = sales_ymd.y, lag_amount = amount.y) %>% 
  arrange(sales_ymd)

df_result
df_result %>% tail(7)

#...............................................................................

n_lag = 3L

db_sales_by_date_with_lag = db_receipt %>% 
  summarise(amount = sum(amount), .by = "sales_ymd") %>% 
  # arrange(sales_ymd) %>% 
  window_order(sales_ymd) %>% 
  mutate(
    lag_ymd = lag(sales_ymd, n = n_lag, default = -1)
    # lag_ymd = lag(sales_ymd, n = n_lag, default = -1, order_by = sales_ymd)
  )

db_sales_by_date_with_lag
# db_sales_by_date_with_lag %>% show_query(cte = TRUE)

.by = join_by(
    between(y$sales_ymd, x$lag_ymd, x$sales_ymd, bounds = "[)")
  )

db_result = db_sales_by_date_with_lag %>% 
  inner_join(db_sales_by_date_with_lag, by = .by, suffix = c("", ".y")) %>% 
  select(sales_ymd, amount, lag_sales_ymd = sales_ymd.y, lag_amount = amount.y) %>% 
  arrange(sales_ymd)

db_result %>% collect()
db_result %>% collect() %>% tail(7)

db_result %>% show_query(cte = TRUE)

#...............................................................................

# n_lag = 3L

# db_sales_by_date_with = db_receipt %>% 
#   summarise(amount = sum(amount), .by = "sales_ymd") %>% 
#   arrange(sales_ymd)

# # db_sales_by_date_with
# # db_sales_by_date_with %>% show_query(cte = TRUE)

# dx = db_sales_by_date_with %>% 
#   # arrange(sales_ymd) %>% 
#   mutate(
#     lag_ymd = lag(sales_ymd, n = n_lag, default = -1)
#     # lag_ymd = lag(sales_ymd, n = n_lag, default = -1, order_by = sales_ymd)
#   )
  
# .by = join_by(
#     between(y$sales_ymd, x$lag_ymd, x$sales_ymd, bounds = "[)")
#   )

# db_result = dx %>% 
#   inner_join(db_sales_by_date_with, by = .by, suffix = c("", ".y")) %>% 
#   select(sales_ymd, amount, lag_sales_ymd = sales_ymd.y, lag_amount = amount.y) %>% 
#   arrange(sales_ymd)

# db_result %>% collect()
# db_result %>% collect() %>% tail(7)

# db_result %>% show_query(cte = TRUE)

#...............................................................................

q = sql("
WITH q01 AS (
  SELECT sales_ymd, SUM(amount) AS amount
  FROM receipt
  GROUP BY sales_ymd
  ORDER BY sales_ymd
),
q02 AS (
  SELECT q01.*, LAG(sales_ymd, 3, -1.0) OVER (ORDER BY sales_ymd) AS lag_ymd
  FROM q01
),
q03 AS (
  SELECT q01.*, LAG(sales_ymd, 3, -1.0) OVER (ORDER BY sales_ymd) AS lag_ymd
  FROM q01
),
q04 AS (
  SELECT
    LHS.sales_ymd AS sales_ymd,
    LHS.amount AS amount,
    RHS.sales_ymd AS lag_sales_ymd,
    RHS.amount AS lag_amount
  FROM q02 LHS
  INNER JOIN q03 RHS
    ON (LHS.lag_ymd <= RHS.sales_ymd AND LHS.sales_ymd > RHS.sales_ymd)
)
SELECT q01.*
FROM q04 q01
ORDER BY sales_ymd
"
)

q %>% my_select(con)
q %>% my_select(con) %>% tail(7)

q = sql("
WITH sales_data AS (
  SELECT 
    sales_ymd, 
    SUM(amount) AS amount,
    LAG(sales_ymd, 3, -1.0) OVER (ORDER BY sales_ymd) AS lag_ymd
  FROM receipt
  GROUP BY sales_ymd
)
SELECT 
  L.sales_ymd,
  L.amount,
  R.sales_ymd AS lag_sales_ymd,
  R.amount AS lag_amount
FROM sales_data L
INNER JOIN sales_data R
  ON (L.lag_ymd <= R.sales_ymd AND L.sales_ymd > R.sales_ymd)
ORDER BY L.sales_ymd;
"
)

q %>% my_select(con)
q %>% my_select(con) %>% tail(7)
