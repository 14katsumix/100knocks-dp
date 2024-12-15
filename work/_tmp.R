vars = c("store_cd", "product_cd", "xxx")
vars = c("store_cd", "product_cd")
tbl_receipt %>% 
  count(pick(!!vars), wt = amount, name = "sum") %>% 
  # count(across(!!vars), wt = amount, name = "sum") %>% 
  arrange(across(!!vars)) %>% my_show_query(F)

vars = c("store_cd", "product_cd")
vars = c("store_cd", "product_cd", "xxx")
tbl_receipt %>% 
  summarise(sum = sum(amount), .by = !!vars) %>% 
  # arrange(across(!!vars)) %>% 
  arrange(!!vars) %>% 
  filter()
  my_show_query(F)


pacman::p_load(skimr)

tbl_product %>% skimr::skim()
tbl_geocode %>% skimr::skim()
# tbl_store %>% skimr::skim()
# tbl_receipt %>% skimr::skim()
# tbl_customer %>% skimr::skim()
# tbl_category %>% skimr::skim()

# df_geocode %>% dim()
# df_geocode %>% 
tbl_geocode %>% 
  select(town, street, address) %>% 
  # filter(!is.na(town)) %>% 
  # filter(!is.na(street)) %>% 
  # filter(!is.na(address)) %>% 
  # filter(!complete.cases(pick(everything()))) %>% 
  filter(if_any(c(town, address), is.na)) %>% 
  # filter(if_any(pick(town, address), is.na)) %>% 
  # my_collect() %>% 
  my_show_query()

#-------------------------------------------------------------------------------
