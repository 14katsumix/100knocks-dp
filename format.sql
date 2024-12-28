SELECT 
  sales_ymd AS sales_date,
  customer_id,
  product_cd,
  amount
FROM 
  receipt
LIMIT 10
