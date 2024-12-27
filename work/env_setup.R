#===============================================================================
# パッケージのロード, オプション設定
#===============================================================================

# pacman のロード ------------
if (!require("pacman")) {
  install.packages("pacman")
  library("pacman")
}

# 各パッケージのロード ------------
# 無い場合は自動でインストールした後にロードする.
pacman::p_load(
  # tidyverse: 
  magrittr, fs, tibble, dplyr, tidyr, stringr, lubridate, # purrr, forcats, 
  # tidymodels: 
  rsample, recipes, themis, 
  # for DB: 
  DBI, duckdb, dbx, dbplyr, 
  # for download: 
  httr, xfun, 
  withr, vroom, janitor, jsonlite, 
  install = T, # 存在しないパッケージをインストールする
  update = F   # 古いパッケージを更新しない
)

# ロード済みのパッケージの確認
pacman::p_loaded() %>% writeLines()
cat("\n")

# 全てのパッケージを一括アンロードする場合: 
# pacman::p_unload("all")

# tibble の標準出力向けの設定 ------------
list(
  "tibble.print_max" = 40, # 表示する最大行数.
  "tibble.print_min" = 15, # 表示する最小行数.
  "tibble.width" = NULL,   # 全体の出力幅. デフォルトは NULL.
  "pillar.sigfig" = 5,     # 表示する有効桁数
  "pillar.max_dec_width" = 13 # 10進数表記の最大許容幅
) |> 
  options()

#-------------------------------------------------------------------------------
