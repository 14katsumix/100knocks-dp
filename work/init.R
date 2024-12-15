#===============================================================================
# R起動後のセットアップ
#===============================================================================

# 作業ディレクトリの設定
# setwd("work")
getwd() |> print() #> "your_root_path/work"
cat("\n")

# tibbleの標準出力向けの設定 ------------
list(
  "tibble.print_max" = 40, # 表示する最大行数.
  "tibble.print_min" = 15, # 表示する最小行数.
  "tibble.width" = NULL,   # 全体の出力幅. デフォルトは NULL.
  "pillar.sigfig" = 5,     # 表示する有効桁数
  "pillar.max_dec_width" = 13 # 10進数表記の最大許容幅
) |> 
  options()

# pacman のロード ------------
# (無ければインストールする)
if (!require("pacman")) {
  install.packages("pacman")
  library("pacman")
}
cat("\n")

# 全てのパッケージを一括アンロードする場合: 
# pacman::p_unload("all")

# 各パッケージのロード ------------
# 無い場合は自動でインストールした後にロードする.
pacman::p_load(
  # tidyverse: 
  magrittr, fs, tibble, dplyr, tidyr, stringr, lubridate, # purrr, forcats, 
  # tidymodels: 
  rsample, recipes, themis, 
  # for DB: 
  DBI, duckdb, dbx, dbplyr, 
  httr, xfun,  # for download
  withr, vroom, jsonlite, 
  install = T, # 存在しないパッケージをインストールする
  update = F   # 古いパッケージを更新しない
)

# ロード済みのパッケージの確認
pacman::p_loaded() %>% writeLines()
cat("\n")

#-------------------------------------------------------------------------------
# functions.R の実行 ------------
source("functions.R", encoding = 'UTF-8')

# data_setup.R の実行 ------------
source("data_setup.R", encoding = 'UTF-8')

#-------------------------------------------------------------------------------

#===============================================================================
# sc ------------
# paste (str_c)
sc = function(..., s = "", c = NULL) {
  return(stringr::str_c(..., sep = s, collapse = c))
}
# ex)
# sc(1.23, "aaa", "bbb", s="+") # => "1.23+aaa+bbb"
# sc(c(1.23, "aaa", "bbb"), c=":") # => "1.23:aaa:bbb"
# sc("AAA", 1:5, s="-") # => [1] "AAA-1" "AAA-2" "AAA-3" "AAA-4" "AAA-5"

# sp ------------
# paste (str_c), sprintf
sp = function(..., s = "", f) {
  if (missing(f))
    f = sc(rep("%s", length(c(...))), s = "", c = s)
  return(sprintf(..., fmt = f))
}
# ex)
# sp(1.23) # => "1.23"
# sp(1.23, "aaa", "bbb", s = "+") # => "1.23+aaa+bbb"
# sp(1.23456, 8.88888, f = "X1 = %0.2f, X2 = %0.4f") # => "X1 = 1.23, X2 = 8.8889"

# ct ------------
# cat
ct = function(..., s = "", f, fill = T, labels = NULL, num.nc = 1) {
  cat( sp(..., s = s, f = f), fill = fill, labels = labels )
  if (num.nc > 1) {
    rep("\n", num.nc) %>% cat()
  }
}
# ex)
# ct(1.23, "aaa", "bbb", s="+") # => 1.23+aaa+bbb
# ct(1.23456, 8.88888, f = "X1 = %0.2f, X2 = %0.4f") # => X1 = 1.23, X2 = 8.8889
# ct(f = "X1 = %0.2f, X2 = %0.4f", 1.23456, 8.88888) # => X1 = 1.23, X2 = 8.8889
# ct(1.23, "aaa", s="+", num.nc = 2)
# ct("aaa", "bbb" , "ccc", s = ", ", fill = T, labels = "{*}") #> {*} aaa, bbb, ccc

# is.not_null ------------
# not NULL か否か (logical)
is.not.null = function(x) { !is.null(x) }

# tbl.print ------------
# tbl_df形式で標準出力
tbl_print = function(
  df, n = 5, n.tail = NULL, all.print = F, 
  width = NULL, max_extra_cols = NULL, max_footer_lines = NULL, 
  sigfig = 5, max_dec_width = 13, min_title_chars = 15, min_chars = 3
  ) {
  old.options = options(
    pillar.sigfig = sigfig, pillar.max_dec_width = max_dec_width, 
    pillar.min_title_chars = min_title_chars, pillar.min_chars = min_chars
  )
  on.exit(options(old.options))
  dim(df) %>%  
    purrr::map_chr(format, big.mark = ",") %>%  sc(c = " x ") %>%  
    sp(f = "dim: %s") %>%  ct(f = "# %s")
  if (all.print) {
    n = nrow(df); n.tail = NULL
  }
  df %>%  head(n) %>%  tibble::as_tibble() %>% 
    print(
      width = width, max_extra_cols = max_extra_cols, 
      max_footer_lines = max_footer_lines
    )
  if (is.not.null(n.tail))
    df %>%  tail(n.tail) %>%  tibble::as_tibble() %>% 
      print(
        width = width, max_extra_cols = max_extra_cols, 
        max_footer_lines = max_footer_lines
      )
  ct(num.nc = 1)
}

#-------------------------------------------------------------------------------
