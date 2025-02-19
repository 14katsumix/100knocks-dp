#-------------------------------------------------------------------------------
# テーブル参照の標準出力のカスタマイズ ------------
# Database: DuckDB v1.1.3-dev165 [root@Darwin 24.1.0:R 4.4.2//Users/.../work/DB/100knocks.duckdb]

# カスタムメソッドを定義
custom_db_get_info = function(dbObj, ...) {
  ll = attr(dbObj, "driver") |> dbGetInfo()
  # s = ll$dbname
  # dbname = paste0(
  #   stringr::str_sub(s, 1, 7), 
  #   "...", 
  #   stringr::str_sub(s, stringr::str_length(s) - 24)
  # )
  list(
    # dbname = ll$dbname, 
    dbname = stringr::str_trunc(ll$dbname, 23, "left"), 
    # dbname = dbname, 
    db.version = ll$driver.version
  )
}

# dbGetInfo メソッドを duckdb_connection 用にオーバーライド
methods::setMethod("dbGetInfo", "duckdb_connection", custom_db_get_info)

DBI::dbGetInfo(con)
db_receipt %>% head(1)
# Source:   table<receipt> [?? x 9]
# Database: DuckDB v1.1.3-dev165 [root@Darwin 24.1.0:R 4.4.2/.../DB/100knocks.duckdb]
#    sales_ymd sales_epoch store_cd receipt_no receipt_sub_no customer_id   
#        <int>       <int> <chr>         <int>          <int> <chr>         
#  1  20181103  1541203200 S14006          112              1 CS006214000001

# 標準出力向けの設定 ------------
list(
  "digits" = 2,  
  "tibble.print_max" = 40, # 表示する最大行数.
  "tibble.print_min" = 15, # 表示する最小行数.
  "tibble.width" = NULL,   # 全体の出力幅. デフォルトは NULL.
  "pillar.sigfig" = 5,     # 表示する有効桁数
  "pillar.max_dec_width" = 13 # 10進数表記の最大許容幅
) |> 
  options()

# dplyr が認識できない関数をエラーにする 
options(dplyr.strict_sql = TRUE)

#-------------------------------------------------------------------------------
# R-003 ------------
# レシート明細データ（df_receipt）から売上年月日（sales_ymd）、顧客ID（customer_id）、
# 商品コード（product_cd）、売上金額（amount）の順に列を指定し、10件表示せよ。
# ただし、sales_ymdをsales_dateに項目名を変更しながら抽出すること。

# [R] データフレームでの処理
df_receipt %>% 
  select(sales_date = sales_ymd, customer_id, product_cd, amount) %>% 
  head(10)

# A tibble: 10 × 4
#    sales_date customer_id    product_cd amount
#         <int> <chr>          <chr>       <dbl>
#  1   20181103 CS006214000001 P070305012    158
#  2   20181118 CS008415000097 P070701017     81
#  3   20170712 CS028414000014 P060101005    170
#  4   20190205 ZZ000000000000 P050301001     25
#  5   20180821 CS025415000050 P060102007     90
#  6   20190605 CS003515000195 P050102002    138
#  7   20181205 CS024514000042 P080101005     30
#  8   20190922 CS040415000178 P070501004    128
#  9   20170504 ZZ000000000000 P071302010    770
# 10   20191010 CS027514000015 P071101003    680

#...............................................................................
# [R] データベース・バックエンドでの処理
db_result = db_receipt %>% 
  select(sales_date = sales_ymd, customer_id, product_cd, amount) %>% 
  head(10)

db_result %>% collect()

db_result
# Source:   SQL [10 x 4]
# Database: DuckDB v1.1.3-dev165 [root@Darwin 24.1.0:R 4.4.2/.../DB/100knocks.duckdb]
#    sales_date customer_id    product_cd amount
#         <int> <chr>          <chr>       <dbl>
#  1   20181103 CS006214000001 P070305012    158
#  2   20181118 CS008415000097 P070701017     81
#  3   20170712 CS028414000014 P060101005    170
#  4   20190205 ZZ000000000000 P050301001     25
#  5   20180821 CS025415000050 P060102007     90
#  6   20190605 CS003515000195 P050102002    138
#  7   20181205 CS024514000042 P080101005     30
#  8   20190922 CS040415000178 P070501004    128
#  9   20170504 ZZ000000000000 P071302010    770
# 10   20191010 CS027514000015 P071101003    680

# class(db_result)
# [1] "tbl_duckdb_connection" "tbl_dbi"               "tbl_sql"              
# [4] "tbl_lazy"              "tbl"

#...............................................................................
# SQLクエリ
db_result %>% my_show_query()

# <SQL>
# SELECT sales_ymd AS sales_date, customer_id, product_cd, amount
# FROM receipt
# LIMIT 10

# リライト
# SELECT 
#   sales_ymd AS sales_date,
#   customer_id,
#   product_cd,
#   amount
# FROM 
#   receipt
# LIMIT 10

#-------------------------------------------------------------------------------
# R-029 ------------
# レシート明細データ（df_receipt）に対し、店舗コード（store_cd）ごとに商品コード（product_cd）の最頻値を求め、10件表示させよ。

# 以下は、最頻値が複数ある場合は全てを表示する解答例です。

# sample.1 ------------

# [R] データフレーム操作
df_result = df_receipt %>% 
  count(store_cd, product_cd) %>% 
  filter(n == max(n), .by = store_cd) %>% 
  arrange(desc(n)) %>% 
  head(10)

df_result

# A tibble: 10 × 3
#    store_cd product_cd     n
#    <chr>    <chr>      <int>
#  1 S14027   P060303001   152
#  2 S14012   P060303001   142
#  3 S14028   P060303001   140
#  4 S12030   P060303001   115
#  5 S13031   P060303001   115
#  6 S12013   P060303001   107
#  7 S13044   P060303001    96
#  8 S14024   P060303001    96
#  9 S12029   P060303001    92
# 10 S13004   P060303001    88

# 結果がたまたま store_cd で ソートされる場合もありますが、順序は保証されないため、
# 確実にソートしたい場合は arrange()を使うべきです。

#...............................................................................
# [R] データベース・バックエンドでの処理
db_result = db_receipt %>% 
  count(store_cd, product_cd) %>% 
  filter(n == max(n), .by = store_cd) %>% 
  arrange(desc(n)) %>% 
  head(10)

db_result %>% collect()

db_result
# Source:     SQL [10 x 3]
# Database:   DuckDB v1.1.3-dev165 [root@Darwin 24.3.0:R 4.4.2/.../DB/100knocks.duckdb]
# Ordered by: desc(n)
#    store_cd product_cd     n
#    <chr>    <chr>      <dbl>
#  1 S14027   P060303001   152
#  2 S14012   P060303001   142
#  3 S14028   P060303001   140
#  4 S12030   P060303001   115
#  5 S13031   P060303001   115
#  6 S12013   P060303001   107
#  7 S13044   P060303001    96
#  8 S14024   P060303001    96
#  9 S12029   P060303001    92
# 10 S13037   P060303001    88

#...............................................................................
# SQLクエリ
db_result %>% my_show_query()

# <SQL>
# WITH q01 AS (
#   SELECT store_cd, product_cd, COUNT(*) AS n
#   FROM receipt
#   GROUP BY store_cd, product_cd
# ),
# q02 AS (
#   SELECT q01.*, MAX(n) OVER (PARTITION BY store_cd) AS col01
#   FROM q01
# )
# SELECT store_cd, product_cd, n
# FROM q02 q01
# WHERE (n = col01)
# ORDER BY n DESC
# LIMIT 10

q = sql("
WITH q01 AS (
  SELECT 
    store_cd, 
    product_cd, 
    COUNT(*) AS n
  FROM 
    receipt
  GROUP BY 
    store_cd, product_cd
),
q02 AS (
  SELECT 
    *, 
    MAX(n) OVER (PARTITION BY store_cd) AS col01
  FROM q01
)
SELECT 
  store_cd, product_cd, n
FROM 
  q02
WHERE 
  n = col01
ORDER BY 
  n DESC
LIMIT 10
"
)

q %>% my_select(con)

# col01, q01, q02 は dbplyrパッケージで自動生成されるエイリアス名.
# col01: 中間列名
# エイリアス名を直接指定する方法はありません。

#...............................................................................
# sample.2 ------------

# [R] データフレームでの処理
df_receipt %>% 
  count(store_cd, product_cd) %>% 
  slice_max(n, n = 1, with_ties = T, by = store_cd) %>% 
  arrange(desc(n)) %>% 
  head(10)

# A tibble: 10 × 3
#    store_cd product_cd     n
#    <chr>    <chr>      <int>
#  1 S14027   P060303001   152
#  2 S14012   P060303001   142
#  3 S14028   P060303001   140
#  4 S12030   P060303001   115
#  5 S13031   P060303001   115
#  6 S12013   P060303001   107
#  7 S13044   P060303001    96
#  8 S14024   P060303001    96
#  9 S12029   P060303001    92
# 10 S13004   P060303001    88

#...............................................................................
# [R] データベース・バックエンドでの処理

db_result = db_receipt %>% 
  count(store_cd, product_cd) %>% 
  slice_max(n, n = 1, with_ties = T, by = store_cd) %>% 
  arrange(desc(n)) %>% 
  head(10)

db_result %>% collect()

# A tibble: 10 × 3
#    store_cd product_cd     n
#    <chr>    <chr>      <dbl>
#  1 S14027   P060303001   152
#  2 S14012   P060303001   142
#  3 S14028   P060303001   140
#  4 S12030   P060303001   115
#  5 S13031   P060303001   115
#  6 S12013   P060303001   107
#  7 S13044   P060303001    96
#  8 S14024   P060303001    96
#  9 S12029   P060303001    92
# 10 S13004   P060303001    88

db_result
#  Source:     SQL [10 x 3]
# Database:   DuckDB v1.1.3-dev165 [root@Darwin 24.3.0:R 4.4.2/.../DB/100knocks.duckdb]
# Ordered by: desc(n)
#    store_cd product_cd     n
#    <chr>    <chr>      <dbl>
#  1 S14027   P060303001   152
#  2 S14012   P060303001   142
#  3 S14028   P060303001   140
#  4 S12030   P060303001   115
#  5 S13031   P060303001   115
#  6 S12013   P060303001   107
#  7 S14024   P060303001    96
#  8 S13044   P060303001    96
#  9 S12029   P060303001    92
# 10 S13004   P060303001    88

#...............................................................................
# SQLクエリ

db_result %>% my_show_query()

# WITH q01 AS (
#   SELECT store_cd, product_cd, COUNT(*) AS n
#   FROM receipt
#   GROUP BY store_cd, product_cd
# ),
# q02 AS (
#   SELECT q01.*, RANK() OVER (PARTITION BY store_cd ORDER BY n DESC) AS col01
#   FROM q01
# )
# SELECT store_cd, product_cd, n
# FROM q02 q01
# WHERE (col01 <= 1)
# ORDER BY n DESC
# LIMIT 10

# リライト
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
ORDER BY n DESC
LIMIT 10
;
"
)
q %>% my_select(con)

#-------------------------------------------------------------------------------
# R-035 ------------
# レシート明細データ（receipt）に対し、顧客ID（customer_id）ごとに売上金額（amount）を合計して
# 全顧客の平均を求め、平均以上に買い物をしている顧客を抽出し、10件表示せよ。
# ただし、顧客IDが"Z"から始まるものは非会員を表すため、除外して計算すること。

df_receipt %>% glimpse()

df_receipt %>% 
  filter(!str_detect(customer_id, "^Z")) %>% 
  summarise(sum_amount = sum(amount), .by = customer_id) %>% 
  # mutate(.mean = mean(sum_amount)) %>% 
  # filter(sum_amount >= .mean) %>% 
  filter(sum_amount >= mean(sum_amount)) %>% 
  arrange(desc(sum_amount))

# A tibble: 2,996 × 2
#    customer_id    sum_amount
#    <chr>               <dbl>
#  1 CS017415000097      23086
#  2 CS015415000185      20153
#  3 CS031414000051      19202
#  4 CS028415000007      19127
#  5 CS001605000009      18925
#  ...

#...............................................................................
# dbplyr
db_receipt %>% glimpse()

db_result = db_receipt %>% 
  # filter(not(customer_id %LIKE% "Z%")) %>% 
  filter(!str_detect(customer_id, "^Z")) %>% 
  summarise(sum_amount = sum(amount), .by = customer_id) %>% 
  # mutate(.mean = mean(sum_amount)) %>% 
  # filter(sum_amount >= .mean) %>% 
  filter(sum_amount >= mean(sum_amount)) %>% 
  arrange(desc(sum_amount))

db_result %>% collect()

#...............................................................................

db_result %>% show_query(cte = TRUE)

q = sql("
WITH q01 AS (
  SELECT *
  FROM receipt
  WHERE customer_id NOT LIKE 'Z%'
),
q02 AS (
  SELECT customer_id, SUM(amount) AS sum_amount
  FROM q01
  GROUP BY customer_id
),
q03 AS (
  SELECT *, AVG(sum_amount) OVER () AS avg_amount
  FROM q02
)
SELECT customer_id, sum_amount
FROM q03
WHERE (sum_amount >= avg_amount)
ORDER BY sum_amount DESC
"
)
q %>% my_select(con)

# 改善点: 
# WITH 句の定義を1つ (customer_sales) にまとめ、不要なCTEを削減。
# 平均値の計算を WHERE 句内のサブクエリで処理し、AVG() のウィンドウ関数を不要に。
# 読みやすさと実行効率を向上。

q = sql("
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
  sum_amount DESC;
"
)
q %>% my_select(con)

#-------------------------------------------------------------------------------
# R-038 ------------
# 顧客データ（customer）とレシート明細データ（receipt）から、顧客ごとの売上金額合計を求め、10件表示せよ。
# ただし、売上実績がない顧客については売上金額を0として表示させること。
# また、顧客は性別コード（gender_cd）が女性（1）であるものを対象とし、非会員（顧客IDが"Z"から始まるもの）は除外すること。

df_customer %>% 
  filter(gender_cd == "1", !str_detect(customer_id, "^Z")) %>% 
  left_join(
    df_receipt %>% select(customer_id, amount), 
    by = "customer_id"
  ) %>% 
  summarise(sum_amount = sum(amount, na.rm = T), .by = "customer_id") %>% 
  arrange(customer_id) %>% 
  head(10)

# A tibble: 10 × 2
#    customer_id    sum_amount
#    <chr>               <dbl>
#  1 CS001112000009          0
#  2 CS001112000019          0
#  3 CS001112000021          0
#  4 CS001112000023          0
#  5 CS001112000024          0
#  6 CS001112000029          0
#  7 CS001112000030          0
#  8 CS001113000004       1298
#  9 CS001113000010          0
# 10 CS001114000005        626

#...............................................................................
# dbplyr

db_result = db_customer %>% 
  # filter(gender_cd == "1", not(customer_id %LIKE% "%Z")) %>% 
  filter(gender_cd == "1", !str_detect(customer_id, "^Z")) %>% 
  left_join(
    db_receipt %>% select(customer_id, amount), 
    by = "customer_id"
  ) %>% 
  summarise(sum_amount = sum(amount), .by = "customer_id") %>% 
  replace_na(list(sum_amount = 0.0)) %>% 
  arrange(customer_id) %>% 
  head(10)

db_result %>% collect()

#...............................................................................
db_result %>% show_query(cte = TRUE)

# NOT(REGEXP_MATCHES(customer_id, '^Z'))
# customer_id NOT LIKE 'Z%'

# WITH q01 AS (
#   SELECT customer.*
#   FROM customer
#   WHERE (gender_cd = '1') AND (NOT(REGEXP_MATCHES(customer_id, '^Z')))
# ),
# q02 AS (
#   SELECT LHS.*, amount
#   FROM q01 LHS
#   LEFT JOIN receipt
#     ON (LHS.customer_id = receipt.customer_id)
# ),
# q03 AS (
#   SELECT customer_id, SUM(amount) AS sum_amount
#   FROM q02 q01
#   GROUP BY customer_id
# )
# SELECT customer_id, COALESCE(sum_amount, 0.0) AS sum_amount
# FROM q03 q01
# ORDER BY customer_id
# LIMIT 10

q = sql("
WITH q01 AS (
  SELECT customer.*
  FROM customer
  WHERE (gender_cd = '1') AND (customer_id NOT LIKE 'Z%')
),
q02 AS (
  SELECT LHS.*, amount
  FROM q01 LHS
  LEFT JOIN receipt
    ON (LHS.customer_id = receipt.customer_id)
),
q03 AS (
  SELECT customer_id, SUM(amount) AS sum_amount
  FROM q02 q01
  GROUP BY customer_id
)
SELECT customer_id, COALESCE(sum_amount, 0.0) AS sum_amount
FROM q03 q01
ORDER BY customer_id
-- LIMIT 10
"
)
q %>% my_select(con)
d1 = q %>% my_select(con)

# WITH 句を削除して1つのクエリに統合
# customer.* の使用を避け、必要な列 (customer_id) のみを選択
# LEFT JOIN を直接 customer テーブルに適用
# SUM(amount) の集計を GROUP BY 句内で直接実施
# COALESCE を最終的な SUM(amount) に適用

q = sql("
SELECT c.customer_id, COALESCE(SUM(r.amount), 0.0) AS sum_amount
FROM customer c
LEFT JOIN receipt r USING (customer_id)
WHERE c.gender_cd = '1' AND customer_id NOT LIKE 'Z%'
GROUP BY c.customer_id
ORDER BY c.customer_id
-- LIMIT 10;
"
)
q %>% my_select(con)
d2 = q %>% my_select(con)

identical(d1, d2)

# A tibble: 10 × 2
#    customer_id    sum_amount
#    <chr>               <dbl>
#  1 CS001112000009          0
#  2 CS001112000019          0
#  3 CS001112000021          0
#  4 CS001112000023          0
#  5 CS001112000024          0
#  6 CS001112000029          0
#  7 CS001112000030          0
#  8 CS001113000004       1298
#  9 CS001113000010          0
# 10 CS001114000005        626

#-------------------------------------------------------------------------------
# R-039 ------------
# レシート明細データ（receipt）から、売上日数の多い顧客の上位20件を抽出したデータと、
# 売上金額合計の多い顧客の上位20件を抽出したデータをそれぞれ作成し、さらにその2つを完全外部結合せよ。
# ただし、非会員（顧客IDが"Z"から始まるもの）は除外すること。

# sample.1

df_rec = df_receipt %>% 
  filter(!str_detect(customer_id, "^Z")) %>% 
  select(customer_id, sales_ymd, amount) %>% 
  group_by(customer_id)

df_date = df_rec %>% 
  summarise(n_date = n_distinct(sales_ymd)) %>% 
  slice_max(n_date, n = 20, with_ties = F)

df_amount = df_rec %>% 
  summarise(sum_amount = sum(amount)) %>% 
  slice_max(sum_amount, n = 20, with_ties = F)

df_result = df_date %>% 
  full_join(df_amount, by = "customer_id") %>% 
  arrange(desc(n_date), desc(sum_amount), customer_id)

df_result
# A tibble: 34 × 3
#    customer_id    n_date sum_amount
#    <chr>           <int>      <dbl>
#  1 CS040214000008     23         NA
#  2 CS015415000185     22      20153
#  3 CS010214000010     22      18585
#  4 CS028415000007     21      19127
#  5 CS010214000002     21         NA
#  6 CS017415000097     20      23086
#  7 CS016415000141     20      18372
#  8 CS031414000051     19      19202
#  9 CS014214000023     19         NA
#  ...

# sample.2

df_rec = df_receipt %>% 
  filter(!str_detect(customer_id, "^Z")) %>% 
  select(customer_id, sales_ymd, amount) %>% 
  group_by(customer_id)

df_date = df_rec %>% 
  summarise(n_date = n_distinct(sales_ymd)) %>% 
  arrange(desc(n_date), customer_id) %>% 
  head(20)

df_amount = df_rec %>% 
  summarise(sum_amount = sum(amount)) %>% 
  arrange(desc(sum_amount), customer_id) %>% 
  head(20)

df_result = df_date %>% 
  full_join(df_amount, by = "customer_id") %>% 
  arrange(desc(n_date), desc(sum_amount), customer_id)

df_result

#...............................................................................
# dbplyr

# sample.1

db_rec = db_receipt %>% 
  filter(!str_detect(customer_id, "^Z")) %>% 
  select(customer_id, sales_ymd, amount) %>% 
  group_by(customer_id)

db_date = db_rec %>% 
  summarise(n_date = n_distinct(sales_ymd) %>% as.integer()) %>% 
  slice_max(n_date, n = 20, with_ties = F)

db_amount = db_rec %>% 
  summarise(sum_amount = sum(amount)) %>% 
  slice_max(sum_amount, n = 20, with_ties = F)

db_result = db_date %>% 
  full_join(db_amount, by = "customer_id") %>% 
  arrange(desc(n_date), desc(sum_amount), customer_id)

# データフレーム操作の結果と比較
janitor::compare_df_cols(df_result, db_result %>% collect())
identical(df_result, db_result %>% collect())
all.equal(df_result, db_result %>% collect())
anti_join(df_result, db_result %>% collect())

pacman::p_load(arsenal)
d = db_result %>% collect()
arsenal::comparedf(df_result, d) %>% summary()
df_result; d

db_result %>% collect()
# A tibble: 34 × 3
#    customer_id    n_date sum_amount
#    <chr>           <int>      <dbl>
#  1 CS040214000008     23         NA
#  2 CS015415000185     22      20153
#  3 CS010214000010     22      18585
#  4 CS028415000007     21      19127
#  5 CS010214000002     21         NA
#  6 CS017415000097     20      23086
#  7 CS016415000141     20      18372
#  8 CS031414000051     19      19202
#  9 CS014214000023     19         NA
#  ...

#................................................
# sample.2

db_rec = db_receipt %>% 
  filter(!str_detect(customer_id, "^Z")) %>% 
  select(customer_id, sales_ymd, amount) %>% 
  group_by(customer_id)

db_date = db_rec %>% 
  summarise(n_date = n_distinct(sales_ymd) %>% as.integer()) %>% 
  arrange(desc(n_date), customer_id) %>% 
  head(20)

db_amount = db_rec %>% 
  summarise(sum_amount = sum(amount)) %>% 
  arrange(desc(sum_amount), customer_id) %>% 
  head(20)

db_result = db_date %>% 
  full_join(db_amount, by = "customer_id") %>% 
  arrange(desc(n_date), desc(sum_amount), customer_id)

db_result %>% collect()

#...............................................................................

# LIMIT を使うべきケース
# 最もシンプルで高速な実装が欲しい場合
# → ORDER BY ... LIMIT 20 のほうが ROW_NUMBER() を使うよりシンプルで速い。
# TIE (同値の扱い) を考慮しなくてよい場合
# → n_date が同じ 20 人が選ばれたとき、同順位の他の人が除外されても問題ないなら LIMIT のほうが効率的。

# arrange() + head() の方が slice_max() を使うよりシンプルで速い

db_result %>% show_query(cte = TRUE)

# WITH q01 AS (
#   SELECT customer_id, sales_ymd, amount
#   FROM receipt
#   WHERE (NOT(REGEXP_MATCHES(customer_id, '^Z')))
# ),
# q02 AS (
#   SELECT customer_id, CAST(COUNT(DISTINCT row(sales_ymd)) AS INTEGER) AS n_date
#   FROM q01
#   GROUP BY customer_id
#   ORDER BY n_date DESC, customer_id
#   LIMIT 20
# ),
# q03 AS (
#   SELECT customer_id, SUM(amount) AS sum_amount
#   FROM q01
#   GROUP BY customer_id
#   ORDER BY sum_amount DESC, customer_id
#   LIMIT 20
# ),
# q04 AS (
#   SELECT
#     COALESCE(LHS.customer_id, RHS.customer_id) AS customer_id,
#     n_date,
#     sum_amount
#   FROM q02 LHS
#   FULL JOIN q03 RHS
#     ON (LHS.customer_id = RHS.customer_id)
# )
# SELECT q01.*
# FROM q04 q01
# ORDER BY n_date DESC, sum_amount DESC, customer_id

q = sql("
WITH filtered_receipt AS (
  SELECT 
    customer_id, sales_ymd, amount 
  FROM 
    receipt 
  WHERE 
    customer_id NOT LIKE 'Z%'
), 
top_customers_by_days AS (
  SELECT 
    customer_id, 
    CAST(COUNT(DISTINCT sales_ymd) AS INTEGER) AS n_date 
  FROM 
    filtered_receipt 
  GROUP BY 
    customer_id 
  ORDER BY 
    n_date DESC, customer_id 
  LIMIT 20
), 
top_customers_by_sales AS (
  SELECT 
    customer_id, 
    SUM(amount) AS sum_amount 
  FROM 
    filtered_receipt 
  GROUP BY 
    customer_id 
  ORDER BY 
    sum_amount DESC, customer_id 
  LIMIT 20
) 
SELECT 
  COALESCE(d.customer_id, s.customer_id) AS customer_id, 
  d.n_date, 
  s.sum_amount 
FROM 
  top_customers_by_days d
FULL JOIN top_customers_by_sales s 
USING (customer_id) 
ORDER BY 
  n_date DESC, sum_amount DESC, customer_id;
"
)
q %>% my_select(con)

# A tibble: 34 × 3
#    customer_id    n_date sum_amount
#    <chr>           <int>      <dbl>
#  1 CS040214000008     23         NA
#  2 CS015415000185     22      20153
#  3 CS010214000010     22      18585
#  4 CS028415000007     21      19127
#  5 CS010214000002     21         NA
#  6 CS017415000097     20      23086
#  7 CS016415000141     20      18372
# ...
# 33 CS030415000034     NA      15468
# 34 CS015515000034     NA      15300

#-------------------------------------------------------------------------------
# R-040 ------------
# 全ての店舗と全ての商品を組み合わせたデータを作成したい。店舗データ（store）と商品データ（product）を直積し、件数を計算せよ。

df_store$store_cd %>% tidyr::crossing(df_product$product_cd) %>% nrow()

df_result = df_store %>% 
  cross_join(df_product) %>% 
  select(store_cd, product_cd)

df_result

# A tibble: 531,590 × 2
#    store_cd product_cd
#    <chr>    <chr>     
#  1 S12014   P040101001
#  2 S12014   P040101002
#  3 S12014   P040101003
#  4 S12014   P040101004
#  5 S12014   P040101005
#  6 S12014   P040101006
#  7 S12014   P040101007
#  8 S12014   P040101008
#  9 S12014   P040101009
# 10 S12014   P040101010
# 11 S12014   P040102001
# 12 S12014   P040102002
# 13 S12014   P040102003
# ...

#...............................................................................
# dbplyr

db_result = db_store %>% 
  cross_join(db_product) %>% 
  select(store_cd, product_cd)

db_result %>% collect()

db_result %>% count() %>% collect()

#...............................................................................

db_result %>% show_query()

q = sql("
SELECT store_cd, product_cd
FROM store
CROSS JOIN product
"
)
q %>% my_select(con)

# A tibble: 531,590 × 2
#    store_cd product_cd
#    <chr>    <chr>     
#  1 S12014   P040101001
#  2 S12014   P040101002
#  3 S12014   P040101003
#  4 S12014   P040101004
#  5 S12014   P040101005
#  6 S12014   P040101006
#  7 S12014   P040101007
#  8 S12014   P040101008
#  9 S12014   P040101009
# 10 S12014   P040101010
# 11 S12014   P040102001
# 12 S12014   P040102002
# 13 S12014   P040102003
# ...

db_result %>% count() %>% show_query()

q = sql("
SELECT COUNT(*) AS total_count
FROM store
CROSS JOIN product
"
)
q %>% my_select(con)

#   total_count
#         <dbl>
# 1      531590

#-------------------------------------------------------------------------------
# R-041 ------------
# レシート明細データ（receipt）の売上金額（amount）を日付（sales_ymd）ごとに集計し、
# 前回売上があった日からの売上金額増減を計算せよ。そして結果を10件表示せよ。

# 参考
df_receipt %>% 
  summarise(amount = sum(amount), .by = sales_ymd) %>% 
  mutate(
    pre_sales_ymd = lag(sales_ymd, order_by = sales_ymd), 
    pre_amount = lag(amount, default = NA, order_by = sales_ymd)
  ) %>% 
  mutate(diff_amount = amount - pre_amount) %>% 
  arrange(sales_ymd) %>% 
  head(10)

# ブログでは以下を採用
df_receipt %>% 
  summarise(amount = sum(amount), .by = sales_ymd) %>% 
  arrange(sales_ymd) %>% 
  mutate(
    pre_sales_ymd = lag(sales_ymd), 
    pre_amount = lag(amount, default = NA)
  ) %>% 
  mutate(diff_amount = amount - pre_amount) %>% 
  head(10)

# A tibble: 1,034 × 5
#    sales_ymd amount pre_sales_ymd pre_amount diff_amount
#        <int>  <dbl>         <int>      <dbl>       <dbl>
#  1  20170101  33723            NA         NA          NA
#  2  20170102  24165      20170101      33723       -9558
#  3  20170103  27503      20170102      24165        3338
#  4  20170104  36165      20170103      27503        8662
#  5  20170105  37830      20170104      36165        1665
#  6  20170106  32387      20170105      37830       -5443
#  7  20170107  23415      20170106      32387       -8972

#...............................................................................
# dbplyr
# arrange(sales_ymd) を window_order(sales_ymd) に変更する
# 最後に arrange(sales_ymd) 

db_result = db_receipt %>% 
  summarise(amount = sum(amount), .by = sales_ymd) %>% 
  window_order(sales_ymd) %>% 
  mutate(
    pre_sales_ymd = lag(sales_ymd), 
    pre_amount = lag(amount, default = NA)
  ) %>% 
  mutate(diff_amount = amount - pre_amount) %>% 
  arrange(sales_ymd) %>% 
  head(10)

db_result %>% collect()

#...............................................................................

db_result %>% show_query(cte = TRUE)

# WITH q01 AS (
#   SELECT sales_ymd, SUM(amount) AS amount
#   FROM receipt
#   GROUP BY sales_ymd
# ),
# q02 AS (
#   SELECT
#     q01.*,
#     LAG(sales_ymd, 1, NULL) OVER (ORDER BY sales_ymd) AS pre_sales_ymd,
#     LAG(amount, 1, NULL) OVER (ORDER BY sales_ymd) AS pre_amount
#   FROM q01
# )
# SELECT q01.*, amount - pre_amount AS diff_amount
# FROM q02 q01
# ORDER BY sales_ymd
# LIMIT 10

q = sql("
WITH sales_by_date AS (
  SELECT 
    sales_ymd, 
    SUM(amount) AS amount
  FROM 
    receipt
  GROUP BY 
    sales_ymd
),
sales_by_date_with_lag AS (
  SELECT 
    sales_ymd, 
    amount, 
    LAG(sales_ymd) OVER win AS pre_sales_ymd,
    LAG(amount) OVER win AS pre_amount
  FROM 
    sales_by_date
  WINDOW win AS (ORDER BY sales_ymd)
)
SELECT 
  sales_ymd, 
  amount, 
  pre_sales_ymd, 
  pre_amount, 
  amount - pre_amount AS diff_amount
FROM 
  sales_by_date_with_lag
ORDER BY 
  sales_ymd
LIMIT 10;
"
)
q %>% my_select(con)

# A tibble: 1,034 × 5
#    sales_ymd sum_amount pre_ymd  pre_amount diff_amount
#    <chr>          <dbl> <chr>         <dbl>       <dbl>
#  1 20170101       33723 NA               NA          NA
#  2 20170102       24165 20170101      33723       -9558
#  3 20170103       27503 20170102      24165        3338
#  4 20170104       36165 20170103      27503        8662
#  5 20170105       37830 20170104      36165        1665
#  6 20170106       32387 20170105      37830       -5443
#  ...

#-------------------------------------------------------------------------------
# R-042 ------------
# レシート明細データ（receipt）の売上金額（amount）を日付（sales_ymd）ごとに集計し、
# 各日付のデータに対し、前回、前々回、3回前に売上があった日のデータを結合せよ。そして結果を10件表示せよ。

# 
n_lag = 3L
# df_sales_by_date_with_lag = df_receipt %>% 
#   summarise(amount = sum(amount), .by = "sales_ymd") %>% 
#   mutate(
#     lag_ymd = lag(sales_ymd, n = n_lag, order_by = sales_ymd), 
#     pre_amount = lag(amount, n = n_lag, default = NA, order_by = sales_ymd)
#   ) %>% 
#   arrange(sales_ymd)

df_sales_by_date_with_lag = df_receipt %>% 
  summarise(amount = sum(amount), .by = "sales_ymd") %>% 
  arrange(sales_ymd) %>% 
  mutate(
    lag_ymd = lag(sales_ymd, n = n_lag)
    # pre_amount = lag(amount, n = n_lag, default = NA)
  )

df_sales_by_date_with_lag; df_sales_by_date_with_lag %>% tail(6)

dx = df_sales_by_date_with_lag %>% 
  select(sales_ymd, lag_ymd_x = lag_ymd, amount) %>% 
  mutate(lag_ymd_x = coalesce(lag_ymd_x, 0L))
  # replace_na(list(lag_ymd_x = 0L))

dy = df_sales_by_date_with_lag %>% 
  select(lag_ymd = sales_ymd, lag_amount = amount)

dx; dx %>% tail(6)
dy; dy %>% tail(6)

.by = join_by(
    between(y$lag_ymd, x$lag_ymd_x, x$sales_ymd, bounds = "[)")
  )

df_result = dx %>% 
  inner_join(dy, by = .by) %>% 
  select(-lag_ymd_x)

df_result; df_result %>% tail(7)

# A tibble: 3,096 × 4
#    sales_ymd amount  lag_ymd lag_amount
#        <int>  <dbl>    <int>      <dbl>
#  1  20170102  24165 20170101      33723
#  2  20170103  27503 20170101      33723
#  3  20170103  27503 20170102      24165
#  4  20170104  36165 20170101      33723
#  5  20170104  36165 20170102      24165
#  6  20170104  36165 20170103      27503
#  7  20170105  37830 20170102      24165
#  8  20170105  37830 20170103      27503
#  9  20170105  37830 20170104      36165
# ...
# 1  20191029  36091 20191028      40161
# 2  20191030  26602 20191027      37484
# 3  20191030  26602 20191028      40161
# 4  20191030  26602 20191029      36091
# 5  20191031  25216 20191028      40161
# 6  20191031  25216 20191029      36091
# 7  20191031  25216 20191030      26602

#...............................................................................
# dbplyr


#................................................
# n_lag = 3L
# d = db_receipt %>% summarise(amount = sum(amount), .by = "sales_ymd") %>% 
#   mutate(
#     lag_ymd = lag(sales_ymd, n = n_lag, order_by = sales_ymd)
#   )
# d %>% my_show_query()

# 別の記述
n_lag = 3L

d = db_receipt %>% summarise(amount = sum(amount), .by = "sales_ymd") %>% 
  window_order(sales_ymd) %>% 
  mutate(
    lag_ymd = lag(sales_ymd, n = n_lag), 
    lag_amount = lag(amount, n = n_lag)
  )

d
# Source:     SQL [?? x 4]
# Database:   DuckDB v1.1.3-dev165 [root@Darwin 24.3.0:R 4.4.2/.../DB/100knocks.duckdb]
# Ordered by: sales_ymd
#    sales_ymd amount  lag_ymd lag_amount
#        <int>  <dbl>    <int>      <dbl>
#  1  20170101  33723       NA         NA
#  2  20170102  24165       NA         NA
#  3  20170103  27503       NA         NA
#  4  20170104  36165 20170101      33723
#  5  20170105  37830 20170102      24165
#  6  20170106  32387 20170103      27503
#  ...

d %>% my_show_query()
d %>% my_collect(T)

dx = d %>% 
  select(sales_ymd_x = sales_ymd, lag_ymd_x = lag_ymd, amount_x = amount) %>% 
  mutate(lag_ymd_x = coalesce(lag_ymd_x, 0L))
  # arrange(sales_ymd) # arrange は最後に記述 (subquery内では書かない)

dx %>% my_show_query()
dx %>% my_collect()
dx %>% my_collect() %>% pull(sales_ymd_x) %>% range()

# dy = d %>% select(sales_ymd, amount) %>% 
#   rename(lag_ymd = sales_ymd, lag_amount = amount)

dy = d %>% select(sales_ymd, amount)

dy %>% my_show_query()
dy %>% my_collect()
dy %>% my_collect() %>% pull(sales_ymd) %>% range()

dx %>% head(10)
dy %>% head(10)

.by = join_by(
    between(y$sales_ymd, x$lag_ymd_x, x$sales_ymd_x, bounds = "[)")
  )

dx %>% inner_join(dy, by = .by) %>% select(-lag_ymd_x)
dx %>% inner_join(dy, by = .by) %>% select(-lag_ymd_x) %>% show_query()

d.res = dx %>% inner_join(dy, by = .by) %>% select(-lag_ymd_x) %>% 
  rename(sales_ymd = sales_ymd_x, amount = amount_x, lag_ymd = sales_ymd, lag_amount = amount) %>% 
  arrange(sales_ymd, lag_ymd)

d.res
d.res %>% my_show_query()

df_result = d.res %>% my_collect()
df_result; df_result %>% tail(7)

#...............................................................................

q = sql("
WITH q01 AS (
  SELECT sales_ymd, SUM(amount) AS amount
  FROM receipt
  GROUP BY sales_ymd
  -- ORDER BY sales_ymd
),
q02 AS (
  SELECT
    sales_ymd,
    LAG(sales_ymd, 3, NULL) OVER (ORDER BY sales_ymd) AS lag_ymd_x,
    amount
  FROM q01
),
q03 AS (
  SELECT sales_ymd, COALESCE(lag_ymd_x, 0) AS lag_ymd_x, amount
  FROM q02 q01
)
SELECT
  LHS.sales_ymd AS sales_ymd,
  LHS.amount AS amount,
  RHS.sales_ymd AS lag_ymd,
  RHS.amount AS lag_amount
FROM q03 LHS
INNER JOIN q01 RHS
  ON (LHS.lag_ymd_x <= RHS.sales_ymd AND LHS.sales_ymd > RHS.sales_ymd)
ORDER BY sales_ymd, lag_ymd
"
)
q %>% my_select(con)

q %>% my_select(con) %>% tail(7)

#...............................................................................
q = sql("
select
    sales_ymd, 
    sum(amount) as amount
  from
    receipt
  group by 
    sales_ymd
"
)
q %>% my_select(con)

# A tibble: 1,034 × 2
#    sales_ymd amount
#        <int>  <dbl>
#  1  20190922  50797
#  2  20170504  22896
#  3  20170116  34075
#  4  20180924  37775
#  5  20190523  53541
#  6  20190718  27778
#  7  20170619  28640
#  ...

q = sql("
with ymd_amount as (
  select
    sales_ymd, 
    sum(amount) as amount
  from
    receipt
  group by 
    sales_ymd
)
select
  sales_ymd, 
  LAG(sales_ymd, 3) OVER (order by sales_ymd) as lag_ymd_3, 
  amount
from
  ymd_amount
"
)
q %>% my_select(con)

# A tibble: 1,034 × 3
#    sales_ymd lag_ymd_3 amount
#        <int>     <int>  <dbl>
#  1  20170101        NA  33723
#  2  20170102        NA  24165
#  3  20170103        NA  27503
#  4  20170104  20170101  36165
#  5  20170105  20170102  37830
#  6  20170106  20170103  32387
#  7  20170107  20170104  23415
#  8  20170108  20170105  24737
#  ...

q = sql("
with ymd_amount as (
  select
    sales_ymd, 
    sum(amount) as amount
  from
    receipt
  group by 
    sales_ymd
), 
lag_data as (
  select
    sales_ymd, 
    LAG(sales_ymd, 3) OVER (order by sales_ymd) as lag_ymd_3, 
    amount
  from
    ymd_amount
  -- order by 
  --  sales_ymd
)
select 
  L.sales_ymd, 
  L.amount, 
  R.sales_ymd as lag_ymd, 
  R.amount as lag_amount
from
  lag_data as L
inner join lag_data as R
on
  (
    L.lag_ymd_3 IS NULL
    OR L.lag_ymd_3 <= R.sales_ymd
  )
  and R.sales_ymd < L.sales_ymd
order by
  L.sales_ymd, lag_ymd
"
)

q %>% my_select(con) %>% head(10)
q %>% my_select(con) %>% tail(7)

# dim: 3,096 x 4
#    sales_ymd amount  lag_ymd lag_amount
#        <int>  <dbl>    <int>      <dbl>
#  1  20170102  24165 20170101      33723
#  2  20170103  27503 20170101      33723
#  3  20170103  27503 20170102      24165
#  4  20170104  36165 20170101      33723
#  5  20170104  36165 20170102      24165
#  6  20170104  36165 20170103      27503
#  7  20170105  37830 20170102      24165
#  8  20170105  37830 20170103      27503
#  9  20170105  37830 20170104      36165
# 10  20170106  32387 20170103      27503
# ...
# 1  20191029  36091 20191028      40161
# 2  20191030  26602 20191027      37484
# 3  20191030  26602 20191028      40161
# 4  20191030  26602 20191029      36091
# 5  20191031  25216 20191028      40161
# 6  20191031  25216 20191029      36091
# 7  20191031  25216 20191030      26602

#-------------------------------------------------------------------------------
# R-043 ------------
# レシート明細データ（receipt）と顧客データ（customer）を結合し、性別コード（gender_cd）と
# 年代（ageから計算）ごとに売上金額（amount）を合計した売上サマリデータを作成せよ。
# 性別コードは0が男性、1が女性、9が不明を表すものとする。
# ただし、項目構成は年代、女性の売上金額、男性の売上金額、性別不明の売上金額の4項目とすること
# （縦に年代、横に性別のクロス集計）。また、年代は10歳ごとの階級とすること。

max_age = df_customer$age %>% max(na.rm = T)

d = 
  df_receipt %>% inner_join(df_customer, by = "customer_id") %>% 
  mutate(
    age_range = 
      epikit::age_categories(
        age, 
        lower = 0, 
        # upper = round(max_age, -1) - ifelse(mod(max_age, 10) == 0, 0L, 1L), 
        upper = floor(max_age / 10) * 10 + 10, 
        by = 10
      )
  ) %>% 
  summarise(sum_amount = sum(amount), .by = c("gender_cd", "age_range")) %>% 
  # mutate(gender_cd = gender_cd %>% as.character(.) %>% lvls_revalue(c("男性", "女性", "不明")))
  mutate(across(gender_cd, ~ forcats::lvls_revalue(.x, c("男性", "女性", "不明"))))

# d$gender_cd %>% forcats::fct_recode(男性 = "0", 女性 = "1", 不明 = "9")
# d$gender_cd %<>% forcats::lvls_revalue(c("男性", "女性", "不明"))

# for test
# d %<>% filter(age_range != "20-29")
# d$age_range

# 縦長
d %>% complete(age_range, gender_cd, fill = list(sum_amount = 0.0))

# A tibble: 33 × 3
#    age_range gender_cd sum_amount
#    <fct>     <fct>          <dbl>
#  1 0-9       男性               0
#  2 0-9       女性               0
#  3 0-9       不明               0
#  4 10-19     男性            1591
#  5 10-19     女性          149836
#  6 10-19     不明            4317
#  7 20-29     男性           72940
#  8 20-29     女性         1363724
#  9 20-29     不明           44328
# 10 30-39     男性          177322
# ...
# 26 80-89     女性          262923
# 27 80-89     不明            5111
# 28 90-99     男性               0
# 29 90-99     女性            6260
# 30 90-99     不明               0
# 31 100+      男性               0
# 32 100+      女性               0
# 33 100+      不明               0

# 横長
d.wide = d %>% pivot_wider(
    id_cols = age_range, id_expand = T, 
    names_from = gender_cd, values_from = sum_amount, names_expand = T, values_fill = 0.0
  )

d.wide

# A tibble: 11 × 4
#    age_range   男性    女性   不明
#    <fct>      <dbl>   <dbl>  <dbl>
#  1 0-9            0       0      0
#  2 10-19       1591  149836   4317
#  3 20-29      72940 1363724  44328
#  4 30-39     177322  693047  50441
#  5 40-49      19355 9320791 483512
#  6 50-59      54320 6685192 342923
#  7 60-69     272469  987741  71418
#  8 70-79      13435   29764   2427
#  9 80-89      46360  262923   5111
# 10 90-99          0    6260      0
# 11 100+           0       0      0

#...............................................................................
# dbplyr ------------







#...............................................................................
q = sql("
with customer_amount as (
  select
    c.customer_id, 
    c.gender_cd, 
    (FLOOR(c.age / 10) * 10) || '代' as age_range, 
    r.amount
  from
    customer as c
  inner join receipt as r
  on c.customer_id = r.customer_id
), 
sum_amount as (
  select
    age_range, 
    gender_cd, 
    SUM(amount) as amount
  from
    customer_amount
  group by 
    age_range, gender_cd
)
select 
  age_range as '年代', 
  COALESCE(SUM(case when gender_cd = '0' then amount end), 0) as '男性', 
  COALESCE(SUM(case when gender_cd = '1' then amount end), 0) as '女性', 
  COALESCE(SUM(case when gender_cd = '9' then amount end), 0) as 'その他'
from
  sum_amount
group by
  age_range
order by 
  age_range
"
)
q %>% my_select(con)

# A tibble: 9 × 4
#   年代    男性    女性 その他
#   <chr>  <dbl>   <dbl>  <dbl>
# 1 10代    1591  149836   4317
# 2 20代   72940 1363724  44328
# 3 30代  177322  693047  50441
# 4 40代   19355 9320791 483512
# 5 50代   54320 6685192 342923
# 6 60代  272469  987741  71418
# 7 70代   13435   29764   2427
# 8 80代   46360  262923   5111
# 9 90代       0    6260      0

sales_summary = q %>% my_select(con)
d.summary = con %>% my_tbl(df = sales_summary, overwrite = T)

#-------------------------------------------------------------------------------
# R-044 ------------
# 043で作成した売上サマリデータ（sales_summary）は性別の売上を横持ちさせたものであった。
# このデータから性別を縦持ちさせ、年代、性別コード、売上金額の3項目に変換せよ。
# ただし、性別コードは男性を"00"、女性を"01"、不明を"99"とする。

d = d.wide %>% 
  pivot_longer(
    cols = !age_range, names_to = "gender_cd", values_to = "amount"
  ) %>% 
  mutate(across(gender_cd, ~ forcats::lvls_revalue(.x, c("00", "01", "99"))))

# d$gender_cd
d
# A tibble: 33 × 3
#    age_range gender_cd  amount
#    <fct>     <fct>       <dbl>
#  1 0-9       01              0
#  2 0-9       00              0
#  3 0-9       99              0
#  4 10-19     01           1591
#  5 10-19     00         149836
#  6 10-19     99           4317
#  7 20-29     01          72940
#  8 20-29     00        1363724
#  9 20-29     99          44328
# ...
# 25 80-89     01          46360
# 26 80-89     00         262923
# 27 80-89     99           5111
# 28 90-99     01              0
# 29 90-99     00           6260
# 30 90-99     99              0
# 31 100+      01              0
# 32 100+      00              0
# 33 100+      99              0

sales_summary
q = sql("
select 年代, '00' as 性別コード, `男性` as 売上金額 from sales_summary
UNION ALL
select 年代, '01' as 性別コード, `女性` as 売上金額 from sales_summary
UNION ALL
select 年代, '99' as 性別コード, `その他` as 売上金額 from sales_summary
"
)
q %>% my_select(con)

# A tibble: 27 × 3
#    年代  性別コード 売上金額
#    <chr> <chr>         <dbl>
#  1 10代  00             1591
#  2 20代  00            72940
#  3 30代  00           177322
# ...
#  9 90代  00                0
# 10 10代  01           149836
# 11 20代  01          1363724
# 12 30代  01           693047
# ...
# 18 90代  01             6260
# 19 10代  99             4317
# 20 20代  99            44328
# 21 30代  99            50441
# ...
# 27 90代  99                0

#-------------------------------------------------------------------------------
# R-045 ------------
# 顧客データ（df_customer）の生年月日（birth_day）は日付型でデータを保有している。
# これをYYYYMMDD形式の文字列に変換し、顧客ID（customer_id）とともに10件表示せよ。




#-------------------------------------------------------------------------------
# R-047 ------------
# レシート明細データ（df_receipt）の売上日（sales_ymd）はYYYYMMDD形式の数値型でデータを保有している。
# これを日付型に変換し、レシート番号(receipt_no)、レシートサブ番号（receipt_sub_no）とともに10件表示せよ。
df_receipt %>% 
  select(receipt_no, receipt_sub_no, sales_ymd) %>% 
  mutate(
    sales_ymd = sales_ymd %>% 
      as.character() %>% 
      lubridate::fast_strptime("%Y%m%d") %>% lubridate::as_date()
  )

# A tibble: 104,681 × 3
#    receipt_no receipt_sub_no sales_ymd 
#         <int>          <int> <date>    
#  1        112              1 2018-11-03
#  2       1132              2 2018-11-18
#  3       1102              1 2017-07-12
#  4       1132              1 2019-02-05
#  5       1102              2 2018-08-21
#  6       1112              1 2019-06-05
#  ...

# dplyr が認識できない関数をエラーにする 
options(dplyr.strict_sql = FALSE)

db_result = db_receipt %>% 
  select(receipt_no, receipt_sub_no, sales_ymd) %>% 
  mutate(
    sales_ymd = sales_ymd %>% 
      as.character() %>% strptime("%Y%m%d") %>% lubridate::as_date()
      # sales_ymd %>% as.character() %>% strptime("%Y%m%d")
      # sales_ymd %>% as.character() %>% lubridate::fast_strptime("%Y%m%d")
      # sales_ymd %>% as.character() %>% lubridate::parse_date_time(sales_ymd, "%Y%m%d")
      # sales_ymd %>% as.character() %>% lubridate::as_date()
  ) %>% 
  head(10)

db_result %>% collect()

db_result %>% show_query()

q = sql("
SELECT
  receipt_no,
  receipt_sub_no,
  CAST(strptime(CAST(sales_ymd AS TEXT), '%Y%m%d') AS DATE) AS sales_ymd
FROM receipt
LIMIT 10
"
)
q %>% my_select(con)

#-------------------------------------------------------------------------------
# R-048 ------------
# レシート明細データ（df_receipt）の売上エポック秒（sales_epoch）は数値型のUNIX秒でデータを保有している。
# これを日付型に変換し、レシート番号(receipt_no)、レシートサブ番号（receipt_sub_no）とともに10件表示せよ。

df_receipt %>% 
  mutate(
    sales_date = 
      lubridate::as_datetime(sales_epoch) %>% 
      lubridate::as_date()
  ) %>% 
  select(receipt_no, receipt_sub_no, sales_date)

db_receipt %>% 
  mutate(
    sales_date = sql("TO_TIMESTAMP(sales_epoch) :: TIMESTAMP"), 
    sales_date = as_date(sales_date)
  ) %>% 
  select(receipt_no, receipt_sub_no, sales_date) %>% 
  my_show_query()

# TIMESTAMP:	タイムゾーンなしの日時型	'2024-02-13 12:34:56'
# TIMESTAMP:  WITH TIME ZONE	タイムゾーン情報を含む日時型	'2024-02-13 12:34:56 UTC'

db_receipt %>% 
  select(receipt_no, receipt_sub_no, sales_ymd, sales_epoch) %>% 
  mutate(
    sales_ymd_d = lubridate::as_datetime(sales_epoch)
  )

# Error in `collect()`:
# ! Failed to collect lazy table.
# Caused by error in `duckdb_result()`:
# ! rapi_execute: Failed to run query
# Error: Conversion Error: Unimplemented type for cast (INTEGER -> TIMESTAMP)
# LINE 6:   CAST(sales_epoch AS TIMESTAMP) AS sales_ymd_d
# FROM receipt

1541203200L %>% as.POSIXct(format = "%Y-%m-%d")
1541203200L %>% as.POSIXct(origin = "1970-01-01")

db_receipt %>% 
  select(receipt_no, receipt_sub_no, sales_ymd, sales_epoch) %>% 
  mutate(
    sales_ymd_d = as.POSIXct(sales_epoch, origin = "1970-01-01") %>% as.Date()
  )

#-------------------------------------------------------------------------------
# R-049 ------------
# レシート明細データ（df_receipt）の売上エポック秒（sales_epoch）を日付型に変換し、「年」だけ取り出してレシート番号(receipt_no)、レシートサブ番号（receipt_sub_no）とともに10件表示せよ。

df_receipt %>% 
  mutate(
    year = 
      lubridate::as_datetime(sales_epoch) %>% 
      lubridate::year() %>% 
      as.integer()
  ) %>% 
  select(receipt_no, receipt_sub_no, year)

# 推奨
db_receipt %>% 
  mutate(
    sales_ymd = sql("TO_TIMESTAMP(sales_epoch) :: TIMESTAMP"), 
    year = sales_ymd %>% lubridate::year() %>% as.integer()
  ) %>% 
  select(receipt_no, receipt_sub_no, year) %>% 
  my_show_query(F)

# 非推奨
db_receipt %>% 
  select(receipt_no, receipt_sub_no, sales_epoch) %>% 
  mutate(
    ymd = sql("YEAR(TO_TIMESTAMP(sales_epoch) :: TIMESTAMP)")
  ) %>% 
  my_show_query(F)
  # my_collect()

#-------------------------------------------------------------------------------
# R-053 ------------
# 顧客データ（customer）の郵便番号（postal_cd）に対し、東京（先頭3桁が100〜209のもの）を1、
# それ以外のものを0に二値化せよ。
# さらにレシート明細データ（receipt）と結合し、全期間において売上実績のある顧客数を、作成した二値ごとにカウントせよ。

customer$postal_cd

d.c = customer %>% select(customer_id, postal_cd) %>% 
  mutate(postal_3 = str_sub(postal_cd, 1, 3)) %>% 
  mutate(tokyo = ifelse(postal_3 >= "100" & postal_3 <= "209", 1, 0))

d.r = receipt %>% select(customer_id, amount) %>% 
  summarise(sum_amount = sum(amount, na.rm = T), .by = "customer_id") %>% 
  filter(sum_amount > 0.0)

d.r %>% inner_join(d.c, by = "customer_id") %>% count(tokyo)

q = sql("
with cust as (
  select 
    customer_id, 
    postal_cd, 
    case 
      when SUBSTR(postal_cd, 1, 3) between '100' and '209' then 1
      else 0
    end as postal_flg
  from
    customer
)
select 
  c.postal_flg, 
  count(*) as n_customer
from
  cust as c
inner join 
  (select distinct customer_id as customer_id from receipt) as r
USING (customer_id)
group by 
  postal_flg
"
)
q %>% my_select(con)

# A tibble: 2 × 2
#   postal_flg n_customer
#        <int>      <int>
# 1          0       3906
# 2          1       4400

#-------------------------------------------------------------------------------
# R-055 ------------
# レシート明細（df_receipt）データの売上金額（amount）を顧客ID（customer_id）ごとに合計し、その合計金額の四分位点を求めよ。その上で、顧客ごとの売上金額合計に対して以下の基準でカテゴリ値を作成し、顧客ID、売上金額合計とともに10件表示せよ。カテゴリ値は順に1〜4とする。
# 
# 最小値以上第1四分位未満 ・・・ 1を付与
# 第1四分位以上第2四分位未満 ・・・ 2を付与
# 第2四分位以上第3四分位未満 ・・・ 3を付与
# 第3四分位以上 ・・・ 4を付与

# Rコード (データフレーム操作)

# df_receipt %>%
#     group_by(customer_id) %>%
#     summarise(sum_amount = sum(amount), .groups = "drop") %>%
#     mutate(pct_group = case_when(
#         sum_amount < quantile(sum_amount)[2]  ~ "1",
#         sum_amount < quantile(sum_amount)[3]  ~ "2",
#         sum_amount < quantile(sum_amount)[4]  ~ "3",
#         quantile(sum_amount)[4] <= sum_amount ~ "4"
#     )) %>%
#     head(10)

df_receipt %>%
  group_by(customer_id) %>% 
  summarise(sum_amount = sum(amount), .groups = "drop") %>% 
  mutate(
    pct_group = 
      cut(
        sum_amount, 
        breaks = quantile(sum_amount), 
        # labels = 1:4 %>% as.character(), 
        labels = FALSE, 
        right = FALSE, 
        include.lowest = TRUE
      ) %>% 
      as.character()
  ) %>% 
  head(10)

#...............................................................................
# Rコード (データベース操作)

# PERCENTILE_CONT() はウィンドウ関数 (OVER ()) として使えない!
db_receipt %>% 
  mutate(
    p25 = quantile(amount, 0.25, na.rm = T)
  ) %>% 
  my_show_query()

q = sql("
SELECT
  receipt.*,
  PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY amount) OVER () AS p25
FROM receipt
"
)
q %>% my_select(con)

# answer
db_sales_amount = db_receipt %>%
  summarise(sum_amount = sum(amount), .by = customer_id)

db_sales_pct = db_sales_amount %>%
  summarise(
    p25 = quantile(sum_amount, 0.25, na.rm = TRUE), 
    p50 = quantile(sum_amount, 0.5, na.rm = TRUE), 
    p75 = quantile(sum_amount, 0.75, na.rm = TRUE)
  )

db_result = db_sales_amount %>% 
  cross_join(db_sales_pct) %>% 
  mutate(
    pct_group = case_when(
      (sum_amount < p25) ~ "1", 
      (sum_amount < p50) ~ "2", 
      (sum_amount < p75) ~ "3", 
      (sum_amount >= p75) ~ "4"
    )
  ) %>% 
  select(customer_id, sum_amount, pct_group) %>% 
  head(10)
  
db_result
db_result %>% collect()

#   customer_id    sum_amount pct_group
#    <chr>               <dbl> <chr>    
#  1 CS003515000195       5412 4        
#  2 CS014415000077      14076 4        
#  3 CS026615000085       2885 3        
#  4 CS015415000120       4106 4        
#  5 CS008314000069       5293 4        

#................................................
db_sales_amount %>% 
  cross_join(db_sales_pct) %>% 
  mutate(
    pct_group = 
      cut(
        sum_amount, 
        breaks = c(-Inf, p25, p50, p75, Inf), 
        # labels = 1:4 %>% as.character(), 
        labels = FALSE, 
        right = FALSE, 
        include.lowest = TRUE
      ) %>% 
      as.character()
  ) %>% 
  head(10)
#=> Error in `cut()`: ! `breaks` are not unique.

#...............................................................................
# SQLクエリ
db_result %>% show_query(cte = TRUE)

q = sql("
WITH q01 AS (
  SELECT customer_id, SUM(amount) AS sum_amount
  FROM receipt
  GROUP BY customer_id
),
q02 AS (
  SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY sum_amount) AS p25,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sum_amount) AS p50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY sum_amount) AS p75
  FROM q01
),
q03 AS (
  SELECT LHS.*, RHS.*
  FROM q01 LHS
  CROSS JOIN q02 RHS
)
SELECT
  customer_id,
  sum_amount,
  CASE
WHEN ((sum_amount < p25)) THEN '1'
WHEN ((sum_amount < p50)) THEN '2'
WHEN ((sum_amount < p75)) THEN '3'
WHEN ((sum_amount >= p75)) THEN '4'
END AS pct_group
FROM q03 q01
LIMIT 10
"
)
q %>% my_select(con)

#-------------------------------------------------------------------------------
# R-056 ------------
# 顧客データ（customer）の年齢（age）をもとに10歳刻みで年代を算出し、
# 顧客ID（customer_id）、生年月日（birth_day）とともに10件表示せよ。
# ただし、60歳以上は全て60歳代とすること。年代を表すカテゴリ名は任意とする。

pacman::p_load(epikit)

df_customer %>% 
  mutate(
    age_rng = epikit::age_categories(age, lower = 0, upper = 60, by = 10)
  ) %>% 
  select(customer_id, birth_day, age, age_rng) %>% 
  head(10)

# A tibble: 21,971 × 4
#    customer_id    birth_day    age age_rng
#    <chr>          <chr>      <int> <fct>  
#  1 CS021313000114 1981-04-29    37 30-39  
#  2 CS037613000071 1952-04-01    66 60+    
#  3 CS031415000172 1976-10-04    42 40-49  
#  4 CS028811000001 1933-03-27    86 60+    
#  5 CS001215000145 1995-03-29    24 20-29  
#  6 CS020401000016 1974-09-15    44 40-49  
#  7 CS015414000103 1977-08-09    41 40-49  
#  8 CS029403000008 1973-08-17    45 40-49  
# ...

#...............................................................................

db_result = db_customer %>% 
  mutate(
    age_rng = pmin((floor(age / 10) * 10), 60) %>% as.integer()
  ) %>% 
  select(customer_id, birth_day, age, age_rng) %>% 
  head(10)
  
db_result %>% collect()

# A tibble: 10 × 4
#    customer_id    birth_day    age age_rng
#    <chr>          <date>     <int>   <int>
#  1 CS021313000114 1981-04-29    37      30
#  2 CS037613000071 1952-04-01    66      60
#  3 CS031415000172 1976-10-04    42      40
#  4 CS028811000001 1933-03-27    86      60
#  5 CS001215000145 1995-03-29    24      20
#  6 CS020401000016 1974-09-15    44      40
#  7 CS015414000103 1977-08-09    41      40
#  ...

#...............................................................................

db_result %>% my_show_query()

q = sql("
SELECT
  customer_id,
  birth_day,
  age,
  CAST(LEAST((FLOOR(age / 10.0) * 10.0), 60.0) AS INTEGER) AS age_rng
FROM customer
LIMIT 10
"
)
q %>% my_select(con)

# printf(): 頭に0をつけて文字列変換できる.

q = sql("
SELECT
  customer_id, 
  birth_day, 
  LEAST((age / 10) * 10, 60) AS era
  -- printf('%02d', LEAST((age / 10) * 10, 60)) AS era
FROM customer
WHERE age IS NOT NULL
ORDER BY era, customer_id;
"
)
q %>% my_select(con)

# A tibble: 21,971 × 3
#    customer_id    birth_day    era
#    <chr>          <chr>      <int>
#  1 CS001105000001 2000-01-14    10
#  2 CS001112000009 2006-08-24    10
#  3 CS001112000019 2001-01-31    10
#  4 CS001112000021 2001-12-15    10
#  5 CS001112000023 2004-01-26    10
#  6 CS001112000024 2001-01-16    10

#-------------------------------------------------------------------------------
# R-057 ------------
# 056の抽出結果と性別コード（gender_cd）により、新たに性別×年代の組み合わせを表すカテゴリデータを作成し、
# 10件表示せよ。組み合わせを表すカテゴリの値は任意とする。

d.c = df_customer %>% 
  mutate(age_rng = epikit::age_categories(age, lower = 0, upper = 60, by = 10)) %>% 
  select(customer_id, birth_day, age, age_rng, gender_cd)

d = d.c %>% 
  unite("gender_age", gender_cd, age_rng, sep = "_", remove = F) %>% 
  # mutate(across(gender_age, ~ as.factor(.x))) %>% 
  arrange(customer_id)

d
# A tibble: 21,971 × 6
#    customer_id    birth_day    age gender_age age_rng gender_cd
#    <chr>          <date>     <int> <chr>      <fct>   <chr>    
#  1 CS001105000001 2000-01-14    19 0_10-19    10-19   0        
#  2 CS001112000009 2006-08-24    12 1_10-19    10-19   1        
#  3 CS001112000019 2001-01-31    18 1_10-19    10-19   1        
#  4 CS001112000021 2001-12-15    17 1_10-19    10-19   1        
#  5 CS001112000023 2004-01-26    15 1_10-19    10-19   1        
#  6 CS001112000024 2001-01-16    18 1_10-19    10-19   1        
#  7 CS001112000029 2005-01-24    14 1_10-19    10-19   1        
#  8 CS001112000030 2003-03-02    16 1_10-19    10-19   1        
#  9 CS001113000004 2003-02-22    16 1_10-19    10-19   1        
# 10 CS001113000010 2005-05-09    13 1_10-19    10-19   1        
# 11 CS001114000005 2004-11-22    14 1_10-19    10-19   1        
# 12 CS001115000006 2007-03-02    12 9_10-19    10-19   9   
# ...

d$gender_age %>% levels() %>% writeLines(sep = ", ")
d$gender_age %>% levels() %>% ll.json()
# ["0_10-19", "0_20-29", "0_30-39", "0_40-49", "0_50-59", "0_60+", "1_10-19", "1_20-29", "1_30-39", "1_40-49", "1_50-59", "1_60+", "9_10-19", "9_20-29", "9_30-39", "9_40-49", "9_50-59", "9_60+"] 

#...............................................................................
# printf(): 頭に0をつけて文字列変換できる.
q = sql("
select
  customer_id, 
  birth_day, 
  gender_cd || printf('%02d', MIN((age / 10) * 10, 60)) as gender_era
from
  customer
order by 
  customer_id
"
)
q %>% my_select(con)
# A tibble: 21,971 × 3
#    customer_id    birth_day  gender_era
#    <chr>          <chr>      <chr>     
#  1 CS001105000001 2000-01-14 010       
#  2 CS001112000009 2006-08-24 110       
#  3 CS001112000019 2001-01-31 110       
#  4 CS001112000021 2001-12-15 110       
#  5 CS001112000023 2004-01-26 110       
#  6 CS001112000024 2001-01-16 110       
#  7 CS001112000029 2005-01-24 110       
#  8 CS001112000030 2003-03-02 110       
#  9 CS001113000004 2003-02-22 110       
# ...

#-------------------------------------------------------------------------------
# R-058 ------------
# 顧客データ（customer）の性別コード（gender_cd）をダミー変数化し、顧客ID（customer_id）とともに10件表示せよ。

d = df_customer %>% mutate(across(gender_cd, ~ as.factor(.x)))
d$gender_cd %>% levels()

# d %>% recipes::recipe(~ customer_id + gender_cd, data = .)
d %>% recipes::recipe() %>% 
  step_select(customer_id, gender_cd) %>% 
  step_dummy(gender_cd, one_hot = T) %>% 
  prep() %>% bake(new_data = NULL)

# A tibble: 21,971 × 4
#    customer_id    gender_cd_X0 gender_cd_X1 gender_cd_X9
#    <fct>                 <dbl>        <dbl>        <dbl>
#  1 CS021313000114            0            1            0
#  2 CS037613000071            0            0            1
#  3 CS031415000172            0            1            0
#  4 CS028811000001            0            1            0
#  5 CS001215000145            0            1            0
#  6 CS020401000016            1            0            0
#  7 CS015414000103            0            1            0
# ...

#...............................................................................

db_result = db_customer %>% 
  select(
    customer_id, gender_cd
  ) %>% 
  mutate(
    gender_cd_0 = ifelse(gender_cd == "0", 1L, 0L), 
    gender_cd_1 = ifelse(gender_cd == "1", 1L, 0L), 
    gender_cd_9 = ifelse(gender_cd == "9", 1L, 0L), 
    .keep = "unused"
  )

db_result %>% collect()

#...............................................................................

db_result %>% show_query()

q = sql("
SELECT
  customer_id,
  CASE WHEN (gender_cd = '0') THEN 1 WHEN NOT (gender_cd = '0') THEN 0 END AS gender_cd_0,
  CASE WHEN (gender_cd = '1') THEN 1 WHEN NOT (gender_cd = '1') THEN 0 END AS gender_cd_1,
  CASE WHEN (gender_cd = '9') THEN 1 WHEN NOT (gender_cd = '9') THEN 0 END AS gender_cd_9
FROM customer
"
)
q %>% my_select(con)

q = sql("
select
  customer_id, 
  case when gender_cd = '0' then 1 else 0 end as gender_cd_0, 
  case when gender_cd = '1' then 1 else 0 end as gender_cd_1, 
  case when gender_cd = '9' then 1 else 0 end as gender_cd_9
from
  customer
"
)
q %>% my_select(con)

# A tibble: 21,971 × 4
# customer_id	gender_cd_0	gender_cd_1	gender_cd_9
# CS021313000114	0	1	0
# CS037613000071	0	0	1
# CS031415000172	0	1	0
# CS028811000001	0	1	0
# ...

#-------------------------------------------------------------------------------
# R-060 ------------
# レシート明細データ（receipt）の売上金額（amount）を顧客ID（customer_id）ごとに合計し、
# 売上金額合計を最小値0、最大値1に正規化して顧客ID、売上金額合計とともに10件表示せよ。
# ただし、顧客IDが"Z"から始まるのものは非会員を表すため、除外して計算すること。

df_receipt %>% 
  filter(!str_detect(customer_id, "^Z")) %>% 
  summarise(sum_amount = sum(amount, na.rm = T), .by = "customer_id") %>% 
  mutate(norm_amount = scales::rescale(sum_amount,, to = c(0, 1))) %>% 
  arrange(customer_id)

# A tibble: 8,306 × 3
#    customer_id    sum_amount norm_amount
#    <chr>               <dbl>       <dbl>
#  1 CS001113000004       1298   0.053354 
#  2 CS001114000005        626   0.024157 
#  3 CS001115000010       3044   0.12921  
#  4 CS001205000004       1988   0.083333 
#  5 CS001205000006       3337   0.14194  
# ...

#...............................................................................

db_result = db_receipt %>% 
  # filter(!str_detect(customer_id, "^Z")) %>% 
  filter(!customer_id %LIKE% "Z%") %>% 
  summarise(sum_amount = sum(amount, na.rm = T), .by = "customer_id") %>% 
  mutate(
    min_amount = min(sum_amount), 
    max_amount = max(sum_amount)
  ) %>% 
  mutate(
    norm_amount = 
      (sum_amount - min_amount) / (max_amount -  min_amount)
  ) %>% 
  select(-c(min_amount, max_amount)) %>% 
  arrange(customer_id)

db_result %>% collect()

#...............................................................................

db_result %>% my_show_query()

q = sql("
WITH q01 AS (
  SELECT receipt.*
  FROM receipt
  -- WHERE (NOT(REGEXP_MATCHES(customer_id, '^Z')))
  WHERE (NOT(customer_id LIKE 'Z%'))
),
q02 AS (
  SELECT customer_id, SUM(amount) AS sum_amount
  FROM q01
  GROUP BY customer_id
),
q03 AS (
  SELECT
    q01.*,
    MIN(sum_amount) OVER () AS min_amount,
    MAX(sum_amount) OVER () AS max_amount
  FROM q02 q01
)
SELECT
  customer_id,
  sum_amount,
  (sum_amount - min_amount) / (max_amount - min_amount) AS norm_amount
FROM q03 q01
ORDER BY customer_id
"
)
q %>% my_select(con)

# A tibble: 8,306 × 3
#    customer_id    sum_amount norm_amount
#    <chr>               <dbl>       <dbl>
#  1 CS001113000004       1298   0.053354 
#  2 CS001114000005        626   0.024157 
#  3 CS001115000010       3044   0.12921  
#  4 CS001205000004       1988   0.083333 
#  5 CS001205000006       3337   0.14194  
# ...

#-------------------------------------------------------------------------------
# R-069 ------------
# レシート明細データ（receipt）と商品データ（product）を結合し、顧客毎に全商品の売上金額合計と、
# カテゴリ大区分コード（category_major_cd）が"07"（瓶詰缶詰）の売上金額合計を計算の上、両者の比率を求めよ。
# 抽出対象はカテゴリ大区分コード"07"（瓶詰缶詰）の売上実績がある顧客のみとし、結果を10件表示せよ。

df_receipt %>% 
  inner_join(df_product, by = "product_cd") %>% 
  select(customer_id, category_major_cd, amount) %>% 
  mutate(amount_07 = ifelse(category_major_cd == "07", amount, 0.0)) %>% 
  summarise(across(c(amount, amount_07), ~ sum(.x, na.rm = T)), .by = "customer_id") %>% 
  filter(amount_07 > 0.0) %>% 
  mutate(sales_rate = amount_07 / amount) %>% 
  arrange(customer_id)

# A tibble: 6,865 × 4
#    customer_id    amount amount_07 sales_rate
#    <chr>           <dbl>     <dbl>      <dbl>
#  1 CS001113000004   1298      1298    1      
#  2 CS001114000005    626       486    0.77636
#  3 CS001115000010   3044      2694    0.88502
#  4 CS001205000004   1988       346    0.17404
#  5 CS001205000006   3337      2004    0.60054
#  ...

#...............................................................................

db_result = db_receipt %>% 
  inner_join(db_product, by = "product_cd") %>% 
  select(customer_id, category_major_cd, amount) %>% 
  mutate(amount_07 = ifelse(category_major_cd == "07", amount, 0.0)) %>% 
  summarise(across(c(amount, amount_07), ~ sum(.x, na.rm = T)), .by = "customer_id") %>% 
  filter(amount_07 > 0.0) %>% 
  mutate(sales_rate = amount_07 / amount) %>% 
  arrange(customer_id)

db_result %>% collect()

#...............................................................................

db_result %>% show_query(cte = TRUE)

# db_receipt %>% 
#   mutate(x = amount %>% round(2L), .keep = "used") %>% my_show_query()

q = sql("
WITH q01 AS (
  SELECT customer_id, category_major_cd, amount
  FROM receipt
  INNER JOIN product
    ON (receipt.product_cd = product.product_cd)
),
q02 AS (
  SELECT
    q01.*,
    CASE WHEN (category_major_cd = '07') THEN amount WHEN NOT (category_major_cd = '07') THEN 0.0 END AS amount_07
  FROM q01
),
q03 AS (
  SELECT customer_id, SUM(amount) AS amount, SUM(amount_07) AS amount_07
  FROM q02 q01
  GROUP BY customer_id
  HAVING (SUM(amount_07) > 0.0)
)
SELECT q01.*, amount_07 / amount AS sales_rate
FROM q03 q01
ORDER BY customer_id
"
)
q %>% my_select(con)

#................................................
q = sql("
with rec as (
  select
    r.customer_id, 
    r.amount, 
    p.category_major_cd
  from
    receipt as r
  inner join product as p
  USING (product_cd)
), 
cust as (
select 
  distinct customer_id
from
  rec
where 
  category_major_cd = '07'
), 
customer_amount as (
  select 
    customer_id, 
    SUM(amount) as sum_amount, 
    SUM(case when category_major_cd = '07' then amount end) as major_amount
  from
    rec
  where 
    customer_id IN cust
  group by
    customer_id
)
select
  *, 
  ROUND(major_amount / sum_amount, 2) as ratio
  -- チェック用
  -- , MIN(major_amount)
from
  customer_amount
"
)
q %>% my_select(con)

#-------------------------------------------------------------------------------
# R-070 ------------
# レシート明細データ（receipt）の売上日（sales_ymd）に対し、顧客データ（customer）の会員申込日
# （application_date）からの経過日数を計算し、顧客ID（customer_id）、売上日、会員申込日とともに
# 10件表示せよ（sales_ymdは数値、application_dateは文字列でデータを保持している点に注意）。

# 経過日数
"20170322" %>% lubridate::parse_date_time("%Y%m%d")
"20170322" %>% lubridate::parse_date_time("%Y%m%d") %>% class()
# "POSIXlt" "POSIXt" 
strptime("20170322", "%Y%m%d")
strptime("20170322", "%Y%m%d") %>% class()
# "POSIXlt" "POSIXt" 
difftime(strptime("20170322", "%Y%m%d"), strptime("20170222", "%Y%m%d")) %>% as.numeric(units = "days")

df_receipt %>% 
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    df_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    elapsed_days = 
      difftime(
        strptime(as.character(sales_ymd), "%Y%m%d"), 
        strptime(application_date, "%Y%m%d"), 
        units = "days"
      ) %>% 
      as.integer()
  ) %>% 
  arrange(customer_id, sales_ymd)

# 
df_receipt %>% 
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    df_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    elapsed_days = 
      lubridate::interval(
        strptime(application_date, "%Y%m%d"), 
        strptime(as.character(sales_ymd), "%Y%m%d")
      ) %/%
      lubridate::days(1L)
  ) %>% 
  arrange(customer_id, sales_ymd)

# A tibble: 32,411 × 4
#    customer_id    sales_ymd application_date elapsed_days
#    <chr>              <int> <chr>                   <int>
#  1 CS001113000004  20190308 20151105                 1219
#  2 CS001114000005  20180503 20160412                  751
#  3 CS001114000005  20190731 20160412                 1205
#  4 CS001115000010  20171228 20150417                  986
#  5 CS001115000010  20180701 20150417                 1171
#  6 CS001115000010  20190405 20150417                 1449
#  ...

#...............................................................................

db_receipt %>% 
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    db_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    elapsed_days = 
      difftime(
        strptime(as.character(sales_ymd), "%Y%m%d"), 
        strptime(application_date, "%Y%m%d"), 
        units = "days"
      ) %>% 
      as.integer()
  ) %>% 
  arrange(customer_id, sales_ymd)

# 上記、db_receipt, db_customer がテーブル参照。
# Error in `difftime()`:
# ! Don't know how to translate `difftime()`

# 
db_receipt %>% 
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    db_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    elapsed_days = 
      # strptime(as.character(sales_ymd), "%Y%m%d") - strptime(application_date, "%Y%m%d")
      lubridate::interval(
        strptime(application_date, "%Y%m%d"), 
        strptime(as.character(sales_ymd), "%Y%m%d")
      ) %/%
      lubridate::days(1L)
  ) %>% 
  arrange(customer_id, sales_ymd)

# Error in `lubridate::interval()`:
# ! No known SQL translation

# dplyr が認識できない関数をエラーにする 
options(dplyr.strict_sql = FALSE)

db_result = db_receipt %>% 
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    db_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    elapsed_days = 
      strptime(
        as.character(sales_ymd), "%Y%m%d") - 
          strptime(application_date, "%Y%m%d"
      )
  ) %>% 
  mutate(
    elapsed_days = sql("EXTRACT(DAY FROM elapsed_days)")
    # elapsed_days = as.integer(elapsed_days)
  ) %>% 
  # select(-elapsed_time) %>% 
  arrange(customer_id, sales_ymd)

db_result %>% collect()

#...............................................................................

db_result %>% show_query(cte = TRUE)

q = sql("
WITH q01 AS (
  SELECT DISTINCT customer_id, sales_ymd
  FROM receipt
),
q02 AS (
  SELECT LHS.*, application_date
  FROM q01 LHS
  INNER JOIN customer
    ON (LHS.customer_id = customer.customer_id)
),
q03 AS (
  SELECT
    q01.*,
    strptime(CAST(sales_ymd AS TEXT), '%Y%m%d') - strptime(application_date, '%Y%m%d') AS elapsed_days
  FROM q02 q01
)
SELECT
  customer_id,
  sales_ymd,
  application_date,
  EXTRACT(DAY FROM elapsed_days) AS elapsed_days
FROM q03 q01
ORDER BY customer_id, sales_ymd
"
)
q %>% my_select(con)

# A tibble: 32,411 × 4
#    customer_id    sales_ymd application_date elapsed_days
#    <chr>              <int> <chr>                   <dbl>
#  1 CS001113000004  20190308 20151105                 1219
#  2 CS001114000005  20180503 20160412                  751
#  3 CS001114000005  20190731 20160412                 1205
#  4 CS001115000010  20171228 20150417                  986
#  5 CS001115000010  20180701 20150417                 1171
#  ...

# sqlight
q = sql("
select
  r.customer_id, 
  r.sales_ymd, 
  c.application_date, 
  julianday(
    substr(r.sales_ymd, 1, 4) || '-' || substr(r.sales_ymd, 5, 2) || '-' || substr(r.sales_ymd, 7, 2)
  )
  - julianday(
    substr(c.application_date, 1, 4) || '-' || substr(c.application_date, 5, 2) || '-' || substr(c.application_date, 7, 2)
  ) as elapsed_days
from
  (
    select distinct customer_id, sales_ymd from receipt
  ) as r 
inner join customer as c
  USING (customer_id)
ORDER BY
  customer_id, sales_ymd
"
)
q %>% my_select(con)

#-------------------------------------------------------------------------------
# R-071 ------------
# レシート明細データ（df_receipt）の売上日（sales_ymd）に対し、顧客データ（df_customer）の会員申込日
# （application_date）からの経過月数を計算し、顧客ID（customer_id）、売上日、会員申込日とともに10件表示せよ
# （sales_ymdは数値、application_dateは文字列でデータを保持している点に注意）。1ヶ月未満は切り捨てること。

df_receipt %>%
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
      df_customer %>% select(customer_id, application_date), 
      by = "customer_id"
  ) %>% 
  mutate(
      intrval = 
        lubridate::interval(
          strptime(application_date, "%Y%m%d"), 
          strptime(as.character(sales_ymd), "%Y%m%d")
        ), 
      elapsed_months = (intrval %/% months(1)) %>% as.integer()
      # time_age = as.period(intrval) %>% year()
  ) %>%
  select(
      customer_id, sales_ymd, application_date, elapsed_months
  ) %>% 
  arrange(customer_id, sales_ymd) %>% 
  head(10)

# A tibble: 10 × 4
#    customer_id    sales_ymd application_date elapsed_months
#    <chr>              <int> <chr>                     <int>
#  1 CS001113000004  20190308 20151105                     40
#  2 CS001114000005  20180503 20160412                     24
#  3 CS001114000005  20190731 20160412                     39
#  4 CS001115000010  20171228 20150417                     32
#  5 CS001115000010  20180701 20150417                     38
#  6 CS001115000010  20190405 20150417                     47
#  7 CS001205000004  20170914 20160615                     14
#  8 CS001205000004  20180821 20160615                     26
#  9 CS001205000004  20180904 20160615                     26
# 10 CS001205000004  20190312 20160615                     32

#...............................................................................
# dplyr が認識できない関数をエラーにする 
options(dplyr.strict_sql = FALSE)

db_result = db_receipt %>% 
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    db_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    sales_ymd_d = strptime(as.character(sales_ymd), "%Y%m%d"), 
    application_date_d = strptime(application_date, "%Y%m%d")
  ) %>% 
  mutate(
    elapsed_months = DATEDIFF('month', application_date_d, sales_ymd_d)
    # elapsed_years = DATEDIFF('year', application_date_d, sales_ymd_d)
  ) %>% 
  select(-c(sales_ymd_d, application_date_d)) %>% 
  arrange(customer_id, sales_ymd) %>% 
  head(10)

# DATEDIFF('year', start_date, end_date) が年の境界を超えた回数を数えるため、28 ヶ月の差が 3 年とカウントする


db_result %>% collect()

#    customer_id    sales_ymd application_date elapsed_months
#    <chr>              <int> <chr>                     <dbl>
#  1 CS001113000004  20190308 20151105                     40
#  2 CS001114000005  20180503 20160412                     25
#  3 CS001114000005  20190731 20160412                     39
#  4 CS001115000010  20171228 20150417                     32
#  5 CS001115000010  20180701 20150417                     39
#  6 CS001115000010  20190405 20150417                     48
#  7 CS001205000004  20170914 20160615                     15
#  8 CS001205000004  20180821 20160615                     26
#  9 CS001205000004  20180904 20160615                     27
# 10 CS001205000004  20190312 20160615                     33

db_result = db_receipt %>% 
  distinct(customer_id, sales_ymd) %>% 
  inner_join(
    db_customer %>% select(customer_id, application_date), 
    by = "customer_id"
  ) %>% 
  mutate(
    sales_ymd_d = strptime(as.character(sales_ymd), "%Y%m%d"), 
    application_date_d = strptime(application_date, "%Y%m%d")
  ) %>% 
  mutate(
    time_age = AGE(sales_ymd_d, application_date_d)
  ) %>% 
  mutate(
    elapsed_months = 
      lubridate::year(time_age) * 12 + lubridate::month(time_age)
  ) %>% 
  select(-c(sales_ymd_d, application_date_d, time_age)) %>% 
  arrange(customer_id, sales_ymd) %>% 
  head(10)

db_result %>% collect()

# A tibble: 10 × 4
#    customer_id    sales_ymd application_date elapsed_months
#    <chr>              <int> <chr>                     <dbl>
#  1 CS001113000004  20190308 20151105                     40
#  2 CS001114000005  20180503 20160412                     24
#  3 CS001114000005  20190731 20160412                     39
#  4 CS001115000010  20171228 20150417                     32
#  5 CS001115000010  20180701 20150417                     38
#  6 CS001115000010  20190405 20150417                     47
#  7 CS001205000004  20170914 20160615                     14
#  8 CS001205000004  20180821 20160615                     26
#  9 CS001205000004  20180904 20160615                     26
# 10 CS001205000004  20190312 20160615                     32

#...............................................................................

db_result %>% show_query(cte = TRUE)

q = sql("
WITH q01 AS (
  SELECT DISTINCT customer_id, sales_ymd
  FROM receipt
),
q02 AS (
  SELECT LHS.*, application_date
  FROM q01 LHS
  INNER JOIN customer
    ON (LHS.customer_id = customer.customer_id)
),
q03 AS (
  SELECT
    q01.*,
    strptime(CAST(sales_ymd AS TEXT), '%Y%m%d') AS sales_ymd_d,
    strptime(application_date, '%Y%m%d') AS application_date_d
  FROM q02 q01
),
q04 AS (
  SELECT q01.*, AGE(sales_ymd_d, application_date_d) AS time_age
  FROM q03 q01
)
SELECT
  customer_id,
  sales_ymd,
  application_date,
  (EXTRACT(year FROM time_age) * 12.0) + EXTRACT(MONTH FROM time_age) AS elapsed_months
FROM q04 q01
ORDER BY customer_id, sales_ymd
LIMIT 10
"
)
q %>% my_select(con)

#-------------------------------------------------------------------------------
# R-074 ------------

# 月曜日を求め、経過日数を計算
df_result = df_receipt %>%
  mutate(
    sales_date = 
      strptime(as.character(sales_ymd), "%Y%m%d") %>% 
      lubridate::as_date()
  ) %>% 
  mutate(
    # 曜日 : 月曜日を週の始まりとする
    dow = wday(sales_date, week_start = 1L),  
    # その週の月曜日の日付を計算
    monday_ymd = sales_date - days(dow - 1L),
    # 月曜日からの経過日数を計算
    elapsed_days = 
      difftime(
        sales_date, 
        monday_ymd, 
        units = "days"
      ) %>% 
      as.integer()
  ) %>%
  select(sales_ymd, sales_date, monday_ymd, elapsed_days) %>%
  head(10)

df_result

# A tibble: 10 × 4
#    sales_ymd sales_date monday_ymd elapsed_days
#        <int> <date>     <date>            <int>
#  1  20181103 2018-11-03 2018-10-29            5
#  2  20181118 2018-11-18 2018-11-12            6
#  3  20170712 2017-07-12 2017-07-10            2
#  4  20190205 2019-02-05 2019-02-04            1
#  5  20180821 2018-08-21 2018-08-20            1
#  6  20190605 2019-06-05 2019-06-03            2
#  7  20181205 2018-12-05 2018-12-03            2
#  8  20190922 2019-09-22 2019-09-16            6
#  9  20170504 2017-05-04 2017-05-01            3
# 10  20191010 2019-10-10 2019-10-07            3

#...............................................................................

db_result = db_receipt %>%
  mutate(
    sales_date = 
      strptime(as.character(sales_ymd), "%Y%m%d") %>% 
      lubridate::as_date()
  ) %>% 
  mutate(
    # 曜日 : 月曜日を週の始まりとする
    dow = lubridate::wday(sales_date, week_start = 1L), 
    # その週の月曜日の日付を計算
    monday_ymd = (sales_date - lubridate::days(dow - 1L)) %>% lubridate::as_date(), 
    # 月曜日からの経過日数を計算
    elapsed_days = (sales_date - monday_ymd) %>% as.integer()
  ) %>% 
  select(sales_ymd, sales_date, monday_ymd, elapsed_days) %>% 
  head(10)

db_result %>% collect()

# A tibble: 10 × 4
#    sales_ymd sales_date monday_ymd elapsed_days
#        <int> <date>     <date>            <int>
#  1  20181103 2018-11-03 2018-10-29            5
#  2  20181118 2018-11-18 2018-11-12            6
#  3  20170712 2017-07-12 2017-07-10            2
#  4  20190205 2019-02-05 2019-02-04            1
#  5  20180821 2018-08-21 2018-08-20            1
#  6  20190605 2019-06-05 2019-06-03            2
#  7  20181205 2018-12-05 2018-12-03            2
#  8  20190922 2019-09-22 2019-09-16            6
#  9  20170504 2017-05-04 2017-05-01            3
# 10  20191010 2019-10-10 2019-10-07            3

#...............................................................................

db_result %>% show_query(cte = TRUE)

q = sql("
WITH q01 AS (
  SELECT
    receipt.*,
    CAST(strptime(CAST(sales_ymd AS TEXT), '%Y%m%d') AS DATE) AS sales_date
  FROM receipt
),
q02 AS (
  SELECT q01.*, EXTRACT('dow' FROM CAST(sales_date AS DATE) + 6) + 1 AS dow
  FROM q01
),
q03 AS (
  SELECT
    q01.*,
    CAST((sales_date - TO_DAYS(CAST(dow - 1 AS INTEGER))) AS DATE) AS monday_ymd
  FROM q02 q01
)
SELECT
  sales_ymd,
  sales_date,
  monday_ymd,
  CAST((sales_date - monday_ymd) AS INTEGER) AS elapsed_days
FROM q03 q01
LIMIT 10
"
)
q %>% my_select(con)

# A tibble: 10 × 4
#    sales_ymd sales_date monday_ymd elapsed_days
#        <int> <date>     <date>            <int>
#  1  20181103 2018-11-03 2018-10-29            5
#  2  20181118 2018-11-18 2018-11-12            6
#  3  20170712 2017-07-12 2017-07-10            2
#  4  20190205 2019-02-05 2019-02-04            1
#  5  20180821 2018-08-21 2018-08-20            1
#  6  20190605 2019-06-05 2019-06-03            2
#  7  20181205 2018-12-05 2018-12-03            2
#  8  20190922 2019-09-22 2019-09-16            6
#  9  20170504 2017-05-04 2017-05-01            3
# 10  20191010 2019-10-10 2019-10-07            3

q = sql("
SELECT 
  sales_ymd, 
  CAST(
    STRFTIME(
      '%Y%m%d', 
      DATE_TRUNC(
        'week', 
        STRPTIME(CAST(sales_ymd AS STRING), '%Y%m%d')
      )
    ) 
  AS INTEGER) AS monday_ymd,
  EXTRACT(
    DAY FROM (
      STRPTIME(
        CAST(
          sales_ymd AS STRING), '%Y%m%d') - 
            DATE_TRUNC('week', STRPTIME(CAST(sales_ymd AS STRING), '%Y%m%d'))
        )
  ) AS days_since_monday
FROM receipt
LIMIT 10
"
)
q %>% my_select(con)

#-------------------------------------------------------------------------------
# R-075 ------------
# 顧客データ（customer）からランダムに1%のデータを抽出し、先頭から10件表示せよ。

df_customer %>% slice_sample(prop = 0.01) %>% withr::with_seed(14, .) %>% head(10)

#...............................................................................

db_customer %>% slice_sample(prop = 0.01) %>% head(10)
# >
# Error in `slice_sample()`:
# ! Sampling by `prop` is not supported on database backends

db_customer %>% 
  slice_sample(n = 100) %>% 
  # slice_sample(n = 0.01 * n()) %>% 
  head(10)

#................................................
# シードを設定
dbExecute(con, "SELECT SETSEED(0.5);")

db_result = db_customer %>% 
  mutate(r = runif(n = n())) %>% 
  filter(r <= 0.01) %>% 
  select(customer_id, gender_cd, gender, birth_day, age)
  # head(10)

db_result %>% collect() %>% arrange(customer_id)

db_result %>% show_query()

#................................................
# シードを設定
dbExecute(con, "SELECT SETSEED(0.5);")
db_result = db_customer %>% 
  # mutate(prank = percent_rank(runif(n = n()))) %>% 
  mutate(r = runif(n = n())) %>% 
  mutate(prank = percent_rank(r)) %>% 
  filter(prank <= 0.01) %>% 
  select(customer_id, gender_cd, gender, birth_day, age)

db_result %>% collect() %>% arrange(customer_id)

# A tibble: 220 × 5
#    customer_id    gender_cd gender birth_day    age
#    <chr>          <chr>     <chr>  <date>     <int>
#  1 CS001305000005 0         男性   1979-01-02    40
#  2 CS001312000261 1         女性   1987-04-07    31
#  3 CS001313000376 1         女性   1980-03-09    39
#  4 CS001315000444 1         女性   1987-04-01    31
#  5 CS001512000180 1         女性   1963-03-26    56
#  6 CS001512000275 1         女性   1960-08-09    58
#  7 CS001513000084 1         女性   1962-07-01    56
#  8 CS001513000355 1         女性   1959-07-14    59
#  9 CS001515000118 1         女性   1967-08-07    51
# 10 CS001515000568 1         女性   1959-07-28    59

#................................................

# ランダムな行番号を生成する方法
# 列の一部を出力
dbExecute(con, "SELECT SETSEED(0.5);")
db_result = db_customer %>% 
  mutate(r = runif(n = n())) %>% 
  mutate(
    row_num = row_number(r)
  ) %>% 
  filter(row_num <= 0.01 * n()) %>% 
  # select(customer_id, customer_name, gender_cd, gender, r, row_num, cnt) %>% 
  select(customer_id, gender_cd, gender, birth_day, age) %>% 
  head(10)

db_result %>% collect() %>% arrange(customer_id)

# A tibble: 10 × 5
#    customer_id    gender_cd gender birth_day    age
#    <chr>          <chr>     <chr>  <date>     <int>
#  1 CS003315000484 1         女性   1988-03-16    31
#  2 CS003513000181 1         女性   1964-05-26    54
#  3 CS005503000015 0         男性   1966-07-09    52
#  4 CS015513000041 1         女性   1962-09-01    56
#  5 CS024313000089 1         女性   1985-07-25    33
#  6 CS027512000028 1         女性   1967-12-15    51
#  7 CS027715000080 1         女性   1943-12-15    75
#  8 CS031312000076 1         女性   1980-04-05    38
#  9 CS035515000219 1         女性   1960-06-29    58
# 10 CS051313000008 1         女性   1982-08-28    36

db_result %>% collect()
db_result %>% collect() %>% arrange(customer_id)

#...............................................................................

# PERCENT_RANK() を使用

dbExecute(con, "SELECT SETSEED(0.5);")
db_result = db_customer %>% 
  mutate(r = runif(n = n())) %>% 
  mutate(prank = percent_rank(r)) %>% 
  filter(prank <= 0.01) %>% 
  select(customer_id, gender_cd, gender, birth_day, age)

db_result %>% show_query(cte = TRUE)

# set seed すること!!!
q = sql("
SELECT SETSEED(0.5);
WITH rand_customers AS (
  SELECT 
    *, 
    RANDOM() AS rand
  FROM customer
),
ranked_customers AS (
  SELECT
    *,
    PERCENT_RANK() OVER (ORDER BY rand) AS prank
  FROM rand_customers
)
SELECT customer_id, gender_cd, gender, birth_day, age
FROM ranked_customers
WHERE (prank <= 0.01)
"
)

q %>% my_select(con) %>% arrange(customer_id)

# A tibble: 220 × 5
#    customer_id    gender_cd gender birth_day    age
#    <chr>          <chr>     <chr>  <date>     <int>
#  1 CS001305000005 0         男性   1979-01-02    40
#  2 CS001312000261 1         女性   1987-04-07    31
#  3 CS001313000376 1         女性   1980-03-09    39
#  4 CS001315000444 1         女性   1987-04-01    31
#  5 CS001512000180 1         女性   1963-03-26    56
#  6 CS001512000275 1         女性   1960-08-09    58
#  7 CS001513000084 1         女性   1962-07-01    56
#  8 CS001513000355 1         女性   1959-07-14    59
#  9 CS001515000118 1         女性   1967-08-07    51
# 10 CS001515000568 1         女性   1959-07-28    59

#................................................
# 以下はブログに書かない
# 再現性が確保されない方法

# set seed すること!!!
q = sql("
SELECT SETSEED(0.5);
WITH ranked_customers AS (
  SELECT 
    customer_id, gender_cd, gender, birth_day, age,
    PERCENT_RANK() OVER (ORDER BY RANDOM()) AS prank
  FROM customer
)
SELECT *
FROM ranked_customers
WHERE prank <= 0.01
"
)

q %>% my_select(con) %>% arrange(customer_id)

# A tibble: 220 × 6
#    customer_id    gender_cd gender birth_day    age      prank
#    <chr>          <chr>     <chr>  <date>     <int>      <dbl>
#  1 CS001305000005 0         男性   1979-01-02    40 0.0045972 
#  2 CS001312000261 1         女性   1987-04-07    31 0.0055985 
#  3 CS001313000376 1         女性   1980-03-09    39 0.0069640 
#  4 CS001315000444 1         女性   1987-04-01    31 0.0085116 
#  5 CS001512000180 1         女性   1963-03-26    56 0.0092399 
#  6 CS001512000275 1         女性   1960-08-09    58 0.0028220 
#  7 CS001513000084 1         女性   1962-07-01    56 0.0063268 
#  8 CS001513000355 1         女性   1959-07-14    59 0.00086482
#  9 CS001515000118 1         女性   1967-08-07    51 0.0018207 
# 10 CS001515000568 1         女性   1959-07-28    59 0.0015931 

#................................................
# 以下はブログに書かない

# set seed すること!!!
q = sql("
SELECT SETSEED(0.5);
WITH q01 AS (
  SELECT customer.*, RANDOM() AS r
  FROM customer
),
q02 AS (
  SELECT
    q01.*,
    ROW_NUMBER() OVER (ORDER BY r) AS row_num,
    COUNT(*) OVER () AS cnt
  FROM q01
)
SELECT customer_id, gender_cd, gender, birth_day, age
FROM q02 q01
WHERE (row_num <= (0.01 * cnt))
-- チェック用
-- order by row_num desc
LIMIT 10
"
)
q %>% my_select(con)

q %>% my_select(con) %>% arrange(customer_id)

#-------------------------------------------------------------------------------
# R-076 ------------
# 顧客データ（customer）から性別コード（gender_cd）の割合に基づきランダムに10%のデータを層化抽出し、
# 性別コードごとに件数を集計せよ。

# 層別サンプリング
df_customer %>% 
  rsample::initial_split(prop = 0.1, strata = "gender_cd") %>% withr::with_seed(14, .) %>% 
  training() %>% 
  count(gender_cd)

# slice_sample
df_customer %>% slice_sample(prop = 0.1, by = gender_cd) %>% withr::with_seed(14, .) %>% 
  count(gender_cd)

# グループ分割
# 同じ postal_cd が双方の分割データに含まれないように分割
df_customer %>% 
  rsample::group_initial_split(group = postal_cd, prop = 0.1) %>% 
  withr::with_seed(14, .) %>% 
  training() %>% 
  count(postal_cd)

#...............................................................................
# ランダムな行番号を生成する方法
# 列の一部を出力

db_customer %>% 
  select(gender_cd) %>% 
  group_by(gender_cd) %>% 
  mutate(r = runif(n = n())) %>% 
  ungroup() %>% 
  my_show_query(T)

# 上記コードは、group_by(gender_cd) が効かない
# SELECT gender_cd, RANDOM() AS r
# FROM customer

#................................................

# ランダムシードを設定
con %>% dbExecute("SELECT SETSEED(0.5);")

db_result = db_customer %>%
  mutate(rand = runif(n = n())) %>% 
  group_by(gender_cd) %>%
  mutate(prank = percent_rank(rand)) %>%
  filter(prank <= 0.1) %>%  # 上位10%を選択
  ungroup()

db_result %>% arrange(customer_id) %>% collect()

db_result %>% select(customer_id, rand, prank) %>% arrange(rand) %>% collect()

db_result %>% count(gender_cd)

#   gender_cd     n
#       <int> <dbl>
# 1         0   299
# 2         1  1792
# 3         9   108

#................................................
# customer をランダムに並び替えてからグループ内で順番付けをする

# ランダムシードを設定
con %>% dbExecute("SELECT SETSEED(0.5);")

db_result = db_customer %>%
  mutate(rand = runif(n = n())) %>% 
  group_by(gender_cd) %>%
  mutate(
    row_num = row_number(rand), # グループ内で順番付け
    cnt = n()
  ) %>%
  # 上位10%を選択
  filter(row_num <= 0.1 * cnt) %>% 
  ungroup()

db_result %>% arrange(customer_id) %>% collect()

db_result %>% count(gender_cd) %>% collect()

  gender_cd     n
  <chr>     <dbl>
1 0           298
2 1          1791
3 9           107

db_result %>% show_query(cte = TRUE)

#................................................

db_result
db_result %>% collect() %>% head(30)
db_result %>% collect() %>% tail(30)
db_result %>% collect() %>% count(gender_cd)
db_result %>% collect() %>% group_by(gender_cd) %>% reframe(x = quantile(rand))

df_customer %>% arrange(customer_id)

#...............................................................................

con %>% dbExecute("SELECT SETSEED(0.5);")

db_result = db_customer %>%
  mutate(rand = runif(n = n())) %>% 
  group_by(gender_cd) %>%
  mutate(
    prank = percent_rank(rand)
  ) %>%
  filter(prank <= 0.1) # 上位10%を選択

db_result %>% count(gender_cd) %>% show_query(cte = TRUE)

# 以下、前者の方が再現性が高く、パフォーマンス的にも安定する可能性がある

q = sql("
SELECT SETSEED(0.5);
WITH rand_customers AS (
  SELECT 
    *, 
    RANDOM() AS rand
  FROM customer
),
ranked_customers AS (
  SELECT
    *,
    PERCENT_RANK() OVER (partition by gender_cd ORDER BY rand) AS prank
  FROM rand_customers
)
SELECT gender_cd, COUNT(*) AS n
FROM ranked_customers
WHERE prank <= 0.1
GROUP BY gender_cd
"
)

q %>% my_select(con)

#................................................
# 以下の方法だと、再現性が確保されない

q = sql("
SELECT SETSEED(0.5);
WITH customer_random AS (
  SELECT
    *, 
    PERCENT_RANK() OVER (partition by gender_cd ORDER BY RANDOM()) AS prank
  FROM customer
)
SELECT *
FROM customer_random
WHERE prank <= 0.1
"
)
q %>% my_select(con) %>% arrange(customer_id)
q %>% my_select(con) %>% count(gender_cd)
df_customer %>% count(gender_cd)

q = sql("
SELECT SETSEED(0.5);
WITH customer_random AS (
  SELECT
    *, 
    PERCENT_RANK() OVER (partition by gender_cd ORDER BY RANDOM()) AS prank
  FROM customer
)
SELECT gender_cd, COUNT(*) AS n
FROM customer_random
WHERE prank <= 0.1
GROUP BY gender_cd
"
)

q %>% my_select(con)

#...............................................................................
# 以下の方法はブログには書かない

q = sql("
WITH q01 AS (
  SELECT customer.*, RANDOM() AS r
  FROM customer
),
q02 AS (
  SELECT
    q01.*,
    ROW_NUMBER() OVER (PARTITION BY gender_cd ORDER BY r) AS row_num,
    COUNT(*) OVER (PARTITION BY gender_cd) AS cnt
  FROM q01
),
q03 AS (
  SELECT q01.*
  FROM q02 q01
  WHERE (row_num <= (0.1 * cnt))
)
SELECT gender_cd, COUNT(*) AS n
FROM q03 q01
GROUP BY gender_cd
"
)
q %>% my_select(con)

q = sql("
SELECT SETSEED(0.5);
WITH cusotmer_r AS (
  SELECT customer.*, RANDOM() AS r
  FROM customer
),
cusotmer_random AS (
  SELECT
    *,
    ROW_NUMBER() OVER (win ORDER BY r) AS row_num,
    COUNT(*) OVER win AS cnt
  FROM cusotmer_r
  WINDOW win as (partition by gender_cd)
)
SELECT gender_cd, COUNT(*) AS n
FROM cusotmer_random
WHERE (row_num <= (0.1 * cnt))
GROUP BY gender_cd
"
)
q %>% my_select(con)

# A tibble: 3 × 2
#   gender_cd     n
#       <int> <dbl>
# 1         0   298
# 2         1  1791
# 3         9   107

#-------------------------------------------------------------------------------
# R-078 ------------
# レシート明細データ（df_receipt）の売上金額（amount）を顧客単位に合計し、合計した売上金額の外れ値を抽出せよ。
# ただし、顧客IDが"Z"から始まるのものは非会員を表すため、除外して計算すること。
# なお、ここでは外れ値を第1四分位と第3四分位の差であるIQRを用いて、「第1四分位数-1.5×IQR」を下回るもの、
# または「第3四分位数+1.5×IQR」を超えるものとする。結果は10件表示せよ。

df_receipt %>% 
  filter(!str_detect(customer_id, "^Z")) %>% 
  summarise(
    sum_amount = sum(amount, na.rm = T), 
    .by = customer_id
  ) %>% 
  drop_na(sum_amount) %>% 
  mutate(
    stat1 = 
      quantile(sum_amount, 0.25, na.rm = T) - 1.5 * IQR(sum_amount), 
    stat2 = 
      quantile(sum_amount, 0.75, na.rm = T) + 1.5 * IQR(sum_amount)
  ) %>% 
  filter(
    sum_amount < stat1 | sum_amount > stat2
  ) %>% 
  select(customer_id, sum_amount) %>% 
  arrange(desc(sum_amount))

# A tibble: 393 × 2
#    customer_id    sum_amount
#    <chr>               <dbl>
#  1 CS017415000097      23086
#  2 CS015415000185      20153
#  3 CS031414000051      19202
#  4 CS028415000007      19127
#  5 CS001605000009      18925
#  6 CS010214000010      18585
#  7 CS016415000141      18372
#  8 CS006515000023      18372
#  9 CS011414000106      18338
# 10 CS038415000104      17847

#...............................................................................
# R-055: PERCENTILE_CONT() はウィンドウ関数 (OVER ()) として使えない!
db_receipt %>% 
  mutate(
    p25 = quantile(amount, 0.25, na.rm = T)
  ) %>% 
  my_show_query(F)

#................................................
db_sales_amount = db_receipt %>% 
  # filter(!str_detect(customer_id, "^Z")) %>% 
  filter(!(customer_id %LIKE% "Z%")) %>% 
  summarise(sum_amount = sum(amount), .by = customer_id) %>% 
  filter(!is.na(sum_amount))

stats_amount = db_sales_amount %>% 
  summarise(
    p25 = quantile(sum_amount, 0.25, na.rm = T), 
    p75 = quantile(sum_amount, 0.75, na.rm = T)
  )

stats_amount
#      p25    p75
#    <dbl>  <dbl>
# 1 548.25 3649.8

db_result = db_sales_amount %>% 
  cross_join(stats_amount) %>% 
  mutate(
    stat1 = p25 - 1.5 * (p75 - p25), 
    stat2 = p75 + 1.5 * (p75 - p25)
  ) %>% 
  filter(
    sum_amount < stat1 | sum_amount > stat2
  ) %>% 
  select(customer_id, sum_amount) %>% 
  arrange(desc(sum_amount))

db_result %>% collect()

#...............................................................................

db_result %>% show_query(cte = TRUE)

# <SQL>
# WITH q01 AS (
#   SELECT receipt.*
#   FROM receipt
#   WHERE (NOT((customer_id LIKE 'Z%')))
# ),
# q02 AS (
#   SELECT customer_id, SUM(amount) AS sum_amount
#   FROM q01
#   GROUP BY customer_id
#   HAVING (NOT(((SUM(amount)) IS NULL)))
# ),
# q03 AS (
#   SELECT customer_id, SUM(amount) AS sum_amount
#   FROM q01
#   GROUP BY customer_id
#   HAVING (NOT(((SUM(amount)) IS NULL)))
# ),
# q04 AS (
#   SELECT
#     PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY sum_amount) AS p25,
#     PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY sum_amount) AS p75
#   FROM q03 q01
# ),
# q05 AS (
#   SELECT LHS.*, RHS.*
#   FROM q02 LHS
#   CROSS JOIN q04 RHS
# ),
# q06 AS (
#   SELECT
#     q01.*,
#     p25 - 1.5 * (p75 - p25) AS stat1,
#     p75 + 1.5 * (p75 - p25) AS stat2
#   FROM q05 q01
# )
# SELECT customer_id, sum_amount
# FROM q06 q01
# WHERE (sum_amount < stat1 OR sum_amount > stat2)
# ORDER BY sum_amount DESC

#-------------------------------------------------------------------------------
# R-079 ------------

df_product %>% skimr::skim()

df_product %>% 
  summarise(
    across(everything(), ~ is.na(.) %>% sum())
  )

df_product %>% 
  summarise(
    across(everything(), ~ sum(ifelse(is.na(.), 1, 0)))
  )

# A tibble: 1 × 6
#   product_cd category_major_cd category_medium_cd category_small_cd unit_price unit_cost
#        <int>             <int>              <int>             <int>      <int>     <int>
# 1          0                 0                  0                 0          7         7

#...............................................................................

db_result = db_product %>% 
  summarise(
    across(everything(), ~ sum(ifelse(is.na(.), 1, 0)))
  )

db_result %>% collect()

#...............................................................................

db_result %>% show_query()

# SELECT
#   SUM(CASE WHEN ((product_cd IS NULL)) THEN 1.0 WHEN NOT ((product_cd IS NULL)) THEN 0.0 END) AS product_cd,
#   SUM(CASE WHEN ((category_major_cd IS NULL)) THEN 1.0 WHEN NOT ((category_major_cd IS NULL)) THEN 0.0 END) AS category_major_cd,
#   SUM(CASE WHEN ((category_medium_cd IS NULL)) THEN 1.0 WHEN NOT ((category_medium_cd IS NULL)) THEN 0.0 END) AS category_medium_cd,
#   SUM(CASE WHEN ((category_small_cd IS NULL)) THEN 1.0 WHEN NOT ((category_small_cd IS NULL)) THEN 0.0 END) AS category_small_cd,
#   SUM(CASE WHEN ((unit_price IS NULL)) THEN 1.0 WHEN NOT ((unit_price IS NULL)) THEN 0.0 END) AS unit_price,
#   SUM(CASE WHEN ((unit_cost IS NULL)) THEN 1.0 WHEN NOT ((unit_cost IS NULL)) THEN 0.0 END) AS unit_cost
# FROM product

#-------------------------------------------------------------------------------
# R-081 ------------
# 単価（unit_price）と原価（unit_cost）の欠損値について、それぞれの平均値で補完した新たな商品データを作成せよ。
# なお、平均値については1円未満を丸めること（四捨五入または偶数への丸めで良い）。
# 補完実施後、各項目について欠損が生じていないことも確認すること。

df_product %>% skimr::skim()

# sample.1
df_result = df_product %>% 
  recipes::recipe() %>% 
  step_impute_mean(starts_with("unit_")) %>% 
  prep() %>% bake(new_data = NULL) %>% 
  mutate(across(starts_with("unit_"), ~ round(.x, 1)))
# 確認
df_result %>% skimr::skim()

# sample.2
avg_price = mean(df_product$unit_price, na.rm = TRUE) %>% round()
avg_cost = mean(df_product$unit_cost, na.rm = TRUE) %>% round()
df_result2 = df_product %>% 
    replace_na(list(unit_price = avg_price, unit_cost = avg_cost))
# 確認
df_result2 %>% skimr::skim()

# avg_price, avg_cost の計算結果が正しいことも確認できる.

df_result2
rm(avg_price, avg_cost)

#................................................

df_stats = df_product %>% 
  mutate(
    unit_price = mean(unit_price, na.rm = T) %>% round(0L), 
    unit_cost = mean(unit_cost, na.rm = T) %>% round(0L)
  ) %>% 
  select(product_cd, starts_with("unit_"))

df_stats
df_result3 = df_product %>% rows_patch(df_stats)
df_result3 %>% skimr::skim()

# A tibble: 10,030 × 6
#    product_cd category_major_cd category_medium_cd category_small_cd unit_price unit_cost
#    <chr>      <chr>             <chr>              <chr>                  <dbl>     <dbl>
#  1 P040101001 04                0401               040101                   198       149
#  2 P040101002 04                0401               040101                   218       164
#  3 P040101003 04                0401               040101                   230       173
#  4 P040101004 04                0401               040101                   248       186
#  5 P040101005 04                0401               040101                   268       201
#  6 P040101006 04                0401               040101                   298       224
#  ...

#...............................................................................
# rows_patch
db_stats = db_product %>% 
  mutate(
    unit_price = mean(unit_price, na.rm = T) %>% round(0L), 
    unit_cost = mean(unit_cost, na.rm = T) %>% round(0L)
  ) %>% 
  select(product_cd, starts_with("unit_"))

db_result = db_product %>% rows_patch(db_stats, unmatched = "ignore")
db_result %>% collect()
db_result %>% skimr::skim()

#................................................

db_result = db_product %>% 
  mutate(
    avg_price = mean(unit_price) %>% round(0L), 
    avg_cost = mean(unit_cost) %>% round(0L)
  ) %>% 
  mutate(
    unit_price = coalesce(unit_price, avg_price), 
    unit_cost = coalesce(unit_cost, avg_cost)
  ) %>% 
  select(-starts_with("avg"))
  # select(starts_with("unit"), starts_with("avg"))

# 確認
db_result %>% skimr::skim()

#...............................................................................

db_result %>% show_query()

q = sql("
WITH q01 AS (
  SELECT
    product.*,
    ROUND_EVEN(AVG(unit_price) OVER (), CAST(ROUND(0, 0) AS INTEGER)) AS avg_price,
    ROUND_EVEN(AVG(unit_cost) OVER (), CAST(ROUND(0, 0) AS INTEGER)) AS avg_cost
  FROM product
)
SELECT
  product_cd,
  category_major_cd,
  category_medium_cd,
  category_small_cd,
  COALESCE(unit_price, avg_price) AS unit_price,
  COALESCE(unit_cost, avg_cost) AS unit_cost
FROM q01
-- チェック用
-- where unit_price IS NULL
"
)
q %>% my_select(con)

# 確認
q %>% my_select(con) %>% skimr::skim()

# A tibble: 10,030 × 6
#    product_cd category_major_cd category_medium_cd category_small_cd unit_price unit_cost
#    <chr>      <chr>             <chr>              <chr>                  <dbl>     <dbl>
#  1 P040101001 04                0401               040101                   198       149
#  2 P040101002 04                0401               040101                   218       164
#  3 P040101003 04                0401               040101                   230       173
#  4 P040101004 04                0401               040101                   248       186
#  5 P040101005 04                0401               040101                   268       201
#  6 P040101006 04                0401               040101                   298       224
#  7 P040101007 04                0401               040101                   338       254
#  8 P040101008 04                0401               040101                   420       315
#  ...

#...............................................................................

## 各商品のカテゴリ小区分コード（category_small_cd）ごとに算出した平均値で補完する場合
q = sql("
with prod as (
  select
    product_cd, 
    category_small_cd, 
    unit_price, 
    unit_cost, 
    AVG(unit_price) OVER (partition by category_small_cd) as avg_price, 
    AVG(unit_cost) OVER (partition by category_small_cd) as avg_cost
  from
    product
)
select
  product_cd, 
  category_small_cd, 
  ROUND(COALESCE(unit_price, avg_price)) as unit_price, 
  ROUND(COALESCE(unit_cost, avg_cost)) as unit_cost, 
  avg_price, 
  avg_cost
from
  prod
-- チェック用
-- where unit_price IS NULL
"
)
q %>% my_select(con)

# A tibble: 10,030 × 6
#    product_cd category_small_cd unit_price unit_cost mean_price mean_cost
#    <chr>      <chr>                  <dbl>     <dbl>      <dbl>     <dbl>
#  1 P040101001 040101                   198       149     329.6     247.5 
#  2 P040101002 040101                   218       164     329.6     247.5 
#  3 P040101003 040101                   230       173     329.6     247.5 
#  4 P040101004 040101                   248       186     329.6     247.5 
#  5 P040101005 040101                   268       201     329.6     247.5 
#  ...

#-------------------------------------------------------------------------------
# R-083 ------------
# 単価（unit_price）と原価（unit_cost）の欠損値について、各商品のカテゴリ小区分コード（category_small_cd）
# ごとに算出した中央値で補完した新たな商品データを作成せよ。なお、中央値については1円未満を丸めること
# （四捨五入または偶数への丸めで良い）。補完実施後、各項目について欠損が生じていないことも確認すること。

df_result = df_product %>% 
  mutate(
    median_price = median(unit_price, na.rm = T) %>% round(0L), 
    median_cost = median(unit_cost, na.rm = T) %>% round(0L), 
    .by = category_small_cd
  ) %>% 
  mutate(
    unit_price = coalesce(unit_price, median_price), 
    unit_cost = coalesce(unit_cost, median_cost)
  ) %>% 
  select(-starts_with("median"))

df_result
# 確認
df_result %>% skimr::skim()

# A tibble: 10,030 × 8
#    category_small_cd median_price median_cost product_cd category_major_cd category_medium_cd unit_price unit_cost
#    <chr>                    <dbl>       <dbl> <chr>      <chr>             <chr>                   <dbl>     <dbl>
#  1 040101                     283         212 P040101001 04                0401                      198       149
#  2 040101                     283         212 P040101002 04                0401                      218       164
#  3 040101                     283         212 P040101003 04                0401                      230       173
#  4 040101                     283         212 P040101004 04                0401                      248       186
#  5 040101                     283         212 P040101005 04                0401                      268       201
#  6 040101                     283         212 P040101006 04                0401                      298       224
#  ...

#...............................................................................

db_result = db_product %>% 
    summarise(
      median_price = median(unit_price, na.rm = TRUE) %>% round(0L), 
      median_cost = median(unit_cost, na.rm = TRUE) %>% round(0L), 
      .by = "category_small_cd"
    ) %>% 
    inner_join(db_product, by = "category_small_cd") %>% 
    mutate(
      unit_price = coalesce(unit_price, median_price), 
      unit_cost = coalesce(unit_cost, median_cost)
    ) %>% 
    select(product_cd, everything(), -starts_with("median"))

db_result %>% collect()
# 確認
db_result %>% skimr::skim()

#...............................................................................

db_result %>% show_query(cte = TRUE)

q = sql("
WITH q01 AS (
  SELECT
    category_small_cd,
    ROUND_EVEN(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY unit_price), CAST(ROUND(0, 0) AS INTEGER)) AS median_price,
    ROUND_EVEN(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY unit_cost), CAST(ROUND(0, 0) AS INTEGER)) AS median_cost
  FROM product
  GROUP BY category_small_cd
),
q02 AS (
  SELECT
    LHS.*,
    product_cd,
    category_major_cd,
    category_medium_cd,
    unit_price,
    unit_cost
  FROM q01 LHS
  INNER JOIN product
    ON (LHS.category_small_cd = product.category_small_cd)
)
SELECT
  product_cd,
  category_small_cd,
  category_major_cd,
  category_medium_cd,
  COALESCE(unit_price, median_price) AS unit_price,
  COALESCE(unit_cost, median_cost) AS unit_cost
FROM q02 q01
"
)

q %>% my_select(con)
# 確認
q %>% my_select(con) %>% skimr::skim()

#-------------------------------------------------------------------------------
# R-084 ------------
# 顧客データ（customer）の全顧客に対して全期間の売上金額に占める2019年売上金額の割合を計算し、
# 新たなデータを作成せよ。
# ただし、売上実績がない場合は0として扱うこと。そして計算した割合が0超のものを抽出し、結果を10件表示せよ。
# また、作成したデータに欠損が存在しないことを確認せよ。

# df_receipt %>% select(customer_id) %>% anti_join(df_customer, by = "customer_id")

df_result = df_receipt %>% 
  select(customer_id, sales_ymd, amount) %>% 
  mutate(
    sales_year = sales_ymd %>% 
      as.character() %>% strptime("%Y%m%d") %>% lubridate::year()
  ) %>% 
  right_join(df_customer %>% select(customer_id), by = "customer_id") %>% 
  mutate(amount_2019 = ifelse(sales_year == 2019, amount, 0.0)) %>% 
  summarise(
    across(starts_with("amount"), 
    ~ sum(.x, na.rm = T), 
    .names = "sales_{.col}"), 
    .by = customer_id
  ) %>% 
  mutate(sales_rate = 
    ifelse(sales_amount == 0.0, 0.0, (sales_amount_2019 / sales_amount))
  ) %>% 
  filter(sales_rate > 0.0) %>% 
  arrange(customer_id)

df_result %>% head(10)
df_result %>% skimr::skim()

df_result %>% filter(is.na(sales_rate))
df_result

# A tibble: 10 × 4
#    customer_id    sales_amount sales_amount_2019 sales_rate
#    <chr>                 <dbl>             <dbl>      <dbl>
#  1 CS001113000004         1298              1298    1      
#  2 CS001114000005          626               188    0.30032
#  3 CS001115000010         3044               578    0.18988
#  4 CS001205000004         1988               702    0.35312
#  5 CS001205000006         3337               486    0.14564
#  6 CS001211000025          456               456    1      
#  7 CS001212000070          456               456    1      
#  8 CS001214000009         4685               664    0.14173
#  9 CS001214000017         4132              2962    0.71684
# 10 CS001214000048         2374              1889    0.79570

#...............................................................................
db_result = db_receipt %>% 
  select(customer_id, sales_ymd, amount) %>% 
  mutate(
    sales_year = sales_ymd %>% 
      as.character() %>% strptime("%Y%m%d") %>% lubridate::year()
  ) %>% 
  right_join(db_customer %>% select(customer_id), by = "customer_id") %>% 
  mutate(amount_2019 = ifelse(sales_year == 2019, amount, 0.0)) %>% 
  summarise(
    across(starts_with("amount"), 
    ~ sum(.x, na.rm = T), 
    .names = "sales_{.col}"), 
    .by = customer_id
  ) %>% 
  mutate(sales_rate = 
    ifelse(sales_amount == 0.0, 0.0, (sales_amount_2019 / sales_amount))
  ) %>% 
  filter(sales_rate > 0.0) %>% 
  arrange(customer_id)

db_result %>% collect()
db_result %>% skimr::skim()

db_result %>% filter(is.na(sales_rate))

#...............................................................................

db_result %>% show_query(cte = TRUE)

q = sql("
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
    CASE WHEN (sales_year = 2019.0) THEN amount WHEN NOT (sales_year = 2019.0) THEN 0.0 END AS amount_2019
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
    q01.*,
    CASE WHEN (sales_amount = 0.0) THEN 0.0 WHEN NOT (sales_amount = 0.0) THEN ((sales_amount_2019 / sales_amount)) END AS sales_rate
  FROM q04 q01
)
SELECT q01.*
FROM q05 q01
WHERE (sales_rate > 0.0)
ORDER BY customer_id
"
)
q %>% my_select(con)

q %>% my_select(con) %>% skimr::skim()

#...............................................................................
con %>% dbExecute("DROP TABLE IF EXISTS cust_sales_rate")

q = sql("
CREATE TABLE cust_sales_rate AS 
  with rec as (
    select 
      c.customer_id, 
      CAST(SUBSTR(r.sales_ymd, 1, 4) as integer) as year, 
      COALESCE(r.amount, 0) as amount
    from
      customer as c
    left join receipt as r
      USING(customer_id)
  ), 
  sales_amount as (
  select
    customer_id, 
    SUM(case when year = 2019 then amount else 0 end) as sales_amount_2019, 
    SUM(amount) as sales_amount_all
  from
    rec
  group by
    customer_id
  )
  select
    *, 
    case 
      when sales_amount_all = 0 then NULL
      else ROUND(sales_amount_2019 / sales_amount_all, 2) 
    end as sales_rate
  from
    sales_amount
"
)
con %>% dbExecute(q)
con %>% dbListTables()

q = sql("
select * from cust_sales_rate where sales_rate > 0.0 LIMIT 10
"
)
q %>% my_select(con)
#    customer_id    sales_amount_2019 sales_amount_all sales_rate
#    <chr>                      <dbl>            <dbl>      <dbl>
#  1 CS001113000004              1298             1298       1   
#  2 CS001114000005               188              626       0.3 
#  3 CS001115000010               578             3044       0.19
#  4 CS001205000004               702             1988       0.35
#  5 CS001205000006               486             3337       0.15
# ...

# インデックスを追加
q = sql("
CREATE UNIQUE INDEX idx_customer_id ON cust_sales_rate (customer_id)
"
)
con %>% dbExecute(q)
con %>% dbGetQuery("PRAGMA index_list(cust_sales_rate)")
#   seq            name unique origin partial
# 1   0 idx_customer_id      1      c       0

#-------------------------------------------------------------------------------
# R-087 ------------
# 顧客データ（customer）では、異なる店舗での申込みなどにより同一顧客が複数登録されている。
# 名前（customer_name）と郵便番号（postal_cd）が同じ顧客は同一顧客とみなして1顧客1レコードとなるように
# 名寄せした名寄顧客データを作成し、顧客データの件数、名寄顧客データの件数、重複数を算出せよ。
# ただし、同一顧客に対しては売上金額合計が最も高いものを残し、売上金額合計が同一もしくは売上実績がない顧客
# については顧客ID（customer_id）の番号が小さいものを残すこととする。

# R-088 も合わせての解答
# 重複のある顧客について確認できるようにする

df_amount = df_receipt %>% 
  summarise(
    sum_amount = sum(amount), 
    .by = customer_id
  )

vars = c("customer_name", "postal_cd")

df_cust = df_customer %>% 
  left_join(df_amount, by = "customer_id") %>% 
  mutate(sum_amount = coalesce(sum_amount, 0.0)) %>% 
  group_by(across(!!vars)) %>% 
  # mutate(
  #   rank = row_number(tibble(desc(sum_amount), customer_id)), 
  #   n = n()
  # ) %>% 
  arrange(desc(sum_amount), customer_id) %>% 
  mutate(
    rank = row_number(), 
    n = n()
  ) %>% 
  mutate(
    integration_id = max(ifelse(rank == 1L, customer_id, "")), 
    .before = 1
  ) %>% 
  ungroup()
  # arrange(across(!!vars), rank)

df_cust %>% glimpse()
df_cust %>% collect()

# for check
df_cust %>% 
  select(integration_id, customer_id, !!vars, sum_amount, rank, n) %>% 
  filter(n > 1) %>% 
  arrange(across(!!vars), rank) %>% 
  collect() %>% 
  head(20)

# 名寄顧客データ
df_customer_u = df_cust %>% 
  filter(rank == 1) %>% 
  select(-c(sum_amount, rank, n))

# 名寄顧客データ
df_customer_u = df_cust %>% 
  filter(rank == 1L) %>% 
  select(-c(integration_id, sum_amount, rank, n))

df_customer_u %>% glimpse()

# 顧客データに統合名寄IDを付与したデータを作成する (R-088)
df_customer_n = df_customer %>% 
  inner_join(
    df_cust %>% select(integration_id, customer_id), 
    by = "customer_id"
  ) %>% 
  relocate(integration_id, .before = 1)

df_customer_n %>% glimpse()
df_customer_n %>% collect()

# 顧客データの件数、名寄顧客データの件数、重複数
df_customer_n %>% 
  summarise(
    n_all = n(), 
    n_unique = n_distinct(integration_id)
  ) %>% 
  mutate(diff = n_all - n_unique)

#   n_all n_unique  diff
#   <int>    <int> <int>
# 1 21971    21941    30

tibble::tribble(
  ~name, ~count, 
  "顧客データの件数", nrow(df_customer), 
  "名寄顧客データの件数", nrow(df_customer_u), 
  "重複数", nrow(df_customer) - nrow(df_customer_u)
)

#   name                 count
#   <chr>                <int>
# 1 顧客データの件数     21971
# 2 名寄顧客データの件数 21941
# 3 重複数                  30

n.all = nrow(df_customer)
n.u = nrow(df_customer_u)
"顧客データの件数: %s\n名寄顧客データの件数: %s\n重複数: %s" %>% 
  sprintf(n.all, n.u, n.all - n.u) %>% cat()
# 顧客データの件数: 21971
# 名寄顧客データの件数: 21941
# 重複数: 30

#................................................
# row_number(tibble(desc(sum_amount), customer_id)) は時間がかかる
d = df_customer %>% 
  select(customer_id, customer_name, postal_cd) %>% 
  left_join(df_amount, by = "customer_id") %>% 
  mutate(sum_amount = coalesce(sum_amount, 0.0)) %>% 
  mutate(
    row = row_number(tibble(desc(sum_amount), customer_id)), 
    .by = c(customer_name, postal_cd)
  )

d %>% filter(row > 1)

#...............................................................................
# dbplyr
db_amount = db_receipt %>% 
  summarise(
    sum_amount = sum(amount), 
    .by = customer_id
  )

vars = c("customer_name", "postal_cd")
db_cust = db_customer %>% 
  left_join(db_amount, by = "customer_id") %>% 
  mutate(sum_amount = coalesce(sum_amount, 0.0)) %>% 
  group_by(across(!!vars)) %>% 
  mutate(
    rank = row_number(tibble(desc(sum_amount), customer_id)), 
    n = n()
  ) %>% 
  mutate(
    integration_id = max(ifelse(rank == 1L, customer_id, "")), 
    .before = 1
  ) %>% 
  ungroup()
  # arrange(across(!!vars), rank)

db_cust %>% glimpse()
db_cust %>% collect()

# for check
db_cust %>% 
  select(integration_id, customer_id, !!vars, sum_amount, rank, n) %>% 
  filter(n > 1) %>% 
  arrange(across(!!vars), rank) %>% 
  collect() %>% 
  head(20)

#    integration_id customer_id    customer_name postal_cd sum_amount  rank     n
#    <chr>          <chr>          <chr>         <chr>          <dbl> <dbl> <dbl>
#  1 CS001515000422 CS001515000422 久野 みゆき   144-0052        1173     1     2
#  2 CS001515000422 CS016712000025 久野 みゆき   144-0052           0     2     2
#  3 CS038214000037 CS038214000037 今 充則       246-0001           0     1     2
#  4 CS038214000037 CS040601000007 今 充則       246-0001           0     2     2
#  5 CS001515000561 CS001515000561 伴 芽以       144-0051        2283     1     2
#  6 CS001515000561 CS004712000149 伴 芽以       144-0051           0     2     2
#  7 CS002215000052 CS002215000052 前田 美紀     185-0022        1002     1     2
#  8 CS002215000052 CS002615000172 前田 美紀     185-0022           0     2     2
#  9 CS017414000126 CS017414000126 原 優         166-0003        1497     1     2
# 10 CS017414000126 CS018413000015 原 優         166-0003           0     2     2
# 11 CS001412000304 CS001412000304 多部 あさみ   222-0032           0     1     2
# 12 CS001412000304 CS010413000041 多部 あさみ   222-0032           0     2     2
# 13 CS004315000058 CS004315000058 宇多田 文世   165-0027         490     1     2
# 14 CS004315000058 CS023403000036 宇多田 文世   165-0027           0     2     2
# 15 CS007315000087 CS007315000087 宇野 真悠子   285-0855           0     1     2
# 16 CS007315000087 CS007715000041 宇野 真悠子   285-0855           0     2     2
# 17 CS020515000002 CS020515000002 宮下 陽子     115-0053        4905     1     2
# 18 CS020515000002 CS003502000148 宮下 陽子     115-0053           0     2     2
# 19 CS028414000005 CS028414000005 小市 礼子     185-0013        8323     1     2
# 20 CS028414000005 CS002815000025 小市 礼子     185-0013        1158     2     2

# 名寄顧客データ
db_customer_u = db_cust %>% 
  filter(rank == 1L) %>% 
  select(-c(integration_id, sum_amount, rank, n))

db_customer_u %>% glimpse()
db_customer_u %>% collect()

#................................................
# 顧客データに統合名寄IDを付与したデータを作成する (R-088)
db_customer_n = db_customer %>% 
  inner_join(
    db_cust %>% select(integration_id, customer_id), 
    by = "customer_id"
  ) %>% 
  relocate(integration_id, .before = 1)

db_customer_n %>% glimpse()
db_customer_n %>% collect()

# 顧客データの件数、名寄顧客データの件数、重複数
db_customer_n %>% 
  summarise(
    n_all = n(), 
    n_unique = n_distinct(integration_id)
  ) %>% 
  mutate(diff = n_all - n_unique)

#   n_all n_unique  diff
#   <dbl>    <dbl> <dbl>
# 1 21971    21941    30

#...............................................................................

db_customer_n %>% show_query(cte = TRUE)

q = sql("
WITH sales_amount AS (
  SELECT 
    customer_id, 
    SUM(amount) AS sum_amount
  FROM receipt
  GROUP BY customer_id
),
cust_sales_amount AS (
  SELECT 
    customer.*, 
    COALESCE(sum_amount, 0.0) AS sum_amount
  FROM customer
  LEFT JOIN sales_amount 
  USING (customer_id)
),
cust_sales_rank AS (
  SELECT
    *, 
    ROW_NUMBER() OVER (
      PARTITION BY customer_name, postal_cd 
      ORDER BY sum_amount DESC, customer_id
    ) AS rank
  FROM 
    cust_sales_amount
),
integration AS (
  SELECT
    MAX(
      CASE WHEN (rank = 1) THEN customer_id ELSE '' END
    ) OVER (
      PARTITION BY customer_name, postal_cd
    ) AS integration_id,
    customer_id
  FROM 
    cust_sales_rank
)
SELECT integration_id, customer.*
FROM customer
INNER JOIN integration
USING (customer_id)
"
)

q %>% my_select(con)
q %>% my_select(con) %>% glimpse()

# A tibble: 21,971 × 12
#    integration_id customer_id  customer_name gender_cd gender birth_day    age postal_cd
#    <chr>          <chr>        <chr>         <chr>     <chr>  <date>     <int> <chr>    
#  1 CS021313000114 CS021313000… 大野 あや子   1         女性   1981-04-29    37 259-1113 
#  2 CS037613000071 CS037613000… 六角 雅彦     9         不明   1952-04-01    66 136-0076 
#  3 CS031415000172 CS031415000… 宇多田 貴美子 1         女性   1976-10-04    42 151-0053 
#  4 CS028811000001 CS028811000… 堀井 かおり   1         女性   1933-03-27    86 245-0016 
#  5 CS001215000145 CS001215000… 田崎 美紀     1         女性   1995-03-29    24 144-0055 
#  6 CS020401000016 CS020401000… 宮下 達士     0         男性   1974-09-15    44 174-0065 
#  7 CS015414000103 CS015414000… 奥野 陽子     1         女性   1977-08-09    41 136-0073 
#  8 CS029403000008 CS029403000… 釈 人志       0         男性   1973-08-17    45 279-0003 
#  9 CS015804000004 CS015804000… 松谷 米蔵     0         男性   1931-05-02    87 136-0073 
# 10 CS033513000180 CS033513000… 安斎 遥       1         女性   1962-07-11    56 241-0823 

#-------------------------------------------------------------------------------
# R-088 ------------
# 087で作成したデータを元に、顧客データに統合名寄IDを付与したデータを作成せよ。
# ただし、統合名寄IDは以下の仕様で付与するものとする。
# - 重複していない顧客：顧客ID（customer_id）を設定
# - 重複している顧客：前設問で抽出したレコードの顧客IDを設定
# 顧客IDのユニーク件数と、統合名寄IDのユニーク件数の差も確認すること。

d.integ = d.customer.u %>% select(-c(sum_amount, n)) %>% 
  rename(integration_id = customer_id)
d.integ

d.customer.n = customer %>% 
  inner_join(d.integ, join_by(customer_name, postal_cd)) %>% 
  select(integration_id, everything())

d.customer.n %>% summarise(n_all = n(), n_i = n_distinct(integration_id)) %>% 
  mutate(diff = n_all - n_i)
#   n_all   n_i  diff
#   <int> <int> <int>
# 1 21971 21941    30

#...............................................................................
q = sql("
with cust_0 as (
  select 
    c.customer_id, 
    c.customer_name, 
    c.postal_cd, 
    SUM(IFNULL(r.amount, 0)) as amount_all
  from 
    customer as c
  left join 
    receipt as r USING(customer_id)
  group by
    c.customer_id
), 
cust as (
  select
    *, 
    ROW_NUMBER() OVER (
      partition by customer_name, postal_cd
      order by amount_all DESC, customer_id
    ) as row, 
  count(*) over (partition by customer_name, postal_cd) as n -- チェック用
  from
    cust_0
  -- チェック用
  -- order by customer_name, postal_cd
)
select 
  MAX(case when row = 1 then customer_id else NULL end) 
    OVER (partition by customer_name, postal_cd) as integration_id, 
  *
from 
  cust
where n > 1 -- チェック用
order by 
  customer_name, postal_cd, row
"
)
q %>% my_select(con)

#    integration_id customer_id    customer_name postal_cd amount_all   row     n
#    <chr>          <chr>          <chr>         <chr>          <dbl> <int> <int>
#  1 CS001515000422 CS001515000422 久野 みゆき   144-0052        1173     1     2
#  2 CS001515000422 CS016712000025 久野 みゆき   144-0052           0     2     2
#  3 CS038214000037 CS038214000037 今 充則       246-0001           0     1     2
#  4 CS038214000037 CS040601000007 今 充則       246-0001           0     2     2
#  5 CS001515000561 CS001515000561 伴 芽以       144-0051        2283     1     2
#  6 CS001515000561 CS004712000149 伴 芽以       144-0051           0     2     2
#  7 CS002215000052 CS002215000052 前田 美紀     185-0022        1002     1     2
#  8 CS002215000052 CS002615000172 前田 美紀     185-0022           0     2     2
#  9 CS017414000126 CS017414000126 原 優         166-0003        1497     1     2
# 10 CS017414000126 CS018413000015 原 優         166-0003           0     2     2
# ...

#-------------------------------------------------------------------------------
# R-089 ------------
# 売上実績がある顧客を、予測モデル構築のため学習用データとテスト用データに分割したい。
# それぞれ 8:2 の割合でランダムにデータを分割せよ。

df_sales_customer = df_receipt %>% 
  summarise(
    sum_amount = sum(amount), 
    .by = customer_id
  ) %>% 
  filter(sum_amount > 0.0) %>% 
  select(-sum_amount) %>% 
  inner_join(df_customer, by = "customer_id")

df_sales_customer

rsplit = df_sales_customer %>% 
  rsample::initial_split(prop = 0.8) %>% 
  withr::with_seed(14, .)

df_train = rsplit %>% training()
df_test = rsplit %>% testing()

df_train
# A tibble: 6,644 × 11
#    customer_id    customer_name gender_cd gender birth_day    age postal_cd address    
#    <chr>          <chr>         <chr>     <chr>  <date>     <int> <chr>     <chr>      
#  1 CS032415000205 細谷 真奈美   1         女性   1970-05-27    48 144-0056  東京都大田…
#  2 CS032513000167 大後 たまき   1         女性   1966-07-13    52 144-0054  東京都大田…
#  3 CS028415000226 小柳 まさみ   1         女性   1974-04-24    44 246-0021  神奈川県横…
#  4 CS029512000122 野口 季衣     1         女性   1964-07-12    54 279-0021  千葉県浦安…
#  5 CS010411000006 森口 めぐみ   1         女性   1973-12-26    45 223-0058  神奈川県横…
#  ...

df_test
#  A tibble: 1,662 × 11
#    customer_id    customer_name gender_cd gender birth_day    age postal_cd address    
#    <chr>          <chr>         <chr>     <chr>  <date>     <int> <chr>     <chr>      
#  1 CS008415000097 中田 光       1         女性   1971-05-21    47 182-0004  東京都調布…
#  2 CS028414000014 米倉 ヒカル   1         女性   1977-02-05    42 246-0023  神奈川県横…
#  3 CS003515000195 梅村 真奈美   1         女性   1963-05-31    55 182-0022  東京都調布…
#  4 CS027514000015 小宮 菜々美   1         女性   1960-08-20    58 251-0016  神奈川県藤…
#  5 CS025415000134 小杉 優       1         女性   1977-02-03    42 242-0024  神奈川県大…
#  ...

#...............................................................................
# ランダムな番号付けをする際、通常は
# percent_rank(runif(n = n()))
# を用いるが、再現性がない。
# そのため、
# 一意な識別子である customer_id を使い、SQL MD5関数(ハッシュ関数) でランダムな文字列を生成し、
# その辞書順によりランダムな番号付けをする

con %>% dbExecute("SELECT SETSEED(0.5);")

db_sales_customer = db_customer %>% 
  select(customer_id) %>% 
  inner_join(
    db_receipt %>% select(customer_id, amount), 
    by = "customer_id"
  ) %>% 
  summarise(
    sum_amount = sum(amount), 
    .by = customer_id
  ) %>% 
  filter(sum_amount > 0.0) %>% 
  mutate(rnum = row_number()) %>% 
  mutate(rand = runif(n = n())) %>% 
  mutate(prank = percent_rank(rand)) %>% 
  select(customer_id, prank)

db_sales_customer %>% collect() %>% arrange(customer_id)

# db_sales_customer %>% pull(prank) %>% sort() %>% diff()
# db_sales_customer %>% glimpse()
# db_sales_customer %>% collect()
# db_sales_customer %>% show_query(cte = TRUE)

# データベースに一時テーブルとして保存
db_sales_customer %>% 
  compute(name = "sales_customer", temporary = TRUE, overwrite = T)
# テーブルの確認
dbReadTable(con, "sales_customer") %>% glimpse()

# Rows: 8,306
# Columns: 2
# $ customer_id <chr> "CS011615000069", "CS027615000105", "CS033415000085", "CS003415000…
# $ prank       <dbl> 0.00000, 0.00012, 0.00024, 0.00036, 0.00048, 0.00060, 0.00072, 0.0…

# 保存したテーブルの参照を取得
db_sales_c = tbl(con, "sales_customer")

db_customer_train = db_sales_c %>% 
  filter(prank <= 0.8) %>% 
  select(-prank) %>% 
  inner_join(
    db_customer, 
    by = "customer_id"
  )

# db_customer_train
# db_customer_train %>% collect()
# db_customer_train %>% glimpse()
# db_customer_train %>% show_query(cte = TRUE)

# データベースに保存
db_customer_train %>% 
  compute(name = "customer_train", temporary = FALSE, overwrite = T)
# テーブルの確認
dbReadTable(con, "customer_train") %>% glimpse()
dbReadTable(con, "customer_train") %>% as_tibble()

# A tibble: 6,645 × 11
#    customer_id    customer_name gender_cd gender birth_day    age postal_cd address    
#    <chr>          <chr>         <chr>     <chr>  <date>     <int> <chr>     <chr>      
#  1 CS031415000172 宇多田 貴美子 1         女性   1976-10-04    42 151-0053  東京都渋谷…
#  2 CS001215000145 田崎 美紀     1         女性   1995-03-29    24 144-0055  東京都大田…
#  3 CS015414000103 奥野 陽子     1         女性   1977-08-09    41 136-0073  東京都江東…
#  4 CS033513000180 安斎 遥       1         女性   1962-07-11    56 241-0823  神奈川県横…
#  5 CS040412000191 川井 郁恵     1         女性   1977-01-05    42 226-0021  神奈川県横…
#  ...

# 保存したテーブルの参照を取得
db_train = tbl(con, "customer_train")

db_customer_test = db_sales_c %>% 
  select(-prank) %>% 
  inner_join(
    db_customer, 
    by = "customer_id"
  ) %>% 
  setdiff(db_train)

# db_customer_test
# db_customer_test %>% collect()
# db_customer_test %>% glimpse()
# db_customer_test %>% show_query(cte = TRUE)

# データベースに保存
db_customer_test %>% 
  compute(name = "customer_test", temporary = FALSE, overwrite = T)
# テーブルの確認
dbReadTable(con, "customer_test") %>% glimpse()

dbReadTable(con, "customer_test") %>% as_tibble() %>% head(10)

# A tibble: 10 × 11
#    customer_id    customer_name gender_cd gender birth_day    age postal_cd address    
#    <chr>          <chr>         <chr>     <chr>  <date>     <int> <chr>     <chr>      
#  1 CS001615000296 吉川 陽子     1         女性   1949-08-18    69 144-0045  東京都大田…
#  2 CS039415000286 長田 麗奈     1         女性   1971-12-27    47 167-0032  東京都杉並…
#  3 CS019412000131 福士 杏       1         女性   1971-12-24    47 174-0063  東京都板橋…
#  4 CS032411000013 長浜 恭子     1         女性   1970-06-15    48 212-0054  神奈川県川…
#  5 CS011511000005 石田 由樹     1         女性   1965-01-03    54 211-0002  神奈川県川…
#  ...

# データベースに保存されているテーブルのリストを確認
con %>% dbListTables()
# [1] "category"       "customer"       "customer_test"  "customer_train" "geocode"       
# [6] "product"        "receipt"        "sales_customer" "store"   

#> sales_customer, customer_train, customer_test が作成されている
# sales_customer は一時テーブルなので、Rセッションが切れると消去される

#...............................................................................
# SQLクエリ

# MD5(customer_id)
q = sql("
SELECT 
  customer_id, 
  PERCENT_RANK() OVER (ORDER BY MD5(customer_id)) AS prank
FROM 
  customer
INNER JOIN 
  receipt r
USING (customer_id)
GROUP BY 
  customer_id
HAVING 
  (SUM(r.amount) > 0.0)
"
)

q %>% my_select(con) %>% arrange(customer_id)
q %>% my_select(con) %>% glimpse()

#................................................

db_sales_customer %>% show_query(cte = TRUE)

q = sql("
SELECT SETSEED(0.5);
WITH q01 AS (
  SELECT customer_id
  FROM customer
  INNER JOIN receipt 
  USING (customer_id)
  GROUP BY customer_id
  HAVING SUM(amount) > 0.0
),
q02 AS (
  SELECT *, ROW_NUMBER() OVER () AS rnum
  FROM q01
),
q03 AS (
  SELECT *, RANDOM() AS rand
  FROM q02
)
SELECT
  customer_id, 
  PERCENT_RANK() OVER (ORDER BY rand) AS prank
FROM q03
"
)

q %>% my_select(con) %>% glimpse()
q %>% my_select(con) %>% arrange(customer_id)

# A tibble: 8,306 × 2
#    customer_id       prank
#    <chr>             <dbl>
#  1 CS001113000004 0.23998 
#  2 CS001114000005 0.43636 
#  3 CS001115000010 0.76123 
#  4 CS001205000004 0.54871 
#  5 CS001205000006 0.96677 
#  6 CS001211000025 0.15521 
#  7 CS001212000027 0.054425
#  8 CS001212000031 0.20554 
#  ...

#................................................

db_customer_train %>% show_query()

q = sql("
SELECT
  c.*
FROM
  sales_customer s
INNER JOIN 
  customer c
USING (customer_id)
WHERE 
  s.prank <= 0.8
"
)

q %>% my_select(con) %>% glimpse()

#................................................

db_customer_test %>% show_query()

q = sql("
SELECT
  c.*
FROM 
  sales_customer
INNER JOIN 
  customer c
USING (customer_id)
EXCEPT
  SELECT * FROM customer_train
"
)

q %>% my_select(con) %>% glimpse()

#...............................................................................
# テーブル作成

# PERCENT_RANK() OVER (ORDER BY MD5(customer_id))

con %>% dbExecute("DROP TABLE IF EXISTS sales_customer")

q = sql("
CREATE TEMP TABLE sales_customer AS 
SELECT 
  customer_id, 
  PERCENT_RANK() OVER (ORDER BY MD5(customer_id)) AS prank
FROM 
  customer
INNER JOIN 
  receipt r
USING (customer_id)
GROUP BY 
  customer_id
HAVING 
  (SUM(r.amount) > 0.0)
"
)

con %>% dbExecute(q)
con %>% dbReadTable("sales_customer") %>% as_tibble() %>% arrange(customer_id)

#................................................

# PERCENT_RANK() OVER (ORDER BY rand)

con %>% dbExecute("DROP TABLE IF EXISTS sales_customer")

con %>% dbExecute("SELECT SETSEED(0.5);")

q = sql("
CREATE TEMP TABLE sales_customer AS 
WITH q01 AS (
  SELECT customer_id
  FROM customer
  INNER JOIN receipt 
  USING (customer_id)
  GROUP BY customer_id
  HAVING SUM(amount) > 0.0
),
q02 AS (
  SELECT *, ROW_NUMBER() OVER () AS rnum
  FROM q01
),
q03 AS (
  SELECT *, RANDOM() AS rand
  FROM q02
)
SELECT
  customer_id, 
  PERCENT_RANK() OVER (ORDER BY rand) AS prank
FROM q03
"
)

con %>% dbExecute(q)

con %>% dbReadTable("sales_customer") %>% as_tibble() %>% arrange(customer_id)

# A tibble: 8,306 × 2
#    customer_id       prank
#    <chr>             <dbl>
#  1 CS001113000004 0.23998 
#  2 CS001114000005 0.43636 
#  3 CS001115000010 0.76123 
#  4 CS001205000004 0.54871 
#  5 CS001205000006 0.96677 
#  ...

#...............................................................................

con %>% dbExecute("DROP TABLE IF EXISTS customer_train")

q = sql("
CREATE TABLE customer_train AS
SELECT
  c.*
FROM
  sales_customer s
INNER JOIN 
  customer c
USING (customer_id)
WHERE 
  s.prank <= 0.8
"
)
con %>% dbExecute(q)

con %>% dbReadTable("customer_train") %>% as_tibble() %>% arrange(customer_id)

#................................................

con %>% dbExecute("DROP TABLE IF EXISTS customer_test")

q = sql("
CREATE TABLE customer_test AS
SELECT
  c.*
FROM 
  sales_customer
INNER JOIN 
  customer c
USING (customer_id)
EXCEPT
  SELECT * FROM customer_train
"
)
con %>% dbExecute(q)

con %>% dbReadTable("customer_test") %>% as_tibble() %>% arrange(customer_id)

# データベースに保存されているテーブルのリストを確認
con %>% dbListTables()
# [1] "category"       "customer"       "customer_test"  "customer_train" "geocode"       
# [6] "product"        "receipt"        "sales_customer" "store"   

#> sales_customer は一時テーブルなので、Rセッションが切れると消去される

# テーブルの内容を確認

con %>% dbReadTable("customer_train") %>% as_tibble() %>% arrange(customer_id)

# A tibble: 6,645 × 11
#    customer_id    customer_name gender_cd gender birth_day    age postal_cd address    
#    <chr>          <chr>         <chr>     <chr>  <date>     <int> <chr>     <chr>      
#  1 CS001113000004 葛西 莉央     1         女性   2003-02-22    16 144-0056  東京都大田…
#  2 CS001114000005 安 里穂       1         女性   2004-11-22    14 144-0056  東京都大田…
#  3 CS001115000010 藤沢 涼       1         女性   2006-05-16    12 144-0056  東京都大田…
#  4 CS001205000004 奥山 秀隆     0         男性   1993-02-28    26 144-0056  東京都大田…
#  5 CS001205000006 福士 明       0         男性   1993-06-12    25 144-0056  東京都大田…
#  6 CS001211000025 河野 夏希     1         女性   1996-06-09    22 140-0013  東京都品川…
#  7 CS001212000031 平塚 恵望子   1         女性   1990-07-26    28 210-0007  神奈川県川…
#  8 CS001212000046 伊東 愛       1         女性   1994-09-08    24 210-0014  神奈川県川…
#  ...

con %>% dbReadTable("customer_test") %>% as_tibble() %>% arrange(customer_id)

# A tibble: 1,661 × 11
#    customer_id    customer_name gender_cd gender birth_day    age postal_cd address    
#    <chr>          <chr>         <chr>     <chr>  <date>     <int> <chr>     <chr>      
#  1 CS001205000006 福士 明       0         男性   1993-06-12    25 144-0056  東京都大田…
#  2 CS001212000046 伊東 愛       1         女性   1994-09-08    24 210-0014  神奈川県川…
#  3 CS001215000080 池谷 菜摘     1         女性   1994-04-28    24 144-0055  東京都大田…
#  4 CS001305000016 梅本 真一     0         男性   1982-02-18    37 144-0046  東京都大田…
#  5 CS001311000059 浜口 菜々美   1         女性   1985-04-22    33 212-0004  神奈川県川…
#  6 CS001314000051 生瀬 杏       1         女性   1978-12-23    40 144-0055  東京都大田…
#  7 CS001411000054 筒井 花       1         女性   1973-06-19    45 210-0007  神奈川県川…
#  8 CS001412000026 美木 彩華     1         女性   1973-01-04    46 212-0058  神奈川県川…
#  ...

#-------------------------------------------------------------------------------
# R-090 ------------
# レシート明細データ（receipt）は2017年1月1日〜2019年10月31日までのデータを有している。
# 売上金額（amount）を月次で集計し、学習用に12ヶ月、テスト用に6ヶ月の時系列モデル構築用データを3セット作成せよ。

d = receipt %>% mutate(ym = my.date_format(sales_ymd, fmt2 = "%Y-%m")) %>% 
  summarise(sum_amount = sum(amount), .by = ym) %>% 
  arrange(ym)

# index: 1-18, 9-25, 16-34
obj.ro = d %>% rsample::rolling_origin(
    initial = 12, assess = 6, cumulative = F, skip = 7
  )

obj.ro
obj.ro %>% get_rsplit(1) %>% training()
obj.ro %>% get_rsplit(1) %>% assessment()
obj.ro %>% get_rsplit(2) %>% training()
obj.ro %>% get_rsplit(2) %>% assessment()
obj.ro %>% get_rsplit(3) %>% training()
obj.ro %>% get_rsplit(3) %>% assessment()

#...............................................................................
# SQL向きではないため、やや強引に記載する（分割数が多くなる場合はSQLが長くなるため現実的ではない）
# 学習データ(0)とテストデータ(1)を区別するフラグを付与する

# 下準備として年月ごとに売上金額を集計し、連番を付与

con %>% dbExecute("DROP TABLE IF EXISTS ts_amount")

q = sql("
CREATE TEMP TABLE ts_amount AS
select
  SUBSTR(sales_ymd, 1, 6) as sales_ym, 
  SUM(amount) as sum_amount, 
  ROW_NUMBER() OVER (order by SUBSTR(sales_ymd, 1, 6)) as row
from
  receipt
group by 
  sales_ym
"
)
con %>% dbExecute(q)

con %>% dbReadTable("ts_amount") %>% as_tibble()

# A tibble: 34 × 3
#    sales_ym sum_amount    row
#    <chr>         <dbl> <int>
#  1 201701       902056     1
#  2 201702       764413     2
#  3 201703       962945     3
#  4 201704       847566     4
# ...
# 33 201909      1105696    33
# 34 201910      1143062    34

q = sql("
with lag_amount as (
select
  sales_ym, 
  sum_amount, 
  row, 
  LAG(row, 12) OVER (order by row) as rn
from
  ts_amount
)
select 
  *, 
  case 
    when rn <= 12 then 0 else 1
  end as test_flg
from
  lag_amount
where
  rn between 1 and 18
"
)
q %>% my_select(con)

# A tibble: 18 × 5
#    sales_ym sum_amount   row    rn test_flg
#    <chr>         <dbl> <int> <int>    <int>
#  1 201801       944509    13     1        0
#  2 201802       864128    14     2        0
#  3 201803       946588    15     3        0
#  4 201804       937099    16     4        0
#  5 201805      1004438    17     5        0
#  6 201806      1012329    18     6        0
#  7 201807      1058472    19     7        0
#  8 201808      1045793    20     8        0
#  9 201809       977114    21     9        0
# 10 201810      1069939    22    10        0
# 11 201811       967479    23    11        0
# 12 201812      1016425    24    12        0
# 13 201901      1064085    25    13        1
# 14 201902       959538    26    14        1
# 15 201903      1093753    27    15        1
# 16 201904      1044210    28    16        1
# 17 201905      1111985    29    17        1
# 18 201906      1089063    30    18        1

#-------------------------------------------------------------------------------
# R-091 ------------
# 顧客データ（customer）の各顧客に対し、売上実績がある顧客数と売上実績がない顧客数が 1:1 と
# なるようにアンダーサンプリングで抽出せよ。

d = customer %>% mutate(
    sales_flg = ifelse(customer_id %in% unique(receipt$customer_id), T, F) %>% as.factor()
  )

d %>% glimpse()
library(recipes); library(themis)

d.cust = d %>% recipe() %>% 
  themis::step_downsample(sales_flg, under_ratio = 1.0, seed = 14) %>% 
  prep() %>% bake(new_data = NULL)

d.cust
d.cust %>% count(sales_flg)

#...............................................................................
d = customer %>% mutate(
    sales_flg = ifelse(customer_id %in% unique(receipt$customer_id), T, F)
  )

d.t = d %>% filter(sales_flg)
d.f = d %>% filter(!sales_flg)
n.t = d.t %>% nrow()
n.f = d.f %>% nrow()
if (n.t > n.f) {
  d.cust = d.t %>% slice_sample(n = n.f) %>% my_with_seed(14) %>% bind_rows(d.f)
} else {
  d.cust = d.f %>% slice_sample(n = n.t) %>% my_with_seed(14) %>% bind_rows(d.t)
}

d.cust %>% count(sales_flg)

#...............................................................................
con %>% dbExecute("DROP TABLE IF EXISTS down_sampling")

# SET SEED TO 0.25;

q = sql("
CREATE TABLE down_sampling AS
with pre_table_1 as (
  select 
    c.customer_id, 
    IFNULL(SUM(r.amount), 0) as sum_amount
  from
    customer as c
  left join receipt as r USING (customer_id)
  group by
    c.customer_id
), 
pre_table_2 as (
  select
    *, 
    case when sum_amount > 0 then 1 else 0 end as is_buy_flag, 
    case when sum_amount > 0 then 0 else 1 end as is_not_buy_flag
  from
    pre_table_1
), 
pre_table_3 as (
  select
    *, 
    row_number() over (partition by is_buy_flag order by random()) as row, 
    SUM(is_buy_flag) over () as n_buy, 
    SUM(is_not_buy_flag) over () as n_not_buy
  from 
    pre_table_2
)
select 
  *
from
  pre_table_3
where 
  row <= n_buy 
  and row <= n_not_buy
"
)
con %>% dbExecute(q)
con %>% dbReadTable("down_sampling") %>% as_tibble()

# A tibble: 16,612 × 7
#    customer_id    sum_amount is_buy_flag is_not_buy_flag   row n_buy n_not_buy
#    <chr>               <dbl>       <int>           <int> <int> <int>     <int>
#  1 CS018602000024          0           0               1     1  8306     13665
#  2 CS001713000232          0           0               1     2  8306     13665
#  3 CS003502000060          0           0               1     3  8306     13665
#  4 CS027712000043          0           0               1     4  8306     13665
#  5 CS007212000006          0           0               1     5  8306     13665
#  6 CS010303000005          0           0               1     6  8306     13665
#  ...

q = sql("
select is_buy_flag, count(*) as n from down_sampling group by is_buy_flag"
)
q %>% my_select(con)
#   is_buy_flag     n
#         <int> <int>
# 1           0  8306
# 2           1  8306

#-------------------------------------------------------------------------------

con %>% dbExecute("DROP TABLE IF EXISTS customer_std")

q = sql("
CREATE TABLE customer_std AS
  SELECT
    customer_id,
    customer_name,
    gender_cd,
    birth_day,
    age,
    postal_cd,
    application_store_cd,
    application_date,
    status_cd
  FROM
    customer
"
)
con %>% dbExecute(q)
con %>% dbReadTable("customer_std") %>% glimpse()

con %>% dbExecute("DROP TABLE IF EXISTS gender_std")
q = sql("
CREATE TABLE gender_std as
  select 
    distinct gender_cd, gender
  from
    customer
"
)
con %>% dbExecute(q)
con %>% dbReadTable("gender_std") %>% as_tibble()
#   gender_cd gender
#       <int> <chr> 
# 1         1 女性  
# 2         9 不明  
# 3         0 男性  

# ユニークインデックスを追加する
q = sql("
CREATE UNIQUE INDEX idx_customer_id ON customer_std (customer_id)
"
)
con %>% dbExecute(q)

"PRAGMA index_list(customer_std)" %>% dbGetQuery(con, .)
#   seq            name unique origin partial
# 1   0 idx_customer_id      1      c       0

q = sql("
CREATE UNIQUE INDEX idx_gender_cd ON gender_std (gender_cd)
"
)
con %>% dbExecute(q)

"PRAGMA index_list(gender_std)" %>% dbGetQuery(con, .)
#   seq          name unique origin partial
# 1   0 idx_gender_cd      1      c       0

#-------------------------------------------------------------------------------
