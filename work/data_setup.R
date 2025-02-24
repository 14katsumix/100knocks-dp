#===============================================================================
# データの準備
# 1. 各CSVファイル等をダウンロードする.
# 2. 各CSVファイルを読み込む.
# 3. DBコネクションを作成する.
# 4. データフレームをDBに書き込み, テーブル参照を取得する.
#===============================================================================

# 各CSVファイル等のダウンロード ------------

# GitHub API URL of 100knocks data
data_url = 
  "https://api.github.com/repos/The-Japan-DataScientist-Society/100knocks-preprocess/contents/docker/work/data"

# 各ファイルのURL
urls = data_url %>% 
  httr::GET() %>% 
  httr::content(as = "text") %>% 
  jsonlite::fromJSON() %>% 
  dplyr::pull(download_url)

# dataディレクトリの作成
data_dir = my_path_join()
if (!fs::dir_exists(data_dir))
  fs::dir_create(data_dir)

for (url in urls) {
  # ダウンロード先のファイルパス
  path = url %>% xfun::url_filename() %>% my_path_join()
  # ダウンロード (上書きはしない)
  if (!fs::file_exists(path))
    xfun::download_file(url, output = path)
}

#-------------------------------------------------------------------------------
# 各CSVファイルの読み込み ------------

my_vroom = function(fname, col_types, .subdir = "data") {
  tictoc::tic(fname)
  on.exit(tictoc::toc())
  on.exit(cat("\n"), add = TRUE)
  d = fname %>% 
    my_path_join(.subdir = .subdir) %>% 
    { print(.); flush.console(); . } %>% 
    vroom::vroom(col_types = col_types) %>% 
    janitor::clean_names() %>% 
    dplyr::glimpse() %T>% 
    { cat("\n") }
  d
}

# receipt.sales_ymd を integer として読み込む
# (エディターのコード補完を利用できるように assign() を用いてオブジェクトを作成しない)
df_receipt = "receipt.csv" %>% my_vroom(col_types = "iiciiccnn")
# customer.birth_day を Dateクラスとして読み込む
df_customer = "customer.csv" %>% my_vroom(col_types = "ccccDiccccc")
df_product = "product.csv" %>% my_vroom(col_types = "ccccnn")
df_category = "category.csv" %>% my_vroom(col_types = "cccccc")
df_store = "store.csv" %>% my_vroom(col_types = "cccccccddd")
df_geocode = "geocode.csv" %>% my_vroom(col_types = "cccccccnn")

#-------------------------------------------------------------------------------
# DBコネクションの作成 (ファイルベースモード) ------------

# DBファイルのパス
dbdir = my_path_join("100knocks.duckdb", .subdir = "DB")

# dbdir の親ディレクトリが無ければ作成する (あれば何もしない)
dbdir %>% fs::path_dir() %>% fs::dir_create()

drv = duckdb::duckdb(dbdir = dbdir) # duckdb_driverオブジェクト
# dbdir = "" #< DBを インメモリモードで一時的に作成する場合

con = duckdb::dbConnect(
    drv = drv
    # timezone_out = Sys.timezone() # ローカルのタイムゾーンで日時の値を表示する
  )

# db.version, dbname などを表示する
con %>% DBI::dbGetInfo() %>% dplyr::glimpse() 
cat("\n")

# DBコネクションを切断する場合: 
# con %>% duckdb::dbDisconnect()

#-------------------------------------------------------------------------------
# データフレームのDBへの書き込みとテーブル参照の取得 ------------

# テーブルが既に存在する場合は上書きする
# (エディターのコード補完を利用できるように assign() を用いてオブジェクトを作成しない)
db_receipt = con %>% my_tbl(df = df_receipt, overwrite = TRUE)
db_customer = con %>% my_tbl(df = df_customer, overwrite = TRUE)
db_product = con %>% my_tbl(df = df_product, overwrite = TRUE)
db_category = con %>% my_tbl(df = df_category, overwrite = TRUE)
db_store = con %>% my_tbl(df = df_store, overwrite = TRUE)
db_geocode = con %>% my_tbl(df = df_geocode, overwrite = TRUE)

# DB上に作成したテーブルのリスト
con %>% DBI::dbListTables() %>% print()

#-------------------------------------------------------------------------------
