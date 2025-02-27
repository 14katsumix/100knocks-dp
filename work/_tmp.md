## SQL

### 解答例(1)

#### 自動生成された SQL クエリ

データベース操作の [解答例(1)]({{< ref "#r-db1" >}}) による操作結果 (`db_result`) に基づき、自動生成された SQLクエリを `show_query()` で確認できます。

```r
db_result %>% show_query(cte = TRUE)
```

```sql
WITH q01 AS (
  SELECT store_cd, product_cd, COUNT(*) AS n
  FROM receipt
  GROUP BY store_cd, product_cd
),
q02 AS (
  SELECT q01.*, MAX(n) OVER (PARTITION BY store_cd) AS col01
  FROM q01
)
SELECT store_cd, product_cd, n
FROM q02 q01
WHERE (n = col01)
ORDER BY n DESC, store_cd
LIMIT 10
```

中間テーブル名および列名の `q01`、`q02`、`col01` は `dbplyr` によって生成されたエイリアス名です。

#### 解答クエリ

このクエリをより簡潔な形に書き直すと、次のようになります。

```sql
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
    store_cd,
    product_cd,
    n, 
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
```

#### 解説

- **CTE `product_num`**  
  `receipt` テーブルから各店舗 (`store_cd`) と各商品 (`product_cd`) の販売数 (`n`) をカウントします。
  
- **CTE `product_max`**  
  `MAX(n) OVER (PARTITION BY store_cd)` により、店舗ごとの最大販売数 (`max_n`) を計算します。

- **最終的な結果**  
  `SELECT` 文では、`n = max_n` の条件により、各店舗ごとに販売数が最大となる商品を抽出します。

#### 実行結果

実行結果は次のようになります。

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
    store_cd,
    product_cd,
    n, 
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

#### 自動生成された SQL クエリ

データベース操作の [解答例(2)]({{< ref "#r-db2" >}}) による操作結果 (`db_result`) に基づき、自動生成された SQLクエリを `show_query()` で確認できます。

```r
db_result %>% show_query(cte = TRUE)
```

```sql
WITH q01 AS (
  SELECT store_cd, product_cd, COUNT(*) AS n
  FROM receipt
  GROUP BY store_cd, product_cd
),
q02 AS (
  SELECT q01.*, RANK() OVER (PARTITION BY store_cd ORDER BY n DESC) AS col01
  FROM q01
)
SELECT store_cd, product_cd, n
FROM q02 q01
WHERE (col01 <= 1)
ORDER BY n DESC, store_cd
LIMIT 10
```

#### 解答クエリ

このクエリをより簡潔な形に書き直すと、次のようになります。

```sql
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
    store_cd,
    product_cd,
    n, 
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
ORDER BY 
  n DESC, store_cd
LIMIT 10
```

#### 解説

- **CTE `product_rank`**  
  `RANK()` 関数を使用して、各店舗ごとに商品を販売数 (`n`) の降順でランク付けします。

- **最終的な結果**  
  `SELECT` 文では、`rank = 1` の条件により、各店舗で最も売れた商品を抽出します。

#### 実行結果

実行結果は次のようになります。

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
    store_cd,
    product_cd,
    n, 
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
