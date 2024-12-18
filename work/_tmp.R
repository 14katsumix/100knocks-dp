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

# tbl_lazy()
d1 = df_receipt |> tbl_lazy(con = simulate_mysql(), name = "receipt")
d2 = df_store |> tbl_lazy(con = simulate_mysql(), name = "store")
d1 = df_receipt |> tbl_lazy(con = simulate_postgres(), name = "receipt")
d1 = df_receipt |> tbl_lazy(con = simulate_duckdb(), name = "receipt")

d1 = df_receipt |> tbl_lazy(con = simulate_mysql(), name = "receipt")
d2 = df_store |> tbl_lazy(con = simulate_mysql(), name = "store")
vars = c("store_cd", "product_cd")
d1 %>% 
  count(pick(!!vars), wt = amount, name = "sum") %>% 
  # count(across(!!vars), wt = amount, name = "sum") %>% 
  # inner_join(tbl_store, by = "store_cd") %>% 
  inner_join(d2, by = "store_cd") %>% 
  arrange(across(!!vars)) %>% 
  remote_query()
  # my_show_query()


