# coppock_hill_vavreck_2020/maintained/clean_favorability_sates.R
# Output: output/favorability_sates.rds
# Depends on: original/exps.rds, original/ad_df.csv, helpers.R
# Description: Weekly sample average treatment effects on target candidate favorability.

source(here::here("maintained", "helpers.R"))

exps  <- read_rds(here::here("original", "exps.rds"))
ad_df <- read_csv(here::here("original", "ad_df.csv"), show_col_types = FALSE)

ates <-
  bind_rows(
    estimate_ad_effects(exps, "favorDT_rev"),
    estimate_ad_effects(exps, "favorHC_rev"),
    estimate_ad_effects(exps, "favorBS_rev"),
    estimate_ad_effects(exps, "favorJK_rev"),
    estimate_ad_effects(exps, "favorTC_rev")
  ) |>
  filter(str_detect(term, "ad_id_fac")) |>
  mutate(ad_id = as.numeric(str_remove(term, "ad_id_fac"))) |>
  left_join(ad_df, by = "ad_id") |>
  mutate(
    target_candidate = (
      outcome == "favorDT_rev" & ad_valence %in% c("Pro Trump", "Anti Trump") |
      outcome == "favorHC_rev" & ad_valence %in% c("Pro Clinton", "Anti Clinton") |
      outcome == "favorBS_rev" & ad_valence %in% c("Pro Sanders", "Anti Sanders") |
      outcome == "favorJK_rev" & ad_valence %in% c("Pro Kasich", "Anti Kasich") |
      outcome == "favorTC_rev" & ad_valence %in% c("Pro Cruz", "Anti Cruz")
    ),
    attack       = as.numeric(str_detect(ad_valence, "Anti")),
    general      = as.numeric(date > as.Date("2016-06-10")),
    date_numeric = as.numeric(date) / 365.25,
    pac          = if_else(ad_sponsor %in% c("clinton", "cruz", "sanders", "trump"), 0, 1),
    attack_d     = attack - mean(attack),
    general_d    = general - mean(general),
    pac_d        = pac - mean(pac),
    date_d       = date_numeric - mean(date_numeric),
    attack_general_d = attack_d * general_d - mean(attack_d * general_d),
    attack_date_d    = attack_d * date_d - mean(attack_d * date_d)
  )

# The sign flip happens after the moderators are demeaned, as in the archive ----
# Higher values mean the advertisement worked: promotional advertisements raise the
# favorability of their target and attack advertisements lower it. Negating an
# interval reverses it, so the two bounds change places. The archive negates each
# bound where it stands, leaving conf.low holding the upper end for every attack
# advertisement; the bounds are swapped here so the column names stay true. Nothing
# published depends on it, because every pooled quantity is built from the estimate
# and its standard error and a line range is drawn the same way either way.
favorability_sates <-
  ates |>
  filter(target_candidate) |>
  mutate(
    flipped_low  = if_else(attack == 1, conf.high * -1, conf.low),
    flipped_high = if_else(attack == 1, conf.low * -1, conf.high),
    estimate     = if_else(attack == 1, estimate * -1, estimate),
    conf.low     = flipped_low,
    conf.high    = flipped_high,
    date_group   = as.numeric(as.factor(date))
  ) |>
  select(-flipped_low, -flipped_high)

write_rds(favorability_sates, here::here("maintained", "output", "favorability_sates.rds"))
