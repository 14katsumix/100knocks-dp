vars = c("store_cd", "product_cd", "xxx")
vars = c("store_cd", "product_cd")
tbl_receipt %>% 
  count(pick(!!vars), wt = amount, name = "sum") %>% 
  # count(across(!!vars), wt = amount, name = "sum") %>% 
  arrange(across(!!vars)) %>% 
  my_show_query()

vars = c("store_cd", "product_cd")
vars = c("store_cd", "product_cd", "xxx")
tbl_receipt %>% 
  summarise(sum = sum(amount), .by = !!vars) %>% 
  # arrange(across(!!vars)) %>% 
  arrange(!!vars) %>% 
  my_show_query(F)


pacman::p_load(skimr)

tbl_product %>% skimr::skim()
tbl_geocode %>% skimr::skim()
# tbl_store %>% skimr::skim()
# tbl_receipt %>% skimr::skim()
# tbl_customer %>% skimr::skim()
# tbl_category %>% skimr::skim()

#-------------------------------------------------------------------------------

vars = c("store_cd", "product_cd")
tbl_receipt %>% 
  count(pick(!!vars), wt = amount, name = "sum") %>% 
  # count(across(!!vars), wt = amount, name = "sum") %>% 
  inner_join(tbl_store, by = "store_cd") %>% 
  arrange(across(!!vars)) %>% 
  my_show_query(F)

#-------------------------------------------------------------------------------

df_receipt$sales_epoch[1:10]/(24*60*60.0)
df_receipt %>% mutate(dt = as.POSIXct(sales_epoch, tz = "UTC")) %>% select(sales_ymd, dt)
tsql_receipt %>% mutate(dt = as.POSIXct(sales_epoch)) %>% select(sales_ymd, dt)
tsql_receipt %>% mutate(dt = as.POSIXlt(sales_epoch)) %>% select(sales_ymd, dt)
df_receipt %>% mutate(dt = as_datetime(sales_epoch)) %>% select(sales_ymd, dt)
tsql_receipt %>% mutate(dt = as_datetime(sales_epoch)) %>% select(sales_ymd, dt)

tsql_receipt %>% mutate(dt = sql("to_timestamp(sales_epoch)")) %>% select(sales_ymd, dt)

q = sql("
select sales_ymd, to_timestamp(sales_epoch)
from receipt
"
)
q %>% my_select(con)

#-------------------------------------------------------------------------------

vignette("translation-function", package = "dbplyr")

特別なフォーム
SQL 関数は、R よりも構文の種類が豊富になる傾向があります。つまり、R コードから直接変換できない式が多数あります。これらを独自のクエリに挿入するには、次のようにリテラル SQL を使用しますsql()。

translate_sql(sql("x!"), con = con)
#> <SQL> x!

mf %>% 
  transmute(factorial = sql("x!")) %>% 
  show_query()
#> <SQL>
#> SELECT x! AS `factorial`
#> FROM `dbplyr_zAmugrm8vk`

db_product %>% select(product_cd, unit_cost) %>% 
  mutate(u = cut(unit_cost, breaks = c(-Inf, 200, 400, Inf), labels = c("a", "b", "c")))

ls()

db_store %>% head(5)
