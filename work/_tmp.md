以下のように日本語の表現をブラッシュアップしました。改善点として、文の流れを自然にし、冗長な部分を簡潔にしています。  

---

## 設問概要

{{< k100/question >}}

---

最頻値が複数存在する場合、それらをすべて抽出する解答例を示します。

## Rコード (データフレーム操作)

### 解答例(1){#r-df1}

```r
df_result = df_receipt %>% 
  count(store_cd, product_cd) %>% 
  filter(n == max(n), .by = store_cd) %>% 
  arrange(desc(n), store_cd) %>% 
  head(10)
```

```text
# A tibble: 10 × 3
   store_cd product_cd     n
   <chr>    <chr>      <int>
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

- `df_receipt` に対し `count()` を使用し、店舗 (`store_cd`) と商品 (`product_cd`) の組み合わせごとに販売数 (`n`) を集計します。  
- `filter(n == max(n), .by = store_cd)` により、各店舗で最も売れた商品を抽出します。  
  販売数が最大のものが複数ある場合、それらをすべて含みます。

### 解答例(2){#r-df2}

`filter()` の代わりに `slice_max()` を使用した解答例です。

```r
df_result = df_receipt %>% 
  count(store_cd, product_cd) %>% 
  slice_max(n, n = 1, with_ties = TRUE, by = store_cd) %>% 
  arrange(desc(n), store_cd) %>% 
  head(10)
```

```text
# A tibble: 10 × 3
   store_cd product_cd     n
   <chr>    <chr>      <int>
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

`slice_max(n, n = 1, with_ties = TRUE, by = store_cd)` を用いることで、  
各店舗 (`store_cd`) ごとに `n` が最大の `product_cd` を抽出します。  
`with_ties = TRUE` を指定することで、最大値が複数ある場合はすべて含まれます。

## Rコード (データベース操作)

### 解答例(1){#r-db1}

データフレーム操作の [解答例(1)]({{< ref "#r-df1" >}}) はデータベース操作でも適用できるため、  
`df_receipt` をテーブル参照 `db_receipt` に置き換えて同様の処理を実行します。

```r
db_result = db_receipt %>% 
  count(store_cd, product_cd) %>% 
  filter(n == max(n), .by = store_cd) %>% 
  arrange(desc(n), store_cd) %>% 
  head(10)

db_result %>% collect()
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

### 解答例(2){#r-db2}

データフレーム操作の [解答例(2)]({{< ref "#r-df2" >}}) をデータベース操作に適用します。

```r
db_result = db_receipt %>% 
  count(store_cd, product_cd) %>% 
  slice_max(n, n = 1, with_ties = TRUE, by = store_cd) %>% 
  arrange(desc(n), store_cd) %>% 
  head(10)

db_result %>% collect()
```

## SQLクエリ

### 解答例(1)

データベース操作の [解答例(1)]({{< ref "#r-db1" >}}) に基づき、自動生成された SQLクエリを `show_query()` で確認できます。

```r
db_result %>% show_query(cte = T)
```

```sql
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

- **`product_num`** CTE では、`receipt` テーブルから各店舗 (`store_cd`) における各商品の販売数 (`n`) を集計します。
- **`product_max`** CTE では、`MAX(n) OVER (PARTITION BY store_cd)` により、各店舗ごとの最大販売数 (`max_n`) を計算します。
- 最後の `SELECT` 文で、`n = max_n` の条件により、各店舗で最も売れた商品を取得します。

この SQL を R から実行する場合、以下のように `sql()` を使用します。

```r
q = sql("
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
")

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
