# 必要なパッケージをロード
library(DBI)
library(dplyr)
library(dbplyr)
library(duckdb)
library(tibble)

# サンプルのデータフレームを作成
df_sales = tribble(
  ~store, ~month, ~sales, ~profit,
  "S001",  7L,     15000,  3000,
  "S001",  8L,     16000,  3200,
  "S002",  7L,     14000,  2800,
  "S002",  8L,     19000,  NA,
  "S003",  7L,     12000,  2500,
  "S003",  8L,     13000,  2600,
  "S004",  7L,     20000,  3800,
  "S004",  8L,     21000,  4200,
  "S005",  7L,     16000,  3300,
  "S005",  8L,     17000,  3400
)

df_master = tribble(
  ~store, ~name,    ~pref, 
  "S001", "storeA", "Tokyo",
  "S002", "storeB", "Osaka",
  "S003", "storeC", "Kanagawa",
  "S004", "storeD", "Fukuoka", 
  "S005", "storeE", "Chiba",
  "S006", "storeF", "Hokkaido",
  "S007", "storeG", "Saitama"
)

# DuckDB に接続 (一時データベース)
con = DBI::dbConnect(duckdb::duckdb())

# テーブルとしてデータベースに登録
DBI::dbWriteTable(
  con, "store_sales", df_sales, overwrite = TRUE
)
DBI::dbWriteTable(
  con, "store_master", df_master, overwrite = TRUE
)

# store_sales テーブルを dplyr で参照
db_sales = tbl(con, "store_sales")
db_master = tbl(con, "store_master")

#...............................................................................

# 
db_sales %>% show_query()

### dplyr 操作全体の変換

## 単一テーブルの操作

# `select()` は `SELECT` 句を修正します: 
db_sales %>% 
  select(store, sales) %>% 
  show_query()

db_sales %>% 
  rename(store_id = store) %>% 
  show_query()

db_sales %>% 
  relocate(profit, sales, .after = store) %>% 
  show_query()

# "month" がダブルクォートで括られてるのは、これが duckdb の予約語だからです。

# `mutate()` は `SELECT` 句を修正します: 
db_sales %>% 
  mutate(margin = 100 * profit / sales, .keep = "unused") %>% 
  show_query()

# filter() は WHERE 句を生成します
db_sales %>% 
  filter(month == 7L, profit >= 3000) %>% 
  show_query()

# arrange() は ORDER BY 句を生成します
db_sales %>% 
  arrange(month, desc(profit)) %>% 
  show_query()

# summarise() は group_by() と合わせて GROUP BY 句を生成します
db_sales %>% 
  group_by(store) %>% 
  summarise(avg_profit = mean(profit)) %>% 
  show_query()

# 集計後の filter() は HAVING 句を生成します
db_sales %>% 
  group_by(store) %>% 
  summarise(avg_profit = mean(profit)) %>% 
  filter(avg_profit > 3500) %>% 
  show_query()

# head() は LIMIT 句を生成します
db_sales %>% 
  head(3) %>% 
  show_query()

## 2つのテーブルの操作

# left_join() LEFT JOIN 句を生成します
db_sales %>% 
  left_join(db_master, by = "store") %>% 
  show_query()

# inner_join(), right_join() についても同様です。

# full_join() は FULL JOIN 句を生成します
db_sales %>% 
  full_join(db_master, by = "store") %>% 
  show_query()

# cross_join() は CROSS JOIN 句を生成します
db_master %>% 
  select(store) %>% 
  cross_join(db_sales %>% select(month)) %>% 
  show_query()

# semi_join() は WHERE 句の EXISTS サブクエリ演算子を生成します
db_master %>% 
  semi_join(db_sales, by = "store") %>% 
  show_query()

# anti_join() は WHERE 句の NOT EXISTS サブクエリ演算子を生成します
db_master %>% 
  anti_join(db_sales, by = "store") %>% 
  show_query()

# intersect() は INTERSECT 演算子を生成します
db_sales %>% 
  select(store) %>% 
  intersect(db_master %>% select(store)) %>% 
  show_query()

# union() は UNION 演算子を生成します
db_sales %>% 
  select(store) %>% 
  union(db_master %>% select(store)) %>% 
  show_query()

# union_all() は UNION ALL 演算子を生成します
db_sales %>% 
  select(store) %>% 
  union_all(db_master %>% select(store)) %>% 
  show_query()

# setdiff() は EXCEPT 演算子を生成します
db_master %>% 
  select(store) %>% 
  setdiff(db_sales %>% select(store)) %>% 
  show_query()

## その他の操作

# count(), slice_min(), slice_max(), replace_na(), pivot_longer() などのその他の操作については、
# ここまでに挙げた SQLの句や演算子、SQL関数を組み合わせて変換されます。

# 例えば、count() は次のように変換されます。
db_sales %>% 
  count(store, name = "n_month") %>% 
  show_query()

# pivot_longer() は次のように変換されます。
db_sales %>% 
  pivot_longer(-c(store, month), names_to = "name", values_to = "amount") %>% 
  show_query()

### dplyr 操作内の式の変換

## 算術演算子
db_sales %>% 
  mutate(
    v1 = sales + profit, 
    v2 = sales - profit, 
    v3 = profit / sales, 
    v4 = profit * sales, 
    v5 = profit ^ 2L, 
    .keep = "none"
  ) %>% 
  show_query()

## 比較演算子、ブール演算子(&, |)
db_sales %>% 
  mutate(
    v1 = (sales == 15000), 
    v2 = (!(sales > 15000)), 
    v3 = (sales != 15000 & profit >= 3000), 
    v4 = (sales < 15000 | profit <= 3000), 
    v5 = (store %in% c("S001", "S002")), 
    .keep = "used"
  ) %>% 
  show_query()

## 数学関数、数値の丸め
db_sales %>% 
  mutate(
    v1 = log(profit), 
    v2 = sqrt(profit), 
    v3 = sin(profit), 
    v4 = floor(profit / sales), 
    .keep = "none"
  ) %>% 
  show_query()

## 型変換
db_sales %>% 
  mutate(
    m = as.character(month), 
    .keep = "used"
  ) %>% 
  show_query()

## 文字列操作
db_master %>% 
  mutate(
    len = nchar(pref), 
    upp = toupper(pref), 
    sub = substr(name, 6, 6), 
    p = paste(name, pref, sep = "-"), 
    .keep = "used"
  ) %>% 
  show_query()

## 日付操作
db_master %>% 
  mutate(
    ymd = lubridate::as_date("2025-04-01"), # サンプルの作成
    .keep = "used"
  ) %>% 
  head(1) %>% 
  mutate(
    strftime = strftime(ymd, "%Y/%m/%d"), 
    month = lubridate::month(ymd), 
    add = ymd + lubridate::days(7L), 
    .keep = "used"
  ) %>% 
  show_query(cte = T)

## パターンマッチング
db_master %>% 
  filter(
    stringr::str_detect(pref, "ka$")
  ) %>% 
  show_query()

## is.na()
db_sales %>% 
  filter(is.na(profit)) %>% 
  show_query()

## distinct()
db_sales %>% 
  distinct(month) %>% 
  show_query()

## if_else()
db_sales %>% 
  mutate(
    s = if_else(profit > 3000, "big", "small", "none"), 
    .keep = "used"
  ) %>% 
  show_query()


mean, median
rank, ntile
lag, lead
cumsum, cummean

translate_sql(sql("x!"), con = con)
translate_sql(x == sql("ANY VALUES(1, 2, 3)"), con = con)

# dbplyr の変換は完璧ではありません。
# SQLは正しくても、簡潔ではないSQLクエリに変換されるケース
!is.na()


store
month
sales
profit

#-------------------------------------------------------------------------------
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

#-------------------------------------------------------------------------------
