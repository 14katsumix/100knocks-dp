df <- tibble(
  customer_id = 1:10,
  n_date = c(5, 3, 8, 6, 8, 4, 5, 7, 7, 9)
)

df %>% slice_max(n_date, n = 2, with_ties = TRUE)
df %>% slice_max(n_date, n = 4, with_ties = TRUE)
df %>% slice_max(n_date, n = 4, with_ties = FALSE)
