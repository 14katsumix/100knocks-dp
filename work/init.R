#===============================================================================
# R起動後のセットアップ
#===============================================================================

# rstudioapi のロード ------------
if (!require("rstudioapi")) {
  install.packages("rstudioapi")
  library("rstudioapi")
}

# 作業ディレクトリの設定 ------------
# work_dir_path をローカル環境に合わせて適宜書き換えてください: 
work_dir_path = rstudioapi::getSourceEditorContext()$path |> dirname()
work_dir_path |> setwd()
getwd() |> print() #> "your_directory_path/work"
cat("\n")

# env_setup.R の実行 ------------
source("env_setup.R", encoding = 'UTF-8')

# functions.R の実行 ------------
source("functions.R", encoding = 'UTF-8')

# data_setup.R の実行 ------------
source("data_setup.R", encoding = 'UTF-8')

#-------------------------------------------------------------------------------
