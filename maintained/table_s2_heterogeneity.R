# coppock_hill_vavreck_2020/maintained/table_s2_heterogeneity.R
# Output: output/table_s2_heterogeneity.csv, output/table_s2_heterogeneity.tex
# Depends on: the four cleaned estimate files in output/, helpers.R
# Description: Table S2: pooled estimates and heterogeneity diagnostics for the SATEs
#   and CATEs on both dependent variables.

source(here::here("maintained", "helpers.R"))

favorability_sates <- read_rds(here::here("maintained", "output", "favorability_sates.rds"))
vote_choice_sates  <- read_rds(here::here("maintained", "output", "vote_choice_sates.rds"))
favorability_cates <- read_rds(here::here("maintained", "output", "favorability_cates.rds"))
vote_choice_cates  <- read_rds(here::here("maintained", "output", "vote_choice_cates.rds"))

meta_df <-
  bind_rows(
    sates = favorability_sates,
    sates = vote_choice_sates,
    cates = favorability_cates,
    cates = vote_choice_cates,
    .id = "estimand"
  ) |>
  mutate(dv = if_else(str_detect(outcome, "favor"), "Favorability", "Vote Choice"))

# The published table uses DerSimonian-Laird ----
# REML is reported beside it because the choice of between-study variance estimator
# is not something the published table makes visible, and it moves the estimates.
pooled <-
  bind_rows(
    meta_df |>
      group_by(estimand, dv) |>
      reframe(pool_effects(estimate, std.error, method = "DL")) |>
      mutate(method = "DL (published)"),
    meta_df |>
      group_by(estimand, dv) |>
      reframe(pool_effects(estimate, std.error, method = "REML")) |>
      mutate(method = "REML (added here)")
  ) |>
  left_join(count(meta_df, estimand, dv, name = "k"), by = c("estimand", "dv")) |>
  arrange(desc(estimand), dv, method) |>
  relocate(method, k, .after = dv)

write_csv(pooled, here::here("maintained", "output", "table_s2_heterogeneity.csv"))

display <-
  pooled |>
  filter(method == "DL (published)") |>
  transmute(
    Estimand            = estimand,
    `Outcome Variable`  = dv,
    `Estimate (SE)`     = make_se_entry(estimate, std.error, digits = 4),
    `p-value`           = sprintf("%.4f", p.value),
    `tau^2`             = sprintf("%.4f", tau2),
    `tau`               = sprintf("%.4f", tau)
  )

print(pooled)

tex <-
  display |>
  kable(format = "latex", booktabs = TRUE,
        caption = "Analysis of heterogeneity across the estimated effects") |>
  kable_styling(latex_options = "hold_position")

write_lines(tex, here::here("maintained", "output", "table_s2_heterogeneity.tex"))
