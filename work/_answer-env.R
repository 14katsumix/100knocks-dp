#-------------------------------------------------------------------------------
# R-029

# pacman を使用してパッケージを管理
if (!require("pacman")) {
  install.packages("pacman")
  library("pacman")
}

# 必要なパッケージのロード
# 存在しない場合はインストールした後にロードする
pacman::p_load(
  magrittr, tibble, dplyr, # データ操作 (tidyverse)
  DBI, dbplyr, duckdb,     # データベース操作
  vroom,                   # CSVファイルの読み込み
  install = TRUE,          # 存在しないパッケージをインストールする
  update = FALSE           # 古いパッケージを更新しない
)

# CSVファイルをデータフレームとして読み込む
data_url = "https://raw.githubusercontent.com/The-Japan-DataScientist-Society/100knocks-preprocess/master/docker/work/data/"

df_receipt = 
  paste0(data_url, "receipt.csv") %>% 
  vroom::vroom(col_types = "iiciiccnn")

# インメモリモードで一時的な DuckDB 環境を作成する
con = duckdb::duckdb(dbdir = "") %>% duckdb::dbConnect()

# データフレームを DuckDB にテーブルとして書き込む
con %>% DBI::dbWriteTable("receipt", df_receipt, overwrite = TRUE)

# DuckDB のテーブルを dplyr で参照する
db_receipt = con %>% dplyr::tbl("receipt")

# my_select() の定義
# SQLクエリを実行し, データフレーム(tibble)を返す
my_select = function(
    statement, con, convert_tibble = TRUE, params = NULL, ...
  ) {
  d = DBI::dbGetQuery(conn = con, statement = statement, params = params, ...)
  if (convert_tibble) d %<>% tibble::as_tibble()
  return(d)
}

#-------------------------------------------------------------------------------

# df_customer = 
#   paste0(data_url, "customer.csv") %>% 
#   vroom::vroom(col_types = "ccccDiccccc")

# con %>% DBI::dbWriteTable("customer", df_customer, overwrite = TRUE)

# db_customer = con %>% dplyr::tbl("customer")

# データベース・コネクションの作成 (ファイルベースモード) ------------
# DuckDB データベースファイルのパス
# dbdir = c(".", "database", "100knocks.duckdb") %>% fs::path_join()
# dbdir の親ディレクトリが無ければ作成する
# dbdir %>% fs::path_dir() %>% fs::dir_create()
# drv = duckdb::duckdb(dbdir = dbdir) # duckdb_driver オブジェクト

# db_receipt %>% collect()
# db_customer %>% collect()
