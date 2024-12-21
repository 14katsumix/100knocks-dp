#===============================================================================
# データの準備
# 1. 各.csvファイル等をダウンロードする.
# 2. 各.csvファイルを読み込む.
# 3. DBコネクションを作成する.
# 4. データフレームをDBに書き込み, テーブル参照を取得する.
#===============================================================================

# 各.csvファイル等のダウンロード ------------

# GitHub API URL of 100knocks data
data_url = 
  "https://api.github.com/repos/The-Japan-DataScientist-Society/100knocks-preprocess/contents/docker/work/data"

# 各ファイルのURL
urls = data_url %>% 
  httr::GET() %>% 
  httr::content(as = "text") %>% 
  jsonlite::fromJSON() %>% 
  pull(download_url)

for (url in urls) {
  # ダウンロード先のファイルパス
  path = url %>% xfun::url_filename() %>% my_path_join()
  # ダウンロード (上書きはしない)
  if (!file_exists(path))
    xfun::download_file(url, output = path)
}

#-------------------------------------------------------------------------------
# 各.csvファイルの読み込み ------------

my_vroom = function(fname, col_types, .subdir = "data") {
  fname %>% 
    my_path_join(.subdir = .subdir) %>% 
    { print(.); flush.console(); . } %>% 
    vroom::vroom(col_types = col_types) %>% 
    glimpse() %T>% 
    { cat("\n") } ->
    d
  d
}

# receipt.sales_ymd を integer として読み込む
df_receipt = "receipt.csv" %>% my_vroom(col_types = "iiciiccnn")
# customer.birth_day を Dateクラスとして読み込む
df_customer = "customer.csv" %>% my_vroom(col_types = "ccicDiccccc")
df_product = "product.csv" %>% my_vroom(col_types = "ccccnn")
df_category = "category.csv" %>% my_vroom(col_types = "cccccc")
df_store = "store.csv" %>% my_vroom(col_types = "cccccccddd")
df_geocode = "geocode.csv" %>% my_vroom(col_types = "cccccccnn")

#-------------------------------------------------------------------------------
# DBコネクションの作成 ------------

# DBファイルのパス
dbdir = my_path_join("100knocks.duckdb", .subdir = "DB")

# dbdir の親ディレクトリが無ければ作成する (あれば何もしない)
dbdir %>% path_dir() %>% fs::dir_create()

# dbdir = "" #< DBを in-memory で一時的に作成する場合
drv = duckdb::duckdb(dbdir = dbdir) # duckdb_driverオブジェクト

duckdb::dbConnect(
  drv = drv
  # timezone_out = Sys.timezone() # ローカルのタイムゾーンで日時の値を表示する
) -> con

con %>% dbGetInfo() %>% glimpse() # db.version, dbname などを表示する
cat("\n")

# DBコネクションを切断する場合: 
# con %>% duckdb::dbDisconnect()

#-------------------------------------------------------------------------------
# データフレームのDBへの書き込みとテーブル参照の取得 ------------

# テーブルが既に存在する場合は上書きする
tsql_receipt = con %>% my_tbl(df = df_receipt, overwrite = T)
tsql_customer = con %>% my_tbl(df = df_customer, overwrite = T)
tsql_product = con %>% my_tbl(df = df_product, overwrite = T)
tsql_category = con %>% my_tbl(df = df_category, overwrite = T)
tsql_store = con %>% my_tbl(df = df_store, overwrite = T)
tsql_geocode = con %>% my_tbl(df = df_geocode, overwrite = T)

# DB上に作成したテーブルのリスト
con %>% DBI::dbListTables() %>% print()

#-------------------------------------------------------------------------------

# DBコネクションの作成 (SQLite)
# dbname = my_path_join("100knocks.sqlite", .subdir = "DB")
# dbname = ":memory:" # DBを in-memory で一時的に作成する場合
# drv = RSQLite::SQLite() # SQLiteDriverオブジェクト
# con = DBI::dbConnect(drv = drv, dbname = dbname, synchronous = "off")
#> synchronous = "off" にすると SQLite への書き込みがかなり速くなる模様.
# DBコネクションを切断する場合: 
# con %>% DBI::dbDisconnect()
