以下に、二番目のSQLクエリに解説を加えた内容を示します。

---

## SQLクエリ

```sql
WITH customer_sales AS (
  SELECT 
    customer_id, 
    SUM(amount) AS sum_amount
  FROM 
    receipt
  WHERE 
    customer_id NOT LIKE 'Z%'
  GROUP BY 
    customer_id
)
SELECT 
  customer_id, 
  sum_amount
FROM 
  customer_sales
WHERE 
  sum_amount >= (
    SELECT AVG(sum_amount) FROM customer_sales
  )
ORDER BY 
  sum_amount DESC
LIMIT 10
```

### 解説

このSQLクエリは、特定の条件に基づいて顧客の売上合計を計算し、平均以上の売上を上げた顧客を抽出するためのものです。クエリは以下のように構成されています。

1. **CTE（共通テーブル式）の作成**: 
   ```sql
   WITH customer_sales AS (
     SELECT 
       customer_id, 
       SUM(amount) AS sum_amount
     FROM 
       receipt
     WHERE 
       customer_id NOT LIKE 'Z%'
     GROUP BY 
       customer_id
   )
   ```
   - この部分では、`receipt`テーブルから`customer_id`ごとの売上合計を計算しています。
   - **`customer_id NOT LIKE 'Z%'`**: ここで、`customer_id`が"Z"で始まる顧客を除外します。これにより、対象外の顧客を排除してデータの質を向上させています。
   - **`SUM(amount) AS sum_amount`**: 各顧客の売上合計を求め、新しい列`sum_amount`を作成します。
   - **`GROUP BY customer_id`**: `customer_id`ごとに集計を行います。

2. **平均以上の顧客の選択**: 
   ```sql
   SELECT 
     customer_id, 
     sum_amount
   FROM 
     customer_sales
   WHERE 
     sum_amount >= (
       SELECT AVG(sum_amount) FROM customer_sales
     )
   ```
   - ここでは、先ほど作成した`customer_sales`のCTEを参照して、売上合計が全体の平均以上の顧客を抽出します。
   - **`SELECT AVG(sum_amount) FROM customer_sales`**: このサブクエリでは、`customer_sales`から計算した`sum_amount`の平均を求めています。

3. **結果の並べ替えと制限**: 
   ```sql
   ORDER BY 
     sum_amount DESC
   LIMIT 10
   ```
   - **`ORDER BY sum_amount DESC`**: 売上合計の降順で結果を並べ替え、売上が高い顧客から順に表示します。
   - **`LIMIT 10`**: 上位10件の結果を抽出します。
