# coppock_hill_vavreck_2020/maintained/clean_vote_choice_sates.R
# Output: output/vote_choice_sates.rds
# Depends on: original/exps.rds, original/ad_df.csv, helpers.R
# Description: Weekly sample average treatment effects on general election vote intention.

source(here::here("maintained", "helpers.R"))

exps  <- read_rds(here::here("original", "exps.rds"))
ad_df <- read_csv(here::here("original", "ad_df.csv"), show_col_types = FALSE)

# Vote intention was only asked once the general election matchup was set ----
general_exps <- exps |> filter(election_phase == "General Election")

ates <-
  bind_rows(
    estimate_ad_effects(general_exps, "general_vote_HC"),
    estimate_ad_effects(general_exps, "general_vote_DT")
  ) |>
  filter(str_detect(term, "ad_id_fac")) |>
  mutate(ad_id = as.numeric(str_remove(term, "ad_id_fac"))) |>
  left_join(ad_df, by = "ad_id") |>
  mutate(
    target_candidate = (
      outcome == "general_vote_DT" & ad_valence %in% c("Pro Trump", "Anti Trump") |
      outcome == "general_vote_HC" & ad_valence %in% c("Pro Clinton", "Anti Clinton")
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
# Negating an interval reverses it, so the two bounds change places. The archive
# negates each bound where it stands; they are swapped here so the column names
# stay true. See clean_favorability_sates.R for why nothing published moves.
vote_choice_sates <-
  ates |>
  filter(target_candidate) |>
  mutate(
    flipped_low  = if_else(attack == 1, conf.high * -1, conf.low),
    flipped_high = if_else(attack == 1, conf.low * -1, conf.high),
    estimate     = if_else(attack == 1, estimate * -1, estimate),
    conf.low     = flipped_low,
    conf.high    = flipped_high
  ) |>
  select(-flipped_low, -flipped_high)

write_rds(vote_choice_sates, here::here("maintained", "output", "vote_choice_sates.rds"))
