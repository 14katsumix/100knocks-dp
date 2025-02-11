#===============================================================================
# 関数の定義
#===============================================================================

# my_path_join ------------
# パスを作成する
# .dir, .subdir: 無効にする場合は NULL を設定する
my_path_join = function(..., .dir = getwd(), .subdir = "data") {
  c(.dir, .subdir, ...) %>% 
    fs::path_join() %>% 
    fs::path_norm()
}

# my_show_query ------------
# dplyr::show_query のラッパー
# e: FALSE の場合は query をそのまま返す
my_show_query = function(
    query, e = TRUE, 
    cte = TRUE, 
    qualify_all_columns = FALSE, 
    use_star = TRUE, 
    sql_op = 
      dbplyr::sql_options(
        cte = cte, 
        qualify_all_columns = qualify_all_columns, 
        use_star = use_star
      )
  ) {
  if (e) {
    query %>% dplyr::show_query(sql_options = sql_op)
  } else {
    query
  }
}

# my_sql_render ------------
# dbplyr::sql_render のラッパー
# デフォルトでは, バッククォート(`)を削除する. 
my_sql_render = function(
    query, con = NULL, 
    cte = T, 
    qualify_all_columns = T, 
    use_star = T, 
    sql_op = 
      dbplyr::sql_options(
        cte = cte, 
        use_star = use_star, 
        qualify_all_columns = qualify_all_columns
      ), 
    subquery = FALSE, lvl = 0, 
    pattern = "`", replacement = ""
  ) {
  s = 
    query %>% 
    dbplyr::sql_render(
      con = con, sql_options = sql_op, subquery = subquery, lvl = lvl
    )
  if (!is.null(pattern)) {
    s %<>% gsub(pattern, replacement, .)
  }
  s
}

# my_select ------------
# dbx::dbxSelect のラッパー
my_select = function(
    statement, con, convert_tibble = TRUE, params = NULL
  ) {
  d = dbx::dbxSelect(conn = con, statement = statement, params = params)
  if (convert_tibble) d %<>% tibble::as_tibble()
  d
}

# my_tbl ------------
# データフレームをDBに書き込み, テーブル参照を取得する.
# con:        DB接続オブジェクト(DBIオブジェクト).
# df:         DBに書き込むデータフレーム.
# name:       テーブル名. デフォルトでは df の名前を使用.
# rm_pattern: nameからマッチしたパターンを削除する.(無効にする場合は NULL or "^$")
# print_list: DBに作成済みのテーブルリストを表示するか否か.
# row_names:  行名をテーブルに含めるか否か.
# overwrite:  テーブルが既に存在する場合に上書きするか否か.
# append:     テーブルにデータを追加するか否か.
my_tbl = function(
    con, df, 
    name = deparse(substitute(df)), 
    rm_pattern = "^df_", 
    overwrite = FALSE, append = FALSE, row_names = FALSE, 
    field_types = NULL, temporary = FALSE
  ) {
  # name からマッチしたパターンを削除する
  if (!is.null(rm_pattern))
    name %<>% stringr::str_remove(pattern = rm_pattern)
  # データフレームをDBに書き込む
  DBI::dbWriteTable(
    conn = con, name = name, value = df, 
    overwrite = overwrite, append = append, row.names = row_names, 
    field.types = field_types, temporary = temporary
  )
  sprintf("table name = %s\n", name) %>% cat()
  # テーブル参照を取得する
  con %>% dplyr::tbl(name)
}

# my_with_seed ------------
# withr::with_seed のラッパー
my_with_seed = function(
    code, seed, 
    .rng_kind = NULL, 
    .rng_normal_kind = NULL, 
    .rng_sample_kind = NULL
  ) {
  withr::with_seed(
    seed = seed, code = code, 
    .rng_kind = .rng_kind, 
    .rng_normal_kind = .rng_normal_kind, 
    .rng_sample_kind = .rng_sample_kind
  )
}

#-------------------------------------------------------------------------------


# my_collect ------------
# dplyr::collect のラッパー
# e: FALSE の場合は x をそのまま返す
my_collect = function(x, e = TRUE, ...) {
  if (e) dplyr::collect(x = x, ...) else x
}
