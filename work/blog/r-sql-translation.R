# 必要なパッケージをロード
library(DBI)
library(dplyr)
library(dbplyr)
library(duckdb)
library(tibble)

# DuckDB に接続 (一時データベース)
con = DBI::dbConnect(duckdb::duckdb())

# サンプルのデータフレームを作成
df1 = tribble(
  ~store, ~month, ~sales, ~profit,
  "S001",  7,     15000,  3000,
  "S001",  8,     16000,  3200,
  "S002",  7,     18000,  3500,
  "S002",  8,     19000,  3600,
  "S003",  7,     12000,  2500,
  "S003",  8,     13000,  2600,
  "S004",  7,     20000,  3800,
  "S004",  8,     21000,  4200,
  "S005",  7,     16000,  3300,
  "S005",  8,     17000,  3400
)

df2 = tribble(
  ~store, ~name,    ~pref, 
  "S001", "storeA", "tokyo",
  "S002", "storeB", "osaka",
  "S003", "storeC", "kanagawa",
  "S004", "storeD", "fukuoka", 
  "S005", "storeE", "chiba",
  "S006", "storeF", "hokkaido",
  "S007", "storeG", "saitama"
)

print(df2)

# テーブルとしてデータベースに登録
DBI::dbWriteTable(
  con, "store_sales", df1, overwrite = TRUE
)
DBI::dbWriteTable(
  con, "store_master", df2, overwrite = TRUE
)

# 
db_sales %>% show_query()

# "month" がダブルクォートで括られてるのは、これが duckdb の予約語だからです。

# store_sales テーブルを dplyr で参照
db_sales = tbl(con, "store_sales")
db_master = tbl(con, "store_master")

## シングルテーブル動詞

# select()
# select(), mutate() は SELECT句を修正します。
db_sales %>% 
  select(store, sales) %>% 
  show_query()

db_sales %>% 
  rename(store_id = store) %>% 
  show_query()

db_sales %>% 
  relocate(profit, sales, .after = store) %>% 
  show_query()

# mutate() は SELECT句を修正します。
db_sales %>% 
  mutate(margin = 100 * profit / sales, .keep = "unused") %>% 
  show_query()

# filter() は WHERE句を生成します
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

# 集計後の filter() は HAVING句を生成します
db_sales %>% 
  group_by(store) %>% 
  summarise(avg_profit = mean(profit)) %>% 
  filter(avg_profit > 3500) %>% 
  show_query()

## デュアルテーブル動詞

# left_join() LEFT JOIN 句を生成します
db_sales %>% 
  left_join(db_master, by = "store") %>% 
  show_query()

# inner_join(), right_join() についても同様です。

# full_join() は FULL JOIN 句を生成します
db_sales %>% 
  full_join(db_master, by = "store") %>% 
  show_query()

# semi_join() は WHERE句の EXISTS サブクエリ演算子を生成します
db_master %>% 
  semi_join(db_sales, by = "store") %>% 
  show_query()

# anti_join() は WHERE句の NOT EXISTS サブクエリ演算子を生成します
db_master %>% 
  anti_join(db_sales, by = "store") %>% 
  show_query()



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
