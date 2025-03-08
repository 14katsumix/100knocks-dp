#### 1.　CTE `customer_sales`

```sql
WITH customer_sales AS (
  SELECT 
    customer_id, 
    SUM(amount) AS sum_amount
  FROM 
    receipt
  GROUP BY 
    customer_id
  HAVING
    SUM(amount) IS NOT NULL
)
```

- **目的**: 顧客ごとに売上金額 (`sum_amount`) の合計を計算し、`NULL` の合計を除外します。
- **`SUM(amount) IS NOT NULL`**: 売上金額が `NULL` でない顧客を抽出します。`HAVING` は集計後に条件を適用するため、売上が `NULL` の顧客は除外されます。

#### 2. CTE `percentiles`

```sql
percentiles AS (
  SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY sum_amount) AS p25,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sum_amount) AS p50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY sum_amount) AS p75
  FROM 
    customer_sales
)
```

- **目的**: `customer_sales` から計算した売上合計を基に、**四分位数 (p25, p50, p75)** を求めます。
- **`PERCENTILE_CONT`**: この関数は連続的な分位点を計算します。ここでは、25%、50%、75% の四分位数を求めています。

#### 3. メインクエリ

```sql
SELECT
  cs.customer_id,
  cs.sum_amount,
  CASE
    WHEN cs.sum_amount < p.p25 THEN '1'
    WHEN cs.sum_amount < p.p50 THEN '2'
    WHEN cs.sum_amount < p.p75 THEN '3'
    ELSE '4'
  END AS pct_group
FROM 
  customer_sales cs
CROSS JOIN 
  percentiles p
ORDER BY 
  cs.customer_id
LIMIT 10
```

- **目的**: `customer_sales` と `percentiles` を結合し、売上金額 (`sum_amount`) を四分位数に基づいてグループ分けします。
  - `CROSS JOIN`: `percentiles` の各行が `customer_sales` のすべての行に結合されます。結果として、各顧客の売上金額と全体の四分位数が組み合わせられます。
  - `CASE` 文を使用して、売上金額 (`sum_amount`) がどの四分位数に該当するかに応じて、顧客をグループ化します。
- 最後に、`customer_id` の順に並べ替え (`ORDER BY cs.customer_id`) て、先頭10行 (`LIMIT 10`) を取得します。
