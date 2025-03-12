data_url = "https://raw.githubusercontent.com/14jcjc/tech-blog/main/static/test/"

data_url %>% paste0("store.csv") %>% vroom::vroom(col_types = "cccccccddd")

data_url %>% 
  httr::GET() %>% 
  httr::content(as = "text") %>% 
  jsonlite::fromJSON()

"https://github.com/14jcjc/tech-blog/tree/main/static/test/store.csv" %>% 
  vroom::vroom(col_types = "cccccccddd")

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
