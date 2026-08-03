# coppock_hill_vavreck_2020/maintained/text_descriptive_claims.R
# Output: output/text_descriptive_claims.csv
# Depends on: output/figure_1_sate_time_series.csv, output/figure_2_cate_partisan_match.csv,
#             output/table_1_meta_regression.csv, output/table_s2_heterogeneity.csv,
#             output/figure_s1_repeat_ads.csv, output/text_repeat_ad_homogeneity.csv,
#             helpers.R
# Description: The article's claims about the shape, sign, count and significance of its
#   own estimates. These are sentences a number-by-number comparison never reaches,
#   because most of them print no number at all, and they are where a description can go
#   on standing after the estimates beside it have moved.
#
#   Two kinds. A claim that reduces to a verdict gets one: "negative in three of four
#   specifications" is a count, "not statistically significant" is a test result. A claim
#   that does not reduce gets its evidence and no verdict: "excludes large persuasive
#   effects", "approximately the same" and "appears to increase in size" name no
#   threshold, and inventing one would put a number in the article's mouth.
#
#   Nothing is estimated here. Every model in this pipeline is fitted by the script that
#   owns its output, and this one reads those outputs and derives.

source(here::here("maintained", "helpers.R"))

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

figure_1    <- out("figure_1_sate_time_series.csv")
figure_2    <- out("figure_2_cate_partisan_match.csv")
figure_s1   <- out("figure_s1_repeat_ads.csv")
table_1     <- out("table_1_meta_regression.csv")
table_s2    <- out("table_s2_heterogeneity.csv")
repeat_homogeneity <- out("text_repeat_ad_homogeneity.csv")

# One cell of Table 1, selected by the row and column that name it ----
t1 <- function(model_label, term_label, column) {
  value <- table_1[[column]][table_1$model == model_label & table_1$term == term_label]
  stopifnot(length(value) == 1, !is.na(value))
  value
}

# One point of Figure 2, selected the same way ----
f2 <- function(dv, pid, ad, column) {
  value <- figure_2[[column]][figure_2$outcome_variable == dv &
                                figure_2$respondent_pid == pid &
                                figure_2$ad_type == ad]
  stopifnot(length(value) == 1, !is.na(value))
  value
}

models <- c("Candidate favorability (1)", "Candidate favorability (2)",
            "Vote choice (3)", "Vote choice (4)")

weekly <- figure_1 |> filter(est_type == "Weekly estimates")
meta   <- figure_1 |> filter(est_type == "Meta-analysis")

# A weekly estimate is statistically significant when its interval excludes zero.
weekly <- weekly |> mutate(significant = conf.low > 0 | conf.high < 0)

# The spread of the weekly estimates ----
weekly_range <-
  weekly |>
  group_by(dv) |>
  summarise(min = min(estimate), max = max(estimate), .groups = "drop")

# The statistically significant weekly favorability estimates ----
significant_favorability <- weekly |> filter(dv == "Favorability", significant)

may_negative <-
  significant_favorability |>
  filter(month(date) == 5) |>
  slice_min(estimate, n = 1)

october_positive <-
  significant_favorability |>
  filter(month(date) == 10) |>
  slice_max(estimate, n = 1)

october_other_negative <-
  significant_favorability |>
  filter(month(date) == 10, estimate < 0)

# The partisanship coefficients of Table 1 ----
partisanship <-
  table_1 |>
  filter(term %in% c("democrat_d", "independent_d")) |>
  mutate(se_exceeds_coefficient = std.error > abs(estimate))

time_slope <- table_1 |> filter(term == "date_d")

tone_and_sponsor <- table_1 |> filter(term %in% c("attack_d", "pac_d"))

target_candidate <-
  table_1 |>
  filter(str_detect(term, "^pro_|^anti_"), term != "pro_democrat_d")

# The four homogeneity tests the appendix reports ----
homogeneity_tests <- table_s2 |> filter(method == "DL (published)")

quotes_by_week <- figure_s1 |> filter(ad_title == "Quotes") |> arrange(date)

# Assemble ----
# computed carries the pipeline's counterpart to the sentence. holds is the verdict
# where the sentence reduces to one and NA where it does not. evidence is the
# distribution the reader needs in order to judge the ones that do not reduce.
descriptive <- tribble(
  ~claim_id, ~claim, ~computed, ~holds, ~evidence,

  "desc_effects_exclude_large",
  "Weekly estimates exclude large persuasive effects",
  NA_real_, NA_real_,
  str_glue("Weekly SATEs run from {sprintf('%.3f', weekly_range$min[weekly_range$dv == 'Favorability'])} to ",
           "{sprintf('%.3f', weekly_range$max[weekly_range$dv == 'Favorability'])} on the five-point favorability scale ",
           "and from {sprintf('%.3f', weekly_range$min[weekly_range$dv == 'Vote Choice'])} to ",
           "{sprintf('%.3f', weekly_range$max[weekly_range$dv == 'Vote Choice'])} on vote choice"),

  "desc_fav_meta_significant",
  "The pooled favorability effect is statistically significant",
  NA_real_,
  as.numeric(meta$conf.low[meta$dv == "Favorability"] > 0),
  str_glue("Pooled favorability effect {sprintf('%.4f', meta$estimate[meta$dv == 'Favorability'])} ",
           "with a 95 per cent interval of [{sprintf('%.4f', meta$conf.low[meta$dv == 'Favorability'])}, ",
           "{sprintf('%.4f', meta$conf.high[meta$dv == 'Favorability'])}]"),

  "desc_vc_meta_not_significant",
  "The pooled vote choice effect is not statistically significant",
  NA_real_,
  as.numeric(meta$conf.low[meta$dv == "Vote Choice"] <= 0 &
               meta$conf.high[meta$dv == "Vote Choice"] >= 0),
  str_glue("Pooled vote choice effect {sprintf('%.4f', meta$estimate[meta$dv == 'Vote Choice'])} ",
           "with a 95 per cent interval of [{sprintf('%.4f', meta$conf.low[meta$dv == 'Vote Choice'])}, ",
           "{sprintf('%.4f', meta$conf.high[meta$dv == 'Vote Choice'])}]"),

  "desc_large_negative_early_may",
  "Largest significant negative favorability estimate in May",
  may_negative$estimate, NA_real_,
  str_glue("{may_negative$ad_title}, week of {may_negative$date}, ",
           "{sprintf('%.3f', may_negative$estimate)} ",
           "[{sprintf('%.3f', may_negative$conf.low)}, {sprintf('%.3f', may_negative$conf.high)}]"),

  "desc_large_positive_october",
  "Largest significant positive favorability estimate in October",
  october_positive$estimate, NA_real_,
  str_glue("{october_positive$ad_title}, week of {october_positive$date}, ",
           "{sprintf('%.3f', october_positive$estimate)} ",
           "[{sprintf('%.3f', october_positive$conf.low)}, {sprintf('%.3f', october_positive$conf.high)}]. ",
           "The largest favorability estimate anywhere in the study is ",
           "{sprintf('%.3f', weekly_range$max[weekly_range$dv == 'Favorability'])}"),

  "desc_two_other_negative_october",
  "Other significant negative favorability estimates in October",
  nrow(october_other_negative), NA_real_,
  str_c(october_other_negative$ad_title, " (",
        sprintf("%.3f", october_other_negative$estimate), ")", collapse = "; "),

  "desc_partisan_ses_exceed_coefficients",
  "Partisanship cells of Table 1 whose standard error exceeds the coefficient",
  sum(partisanship$se_exceeds_coefficient),
  as.numeric(all(partisanship$se_exceeds_coefficient)),
  str_c(partisanship$model, " ", partisanship$term, ": ",
        sprintf("%.4f", partisanship$estimate), " (",
        sprintf("%.4f", partisanship$std.error), ")", collapse = "; "),

  "desc_independents_not_more_malleable",
  "No partisanship coefficient in Table 1 is distinguishable from zero",
  sum(partisanship$p.value < 0.05),
  as.numeric(all(partisanship$p.value >= 0.05)),
  str_c(partisanship$model, " ", partisanship$term, ": p = ",
        sprintf("%.3f", partisanship$p.value), collapse = "; "),

  "desc_time_slope_negative_count",
  "Specifications in which the time slope is negative",
  sum(time_slope$estimate < 0), NA_real_,
  str_c(time_slope$model, ": ", sprintf("%.4f", time_slope$estimate), collapse = "; "),

  "desc_time_slope_significant_count",
  "Specifications in which the time slope is distinguishable from zero",
  sum(time_slope$p.value < 0.05), NA_real_,
  str_c(time_slope$model, ": p = ", sprintf("%.3f", time_slope$p.value), collapse = "; "),

  "desc_general_election_not_significant",
  "The general election coefficient is not statistically significant",
  NA_real_,
  as.numeric(t1("Candidate favorability (1)", "general_d", "p.value") >= 0.05),
  str_glue("General election coefficient ",
           "{sprintf('%.4f', t1('Candidate favorability (1)', 'general_d', 'estimate'))} ",
           "(p = {sprintf('%.4f', t1('Candidate favorability (1)', 'general_d', 'p.value'))})"),

  "desc_attack_and_pac_not_significant",
  "No tone or sponsor coefficient in Table 1 is distinguishable from zero",
  sum(tone_and_sponsor$p.value < 0.05),
  as.numeric(all(tone_and_sponsor$p.value >= 0.05)),
  str_c(tone_and_sponsor$model, " ", tone_and_sponsor$term, ": p = ",
        sprintf("%.3f", tone_and_sponsor$p.value), collapse = "; "),

  "desc_pro_clinton_more_effective",
  "Target candidate coefficients relative to the omitted pro-Clinton category",
  sum(target_candidate$estimate < 0), NA_real_,
  str_c(target_candidate$model, " ", target_candidate$term, ": ",
        sprintf("%.4f", target_candidate$estimate), collapse = "; "),

  "desc_pro_clinton_differences_not_significant",
  "No target candidate coefficient in Table 1 is distinguishable from zero",
  sum(target_candidate$p.value < 0.05),
  as.numeric(all(target_candidate$p.value >= 0.05)),
  str_c(target_candidate$model, " ", target_candidate$term, ": p = ",
        sprintf("%.3f", target_candidate$p.value), collapse = "; "),

  "desc_partisan_match_democrats",
  "Democratic respondents respond more strongly to pro-Democratic than pro-Republican advertisements",
  NA_real_,
  as.numeric(
    f2("Favorability", "Democratic respondents", "pro-Democratic ad", "estimate") >
      f2("Favorability", "Democratic respondents", "pro-Republican ad", "estimate") &
      f2("Vote choice", "Democratic respondents", "pro-Democratic ad", "estimate") >
      f2("Vote choice", "Democratic respondents", "pro-Republican ad", "estimate")
  ),
  str_glue("Favorability {sprintf('%.3f', f2('Favorability', 'Democratic respondents', 'pro-Democratic ad', 'estimate'))} ",
           "versus {sprintf('%.3f', f2('Favorability', 'Democratic respondents', 'pro-Republican ad', 'estimate'))}; ",
           "vote choice {sprintf('%.3f', f2('Vote choice', 'Democratic respondents', 'pro-Democratic ad', 'estimate'))} ",
           "versus {sprintf('%.3f', f2('Vote choice', 'Democratic respondents', 'pro-Republican ad', 'estimate'))}"),

  "desc_partisan_match_republicans",
  "Republican respondents respond similarly to pro-Democratic and pro-Republican advertisements",
  NA_real_, NA_real_,
  str_glue("Favorability {sprintf('%.3f', f2('Favorability', 'Republican respondents', 'pro-Democratic ad', 'estimate'))} ",
           "versus {sprintf('%.3f', f2('Favorability', 'Republican respondents', 'pro-Republican ad', 'estimate'))}, ",
           "neither distinguishable from zero; vote choice ",
           "{sprintf('%.3f', f2('Vote choice', 'Republican respondents', 'pro-Democratic ad', 'estimate'))} ",
           "versus {sprintf('%.3f', f2('Vote choice', 'Republican respondents', 'pro-Republican ad', 'estimate'))}, ",
           "the second of which is negative. The sentence does not say which outcome it describes"),

  "desc_fail_reject_three_of_four",
  "Homogeneity tests in Table S2 that fail to reject at the 5 per cent level",
  sum(homogeneity_tests$p.value >= 0.05), NA_real_,
  str_c(homogeneity_tests$estimand, " ", homogeneity_tests$dv, ": p = ",
        sprintf("%.4f", homogeneity_tests$p.value), collapse = "; "),

  "desc_repeat_ads_no_significant_variation",
  "Repeat advertisements whose effect varies significantly across weeks",
  sum(repeat_homogeneity$p.value < 0.05),
  as.numeric(all(repeat_homogeneity$p.value >= 0.05)),
  str_c(repeat_homogeneity$ad_title, ": p = ",
        sprintf("%.3f", repeat_homogeneity$p.value), collapse = "; "),

  "desc_repeat_ad_quotes_increases",
  "Weekly estimates for the advertisement Quotes",
  NA_real_, NA_real_,
  str_c(as.character(quotes_by_week$date), ": ",
        sprintf("%.3f", quotes_by_week$estimate), collapse = "; "),

  "desc_table_1_m1_intrcpt_star",
  "Table 1 marks the model 1 average effect as significant at the 5 per cent level",
  NA_real_,
  as.numeric(t1(models[1], "intrcpt", "p.value") < 0.05),
  str_glue("p = {sprintf('%.5f', t1(models[1], 'intrcpt', 'p.value'))}"),

  "desc_table_1_m2_intrcpt_star",
  "Table 1 marks the model 2 average effect as significant at the 5 per cent level",
  NA_real_,
  as.numeric(t1(models[2], "intrcpt", "p.value") < 0.05),
  str_glue("p = {sprintf('%.5f', t1(models[2], 'intrcpt', 'p.value'))}"),

  "desc_table_1_m3_date_d_star",
  "Table 1 marks the model 3 time slope as significant at the 5 per cent level",
  NA_real_,
  as.numeric(t1(models[3], "date_d", "p.value") < 0.05),
  str_glue("p = {sprintf('%.5f', t1(models[3], 'date_d', 'p.value'))}")
) |>
  mutate(evidence = as.character(evidence))

stopifnot(all(nzchar(descriptive$evidence)), !anyDuplicated(descriptive$claim_id))

print(descriptive, n = nrow(descriptive), width = 200)

write_csv(descriptive,
          here::here("maintained", "output", "text_descriptive_claims.csv"))
