# coppock_hill_vavreck_2020/maintained/clean_favorability_cates.R
# Output: output/favorability_cates.rds
# Depends on: original/exps.rds, original/ad_df.csv, helpers.R
# Description: Weekly favorability effects within partisanship by battleground subgroups.

source(here::here("maintained", "helpers.R"))

exps  <- read_rds(here::here("original", "exps.rds"))
ad_df <- read_csv(here::here("original", "ad_df.csv"), show_col_types = FALSE)

# Some subgroup by week cells have a collinear design matrix, for instance when only
# one advertisement valence was fielded in a battleground subgroup that week.
# lm_robust drops the rank-deficient coefficient and says so; that is expected here.
cates <-
  bind_rows(
    exps |> group_by(pid_3_pre, battleground) |> reframe(estimate_ad_effects(pick(everything()), "favorDT_rev")),
    exps |> group_by(pid_3_pre, battleground) |> reframe(estimate_ad_effects(pick(everything()), "favorHC_rev")),
    exps |> group_by(pid_3_pre, battleground) |> reframe(estimate_ad_effects(pick(everything()), "favorBS_rev")),
    exps |> group_by(pid_3_pre, battleground) |> reframe(estimate_ad_effects(pick(everything()), "favorJK_rev")),
    exps |> group_by(pid_3_pre, battleground) |> reframe(estimate_ad_effects(pick(everything()), "favorTC_rev"))
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
    attacking_candidate = (
      outcome == "favorDT_rev" & ad_valence %in% c("Anti Clinton") |
      outcome == "favorHC_rev" & ad_valence %in% c("Anti Trump")
    ),
    estimate_type = case_when(
      target_candidate    ~ "target_candidate",
      attacking_candidate ~ "attacking_candidate",
      TRUE                ~ NA_character_
    ),
    attack       = as.numeric(str_detect(ad_valence, "Anti")),
    general      = as.numeric(date > as.Date("2016-06-10")),
    pro_clinton  = as.numeric(ad_valence == "Pro Clinton"),
    pro_sanders  = as.numeric(ad_valence == "Pro Sanders"),
    pro_cruz     = as.numeric(ad_valence == "Pro Cruz"),
    pro_kasich   = as.numeric(ad_valence == "Pro Kasich"),
    pro_trump    = as.numeric(ad_valence == "Pro Trump"),
    anti_clinton = as.numeric(ad_valence == "Anti Clinton"),
    anti_trump   = as.numeric(ad_valence == "Anti Trump"),
    date_numeric = as.numeric(date) / 31,
    pac          = if_else(ad_sponsor %in% c("clinton", "cruz", "sanders", "trump"), 0, 1),
    pro_democrat   = as.numeric(ad_valence %in% c("Anti Trump", "Pro Clinton", "Pro Sanders")),
    pro_republican = as.numeric(ad_valence %in% c("Pro Cruz", "Pro Kasich", "Pro Trump", "Anti Clinton")),
    democrat    = as.numeric(pid_3_pre == "Democrat"),
    republican  = as.numeric(pid_3_pre == "Republican"),
    independent = as.numeric(pid_3_pre == "Independent"),
    attack_d    = attack - mean(attack),
    general_d   = general - mean(general),
    pac_d       = pac - mean(pac),
    date_d      = date_numeric - mean(date_numeric),
    attack_general_d = attack_d * general_d - mean(attack_d * general_d),
    attack_date_d    = attack_d * date_d - mean(attack_d * date_d),
    pro_clinton_d  = pro_clinton  - mean(pro_clinton),
    pro_sanders_d  = pro_sanders  - mean(pro_sanders),
    pro_trump_d    = pro_trump    - mean(pro_trump),
    pro_cruz_d     = pro_cruz     - mean(pro_cruz),
    pro_kasich_d   = pro_kasich   - mean(pro_kasich),
    anti_clinton_d = anti_clinton - mean(anti_clinton),
    anti_trump_d   = anti_trump   - mean(anti_trump),
    pro_democrat_d   = pro_democrat   - mean(pro_democrat),
    pro_republican_d = pro_republican - mean(pro_republican),
    democrat_d     = democrat    - mean(democrat),
    republican_d   = republican  - mean(republican),
    independent_d  = independent - mean(independent),
    battleground_d = battleground - mean(battleground),
    ad_match = case_when(
      democrat == 1    & pro_democrat == 1   ~ "Democratic respondents, pro-Democratic ad",
      democrat == 1    & pro_republican == 1 ~ "Democratic respondents, pro-Republican ad",
      independent == 1 & pro_democrat == 1   ~ "Independent respondents, pro-Democratic ad",
      independent == 1 & pro_republican == 1 ~ "Independent respondents, pro-Republican ad",
      republican == 1  & pro_democrat == 1   ~ "Republican respondents, pro-Democratic ad",
      republican == 1  & pro_republican == 1 ~ "Republican respondents, pro-Republican ad"
    )
  )

# The sign flip happens after the moderators are demeaned, as in the archive ----
# Negating an interval reverses it, so the two bounds change places. The archive
# negates each bound where it stands; they are swapped here so the column names
# stay true. See clean_favorability_sates.R for why nothing published moves.
favorability_cates <-
  cates |>
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

write_rds(favorability_cates, here::here("maintained", "output", "favorability_cates.rds"))
