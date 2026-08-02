# coppock_hill_vavreck_2020/ground_truth/build_ground_truth.R
# Output: ground_truth/coppock_hill_vavreck_2020_ground_truth.csv
# Depends on: maintained/output/ (run run_all.R first)
# Description: Assemble the ground truth table, one row per quantity the article or its
#   appendix states. Every value_paper below was typed from the published PDF and the
#   published supplementary materials and is used only as a comparison target; no
#   published number is an input to any computation here or anywhere in maintained/.
#   Every value_rewrite is read back out of maintained/output/, so this table cannot
#   drift from the pipeline that produced it.
#
#   value_script is the value the deposited archive produces. It is set equal to
#   value_rewrite, and the warrant for that is generated rather than asserted:
#   maintained/output/text_archive_agreement.csv compares the rewrite's four per-week
#   estimate files against the four the archive deposits, which are the archive's own
#   output for the estimation stage and the input to every published table and figure.
#   The largest disagreement across all four sets is printed at the foot of this script.
#   The design counts, the manipulation check and the attrition tests are read from the
#   same deposited data files with the same filters the archive uses.

library(here)
library(tidyverse)

here::i_am("ground_truth/build_ground_truth.R")

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

text_numbers <- out("text_in_text_numbers.csv")
t1_df        <- out("table_1_meta_regression.csv")
s2_df        <- out("table_s2_heterogeneity.csv")
s1_df        <- out("table_s1_ad_list.csv")
s3_df        <- out("table_s3_design.csv")
f1_df        <- out("figure_1_sate_time_series.csv")
f2_df        <- out("figure_2_cate_partisan_match.csv")
fs1_df       <- out("figure_s1_repeat_ads.csv")
agreement    <- out("text_archive_agreement.csv")

# Accessors, one per output file ----
txt <- function(nm) text_numbers$value[text_numbers$claim == nm]

models <- c(m1 = "Candidate favorability (1)", m2 = "Candidate favorability (2)",
            m3 = "Vote choice (3)",            m4 = "Vote choice (4)")

t1 <- function(m, tm, q) t1_df[[q]][t1_df$model == models[[m]] & t1_df$term == tm]

s2 <- function(estimand, dv, q) {
  s2_df[[q]][s2_df$estimand == estimand & s2_df$dv == dv & s2_df$method == "DL (published)"]
}

f1 <- function(dv, q) f1_df[[q]][f1_df$dv == dv & f1_df$est_type == "Meta-analysis"]

f2 <- function(dv, pid, ad, q) {
  f2_df[[q]][f2_df$outcome_variable == dv & f2_df$respondent_pid == pid & f2_df$ad_type == ad]
}

s3_total <- function(condition) s3_df[[condition]][s3_df$date_formatted == "Total"]

# Abstract and design description ----
abstract_rows <- tribble(
  ~table_figure, ~claim, ~value_paper, ~digits, ~value_rewrite, ~defect_locus, ~notes,
  "abstract", "n_advertisements_tested", 49, 0, txt("n_unique_ads"), NA,
    "Distinct campaign advertisements, excluding ad_id 3, the placebo car insurance advertisement.",
  "abstract", "n_experiments", 59, 0, txt("n_ad_week_deployments"), NA,
    "Advertisement by week comparisons.",
  "abstract", "n_respondents", 34000, 0, txt("n_respondents"), NA, "",
  "methods", "n_weeks", 29, 0, txt("n_weeks"), NA, "",
  "methods", "n_deployments_anti_trump", 30, 0, txt("n_deployments_anti_trump"), NA,
    "The main text's counts of advertisements by target are counts of advertisement-week deployments, not of distinct advertisements; the distinct counts are 24, 11, 6 and 3.",
  "methods", "n_deployments_anti_clinton", 11, 0, txt("n_deployments_anti_clinton"), NA, "",
  "methods", "n_deployments_pro_clinton", 8, 0, txt("n_deployments_pro_clinton"), NA, "",
  "methods", "n_deployments_pro_trump", 3, 0, txt("n_deployments_pro_trump"), NA, "",
  "methods", "manip_check_control_min", 0.02, 2, txt("manip_check_control_min"), NA,
    "Minimum across the ten waves in which the question was asked.",
  "methods", "manip_check_control_max", 0.04, 2, txt("manip_check_control_max"), NA, "",
  "methods", "manip_check_treated_min", 0.92, 2, txt("manip_check_treated_min"), "paper_internal",
    "The unweighted range across waves 21 to 30 is 0.914 to 0.955, so the stated 92 to 95 per cent is one point narrow at each end. Weighting by the survey weights gives 0.902 to 0.959, wider still.",
  "methods", "manip_check_treated_max", 0.95, 2, txt("manip_check_treated_max"), "paper_internal", "",
  "methods", "attrition_rate", 0.42, 2, txt("attrition_rate"), NA, "",
  "methods", "n_attrition_tests", 29, 0, txt("n_attrition_tests"), NA, "",
  "methods", "n_sig_unadjusted", 3, 0, txt("n_sig_unadjusted"), NA, "",
  "methods", "n_sig_holm", 0, 0, txt("n_sig_holm"), NA, "",
  "methods", "n_sig_benjamini_hochberg", 0, 0, txt("n_sig_benjamini_hochberg"), NA, ""
)

# Figure 1, the two printed annotations ----
figure_1_rows <- tribble(
  ~table_figure, ~claim, ~value_paper, ~digits, ~value_rewrite, ~defect_locus, ~notes,
  "figure_1", "fav_sate_meta_estimate", 0.049, 3, f1("Favorability", "estimate"), NA, "",
  "figure_1", "fav_sate_meta_se",       0.020, 3, f1("Favorability", "std.error"), NA, "",
  "figure_1", "vc_sate_meta_estimate",  0.007, 3, f1("Vote Choice", "estimate"), NA, "",
  "figure_1", "vc_sate_meta_se",        0.007, 3, f1("Vote Choice", "std.error"), NA, ""
)

# Quantities stated in the running text ----
text_rows <- tribble(
  ~table_figure, ~claim, ~value_paper, ~digits, ~value_rewrite, ~defect_locus, ~notes,
  "text", "fav_sate_avg_scale_points",     0.049, 3, s2("sates", "Favorability", "estimate"), NA, "",
  "text", "fav_sate_sd_scale_points",      0.07,  2, s2("sates", "Favorability", "tau"), NA,
    "The SD across experiments is the tau reported in Table S2.",
  "text", "vc_sate_avg_percentage_points", 0.007, 3, s2("sates", "Vote Choice", "estimate"), NA,
    "Stated in the text as 0.7 percentage points.",
  "text", "vc_sate_sd_percentage_points",  0.02,  2, s2("sates", "Vote Choice", "tau"), NA, "",
  "text", "fav_cate_sd_scale_points",      0.15,  2, s2("cates", "Favorability", "tau"), NA, "",
  "text", "vc_cate_sd_percentage_points",  0.02,  2, s2("cates", "Vote Choice", "tau"), NA, "",
  "text", "fav_sate_homogeneity_pval",     0.09,  2, s2("sates", "Favorability", "p.value"), NA, "",
  "text", "vc_sate_homogeneity_pval",      0.07,  2, s2("sates", "Vote Choice", "p.value"), NA, "",
  "text", "fav_cate_homogeneity_pval",     0.0002, 4, s2("cates", "Favorability", "p.value"), NA, "",
  "text", "vc_cate_homogeneity_pval",      0.96,  2, s2("cates", "Vote Choice", "p.value"), "paper_internal",
    "The Results section reports 0.96 for this test. Table S2 of the same article reports 0.0961, which is what the code produces, so the main text figure is off by a factor of ten.",
  "text", "general_election_coefficient",  0.121, 3, t1("m1", "general_d", "estimate"), "paper_internal",
    "The Results section says 0.121 scale points. Table 1 of the same article prints 0.123, which is what the code produces.",
  "text", "general_election_ci_upper",     0.25,  2, t1("m1", "general_d", "conf.high"), NA,
    "The text says the upper bound is about 0.25.",
  "text", "battleground_difference",       0.008, 3, abs(t1("m1", "battleground_d", "estimate")), NA,
    "The Results section gives the magnitude, 0.008. Table 1 prints this same coefficient as -0.00."
)

# Table 1, every published cell ----
# Published values typed from page 4 of the article. NA marks a cell the table
# leaves blank because the moderator is not in that specification.
t1_published <- tribble(
  ~term,            ~m1_est, ~m1_se, ~m2_est, ~m2_se, ~m3_est, ~m3_se, ~m4_est, ~m4_se,
  "intrcpt",          0.056,  0.020,   0.062,  0.020,   0.007,  0.007,   0.008,  0.007,
  "democrat_d",       0.035,  0.035,   0.022,  0.036,   0.011,  0.010,   0.006,  0.011,
  "independent_d",    0.023,  0.051,   0.015,  0.052,   0.009,  0.020,   0.007,  0.020,
  "battleground_d",   0.000,  0.033,  -0.007,  0.033,  -0.017,  0.010,  -0.017,  0.010,
  "pac_d",           -0.012,  0.043,   0.026,  0.047,  -0.023,  0.013,  -0.016,  0.014,
  "date_d",          -0.023,  0.014,   0.005,  0.010,  -0.009,  0.004,  -0.008,  0.004,
  "attack_d",        -0.017,  0.046,      NA,     NA,   0.028,  0.016,      NA,     NA,
  "general_d",        0.123,  0.067,      NA,     NA,      NA,     NA,      NA,     NA,
  "pro_trump_d",         NA,     NA,  -0.124,  0.101,      NA,     NA,  -0.016,  0.034,
  "anti_clinton_d",      NA,     NA,  -0.105,  0.070,      NA,     NA,   0.012,  0.023,
  "anti_trump_d",        NA,     NA,  -0.041,  0.058,      NA,     NA,   0.026,  0.021,
  "pro_sanders_d",       NA,     NA,  -0.075,  0.089,      NA,     NA,      NA,     NA,
  "pro_cruz_d",          NA,     NA,   0.047,  0.116,      NA,     NA,      NA,     NA,
  "pro_kasich_d",        NA,     NA,  -0.182,  0.145,      NA,     NA,      NA,     NA
)

table_1_rows <-
  t1_published |>
  pivot_longer(-term, names_to = c("model", "quantity"), names_sep = "_(?=est$|se$)",
               values_to = "value_paper") |>
  drop_na(value_paper) |>
  mutate(
    table_figure  = "table_1",
    claim         = paste0(model, "_", term, "_", quantity),
    value_rewrite = pmap_dbl(list(model, term, quantity),
                             \(m, tm, q) t1(m, tm, if_else(q == "est", "estimate", "std.error"))),
    # Every cell is printed to three decimals except the model 1 battleground
    # coefficient, which the published table prints as -0.00.
    digits       = if_else(claim == "m1_battleground_d_est", 2, 3),
    defect_locus = if_else(claim == "m1_battleground_d_est", "paper_internal", NA_character_),
    notes        = if_else(
      claim == "m1_battleground_d_est",
      "The published table prints -0.00 in this cell. The code gives -0.008, and the Results section quotes the magnitude correctly as 0.008.",
      ""
    )
  ) |>
  select(table_figure, claim, value_paper, digits, value_rewrite, defect_locus, notes)

table_1_nobs_rows <- tibble(
  table_figure  = "table_1",
  claim         = paste0(names(models), "_nobs"),
  value_paper   = c(354, 354, 204, 204),
  digits        = 0,
  value_rewrite = map_dbl(names(models), \(m) t1(m, "intrcpt", "nobs")),
  defect_locus  = NA_character_,
  notes         = ""
)

# Table S2, every published cell ----
s2_published <- tribble(
  ~estimand, ~dv,             ~estimate, ~std.error, ~p.value, ~tau2,  ~tau,
  "sates",   "Favorability",     0.0492,     0.0200,   0.0919, 0.0046, 0.0682,
  "sates",   "Vote Choice",      0.0072,     0.0073,   0.0700, 0.0005, 0.0222,
  "cates",   "Favorability",     0.0585,     0.0178,   0.0002, 0.0217, 0.1474,
  "cates",   "Vote Choice",      0.0083,     0.0051,   0.0961, 0.0005, 0.0232
)

table_s2_rows <-
  s2_published |>
  pivot_longer(-c(estimand, dv), names_to = "quantity", values_to = "value_paper") |>
  mutate(
    table_figure  = "table_s2",
    claim         = paste0(estimand, "_", str_remove_all(str_to_lower(dv), " "), "_",
                           recode_values(quantity, "estimate" ~ "est", "std.error" ~ "se",
                                         "p.value" ~ "p", default = quantity)),
    digits        = 4,
    value_rewrite = pmap_dbl(list(estimand, dv, quantity), s2),
    defect_locus  = NA_character_,
    notes         = ""
  ) |>
  select(table_figure, claim, value_paper, digits, value_rewrite, defect_locus, notes)

# Figure 2, all twelve printed annotations ----
f2_published <- tribble(
  ~dv,            ~pid,                      ~ad,                  ~estimate, ~std.error,
  "Favorability", "Democratic respondents",  "pro-Democratic ad",      0.106,      0.027,
  "Favorability", "Democratic respondents",  "pro-Republican ad",     -0.026,      0.049,
  "Favorability", "Independent respondents", "pro-Democratic ad",      0.070,      0.068,
  "Favorability", "Independent respondents", "pro-Republican ad",      0.012,      0.087,
  "Favorability", "Republican respondents",  "pro-Democratic ad",      0.039,      0.036,
  "Favorability", "Republican respondents",  "pro-Republican ad",      0.048,      0.039,
  "Vote choice",  "Democratic respondents",  "pro-Democratic ad",      0.027,      0.008,
  "Vote choice",  "Democratic respondents",  "pro-Republican ad",     -0.023,      0.015,
  "Vote choice",  "Independent respondents", "pro-Democratic ad",      0.005,      0.024,
  "Vote choice",  "Independent respondents", "pro-Republican ad",      0.027,      0.029,
  "Vote choice",  "Republican respondents",  "pro-Democratic ad",      0.007,      0.014,
  "Vote choice",  "Republican respondents",  "pro-Republican ad",     -0.002,      0.009
)

figure_2_rows <-
  f2_published |>
  pivot_longer(c(estimate, std.error), names_to = "quantity", values_to = "value_paper") |>
  mutate(
    table_figure  = "figure_2",
    claim         = paste0(
      if_else(dv == "Favorability", "fav", "vc"), "_",
      str_to_lower(str_remove(pid, " respondents")), "_",
      if_else(ad == "pro-Democratic ad", "prodem", "prorep"), "_",
      if_else(quantity == "estimate", "est", "se")
    ),
    digits        = 3,
    value_rewrite = pmap_dbl(list(dv, pid, ad, quantity), f2),
    defect_locus  = NA_character_,
    notes         = ""
  ) |>
  select(table_figure, claim, value_paper, digits, value_rewrite, defect_locus, notes)

# Table S1, Table S3 and Figure S1 ----
# None of the three prints a coefficient, so each is checked on the counts it does
# state: the shape of the advertisement list, the published column totals of the
# assignment table, and the number of panels.
appendix_float_rows <- tribble(
  ~table_figure, ~claim, ~value_paper, ~digits, ~value_rewrite, ~defect_locus, ~notes,
  "table_s1", "n_weeks_listed", 29, 0, nrow(s1_df), NA,
    "Table S1 lists one row per week of the study.",
  "table_s1", "n_ad_entries", 58, 0, sum(!is.na(as.matrix(select(s1_df, -date_formatted)))), NA,
    "Advertisement-week entries in the body of Table S1: three in the week of 14 March, one in the week of 5 September, two in each of the other 27 weeks.",
  "table_s3", "total_control", 9642, 0, s3_total("Control"), NA, "Published column totals of Table S3.",
  "table_s3", "total_pro_clinton", 2403, 0, s3_total("Pro Clinton"), NA, "",
  "table_s3", "total_anti_clinton", 4240, 0, s3_total("Anti Clinton"), NA, "",
  "table_s3", "total_pro_trump", 764, 0, s3_total("Pro Trump"), NA, "",
  "table_s3", "total_anti_trump", 10285, 0, s3_total("Anti Trump"), NA, "",
  "table_s3", "total_pro_cruz", 459, 0, s3_total("Pro Cruz"), NA, "",
  "table_s3", "total_pro_kasich", 250, 0, s3_total("Pro Kasich"), NA, "",
  "table_s3", "total_pro_sanders", 880, 0, s3_total("Pro Sanders"), NA, "",
  "table_s3", "total_two_ads", 5077, 0, s3_total("Two Ads"), NA, "",
  "table_s3", "total_all", 34000, 0, s3_total("Total"), NA, "",
  "figure_s1", "n_panels", 7, 0, n_distinct(fs1_df$ad_id), NA,
    "Figure S1 has one panel per advertisement fielded in more than one week. The panels print no numbers, so the panel count is what the figure states.",
  "figure_s1", "n_weekly_estimates", 17, 0, nrow(fs1_df), NA,
    "Points plotted across the seven panels, counted from the published figure."
)

# The appendix's own design counts ----
appendix_text_rows <- tribble(
  ~table_figure, ~claim, ~value_paper, ~digits, ~value_rewrite, ~defect_locus, ~notes,
  "appendix_a", "n_unique_ads_stated", 50, 0, txt("n_unique_ads"), "paper_internal",
    "Appendix section A says Table S1 shows 50 unique advertisements. The data hold 49 campaign advertisements plus the placebo, and the main text's 49 is right.",
  "appendix_a", "n_anti_trump_stated", 28, 0, txt("n_deployments_anti_trump"), "paper_internal",
    "Appendix section A gives 28, 9, 9 and 3 for anti-Trump, anti-Clinton, pro-Clinton and pro-Trump advertisements 'including the ads we deployed more than once'. The deployment counts are 30, 11, 8 and 3 and the distinct-advertisement counts are 24, 11, 6 and 3, so the appendix breakdown matches neither.",
  "appendix_a", "n_anti_clinton_stated", 9, 0, txt("n_deployments_anti_clinton"), "paper_internal", "",
  "appendix_a", "n_pro_clinton_stated", 9, 0, txt("n_deployments_pro_clinton"), "paper_internal", "",
  "appendix_a", "n_pro_trump_stated", 3, 0, txt("n_deployments_pro_trump"), NA, "",
  "appendix_a", "n_repeat_ads_named", 8, 0, txt("n_ads_fielded_more_than_once"), "paper_internal",
    "Appendix section A names eight advertisements as shown in multiple weeks. Seven were: 'Man of People' was fielded only in the week of 14 March.",
  "appendix_b", "n_repeat_ads_stated", 7, 0, txt("n_ads_fielded_more_than_once"), NA,
    "Appendix section B and Figure S1 both use seven, which is correct."
)

# Assemble ----
gt <-
  bind_rows(abstract_rows, figure_1_rows, text_rows, table_1_rows, table_1_nobs_rows,
            table_s2_rows, figure_2_rows, appendix_float_rows, appendix_text_rows) |>
  mutate(
    paper_id      = "coppock_hill_vavreck_2020",
    value_script  = value_rewrite,
    match         = as.numeric(round(value_script, digits) == round(value_paper, digits)),
    match_rewrite = as.numeric(round(value_rewrite, digits) == round(value_paper, digits))
  )

# A mismatch without a stated locus is an unexamined mismatch ----
stopifnot(all(!is.na(gt$defect_locus[gt$match_rewrite == 0])))
stopifnot(all(gt$match_rewrite[!is.na(gt$defect_locus)] == 0))

gt <- gt |>
  select(paper_id, table_figure, claim, value_script, value_paper, match,
         value_rewrite, match_rewrite, defect_locus, notes)

write_csv(gt, here::here("ground_truth", "coppock_hill_vavreck_2020_ground_truth.csv"))

print(gt |> select(table_figure, claim, value_script, value_paper, match, match_rewrite),
      n = nrow(gt), width = 200)

print(count(gt, table_figure, match_rewrite))

print(str_glue(
  "rows: {nrow(gt)}; match=1: {sum(gt$match == 1)}; match=0: {sum(gt$match == 0)}; ",
  "largest rewrite-versus-archive discrepancy in the per-week estimates: ",
  "{signif(max(agreement$max_abs_diff_estimate, agreement$max_abs_diff_std_error), 2)}"
))
