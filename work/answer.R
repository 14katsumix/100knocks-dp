#-------------------------------------------------------------------------------
# テーブル参照の標準出力のカスタマイズ
# Database: DuckDB v1.1.3-dev165 [root@Darwin 24.1.0:R 4.4.2//Users/.../work/DB/100knocks.duckdb]

# カスタムメソッドを定義
custom_db_get_info = function(dbObj, ...) {
  ll = attr(dbObj, "driver") |> dbGetInfo()
  s = ll$dbname
  dbname = paste0(
    stringr::str_sub(s, 1, 7), 
    "...", 
    stringr::str_sub(s, stringr::str_length(s) - 24)
  )
  list(
    # dbname = ll$dbname, 
    # dbname = stringr::str_trunc(ll$dbname, 28, "left"), 
    dbname = dbname, 
    db.version = ll$driver.version
  )
}

# dbGetInfo メソッドを duckdb_connection 用にオーバーライド
methods::setMethod("dbGetInfo", "duckdb_connection", custom_db_get_info)

DBI::dbGetInfo(con)
db_result
# Source:   SQL [10 x 4]
# Database: DuckDB v1.1.3-dev165 [root@Darwin 24.1.0:R 4.4.2//Users/.../work/DB/100knocks.duckdb]
#    sales_date customer_id    product_cd amount
#         <int> <chr>          <chr>       <dbl>
#  1   20181103 CS006214000001 P070305012    158

#-------------------------------------------------------------------------------
# R-003
# レシート明細データ（df_receipt）から売上年月日（sales_ymd）、顧客ID（customer_id）、
# 商品コード（product_cd）、売上金額（amount）の順に列を指定し、10件表示せよ。
# ただし、sales_ymdをsales_dateに項目名を変更しながら抽出すること。

df_receipt %>% 
  select(sales_date = sales_ymd, customer_id, product_cd, amount) %>% 
  head(10)

db_receipt %>% 
  select(sales_date = sales_ymd, customer_id, product_cd, amount) %>% 
  head(10) -> 
  db_result

db_result
# Source:   SQL [10 x 4]
# Database: DuckDB v1.1.3-dev165 [root@Darwin 24.1.0:R 4.4.2//Users/kk/ds/100knocks-dp/work/DB/100knocks.duckdb]
   sales_date customer_id    product_cd amount
        <int> <chr>          <chr>       <dbl>
 1   20181103 CS006214000001 P070305012    158
 2   20181118 CS008415000097 P070701017     81
 3   20170712 CS028414000014 P060101005    170
 4   20190205 ZZ000000000000 P050301001     25
 5   20180821 CS025415000050 P060102007     90
 6   20190605 CS003515000195 P050102002    138
 7   20181205 CS024514000042 P080101005     30
 8   20190922 CS040415000178 P070501004    128
 9   20170504 ZZ000000000000 P071302010    770
10   20191010 CS027514000015 P071101003    680

# class(db_result)
# [1] "tbl_duckdb_connection" "tbl_dbi"               "tbl_sql"              
# [4] "tbl_lazy"              "tbl"

db_result %>% my_show_query()

# SELECT sales_ymd AS sales_date, customer_id, product_cd, amount
# FROM receipt
# LIMIT 10

#-------------------------------------------------------------------------------
# R-029 ------------
# レシート明細データ（receipt）に対し、店舗コード（store_cd）ごとに商品コード（product_cd）の最頻値を求めよ.

# sample.1 ------------

# データフレーム
df_receipt %>% 
  count(store_cd, product_cd) %>% 
  filter(n == max(n), .by = store_cd) %>% 
  arrange(store_cd) %>% 
  head(10)

# 結果がたまたま store_cdで ソートされる場合もありますが、順序は保証されないため、
# 確実にソートしたい場合はarrange()を使うべきです。

# tbl
db_receipt %>% 
  count(store_cd, product_cd) %>% 
  filter(n == max(n), .by = store_cd) %>% 
  arrange(store_cd) %>% 
  head(10) -> 
  db_result

db_result
# Ordered by: store_cd
#    store_cd product_cd     n
#    <chr>    <chr>      <dbl>
#  1 S12007   P060303001    72
#  2 S12013   P060303001   107
#  3 S12014   P060303001    65
#  4 S12029   P060303001    92
#  5 S12030   P060303001   115
#  6 S13001   P060303001    67
#  7 S13002   P060303001    78
#  8 S13003   P071401001    65
#  9 S13004   P060303001    88
# 10 S13005   P040503001    36

# SQL
query %>% my_show_query()

WITH q01 AS (
  SELECT store_cd, product_cd, COUNT(*) AS n
  FROM receipt
  GROUP BY store_cd, product_cd
),
q02 AS (
  SELECT q01.*, MAX(n) OVER (PARTITION BY store_cd) AS col02
  FROM q01
)
SELECT store_cd, product_cd, n
FROM q02 q01
WHERE (n = col02)
ORDER BY store_cd
LIMIT 10

# col01, q01, q02 は dbplyrパッケージで自動生成されるエイリアス名.
# col01: 中間列名
# エイリアス名を直接指定する方法はありません。

# A tibble: 55 × 3
#    store_cd product_cd  mode
#    <chr>    <chr>      <int>
#  1 S12007   P060303001    72
#  2 S12013   P060303001   107
#  3 S12014   P060303001    65
#  4 S12029   P060303001    92
# ...

# sample.2 ------------

# データフレーム
df_receipt %>% 
  count(store_cd, product_cd) %>% 
  slice_max(n, n = 3, with_ties = T, by = store_cd) %>% 
  arrange(store_cd, n)

# tbl
tbl_receipt %>% 
  count(store_cd, product_cd) %>% 
  slice_max(n, n = 3, with_ties = T, by = store_cd) %>% 
  arrange(store_cd, n) %>% 
  my_collect()

# SQL
tbl_receipt %>% 
  count(store_cd, product_cd) %>% 
  slice_max(n, n = 3, with_ties = T, by = store_cd) %>% 
  arrange(store_cd, n) %>% 
  my_show_query()

# A tibble: 171 × 3
#    store_cd product_cd     n
#    <chr>    <chr>      <int>
#  1 S12007   P050102001    28
#  2 S12007   P050601001    25
#  3 S12007   P060303001    72
#  4 S12013   P060101001    40
#  5 S12013   P060303001   107
#  6 S12013   P071401001    63

q = sql("
with product_num as (
  select
    store_cd, 
    product_cd, 
    count(*) as n_product
  from 
    receipt
  group by 
    store_cd, product_cd
), 
product_rank as (
  select 
    *, 
    RANK() OVER (partition by store_cd order by n_product DESC) as rank
  from  
    product_num
  -- order by store_cd, rank
)
select 
  store_cd, 
  product_cd, 
  n_product as mode 
from 
  product_rank 
where 
  rank <= 3
order by 
  store_cd, n_product
"
)
q %>% my_select(con)

#-------------------------------------------------------------------------------
# R-035 ------------
# レシート明細データ（receipt）に対し、顧客ID（customer_id）ごとに売上金額（amount）を合計して
# 全顧客の平均を求め、平均以上に買い物をしている顧客を抽出し、10件表示せよ。
# ただし、顧客IDが"Z"から始まるものは非会員を表すため、除外して計算すること。

receipt %>% glimpse()

receipt %>% 
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
tbl_receipt %>% glimpse()

tbl_receipt %>% 
  filter(not(customer_id %like% "Z%")) %>% 
  summarise(sum_amount = sum(amount), .by = customer_id) %>% 
  # mutate(.mean = mean(sum_amount)) %>% 
  # filter(sum_amount >= .mean) %>% 
  filter(sum_amount >= mean(sum_amount)) %>% 
  arrange(desc(sum_amount)) %>% 
  my_collect(T)

#...............................................................................
q = sql("
with customer_amount as (
  select
    customer_id, 
    SUM(amount) as total_amount
  from receipt
  where customer_id NOT LIKE 'Z%'
  group by customer_id
)
select 
  *
from
  customer_amount
where 
  total_amount >= (select AVG(total_amount) from customer_amount)
order by
  total_amount DESC
"
)
q %>% my_select(con)

q = sql("
with customer_amount as (
  select
    customer_id, 
    SUM(amount) as total_amount
  from receipt
  where customer_id NOT LIKE 'Z%'
  group by customer_id
)
select
  *
from
  (
  select 
    *, 
    AVG(total_amount) OVER () as mean_amount
  from
    customer_amount
  )
where 
  total_amount >= mean_amount
order by
  total_amount DESC
"
)
q %>% my_select(con)

# A tibble: 2,996 × 3
#    customer_id    total_amount mean_amount
#    <chr>                 <dbl>       <dbl>
#  1 CS017415000097        23086      2547.7
#  2 CS015415000185        20153      2547.7
#  3 CS031414000051        19202      2547.7
# ...

#-------------------------------------------------------------------------------
# R-038 ------------
# 顧客データ（customer）とレシート明細データ（receipt）から、顧客ごとの売上金額合計を求め、10件表示せよ。
# ただし、売上実績がない顧客については売上金額を0として表示させること。
# また、顧客は性別コード（gender_cd）が女性（1）であるものを対象とし、非会員（顧客IDが"Z"から始まるもの）は除外すること。

customer %>% 
  left_join(receipt, by = "customer_id") %>% 
  filter(gender_cd == 1, !str_detect(customer_id, "^Z")) %>% 
  summarise(sum_aomunt = sum(amount, na.rm = T), .by = "customer_id") %>% 
  arrange(customer_id)

#...............................................................................
# dbplyr

tbl_customer %>% 
  left_join(tbl_receipt, by = "customer_id") %>% 
  filter(gender_cd == 1, not(customer_id %like% "^Z")) %>% 
  summarise(sum_aomunt = sum(amount, na.rm = T), .by = "customer_id") %>% 
  arrange(customer_id) %>% 
  my_collect()

#...............................................................................
q = sql("
with customer_amount as (
select 
  customer_id, 
  SUM(amount) as sum_amount
from
  receipt
group by 
  customer_id
)
select 
  cu.customer_id, 
  coalesce(cm.sum_amount, 0) as sum_amount
from 
  customer as cu
left join customer_amount as cm
  on cu.customer_id = cm.customer_id
where
  cu.gender_cd = '1' and cu.customer_id NOT LIKE 'Z%'
order by 
  cu.customer_id
  -- cm.sum_amount
"
)
q %>% my_select(con)
# A tibble: 17,918 × 2
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
# ...

#-------------------------------------------------------------------------------
# R-039 ------------
# レシート明細データ（receipt）から、売上日数の多い顧客の上位20件を抽出したデータと、
# 売上金額合計の多い顧客の上位20件を抽出したデータをそれぞれ作成し、さらにその2つを完全外部結合せよ。
# ただし、非会員（顧客IDが"Z"から始まるもの）は除外すること。

d.rec = receipt %>% filter(!str_detect(customer_id, "^Z")) %>% 
  select(customer_id, sales_ymd, amount)

# sample.1
d.date = d.rec %>% 
  summarise(n_date = n_distinct(sales_ymd), .by = customer_id) %>% 
  slice_max(n_date, n = 20, with_ties = F)

d.amount = d.rec %>% 
  summarise(sum_amount = sum(amount), .by = customer_id) %>% 
  slice_max(sum_amount, n = 20, with_ties = F)

d.date %>% full_join(d.amount, by = "customer_id") %>% arrange(desc(n_date), desc(sum_amount))

# sample.2
d.date = d.rec %>% 
  summarise(n_date = n_distinct(sales_ymd), .by = customer_id) %>% 
  arrange(desc(n_date), customer_id) %>% head(n = 20)

d.amount = d.rec %>% 
  summarise(sum_amount = sum(amount), .by = customer_id) %>% 
  arrange(desc(sum_amount), customer_id) %>% head(n = 20)

d.date %>% full_join(d.amount, by = "customer_id") %>% arrange(desc(n_date), desc(sum_amount))

#...............................................................................
# dbplyr
d.rec = tbl_receipt %>% filter(!str_detect(customer_id, "^Z")) %>% 
  select(customer_id, sales_ymd, amount)

d.rec = tbl_receipt %>% filter(not(customer_id %like% 'Z%')) %>% 
  select(customer_id, sales_ymd, amount)

# sample.1
d.date = d.rec %>% 
  summarise(n_date = n_distinct(sales_ymd), .by = customer_id) %>% 
  slice_max(n_date, n = 20, with_ties = F)

d.amount = d.rec %>% 
  summarise(sum_amount = sum(amount), .by = customer_id) %>% 
  slice_max(sum_amount, n = 20, with_ties = F)

d.date %>% full_join(d.amount, by = "customer_id") %>% 
  arrange(desc(n_date), desc(sum_amount)) %>% 
  my_collect()

#...............................................................................
q = sql("
with customer_data as (
  select
    customer_id, 
    sales_ymd, 
    amount
  from
    receipt
  where
    customer_id NOT LIKE 'Z%'
), 
customer_date_n as (
  select
    customer_id, 
    count(distinct sales_ymd) as n_date
  from
    customer_data
  group by 
    customer_id
  order by 
    n_date DESC
  LIMIT 20
), 
customer_amount as (
  select
    customer_id, 
    sum(amount) as sum_amount
  from
    customer_data
  group by 
    customer_id
  order by 
    sum_amount DESC
  LIMIT 20
)
select 
  COALESCE(d.customer_id, a.customer_id) as customer_id, 
  d.n_date, 
  a.sum_amount
from
  customer_date_n as d
FULL JOIN customer_amount as a
  ON d.customer_id = a.customer_id
-- order by customer_id
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

store$store_cd %>% crossing(product$product_cd) %>% nrow()

#...............................................................................
# dbplyr

tbl_store %>% cross_join(tbl_product) %>% select(store_cd, product_cd) %>% count()
tbl_store %>% cross_join(tbl_product) %>% select(store_cd, product_cd) %>% count() %>% 
  my_collect()

#...............................................................................
q = sql("
select 
  s.store_cd, p.product_cd
from store as s
CROSS JOIN product as p
"
)
q %>% my_select(con)

q = sql("
select 
  count(*)
from store
CROSS JOIN product
"
)
q %>% my_select(con)
#   `count(*)`
#        <int>
# 1     531590

#-------------------------------------------------------------------------------
# R-041 ------------
# レシート明細データ（receipt）の売上金額（amount）を日付（sales_ymd）ごとに集計し、
# 前回売上があった日からの売上金額増減を計算せよ。そして結果を10件表示せよ。

receipt %>% summarise(amount = sum(amount), .by = "sales_ymd") %>% 
  mutate(
    pre_sales_ymd = lag(sales_ymd, n = 1L, order_by = sales_ymd), 
    pre_amount = lag(amount, n = 1L, default = NA, order_by = sales_ymd)
  ) %>% 
  mutate(diff_amount = amount - pre_amount) %>% 
  arrange(sales_ymd)

#...............................................................................
# dbplyr
tbl_receipt %>% summarise(amount = sum(amount), .by = "sales_ymd") %>% 
  mutate(
    pre_sales_ymd = lag(sales_ymd, n = 1L, order_by = sales_ymd), 
    pre_amount = lag(amount, n = 1L, default = NA, order_by = sales_ymd)
  ) %>% 
  mutate(diff_amount = amount - pre_amount) %>% 
  arrange(sales_ymd) %>% 
  my_collect()

#...............................................................................
q = sql("
with ymd_amount as (
select 
  sales_ymd, 
  sum(amount) as sum_amount
from
  receipt
group by
  sales_ymd
-- order by
--   sales_ymd
), 
tmp as (
  select
    sales_ymd, 
    sum_amount, 
    LAG(sales_ymd, 1) OVER (order by sales_ymd) as pre_ymd, 
    LAG(sum_amount, 1) OVER (order by sales_ymd) as pre_amount
  from
    ymd_amount
--   order by
--     sales_ymd
)
select 
  *, 
  sum_amount - pre_amount as diff_amount
from 
  tmp
order by
  sales_ymd
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
d = receipt %>% summarise(amount = sum(amount), .by = "sales_ymd") %>% 
  mutate(
    lag_ymd = lag(sales_ymd, n = n_lag, order_by = sales_ymd), 
    pre_amount = lag(amount, n = n_lag, default = NA, order_by = sales_ymd)
  ) %>% 
  arrange(sales_ymd)

d %>% tbl_print(n = 12, n.tail = 5)

dx = d %>% select(sales_ymd, lag_ymd_x = lag_ymd, amount) %>% 
  mutate(lag_ymd_x = replace_na(lag_ymd_x, ""))

dy = d %>% select(lag_ymd = sales_ymd, lag_amount = amount)

dx %>% tbl_print(n = 12, n.tail = 5)
dy %>% tbl_print(n = 12, n.tail = 5)

.by = join_by(
    between(y$lag_ymd, x$lag_ymd_x, x$sales_ymd, bounds = "[)")
  )
dx %>% inner_join(dy, by = .by) %>% select(-lag_ymd_x) %>% 
  tbl_print(n = 12, n.tail = 8)

#...............................................................................
# dbplyr

# tbl_lazyにおけるlag関数の使用: 
# order_by オプションがデータベースバックエンドによって正しくサポートされていない場合があります。
# 特に、このコードはRDBMSでエラーになる可能性があります。
# 解決策: arrange(sales_ymd) を事前に適用してからlagを使うことで、安全性を高められます。

n_lag = 3L
d = tbl_receipt %>% summarise(amount = sum(amount), .by = "sales_ymd") %>% 
  mutate(
    lag_ymd = lag(sales_ymd, n = n_lag, order_by = sales_ymd)
  )

d %>% my_show_query()
d
# Database: sqlite 3.47.0 [...
#    sales_ymd amount lag_ymd 
#    <chr>      <dbl> <chr>   
#  1 20170101   33723 NA      
#  2 20170102   24165 NA      
#  3 20170103   27503 NA      
#  4 20170104   36165 20170101
# ...

# 別の記述
d = tbl_receipt %>% summarise(amount = sum(amount), .by = "sales_ymd") %>% 
  window_order(sales_ymd) %>% 
  mutate(
    # 共に 'order_by = sales_ymd' 無しでOK!
    lag_ymd = lag(sales_ymd, n = n_lag), 
    lag_amount = lag(amount, n = n_lag)
  )
d
# Database:   sqlite 3.47.0 [/Users/kk/Home/_work/Analysis/sample/All/R/app/DB/100knocks/100knocks.sqlite]
# Ordered by: sales_ymd   <<<<<<<<<<<<<<<<< ここが変わる
#    sales_ymd amount lag_ymd  lag_amount
#    <chr>      <dbl> <chr>         <dbl>
#  1 20170101   33723 NA               NA
#  2 20170102   24165 NA               NA
#  3 20170103   27503 NA               NA
#  4 20170104   36165 20170101      33723
#  ...

d %>% my_show_query()
d %>% my_collect(T)

dx = d %>% select(sales_ymd_x = sales_ymd, lag_ymd_x = lag_ymd, amount_x = amount) %>% 
  mutate(lag_ymd_x = coalesce(lag_ymd_x, ""))
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
  rename(sales_ymd = sales_ymd_x, amount = amount_x, lag_ymd = sales_ymd, lag_amount = amount)

d.res
d.res %>% my_show_query()
d.res %>% my_sql_render(con)
d.res %>% my_collect() %>% tbl_print(10, n.tail = 7)

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
#    sales_ymd amount
#    <chr>      <dbl>
#  1 20170101   33723
#  2 20170102   24165
#  3 20170103   27503
#  4 20170104   36165
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
  #  sales_ymd lag_ymd_3 amount
#    <chr>     <chr>      <dbl>
#  1 20170101  NA         33723
#  2 20170102  NA         24165
#  3 20170103  NA         27503
#  4 20170104  20170101   36165
#  5 20170105  20170102   37830
#  6 20170106  20170103   32387
#  7 20170107  20170104   23415
#  8 20170108  20170105   24737
#  9 20170109  20170106   26718
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
q %>% my_select(con) %>% tbl_print(n = 10, n.tail = 7)
# dim: 3,096 x 4
# A tibble: 10 × 4
#    sales_ymd amount lag_ymd  lag_amount
#    <chr>      <dbl> <chr>         <dbl>
#  1 20170102   24165 20170101      33723
#  2 20170103   27503 20170101      33723
#  3 20170103   27503 20170102      24165
#  4 20170104   36165 20170101      33723
#  5 20170104   36165 20170102      24165
#  6 20170104   36165 20170103      27503
#  7 20170105   37830 20170102      24165
#  8 20170105   37830 20170103      27503
#  9 20170105   37830 20170104      36165
# 10 20170106   32387 20170103      27503
# # A tibble: 7 × 4
#   sales_ymd amount lag_ymd  lag_amount
#   <chr>      <dbl> <chr>         <dbl>
# 1 20191029   36091 20191028      40161
# 2 20191030   26602 20191027      37484
# 3 20191030   26602 20191028      40161
# 4 20191030   26602 20191029      36091
# 5 20191031   25216 20191028      40161
# 6 20191031   25216 20191029      36091
# 7 20191031   25216 20191030      26602

#-------------------------------------------------------------------------------
# R-043 ------------
# レシート明細データ（receipt）と顧客データ（customer）を結合し、性別コード（gender_cd）と
# 年代（ageから計算）ごとに売上金額（amount）を合計した売上サマリデータを作成せよ。
# 性別コードは0が男性、1が女性、9が不明を表すものとする。
# ただし、項目構成は年代、女性の売上金額、男性の売上金額、性別不明の売上金額の4項目とすること
# （縦に年代、横に性別のクロス集計）。また、年代は10歳ごとの階級とすること。

max_age = customer$age %>% max(na.rm = T)

d = 
  receipt %>% inner_join(customer, by = "customer_id") %>% 
  mutate(age_range = 
    epikit::age_categories(
      age, 
      lower = 0, 
      # upper = round(max_age, -1) - ifelse(mod(max_age, 10) == 0, 0L, 1L), 
      upper = trunc(max_age / 10) * 10 + 10, 
      by = 10
    )) %>% 
  summarise(sum_amount = sum(amount), .by = c("gender_cd", "age_range")) %>% 
  # mutate(gender_cd = gender_cd %>% as.character(.) %>% lvls_revalue(c("男性", "女性", "不明")))
  mutate(across(gender_cd, ~ as.character(.x) %>% lvls_revalue(c("男性", "女性", "不明"))))

# d$gender_cd %>% as.character() %>% fct_recode(男性 = "0", 女性 = "1", 不明 = "9")
# d$gender_cd %<>% as.character() %>% lvls_revalue(c("男性", "女性", "不明"))

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
    ((c.age / 10) * 10) || '代' as age_range, 
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
  COALESCE(SUM(case when gender_cd = 0 then amount end), 0) as '男性', 
  COALESCE(SUM(case when gender_cd = 1 then amount end), 0) as '女性', 
  COALESCE(SUM(case when gender_cd = 9 then amount end), 0) as 'その他'
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

d = d.wide %>% pivot_longer(
    cols = !age_range, names_to = "gender_cd", values_to = "amount"
  ) %>% 
  mutate(across(gender_cd, ~ .x %>% lvls_revalue(c("00", "01", "99"))))

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
# R-056 ------------
# 顧客データ（customer）の年齢（age）をもとに10歳刻みで年代を算出し、
# 顧客ID（customer_id）、生年月日（birth_day）とともに10件表示せよ。
# ただし、60歳以上は全て60歳代とすること。年代を表すカテゴリ名は任意とする。

customer %>% mutate(age_rng = epikit::age_categories(age, lower = 0, upper = 60, by = 10)) %>% 
  select(customer_id, birth_day, age, age_rng)

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
# printf(): 頭に0をつけて文字列変換できる.

q = sql("
select
  customer_id, 
  birth_day, 
  -- LEAST((age / 10) * 10, 60) as era
  -- MIN((age / 10) * 10, 60) as era
  printf('%02d', MIN((age / 10) * 10, 60)) as era
from
  customer
where
  age IS NOT NULL
order by 
  -- customer_id
  era, customer_id
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

d.c = customer %>% 
  mutate(age_rng = epikit::age_categories(age, lower = 0, upper = 60, by = 10)) %>% 
  select(customer_id, birth_day, age, age_rng, gender_cd)

d = d.c %>% unite("gender_age", gender_cd, age_rng, sep = "_", remove = F) %>% 
  mutate(across(gender_age, ~ as.factor(.x))) %>% 
  arrange(customer_id)

d
# A tibble: 21,971 × 6
#    customer_id    birth_day    age gender_age age_rng gender_cd
#    <chr>          <chr>      <int> <fct>      <fct>       <int>
#  1 CS001105000001 2000-01-14    19 0_10-19    10-19           0
#  2 CS001112000009 2006-08-24    12 1_10-19    10-19           1
#  3 CS001112000019 2001-01-31    18 1_10-19    10-19           1
#  4 CS001112000021 2001-12-15    17 1_10-19    10-19           1
#  5 CS001112000023 2004-01-26    15 1_10-19    10-19           1
#  6 CS001112000024 2001-01-16    18 1_10-19    10-19           1
#  7 CS001112000029 2005-01-24    14 1_10-19    10-19           1
#  8 CS001112000030 2003-03-02    16 1_10-19    10-19           1
#  9 CS001113000004 2003-02-22    16 1_10-19    10-19           1
# 10 CS001113000010 2005-05-09    13 1_10-19    10-19           1
# 11 CS001114000005 2004-11-22    14 1_10-19    10-19           1
# 12 CS001115000006 2007-03-02    12 9_10-19    10-19           9
# 13 CS001115000010 2006-05-16    12 1_10-19    10-19           1
# 14 CS001202000023 1995-08-27    23 0_20-29    20-29           0
# 15 CS001202000024 1994-10-17    24 0_20-29    20-29           0
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

d = customer %>% mutate(across(gender_cd, ~ as.factor(.x)))
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
q = sql("
select
  customer_id,
  case when gender_cd = '0' then '1' else '0' end as gender_cd_0, 
  case when gender_cd = '1' then '1' else '0' end as gender_cd_1, 
  case when gender_cd = '9' then '1' else '0' end as gender_cd_9
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

receipt %>% filter(!str_detect(customer_id, "^Z")) %>% 
  summarise(sum_amount = sum(amount, na.rm = T), .by = "customer_id") %>% 
  mutate(norm_amount = rescale(sum_amount,, to = c(0, 1))) %>% 
  arrange(customer_id)

#...............................................................................
q = sql("
with customer_amount as (
select
  customer_id, 
  SUM(amount) as amount
from
  receipt
where
  customer_id NOT LIKE 'Z%'
group by 
  customer_id
), 
stats_amount as (
  select 
    MIN(amount) as min_a, 
    MAX(amount) as max_a
  from
    customer_amount
)
select
  c.customer_id, 
  c.amount, 
  (c.amount - s.min_a) / (s.max_a - s.min_a) as scale_amount
from
  customer_amount as c
cross join stats_amount as s
"
)
q %>% my_select(con)

q = sql("
with customer_amount as (
select
  customer_id, 
  SUM(amount) as amount
from
  receipt
where
  customer_id NOT LIKE 'Z%'
group by 
  customer_id
), 
cust as (
  select 
    *, 
    MIN(amount) OVER () as min_a, 
    MAX(amount) OVER () as max_a
  from
    customer_amount
)
select
  customer_id, 
  amount, 
  (amount - min_a) / (max_a - min_a) as scale_amount
from
  cust
"
)
q %>% my_select(con)

# A tibble: 8,306 × 3
#    customer_id    amount scale_amount
#    <chr>           <dbl>        <dbl>
#  1 CS001113000004   1298    0.053354 
#  2 CS001114000005    626    0.024157 
#  3 CS001115000010   3044    0.12921  
#  4 CS001205000004   1988    0.083333 
#  ...

#-------------------------------------------------------------------------------
# R-069 ------------
# レシート明細データ（receipt）と商品データ（product）を結合し、顧客毎に全商品の売上金額合計と、
# カテゴリ大区分コード（category_major_cd）が"07"（瓶詰缶詰）の売上金額合計を計算の上、両者の比率を求めよ。
# 抽出対象はカテゴリ大区分コード"07"（瓶詰缶詰）の売上実績がある顧客のみとし、結果を10件表示せよ。

receipt %>% left_join(product, by = "product_cd") %>% 
  select(customer_id, category_major_cd, amount) %>% 
  mutate(amount_07 = ifelse(category_major_cd == "07", amount, 0.0)) %>% 
  summarise(across(c(amount, amount_07), ~ sum(.x, na.rm = T)), .by = "customer_id") %>% 
  filter(amount_07 > 0.0) %>% 
  mutate(sales_rate = (amount_07 / amount) %>% round(2)) %>% 
  arrange(customer_id)

#...............................................................................
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

# A tibble: 6,865 × 4
#    customer_id    sum_amount major_amount ratio
#    <chr>               <dbl>        <dbl> <dbl>
#  1 CS001113000004       1298         1298  1   
#  2 CS001114000005        626          486  0.78
#  3 CS001115000010       3044         2694  0.89
#  4 CS001205000004       1988          346  0.17
#  5 CS001205000006       3337         2004  0.6 
# ...

#-------------------------------------------------------------------------------
# R-070 ------------
# レシート明細データ（receipt）の売上日（sales_ymd）に対し、顧客データ（customer）の会員申込日
# （application_date）からの経過日数を計算し、顧客ID（customer_id）、売上日、会員申込日とともに
# 10件表示せよ（sales_ymdは数値、application_dateは文字列でデータを保持している点に注意）。

# 経過日数
difftime(get.POSIXct("20170322"), get.POSIXct("20160322")) %>% as.numeric(units = "days")

receipt %>% 
  distinct(customer_id, sales_ymd) %>% 
  inner_join(customer %>% select(customer_id, application_date), by = "customer_id") %>% 
  mutate(
    elapsed_days = 
      difftime(get.POSIXct(sales_ymd), get.POSIXct(application_date)) %>% as.numeric(units = "days")
  ) %>% 
  arrange(customer_id, sales_ymd)

#...............................................................................
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

# A tibble: 32,411 × 4
#    customer_id    sales_ymd application_date elapsed_days
#    <chr>          <chr>     <chr>                   <dbl>
#  1 CS001113000004 20190308  20151105                 1219
#  2 CS001114000005 20180503  20160412                  751
#  3 CS001114000005 20190731  20160412                 1205
#  4 CS001115000010 20171228  20150417                  986
#  5 CS001115000010 20180701  20150417                 1171
#  6 CS001115000010 20190405  20150417                 1449
#  7 CS001205000004 20170914  20160615                  456
#  8 CS001205000004 20180821  20160615                  797
#  ...

#-------------------------------------------------------------------------------
# R-075 ------------
# 顧客データ（customer）からランダムに1%のデータを抽出し、先頭から10件表示せよ。

customer %>% slice_sample(prop = 0.01) %>% my_with_seed(14)

#...............................................................................
q = sql("
with tmp as (
SELECT 
  *, 
  row_number() OVER (order by random()) as row, 
  count(*) OVER () as cnt
FROM 
  customer
)
select 
  row, cnt, 
  customer_id, customer_name, gender_cd
from
  tmp
where
  row <= 0.01 * cnt
-- チェック用
-- order by row desc
"
)
q %>% my_select(con)

# A tibble: 219 × 5
#      row   cnt customer_id    customer_name gender_cd
#    <int> <int> <chr>          <chr>             <int>
#  1     1 21971 CS004414000181 柴山 奈々             1
#  2     2 21971 CS018612000090 塩田 はるみ           9
#  3     3 21971 CS002615000275 筒井 薫               1
#  4     4 21971 CS008702000021 綾小路 明             0
#  ...

#-------------------------------------------------------------------------------
# R-076 ------------
# 顧客データ（customer）から性別コード（gender_cd）の割合に基づきランダムに10%のデータを層化抽出し、
# 性別コードごとに件数を集計せよ。

# 層別サンプリング
customer %>% 
  rsample::initial_split(prop = 0.1, strata = "gender_cd") %>% my_with_seed(14) %>% 
  training() %>% 
  count(gender_cd)

# slice_sample
customer %>% slice_sample(prop = 0.1, by = gender_cd) %>% my_with_seed(14) %>% 
  count(gender_cd)

# グループ分割
# 同じ postal_cd が双方の分割データに含まれないように分割
customer %>% 
  rsample::group_initial_split(group = postal_cd, prop = 0.1) %>% 
  my_with_seed(14) %>% 
  training() %>% 
  count(gender_cd)

#...............................................................................
q = sql("
with cusotmer_random as (
  select
    gender_cd, 
    row_number() OVER (win order by RANDOM()) as row, 
    count(*) OVER win as cnt
  from
    customer
  WINDOW win as (partition by gender_cd)
)
select
  gender_cd, 
  count(*) as n_customer
from
  cusotmer_random
where
  row <= 0.1 * cnt
group by
  gender_cd
order by
  gender_cd
"
)
q %>% my_select(con)

# A tibble: 3 × 2
#   gender_cd n_customer
#       <int>      <int>
# 1         0        298
# 2         1       1791
# 3         9        107

#-------------------------------------------------------------------------------
# R-081 ------------
# 単価（unit_price）と原価（unit_cost）の欠損値について、それぞれの平均値で補完した新たな商品データを作成せよ。
# なお、平均値については1円未満を丸めること（四捨五入または偶数への丸めで良い）。
# 補完実施後、各項目について欠損が生じていないことも確認すること。

product %>% skim()

d = product %>% recipes::recipe() %>% 
  step_impute_mean(starts_with("unit_")) %>% 
  prep() %>% bake(new_data = NULL) %>% 
  mutate(across(starts_with("unit_"), ~ round(.x, 1)))

d %>% skim()
d
# A tibble: 10,030 × 6
#    product_cd category_major_cd category_medium_cd category_small_cd unit_price
#    <chr>      <chr>             <chr>              <chr>                  <dbl>
#  1 P040101001 04                0401               040101                   198
#  2 P040101002 04                0401               040101                   218
#  3 P040101003 04                0401               040101                   230
#  4 P040101004 04                0401               040101                   248
#  5 P040101005 04                0401               040101                   268
#  ...

#...............................................................................
q = sql("
with prod as (
  select
    product_cd, 
    unit_price, 
    unit_cost, 
    AVG(unit_price) OVER () as mean_price, 
    AVG(unit_cost) OVER () as mean_cost
  from
    product
)
select
  product_cd, 
  ROUND(COALESCE(unit_price, mean_price)) as unit_price, 
  ROUND(COALESCE(unit_cost, mean_cost)) as unit_cost, 
  mean_price, 
  mean_cost
from
  prod
-- チェック用
-- where unit_price IS NULL
"
)
q %>% my_select(con)

# A tibble: 10,030 × 5
#    product_cd unit_price unit_cost mean_price mean_cost
#    <chr>           <dbl>     <dbl>      <dbl>     <dbl>
#  1 P040101001        198       149     402.58    302.19
#  2 P040101002        218       164     402.58    302.19
#  3 P040101003        230       173     402.58    302.19
#  4 P040101004        248       186     402.58    302.19
#  5 P040101005        268       201     402.58    302.19
#  ...

## 各商品のカテゴリ小区分コード（category_small_cd）ごとに算出した平均値で補完する場合
q = sql("
with prod as (
  select
    product_cd, 
    category_small_cd, 
    unit_price, 
    unit_cost, 
    AVG(unit_price) OVER (partition by category_small_cd) as mean_price, 
    AVG(unit_cost) OVER (partition by category_small_cd) as mean_cost
  from
    product
)
select
  product_cd, 
  category_small_cd, 
  ROUND(COALESCE(unit_price, mean_price)) as unit_price, 
  ROUND(COALESCE(unit_cost, mean_cost)) as unit_cost, 
  mean_price, 
  mean_cost
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
# R-084 ------------
# 顧客データ（customer）の全顧客に対して全期間の売上金額に占める2019年売上金額の割合を計算し、
# 新たなデータを作成せよ。
# ただし、売上実績がない場合は0として扱うこと。そして計算した割合が0超のものを抽出し、結果を10件表示せよ。
# また、作成したデータに欠損が存在しないことを確認せよ。

# receipt %>% select(customer_id) %>% anti_join(customer, by = "customer_id")

d = receipt %>% select(customer_id, sales_ymd, amount) %>% 
  mutate(sales_year = sales_ymd %>% get.POSIXct() %>% year()) %>% 
  right_join(customer, by = "customer_id") %>% 
  mutate(amount_2019 = ifelse(sales_year == 2019, amount, 0.0), .after = sales_year) %>% 
  summarise(
    across(starts_with("amount"), ~ sum(.x, na.rm = T), 
    .names = "sales_{.col}"), .by = customer_id
  ) %>% 
  mutate(sales_rate = 
    ifelse(sales_amount == 0.0, 0.0, (sales_amount_2019 / sales_amount) %>% round(2))
  ) %>% 
  filter(sales_rate > 0.0) %>% 
  arrange(customer_id)
  
d %>% skim()

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

d.amount = receipt %>% summarise(
    sum_amount = sum(amount), 
    .by = customer_id
  )

vars = c("customer_name", "postal_cd")
d.cust =
  customer %>% 
  # select(customer_id, customer_name, postal_cd) %>% 
  left_join(d.amount, by = "customer_id") %>% 
  mutate(sum_amount = coalesce(sum_amount, 0.0)) %>% 
  group_by(across(!!vars)) %>% 
  add_count(name = "n") %>% 
  arrange(desc(sum_amount), customer_id) %>% 
  mutate(row = row_number()) %>% 
  mutate(integration_id = max(ifelse(row == 1, customer_id, "")), .before = 1) %>% 
  ungroup() %>% 
  arrange(across(!!vars), row)

# for check
d.cust %>% filter(n > 1) %>% arrange(customer_name, postal_cd) %>% 
  select(integration_id, customer_id, customer_name, postal_cd, sum_amount, row) %>% 
  tbl_print(30)

d.customer.u = d.cust %>% filter(row == 1)

n.all = customer %>% nrow() %T>% print()
n.u = d.customer.u %>% nrow() %T>% print()
n.all - n.u

# row_number(tibble(desc(sum_amount), customer_id)) は時間がかかる
d = customer %>% 
  select(customer_id, customer_name, postal_cd) %>% 
  left_join(d.amount, by = "customer_id") %>% 
  mutate(sum_amount = coalesce(sum_amount, 0.0)) %>% 
  mutate(row = row_number(tibble(desc(sum_amount), customer_id)), .by = c(customer_name, postal_cd))

d %>% filter(row > 1)

# dbplyr
d.ant = tbl_receipt %>% summarise(
    sum_amount = sum(amount), 
    .by = customer_id
  )

vars = c("customer_name", "postal_cd")
d = tbl_customer %>% 
  left_join(d.ant, by = "customer_id") %>% 
  mutate(sum_amount = coalesce(sum_amount, 0.0)) %>% 
  group_by(across(!!vars)) %>% 
  mutate(
    n = n(), 
    row = row_number(tibble(desc(sum_amount), customer_id))
  ) %>% 
  mutate(
    integration_id = max(ifelse(row == 1, customer_id, "")), 
    .before = 1
  ) %>% 
  ungroup() %>% 
  window_order(across(!!vars), row)
  # arrange(across(!!vars), desc(sum_amount), customer_id)

d %>% my_show_query()

d %>% glimpse()
d %>% collect()
d %>% filter(n > 1) %>% collect() %>% 
  select(integration_id, customer_id, customer_name, postal_cd, sum_amount, row)

#...............................................................................
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

d = receipt %>% summarise(sum_amount = sum(amount), .by = customer_id) %>% 
  filter(sum_amount > 0.0) %>% 
  inner_join(customer, by = "customer_id")
d

obj.rsplit = d %>% rsample::initial_split(prop = 0.8) %>% my_with_seed(14)
obj.rsplit %>% training()
obj.rsplit %>% testing()

#...............................................................................
con %>% dbExecute("DROP TABLE IF EXISTS cust")

# SET SEED TO 0.25;

q = sql("
CREATE TEMP TABLE cust AS 
with cust0 as (
select
  customer_id, 
  customer_name, 
  SUM(amount) as sum_amount
from
  customer
inner join receipt USING(customer_id)
group by 
  customer_id
having
  sum_amount > 0.0
)
select
  *, 
  PERCENT_RANK() OVER (order by RANDOM()) as rank
from
  cust0
-- order by rank desc
"
)
con %>% dbExecute(q)

con %>% dbReadTable("cust") %>% as_tibble()
#    customer_id    customer_name     sum_amount       rank
#    <chr>          <chr>                  <dbl>      <dbl>
#  1 CS001515000018 緒方 優                  276 0         
#  2 CS004414000255 成海 莉沙                210 0.00012041
#  3 CS002514000100 溝口 さやか              625 0.00024082
#  4 CS042515000025 宮崎 恵麻                483 0.00036123
#  5 CS009513000055 矢口 美咲               2491 0.00048164
#  6 ...

con %>% dbExecute("DROP TABLE IF EXISTS customer_train")

q = sql("
CREATE TABLE customer_train AS
select * from cust where rank < 0.8
-- order by rank desc
"
)
con %>% dbExecute(q)

con %>% dbReadTable("customer_train") %>% as_tibble()

con %>% dbExecute("DROP TABLE IF EXISTS customer_test")

q = sql("
CREATE TABLE customer_test AS
select * from cust
EXCEPT
select * from customer_train
"
)
con %>% dbExecute(q)

con %>% dbReadTable("customer_test") %>% as_tibble()

con %>% dbListTables()

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
