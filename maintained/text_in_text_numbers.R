# coppock_hill_vavreck_2020/maintained/text_in_text_numbers.R
# Output: output/text_in_text_numbers.csv
# Depends on: original/exps.rds, original/exps_with_incompletes.rds,
#             output/favorability_sates.rds, helpers.R
# Description: Every in-text quantity in the article and appendix that is not a cell of
#   a table or a point on a figure: design counts, the manipulation check and attrition.

source(here::here("maintained", "helpers.R"))

exps     <- read_rds(here::here("original", "exps.rds"))
exps_inc <- read_rds(here::here("original", "exps_with_incompletes.rds"))

# Design counts ----
# ad_id 3 is the placebo car insurance advertisement, not a campaign advertisement.
deployments <-
  exps |>
  filter(!is.na(ad_id), ad_id != 3) |>
  distinct(ad_id, ad_title, ad_valence, date)

unique_ads <- distinct(deployments, ad_id, ad_title, ad_valence)

repeat_ads <- deployments |> count(ad_id, ad_title) |> filter(n > 1)

# Completed responses per week, and the span of the fielding period ----
weekly_n <- count(exps, date)

design_claims <- tibble(
  claim = c("n_respondents", "n_weeks", "n_unique_ads", "n_ad_week_deployments",
            "n_ads_fielded_more_than_once", "weekly_n_min", "weekly_n_max",
            "months_spanned"),
  value = c(nrow(exps), n_distinct(exps$date), nrow(unique_ads),
            nrow(deployments), nrow(repeat_ads), min(weekly_n$n), max(weekly_n$n),
            as.numeric(diff(range(exps$date))) / 30.4375)
)

valence_claims <-
  bind_rows(
    count(unique_ads, ad_valence) |> mutate(claim = paste0("n_unique_ads_", ad_valence)),
    count(deployments, ad_valence) |> mutate(claim = paste0("n_deployments_", ad_valence))
  ) |>
  transmute(claim = str_replace_all(str_to_lower(claim), " ", "_"), value = n)

# Manipulation check ----
# Asked from wave 21 onward. The claim is a range across weeks, so the minimum and
# maximum are what the text asserts, not any single week.
manip_by_wave <-
  exps |>
  filter(wave >= 21) |>
  mutate(
    campaign_video = as.numeric(manip == 2),
    any_treat      = as.numeric(assignment != "Control")
  ) |>
  group_by(any_treat, wave) |>
  summarise(pct_campaign_video = mean(campaign_video, na.rm = TRUE), .groups = "drop")

manip_claims <-
  manip_by_wave |>
  group_by(any_treat) |>
  summarise(min = min(pct_campaign_video), max = max(pct_campaign_video), .groups = "drop") |>
  pivot_longer(c(min, max), names_to = "bound", values_to = "value") |>
  transmute(
    claim = paste0("manip_check_", if_else(any_treat == 1, "treated", "control"), "_", bound),
    value
  )

# Attrition ----
# A respondent who did not finish has no post-stratification weight.
exps_inc <- exps_inc |> mutate(complete = as.numeric(!is.na(weights)))

p_values <-
  exps_inc |>
  split(exps_inc$wave) |>
  map_dbl(\(d) stats::chisq.test(table(d$complete, d$Z))$p.value)

attrition_claims <- tibble(
  claim = c("attrition_rate", "n_attrition_tests", "n_sig_unadjusted",
            "n_sig_holm", "n_sig_benjamini_hochberg"),
  value = c(mean(exps_inc$complete == 0), length(p_values),
            sum(p_values <= 0.05),
            sum(p.adjust(p_values, method = "holm") <= 0.05),
            sum(p.adjust(p_values, method = "BH") <= 0.05))
)

results <- bind_rows(design_claims, valence_claims, manip_claims, attrition_claims)

print(results, n = nrow(results))

write_csv(results, here::here("maintained", "output", "text_in_text_numbers.csv"))
