#===============================================================================
# R 起動後のセットアップ
#===============================================================================

# .R ファイルの実行関数
safe_source = function(file) {
  tryCatch({
    message(file, " の実行を開始します. \n\n")
    source(file, encoding = 'UTF-8')
    message("\n", file, " の実行が完了しました. \n\n")
  }, 
  error = function(e) {
    stop(file, " の実行中にエラーが発生しました: \n", e$message, "\n", call. = FALSE)
  })
}

# pacman のロード ------------
if (!require("pacman")) {
  install.packages("pacman")
  library("pacman")
}

# rstudioapi, tictoc のロード ------------
# 無い場合は自動でインストールした後にロードする.
pacman::p_load(
  rstudioapi,  # ローカルファイルパスの取得向け
  tictoc,      # 処理時間の計測向け
  install = T, # 存在しないパッケージをインストールする
  update = F   # 古いパッケージを更新しない
)

# tictoc::tic.clear() # tic/toc スタックのクリア
tictoc::tic("init") # タイマーの開始

tryCatch({
  # 実行ファイル(init.R)のフルパス
  init_path = rstudioapi::getSourceEditorContext()$path
  # 作業ディレクトリの設定 ------------
  # work_dir_path をローカル環境に合わせて適宜書き換えてください: 
  work_dir_path = init_path |> dirname()
  work_dir_path |> setwd()
  getwd() |> print() #> "your_directory_path/work"
  cat("\n")
  # 各スクリプトの実行
  safe_source("env_setup.R")
  safe_source("functions.R")
  safe_source("data_setup.R")
}, 
error = function(e) {
  message(e$message)
  message("処理を中断します.")
}, 
finally = {
  tictoc::toc() # 経過時間の出力
})

#-------------------------------------------------------------------------------
