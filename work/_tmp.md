## SQLクエリ

### 解答例(1)

データベース操作の [解答例(1)]({{< ref "#r-db1" >}}) の操作結果 (`db_result`) に基づいて自動生成された SQL クエリは次の通りです。

```r
db_result %>% show_query(cte = T)
```

```sql
<SQL>
WITH product_num AS (
  SELECT store_cd, product_cd, COUNT(*) AS n
  FROM receipt
  GROUP BY store_cd, product_cd
),
product_max AS (
  SELECT *, MAX(n) OVER (PARTITION BY store_cd) AS max_n
  FROM product_num
)
SELECT store_cd, product_cd, n
FROM product_max
WHERE n = max_n
ORDER BY n DESC, store_cd
LIMIT 10
```

- **`product_num`** CTE では、`receipt` テーブルから店舗 (`store_cd`) 毎に各商品の販売数 (`n`) をカウントします。
- **`product_max`** CTE では、前の CTE からの結果を基に、店舗毎の最大販売数 (`max_n`) を計算します。
- 最後の `SELECT` 文では、`WHERE n = max_n` の条件を用いて、店舗毎に販売数が最大となる商品を抽出します。

この SQL クエリの実行結果は、次のように確認できます。

```r
q = sql("
WITH product_num AS (
  SELECT 
    store_cd, 
    product_cd, 
    COUNT(*) AS n
  FROM 
    receipt
  GROUP BY 
    store_cd, product_cd
),
product_max AS (
  SELECT 
    *, 
    MAX(n) OVER (PARTITION BY store_cd) AS max_n
  FROM product_num
)
SELECT 
  store_cd, 
  product_cd, 
  n
FROM 
  product_max
WHERE 
  n = max_n
ORDER BY 
  n DESC, store_cd
LIMIT 10
"
)

q %>% my_select(con)
```

```text
# A tibble: 10 × 3
   store_cd product_cd     n
   <chr>    <chr>      <dbl>
 1 S14027   P060303001   152
 2 S14012   P060303001   142
 3 S14028   P060303001   140
 4 S12030   P060303001   115
 5 S13031   P060303001   115
 6 S12013   P060303001   107
 7 S13044   P060303001    96
 8 S14024   P060303001    96
 9 S12029   P060303001    92
10 S13004   P060303001    88
```

### 解答例(2)

データベース操作の [解答例(2)]({{< ref "#r-db2" >}}) に基づいて自動生成された SQL クエリは次の通りです。

```r
db_result %>% show_query(cte = T)
```

```sql
<SQL>
WITH product_num AS (
  SELECT store_cd, product_cd, COUNT(*) AS n
  FROM receipt
  GROUP BY store_cd, product_cd
),
product_rank AS (
  SELECT *, RANK() OVER (PARTITION BY store_cd ORDER BY n DESC) AS rank
  FROM product_num
)
SELECT store_cd, product_cd, n
FROM product_rank
WHERE rank = 1
ORDER BY n DESC, store_cd
LIMIT 10
```

- **`product_rank`** CTE では、`RANK()` 関数を用いて、店舗毎に商品の販売数をランク付けしています。
- 最後の `SELECT` 文では、`rank = 1` の条件を用いて、各店舗で最も売れた商品を抽出します。

この SQL クエリの実行結果は、次のように確認できます。

```r
q = sql("
WITH product_num AS (
  SELECT 
    store_cd,
    product_cd,
    COUNT(*) AS n
  FROM 
    receipt
  GROUP BY 
    store_cd, product_cd
),
product_rank AS (
  SELECT 
    *,
    RANK() OVER (
      PARTITION BY store_cd
      ORDER BY n DESC
    ) AS rank
  FROM 
    product_num
)
SELECT 
  store_cd,
  product_cd,
  n
FROM 
  product_rank
WHERE
  rank = 1
ORDER BY n DESC, store_cd
LIMIT 10
"
)

q %>% my_select(con)
```

```text
# A tibble: 10 × 3
   store_cd product_cd     n
   <chr>    <chr>      <dbl>
 1 S14027   P060303001   152
 2 S14012   P060303001   142
 3 S14028   P060303001   140
 4 S12030   P060303001   115
 5 S13031   P060303001   115
 6 S12013   P060303001   107
 7 S13044   P060303001    96
 8 S14024   P060303001    96
 9 S12029   P060303001    92
10 S13004   P060303001    88
```
