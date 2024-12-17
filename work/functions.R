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
    cte = TRUE, qualify_all_columns = FALSE, use_star = TRUE, 
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

# my_select ------------
# dbx::dbxSelect のラッパー
my_select = function(statement, conn, convert_tibble = TRUE, params = NULL) {
  d = dbx::dbxSelect(conn = conn, statement = statement, params = params)
  if (convert_tibble) d %<>% tibble::as_tibble()
  d
}

# my_collect ------------
# dplyr::collect のラッパー
# e: FALSE の場合は x をそのまま返す
my_collect = function(x, e = TRUE, ...) {
  if (e) dplyr::collect(x = x, ...) else x
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
    print_list = FALSE, 
    print_tbl = TRUE, 
    row_names = FALSE, overwrite = TRUE, append = FALSE
  ) {
  # name からマッチしたパターンを削除する
  if (!is.null(rm_pattern))
    name %<>% stringr::str_remove(pattern = rm_pattern)
  # データフレームをDBに書き込む
  DBI::dbWriteTable(
    conn = con, name = name, value = df, 
    row_names = row_names, overwrite = overwrite, append = append
  )
  # テーブル参照を取得する
  t = con %>% dplyr::tbl(name)
  # テーブルリストを表示する
  if (print_list) DBI::dbListTables(con) %>% print(); cat("\n")
  if (print_tbl) t %>% glimpse()
  t
}

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
is.not.null = function(x) { return(!is.null(x)) }

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
