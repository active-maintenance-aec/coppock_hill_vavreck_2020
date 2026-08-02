# coppock_hill_vavreck_2020/maintained/table_s1_ad_list.R
# Output: output/table_s1_ad_list.csv, output/table_s1_ad_list.tex
# Depends on: original/exps.rds, helpers.R
# Description: Table S1: the treatment advertisements fielded in each week.

source(here::here("maintained", "helpers.R"))

exps <- read_rds(here::here("original", "exps.rds"))

# assignment carries the advertisement's valence label ("Anti Trump", "Pro Clinton").
# Control and the two-advertisement arm are not treatment advertisements of their own.
ad_table <-
  exps |>
  mutate(
    date_formatted = format(date, format = "%B %d"),
    date_formatted = fct_reorder(factor(date_formatted), date)
  ) |>
  filter(!assignment %in% c("Control", "Two Ads")) |>
  distinct(date_formatted, ad_title, assignment) |>
  arrange(date_formatted, ad_title, assignment) |>
  group_by(date_formatted) |>
  mutate(ad_num = paste0("Ad ", seq_len(n()))) |>
  ungroup() |>
  transmute(
    date_formatted,
    ad_num,
    entry = paste0(assignment, ': "', ad_title, '"')
  ) |>
  pivot_wider(names_from = ad_num, values_from = entry)

write_csv(ad_table, here::here("maintained", "output", "table_s1_ad_list.csv"))

tex <-
  ad_table |>
  rename(Week = date_formatted) |>
  mutate(across(everything(), \(x) replace_na(as.character(x), ""))) |>
  kable(format = "latex", booktabs = TRUE, caption = "Treatment ads by week") |>
  kable_styling(latex_options = c("hold_position", "scale_down"))

write_lines(tex, here::here("maintained", "output", "table_s1_ad_list.tex"))
