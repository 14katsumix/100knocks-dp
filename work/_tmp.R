q = sql("
WITH receipt_distinct AS (
  SELECT DISTINCT 
    customer_id, sales_ymd
  FROM receipt
)
SELECT 
  c.customer_id, 
  r.sales_ymd, 
  c.application_date,
  EXTRACT(DAY FROM (
      STRPTIME(CAST(r.sales_ymd AS TEXT), '%Y%m%d') - 
        STRPTIME(c.application_date, '%Y%m%d')
    )
  ) AS elapsed_days
FROM 
  receipt_distinct r
INNER JOIN 
  customer c
USING (customer_id)
ORDER BY 
  customer_id, sales_ymd
"
)
q %>% my_select(con)

