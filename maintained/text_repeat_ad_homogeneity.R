# coppock_hill_vavreck_2020/maintained/text_repeat_ad_homogeneity.R
# Output: output/text_repeat_ad_homogeneity.csv
# Depends on: output/figure_s1_repeat_ads.csv, helpers.R
# Description: Appendix section B claims that an advertisement's effect does not vary
#   significantly with the week it was fielded. Figure S1 plots the weekly estimates
#   and prints no test, so the test is fitted here: one Q test of effect homogeneity
#   across weeks for each of the seven advertisements shown more than once.

source(here::here("maintained", "helpers.R"))

repeat_ads <- read_csv(here::here("maintained", "output", "figure_s1_repeat_ads.csv"),
                       show_col_types = FALSE)

homogeneity <-
  repeat_ads |>
  group_by(ad_id, ad_title, ad_valence, outcome) |>
  reframe(pool_effects(estimate, std.error, method = "DL")) |>
  left_join(count(repeat_ads, ad_id, name = "n_weeks"), by = "ad_id") |>
  select(ad_id, ad_title, ad_valence, outcome, n_weeks, estimate, std.error, p.value,
         tau2, tau) |>
  arrange(ad_id)

print(homogeneity)

write_csv(homogeneity,
          here::here("maintained", "output", "text_repeat_ad_homogeneity.csv"))
