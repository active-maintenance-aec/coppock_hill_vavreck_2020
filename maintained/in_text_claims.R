# coppock_hill_vavreck_2020/maintained/in_text_claims.R
# Output: printed CLAIM lines and a CLAIM SUMMARY line; no files
# Depends on: everything in output/, ground_truth/published_claims.csv,
#             errata_entries.csv, helpers.R, excheckr
# Description: Every number the article and its supplementary materials print, paired
#   with the sentence that prints it and with the value this pipeline produces, in the
#   article's own units, in the order a reader meets them.
#
#   This file recomputes. It reads the same output/ files the ground truth reads and
#   does its own selection and unit conversion, so the two arrive at each number by
#   separate paths and a disagreement between them is a finding rather than a
#   coincidence. It never reads the ground-truth CSV and it never refits a model: the
#   pipeline has already produced the numbers.
#
#   Each block carries the article's sentence verbatim, then the value. Float cells
#   carry no sentence, because they are read off a table rather than out of a sentence,
#   and their blocks print every cell of the float.
#
#   The scoring comes from excheckr. claim_start() is handed the extraction, which says
#   what the article prints and at what precision, and the errata spine, which says which
#   of those numbers a published quantity erratum corrects and to what. Every claim() then
#   names a number and nothing else, and prints a line of the form
#     CLAIM <claim_id> = <value> || [verdict] <label>
#   which ground_truth/build_ground_truth.R parses: it runs this file non-interactively,
#   counts those lines, checks the set of claim_ids against
#   ground_truth/published_claims.csv, and compares every printed value against the one
#   it derived for itself. A block that errors, or that quietly stops printing, fails that
#   gate; the "# covers:" comments alone could not catch either.
#
#   Three declarations are made at a call site rather than derived. A descriptive claim
#   whose sentence prints no number is settled by the verdict computed in
#   maintained/text_descriptive_claims.R, printed as 1 (holds) or 0 (fails) and declared
#   expect = "shape". One whose sentence sets no threshold reduces to no value at all,
#   prints NA, and is declared expect = "absent". The roster of repeat advertisements in
#   Appendix A prints no count, so its block is declared expect = "derived".
#
#   Definitional, structural and transcribed claims carry no block. Nothing in the
#   pipeline can move a scale endpoint, an IRB number, a section heading or a line of an
#   advertisement's script, and giving one a block would mean typing a published number
#   into this file, which the maintained code may not contain.
#
#   cat() is used here and nowhere else in this repository, per the house rule for
#   in-text claims files; excheckr does the printing.

source(here::here("maintained", "helpers.R"))
library(excheckr)

options(width = 200)

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

text_numbers <- out("text_in_text_numbers.csv")
descriptive  <- out("text_descriptive_claims.csv")
figure_1     <- out("figure_1_sate_time_series.csv")
figure_2     <- out("figure_2_cate_partisan_match.csv")
figure_s1    <- out("figure_s1_repeat_ads.csv")
table_1      <- out("table_1_meta_regression.csv")
table_s1     <- out("table_s1_ad_list.csv")
table_s2     <- out("table_s2_heterogeneity.csv")
table_s3     <- out("table_s3_design.csv")

# Accessors ----
# Every value below comes through one of these, so no claim can quietly read a row
# that is not there: each stops if its filter selects other than exactly one value.
txt <- function(name) {
  value <- text_numbers$value[text_numbers$claim == name]
  stopifnot(length(value) == 1, !is.na(value))
  value
}

t1 <- function(model_label, term_label, column) {
  value <- table_1[[column]][table_1$model == model_label & table_1$term == term_label]
  stopifnot(length(value) == 1, !is.na(value))
  value
}

s2 <- function(estimand_label, dv_label, column) {
  value <- table_s2[[column]][table_s2$estimand == estimand_label &
                                table_s2$dv == dv_label &
                                table_s2$method == "DL (published)"]
  stopifnot(length(value) == 1, !is.na(value))
  value
}

f1_meta <- function(dv_label, column) {
  value <- figure_1[[column]][figure_1$dv == dv_label & figure_1$est_type == "Meta-analysis"]
  stopifnot(length(value) == 1, !is.na(value))
  value
}

f2 <- function(dv_label, pid_label, ad_label, column) {
  value <- figure_2[[column]][figure_2$outcome_variable == dv_label &
                                figure_2$respondent_pid == pid_label &
                                figure_2$ad_type == ad_label]
  stopifnot(length(value) == 1, !is.na(value))
  value
}

desc <- function(claim, column) {
  value <- descriptive[[column]][descriptive$claim_id == claim]
  stopifnot(length(value) == 1)
  value
}

# The extraction and the errata spine ----
# Both are read with every column as character: value_paper carries "0.020" and a reader
# left to guess would return 0.02 and destroy the precision the comparison depends on.
# Reading the extraction is not reading the comparison: this file never sees the ground
# truth.
published <- read_csv(here::here("ground_truth", "published_claims.csv"),
                      col_types = cols(.default = col_character()))
errata <- read_csv(here::here("errata_entries.csv"),
                   col_types = cols(.default = col_character()))

claim_start(published = published, errata = errata, format = "id")

# Title ----

# "The small effects of political advertising are small regardless of context, message,
# sender, or receiver: Evidence from 59 real-time randomized experiments"
# covers: title_n_experiments
claim("title_n_experiments", txt("n_ad_week_deployments"),
      "Title, advertisement-week experiments")

# Abstract ----

# "We tested 49 political advertisements in 59 unique experiments on 34,000 people."
# covers: abstract_n_ads
claim("abstract_n_ads", txt("n_unique_ads"), "Abstract, distinct advertisements tested")
# covers: abstract_n_experiments
claim("abstract_n_experiments", txt("n_ad_week_deployments"),
      "Abstract, unique experiments")
# covers: abstract_n_respondents
claim("abstract_n_respondents", txt("n_respondents"), "Abstract, respondents")

# Introduction ----

# "We have designed a series of unique tests spanning 8 months in which the sample,
# design, instrument, and analysis are all held constant."
# covers: intro_months_span
claim("intro_months_span", txt("months_spanned"),
      "Introduction, months spanned by the fielding period")

# "We measure the effects of 49 unique presidential advertisements made by professional
# ad makers during the 2016 presidential election among large, nationally representative
# samples using randomized experiments (we tested some of the 49 unique advertisements in
# multiple weeks)."
# covers: intro_n_ads
claim("intro_n_ads", txt("n_unique_ads"),
      "Introduction, distinct advertisements measured")
# covers: intro_n_ads_multiweek
claim("intro_n_ads_multiweek", txt("n_unique_ads"),
      "Introduction, distinct advertisements, restated")

# "We estimate an average treatment effect of presidential advertising on candidate
# favorability of 0.05 scale points on a five-point scale, with an SD across experiments
# of 0.07 scale points. On vote choice, the average effect is 0.7 percentage points with
# an SD of 2 points."
# covers: intro_fav_ate
claim("intro_fav_ate", s2("sates", "Favorability", "estimate"),
      "Introduction, pooled favorability effect (scale points)")
# covers: intro_fav_sd
claim("intro_fav_sd", s2("sates", "Favorability", "tau"),
      "Introduction, SD of favorability effects across experiments")
# covers: intro_vc_ate
claim("intro_vc_ate", 100 * s2("sates", "Vote Choice", "estimate"),
      "Introduction, pooled vote choice effect (percentage points)")
# covers: intro_vc_sd
claim("intro_vc_sd", 100 * s2("sates", "Vote Choice", "tau"),
      "Introduction, SD of vote choice effects (percentage points)")

# "Advertising effects do vary around small average effects, but the distribution of
# advertising effects in our experiments excludes large persuasive effects."
# covers: desc_effects_exclude_large
claim("desc_effects_exclude_large", desc("desc_effects_exclude_large", "holds"),
      "Introduction, the spread of the weekly estimates",
      digits = 0, expect = "absent")
claim_evidence(desc("desc_effects_exclude_large", "evidence"))

# Materials and Methods ----

# "Each week for 29 (not always consecutive) weeks, a representative sample of Americans
# was divided at random into groups and assigned to watch campaign advertisements or a
# placebo advertisement before answering a short survey."
# covers: methods_n_weeks
claim("methods_n_weeks", txt("n_weeks"), "Methods, weeks of fielding")

# "Our subjects were recruited by YouGov, which furnished samples of exactly 1000 (or
# 2000, depending on the week) complete responses."
# covers: methods_weekly_n_small
claim("methods_weekly_n_small", txt("weekly_n_min"), "Methods, smallest weekly sample")
# covers: methods_weekly_n_large
claim("methods_weekly_n_large", txt("weekly_n_max"), "Methods, largest weekly sample")

# "Some subjects (42%, on average) started the survey but did not finish, which can cause
# bias away from our inferential target, the U.S. population average treatment effect."
# covers: methods_attrition_rate
claim("methods_attrition_rate", 100 * txt("attrition_rate"),
      "Methods, share starting but not finishing (%)")

# "Specifically, we conduct separate chi-squared tests of the dependence between response
# and treatment assignment within each week of the study. Of the 29 tests, three return
# unadjusted P values that are statistically significant. When we adjust for multiple
# comparisons using the Holm or Benjamini-Hochberg corrections (32, 33), none of the tests
# remain significant."
# covers: methods_n_attrition_tests
claim("methods_n_attrition_tests", txt("n_attrition_tests"),
      "Methods, attrition tests conducted")
# covers: methods_n_sig_unadjusted
claim("methods_n_sig_unadjusted", txt("n_sig_unadjusted"),
      "Methods, tests significant unadjusted")
# covers: methods_n_sig_holm
claim("methods_n_sig_holm", txt("n_sig_holm"), "Methods, tests significant after Holm")
# covers: methods_n_sig_benjamini_hochberg
claim("methods_n_sig_benjamini_hochberg", txt("n_sig_benjamini_hochberg"),
      "Methods, tests significant after Benjamini-Hochberg")

# "In total, we tested 30 advertisements attacking Republican candidate Donald Trump, 11
# attacking Democratic candidate Hillary Clinton, 8 promoting Clinton, and 3 promoting
# Trump."
#
# The counts are of advertisement-week deployments, not of distinct advertisements: the
# distinct counts are 24, 11, 6 and 3.
# covers: methods_n_deployments_anti_trump
claim("methods_n_deployments_anti_trump", txt("n_deployments_anti_trump"),
      "Methods, anti-Trump advertisement deployments")
# covers: methods_n_deployments_anti_clinton
claim("methods_n_deployments_anti_clinton", txt("n_deployments_anti_clinton"),
      "Methods, anti-Clinton advertisement deployments")
# covers: methods_n_deployments_pro_clinton
claim("methods_n_deployments_pro_clinton", txt("n_deployments_pro_clinton"),
      "Methods, pro-Clinton advertisement deployments")
# covers: methods_n_deployments_pro_trump
claim("methods_n_deployments_pro_trump", txt("n_deployments_pro_trump"),
      "Methods, pro-Trump advertisement deployments")

# "We are confident that treatments were delivered as intended: Tiny fractions of the
# control groups claimed to have seen campaign advertisements (2 to 4%) compared with
# large majorities of the treatment groups (92 to 95%)."
#
# The range is across the ten waves in which the manipulation check was asked, and the
# shares are unweighted, as in the deposited code. Weighting by the survey weights gives
# a wider range in both groups.
# covers: methods_manip_control_min
claim("methods_manip_control_min", 100 * txt("manip_check_control_min"),
      "Methods, control group manipulation check, minimum (%)")
# covers: methods_manip_control_max
claim("methods_manip_control_max", 100 * txt("manip_check_control_max"),
      "Methods, control group manipulation check, maximum (%)")
# covers: methods_manip_treated_min
claim("methods_manip_treated_min", 100 * txt("manip_check_treated_min"),
      "Methods, treatment group manipulation check, minimum (%)")
# covers: methods_manip_treated_max
claim("methods_manip_treated_max", 100 * txt("manip_check_treated_max"),
      "Methods, treatment group manipulation check, maximum (%)")

# "The treatment effects in any single 1000-person study are estimated with a fair amount
# of sampling variability, but pooling across weeks via random-effects meta-analysis
# allows us to sharpen the estimates considerably."
# covers: methods_single_study_n
claim("methods_single_study_n", txt("weekly_n_min"),
      "Methods, respondents in a single weekly study")

# Results ----

# "In Figure 1, we plot average treatment effect estimates (and 95% confidence intervals)
# for each of our 59 experimental comparisons for our two dependent variables."
# covers: results_n_experiments
claim("results_n_experiments",
      sum(figure_1$est_type == "Weekly estimates" & figure_1$dv == "Favorability"),
      "Results, experimental comparisons plotted in Figure 1")

# "On average, the advertisements moved target candidate favorability 0.049 scale points
# (1 to 5 scale) in the "correct" direction", the analysis being scaled so that the
# treatment effect of promotional advertisements is in the direction of favorability and
# that of attack advertisements is in the opposite direction.
# covers: results_fav_meta_estimate
claim("results_fav_meta_estimate", f1_meta("Favorability", "estimate"),
      "Results, pooled favorability effect (scale points)")

# "This estimate, though small, is statistically significant owing to the large size of
# our study."
# covers: desc_fav_meta_significant
claim("desc_fav_meta_significant", desc("desc_fav_meta_significant", "holds"),
      "Results, is the pooled favorability effect significant",
      digits = 0, expect = "shape")
claim_evidence(desc("desc_fav_meta_significant", "evidence"))

# "The effect on target candidate vote choice is also small at 0.7 percentage points, but
# is not statistically significant."
# covers: results_vc_meta_estimate
claim("results_vc_meta_estimate", 100 * f1_meta("Vote Choice", "estimate"),
      "Results, pooled vote choice effect (percentage points)")
# covers: desc_vc_meta_not_significant
claim("desc_vc_meta_not_significant", desc("desc_vc_meta_not_significant", "holds"),
      "Results, is the pooled vote choice effect insignificant",
      digits = 0, expect = "shape")
claim_evidence(desc("desc_vc_meta_not_significant", "evidence"))

# "Using formal tests, we fail to reject the null of homogeneity in both cases
# (favorability, P = 0.09; vote choice, P = 0.07)."
# covers: results_fav_homogeneity_p
claim("results_fav_homogeneity_p", s2("sates", "Favorability", "p.value"),
      "Results, favorability SATE homogeneity p-value")
# covers: results_vc_homogeneity_p
claim("results_vc_homogeneity_p", s2("sates", "Vote Choice", "p.value"),
      "Results, vote choice SATE homogeneity p-value")

# "If only statistically significant results were published, then we would be left with
# one large negative result (nearly -0.5 points on favorability in early May), one large
# positive result toward the end of the campaign in October (more than +0.5 points), and
# two other negative results in October."
# covers: desc_large_negative_early_may
claim("desc_large_negative_early_may", desc("desc_large_negative_early_may", "computed"),
      "Results, largest significant negative favorability estimate in May")
claim_evidence(desc("desc_large_negative_early_may", "evidence"))
# covers: desc_large_positive_october
claim("desc_large_positive_october", desc("desc_large_positive_october", "computed"),
      "Results, largest significant positive favorability estimate in October")
claim_evidence(desc("desc_large_positive_october", "evidence"))
# covers: desc_two_other_negative_october
claim("desc_two_other_negative_october",
      desc("desc_two_other_negative_october", "computed"),
      "Results, other significant negative favorability estimates in October")
claim_evidence(desc("desc_two_other_negative_october", "evidence"))

# "The main story of the graph is that treatment effects are similarly small over time,
# but sample sizes of 1000 or 2000 generate week-to-week sampling variability."
# covers: results_sample_size_small
claim("results_sample_size_small", txt("weekly_n_min"), "Results, smallest weekly sample")
# covers: results_sample_size_large
claim("results_sample_size_large", txt("weekly_n_max"), "Results, largest weekly sample")

# "Turning first to features of receiver, we see that the differences in treatment
# response across Democrats, Independents, and Republicans are small, with SEs greater
# than coefficients."
# covers: desc_partisan_ses_exceed_coefficients
claim("desc_partisan_ses_exceed_coefficients",
      desc("desc_partisan_ses_exceed_coefficients", "holds"),
      "Results, do the partisanship SEs exceed their coefficients in all eight cells",
      digits = 0, expect = "shape")
claim_evidence(desc("desc_partisan_ses_exceed_coefficients", "evidence"))

# "Independents do not appear to be more malleable than partisans, and neither partisan
# group is more responsive than the other."
# covers: desc_independents_not_more_malleable
claim("desc_independents_not_more_malleable",
      desc("desc_independents_not_more_malleable", "holds"),
      "Results, is any partisanship coefficient distinguishable from zero",
      digits = 0, expect = "shape")
claim_evidence(desc("desc_independents_not_more_malleable", "evidence"))

# "Of the three features of context, the slope with respect to the timing of the
# advertisement is negative in three of four specifications and statistically distinct
# from zero in one."
# covers: desc_time_slope_negative_count
claim("desc_time_slope_negative_count",
      desc("desc_time_slope_negative_count", "computed"),
      "Results, specifications with a negative time slope")
claim_evidence(desc("desc_time_slope_negative_count", "evidence"))
# covers: desc_time_slope_significant_count
claim("desc_time_slope_significant_count",
      desc("desc_time_slope_significant_count", "computed"),
      "Results, specifications with a time slope distinguishable from zero")
claim_evidence(desc("desc_time_slope_significant_count", "evidence"))

# "Difference in effectiveness for subjects who do and do not live in battleground states
# is 0.008 scale points."
#
# The Results section gives the magnitude; the coefficient itself is negative.
# covers: results_battleground_difference
claim("results_battleground_difference",
      abs(t1("Candidate favorability (1)", "battleground_d", "estimate")),
      "Results, battleground difference in favorability (scale points, magnitude)")

# "On average, general election advertisements move candidate favorability by 0.121 scale
# points more than primary advertisements, although the estimate is not precise enough to
# achieve statistical significance."
# covers: results_general_election_coefficient
claim("results_general_election_coefficient",
      t1("Candidate favorability (1)", "general_d", "estimate"),
      "Results, general election coefficient (scale points)")
# covers: desc_general_election_not_significant
claim("desc_general_election_not_significant",
      desc("desc_general_election_not_significant", "holds"),
      "Results, is the general election coefficient insignificant",
      digits = 0, expect = "shape")
claim_evidence(desc("desc_general_election_not_significant", "evidence"))

# "The upper bound of the 95% confidence interval for the average difference between
# primary and general election advertisements is about 0.25 scale points on a five-point
# favorability scale."
# covers: results_general_election_ci_upper
claim("results_general_election_ci_upper",
      t1("Candidate favorability (1)", "general_d", "conf.high"),
      "Results, upper bound of the general election interval (scale points)")

# "We find that attack advertisements are about as effective in achieving their goals as
# promotional advertisements and that PAC- or SuperPAC-sponsored advertisements are no
# more effective than those sponsored by candidates."
# covers: desc_attack_and_pac_not_significant
claim("desc_attack_and_pac_not_significant",
      desc("desc_attack_and_pac_not_significant", "holds"),
      "Results, is any tone or sponsor coefficient distinguishable from zero",
      digits = 0, expect = "shape")
claim_evidence(desc("desc_attack_and_pac_not_significant", "evidence"))

# "While pro-Clinton advertisements tended to be more effective than advertisements in
# support of or in opposition to other candidates, these differences cannot be
# distinguished from zero."
# covers: desc_pro_clinton_more_effective
claim("desc_pro_clinton_more_effective", desc("desc_pro_clinton_more_effective", "holds"),
      "Results, sign of the target candidate coefficients",
      digits = 0, expect = "absent")
claim_evidence(desc("desc_pro_clinton_more_effective", "evidence"))
# covers: desc_pro_clinton_differences_not_significant
claim("desc_pro_clinton_differences_not_significant",
      desc("desc_pro_clinton_differences_not_significant", "holds"),
      "Results, is any target candidate coefficient distinguishable from zero",
      digits = 0, expect = "shape")
claim_evidence(desc("desc_pro_clinton_differences_not_significant", "evidence"))

# "Figure 2 provides partial support for the "partisan match" theory: Democratic subjects
# respond more strongly to pro-Democratic advertisements than to pro-Republican
# advertisements. However, we do not observe a corresponding pattern among Republican
# respondents: Both pro-Democratic and pro-Republican advertisements have approximately
# the same small, positive, nonsignificant effect."
# covers: desc_partisan_match_democrats
claim("desc_partisan_match_democrats", desc("desc_partisan_match_democrats", "holds"),
      "Results, do Democratic respondents respond more to pro-Democratic advertisements",
      digits = 0, expect = "shape")
claim_evidence(desc("desc_partisan_match_democrats", "evidence"))
# covers: desc_partisan_match_republicans
claim("desc_partisan_match_republicans", desc("desc_partisan_match_republicans", "holds"),
      "Results, do Republican respondents respond similarly to both",
      digits = 0, expect = "absent")
claim_evidence(desc("desc_partisan_match_republicans", "evidence"))

# "For the sample average treatment effects (SATEs) across experiments, P values from
# tests against the null of treatment effect homogeneity are 0.09 for favorability and
# 0.07 for vote choice. For the set of conditional average treatment effects (CATEs), P
# values are 0.0002 and 0.96."
# covers: results_s2_sate_fav_p
claim("results_s2_sate_fav_p", s2("sates", "Favorability", "p.value"),
      "Results, SATE favorability homogeneity p-value, restated")
# covers: results_s2_sate_vc_p
claim("results_s2_sate_vc_p", s2("sates", "Vote Choice", "p.value"),
      "Results, SATE vote choice homogeneity p-value, restated")
# covers: results_s2_cate_fav_p
claim("results_s2_cate_fav_p", s2("cates", "Favorability", "p.value"),
      "Results, CATE favorability homogeneity p-value")
# covers: results_s2_cate_vc_p
claim("results_s2_cate_vc_p", s2("cates", "Vote Choice", "p.value"),
      "Results, CATE vote choice homogeneity p-value")

# "While we fail to reject the null hypothesis of treatment effect homogeneity in three of
# four opportunities, we do not affirm that null."
# covers: desc_fail_reject_three_of_four
claim("desc_fail_reject_three_of_four",
      desc("desc_fail_reject_three_of_four", "computed"),
      "Results, homogeneity tests failing to reject at the 5 per cent level")
claim_evidence(desc("desc_fail_reject_three_of_four", "evidence"))

# "The square root of the tau-squared statistic is an estimate of the true SD of the
# treatment effects. We estimate this value to be 0.07 (SATEs) and 0.15 (CATEs) for
# favorability on a five-point scale and 0.02 and 0.02 for the vote choice."
# covers: results_tau_sate_favorability
claim("results_tau_sate_favorability", s2("sates", "Favorability", "tau"),
      "Results, tau, favorability SATEs")
# covers: results_tau_cate_favorability
claim("results_tau_cate_favorability", s2("cates", "Favorability", "tau"),
      "Results, tau, favorability CATEs")
# covers: results_tau_sate_vote_choice
claim("results_tau_sate_vote_choice", s2("sates", "Vote Choice", "tau"),
      "Results, tau, vote choice SATEs")
# covers: results_tau_cate_vote_choice
claim("results_tau_cate_vote_choice", s2("cates", "Vote Choice", "tau"),
      "Results, tau, vote choice CATEs")

# Discussion ----

# "Our 59 experiments demonstrate this."
# covers: discussion_n_experiments
claim("discussion_n_experiments", txt("n_ad_week_deployments"), "Discussion, experiments")

# "The present study is unusual in its size (34,000 nationally representative subjects)
# and breadth of treatments (a purposive sample of 49 of the highest-profile presidential
# advertisements fielded in the midst of the 2016 presidential election), allowing us to
# systematically investigate how variations in message, context, sender, or receiver
# condition persuasive effects".
# covers: discussion_n_respondents
claim("discussion_n_respondents", txt("n_respondents"), "Discussion, respondents")
# covers: discussion_n_ads
claim("discussion_n_ads", txt("n_unique_ads"), "Discussion, distinct advertisements")

# Figure 1 ----
# The figure prints two annotations, one per facet, each an estimate with its standard
# error in parentheses.
# covers: figure_1_fav_estimate
claim("figure_1_fav_estimate", f1_meta("Favorability", "estimate"),
      "Figure 1, favorability meta-analytic estimate")
# covers: figure_1_fav_se
claim("figure_1_fav_se", f1_meta("Favorability", "std.error"),
      "Figure 1, favorability meta-analytic standard error")
# covers: figure_1_vc_estimate
claim("figure_1_vc_estimate", f1_meta("Vote Choice", "estimate"),
      "Figure 1, vote choice meta-analytic estimate")
# covers: figure_1_vc_se
claim("figure_1_vc_se", f1_meta("Vote Choice", "std.error"),
      "Figure 1, vote choice meta-analytic standard error")

# Table 1 ----
# Every published cell of the meta-regression table, at the three decimals the page
# prints. The model index is the column of the published table; the term is the
# moderator's name in the fitted object.
# covers: table_1_*
table_1_models <- c("Candidate favorability (1)", "Candidate favorability (2)",
                    "Vote choice (3)", "Vote choice (4)")

for (i in seq_along(table_1_models)) {
  model_rows <- table_1 |> filter(model == table_1_models[i])
  for (term_name in model_rows$term) {
    est_id <- str_glue("table_1_m{i}_{term_name}_est")
    se_id  <- str_glue("table_1_m{i}_{term_name}_se")
    claim(est_id, t1(table_1_models[i], term_name, "estimate"),
          str_glue("Table 1, model {i}, {term_name}, estimate"))
    claim(se_id, t1(table_1_models[i], term_name, "std.error"),
          str_glue("Table 1, model {i}, {term_name}, standard error"))
  }
  claim(str_glue("table_1_m{i}_nobs"), t1(table_1_models[i], "intrcpt", "nobs"),
        str_glue("Table 1, model {i}, number of observations"))

}

# The three cells the published table marks with an asterisk.
# covers: desc_table_1_m1_intrcpt_star
claim("desc_table_1_m1_intrcpt_star", desc("desc_table_1_m1_intrcpt_star", "holds"),
      "Table 1, model 1 average effect starred",
      digits = 0, expect = "shape")
claim_evidence(desc("desc_table_1_m1_intrcpt_star", "evidence"))
# covers: desc_table_1_m2_intrcpt_star
claim("desc_table_1_m2_intrcpt_star", desc("desc_table_1_m2_intrcpt_star", "holds"),
      "Table 1, model 2 average effect starred",
      digits = 0, expect = "shape")
claim_evidence(desc("desc_table_1_m2_intrcpt_star", "evidence"))
# covers: desc_table_1_m3_date_d_star
claim("desc_table_1_m3_date_d_star", desc("desc_table_1_m3_date_d_star", "holds"),
      "Table 1, model 3 time slope starred",
      digits = 0, expect = "shape")
claim_evidence(desc("desc_table_1_m3_date_d_star", "evidence"))

# Figure 2 ----
# All twelve printed annotations, each an estimate with its standard error.
# covers: figure_2_*
figure_2_ids <-
  figure_2 |>
  transmute(
    outcome_variable, respondent_pid, ad_type,
    dv_slug  = if_else(outcome_variable == "Favorability", "fav", "vc"),
    pid_slug = str_to_lower(str_remove(respondent_pid, " respondents")),
    ad_slug  = if_else(ad_type == "pro-Democratic ad", "prodem", "prorep")
  )

for (row in seq_len(nrow(figure_2_ids))) {
  ids <- figure_2_ids[row, ]
  stem <- str_glue("figure_2_{ids$dv_slug}_{ids$pid_slug}_{ids$ad_slug}")
  claim(str_glue("{stem}_est"),
        f2(ids$outcome_variable, ids$respondent_pid, ids$ad_type, "estimate"),
        str_glue("Figure 2, {ids$outcome_variable}, {ids$respondent_pid}, {ids$ad_type}, estimate"))
  claim(str_glue("{stem}_se"),
        f2(ids$outcome_variable, ids$respondent_pid, ids$ad_type, "std.error"),
        str_glue("Figure 2, {ids$outcome_variable}, {ids$respondent_pid}, {ids$ad_type}, standard error"))
}

# Appendix A: Treatments ----

# "Table S1 shows the name and target of the 50 unique advertisements and the week they
# were deployed."
#
# Two of the 49 distinct advertisements share the title "Sacrifice" and the week of
# 5 September, so the table's body carries 48 distinct names.
# covers: appendix_a_n_unique_ads
claim("appendix_a_n_unique_ads", txt("n_unique_ads"),
      "Appendix A, distinct advertisements")

# "Some advertisements ("America," "Love/Kindness," "Man of People," "Mirrors," "Quotes,"
# "Real Life," "Role Model," "Speak") were shown in multiple weeks, enabling us to
# estimate how the effect of the same advertisement may vary with the changing electoral
# context."
#
# The sentence prints no number: it names eight advertisements, and the extraction counts
# the names. The block prints the count of advertisements fielded in more than one week,
# which is what the list is a roster of, and declares it derived, because the erratum that
# corrects this sentence (entry 8) corrects a label rather than a printed quantity.
# covers: appendix_a_n_repeat_ads_named
claim("appendix_a_n_repeat_ads_named", txt("n_ads_fielded_more_than_once"),
      "Appendix A, advertisements fielded in more than one week",
      expect = "derived")

# "Including the ads we deployed more than once, we tested 28 ads that attacked Trump,
# nine attacks on Clinton, nine Clinton promotional ads, and three promotional Trump ads."
# covers: appendix_a_n_anti_trump
claim("appendix_a_n_anti_trump", txt("n_deployments_anti_trump"),
      "Appendix A, anti-Trump deployments")
# covers: appendix_a_n_anti_clinton
claim("appendix_a_n_anti_clinton", txt("n_deployments_anti_clinton"),
      "Appendix A, anti-Clinton deployments")
# covers: appendix_a_n_pro_clinton
claim("appendix_a_n_pro_clinton", txt("n_deployments_pro_clinton"),
      "Appendix A, pro-Clinton deployments")
# covers: appendix_a_n_pro_trump
claim("appendix_a_n_pro_trump", txt("n_deployments_pro_trump"),
      "Appendix A, pro-Trump deployments")

# Table S1 ----
# The table itself carries no coefficients. What it states is its own shape: one row per
# week of the study, and one entry per advertisement fielded in that week.
# covers: table_s1_n_weeks
claim("table_s1_n_weeks", nrow(table_s1), "Table S1, weeks listed")
# covers: table_s1_n_ad_entries
claim("table_s1_n_ad_entries", sum(!is.na(as.matrix(select(table_s1, -date_formatted)))),
      "Table S1, advertisement-week entries")

# Appendix B: Repeat advertisements ----

# "In this section, we present an analysis of the seven ads that we fielded more than
# once, first in the week they were released by the campaigns and then again in later
# weeks."
# covers: appendix_b_n_repeat_ads
claim("appendix_b_n_repeat_ads", txt("n_ads_fielded_more_than_once"),
      "Appendix B, advertisements fielded more than once")

# "However, as Figure S1 shows, the effects of ads are remarkably consistent over time. In
# no case does the estimate of an ad's effectiveness significantly vary with the week of
# experiment."
# covers: desc_repeat_ads_no_significant_variation
claim("desc_repeat_ads_no_significant_variation",
      desc("desc_repeat_ads_no_significant_variation", "holds"),
      "Appendix B, does any repeat advertisement vary significantly across weeks",
      digits = 0, expect = "shape")
claim_evidence(desc("desc_repeat_ads_no_significant_variation", "evidence"))

# "In the case of "Quotes," the estimate appears to increase in size as Trump's treatment
# of women increases in salience mid-year (the end of the primaries) perhaps in concert
# with a CNN interview on the topic, but this is entirely speculative."
# covers: desc_repeat_ad_quotes_increases
claim("desc_repeat_ad_quotes_increases", desc("desc_repeat_ad_quotes_increases", "holds"),
      "Appendix B, the weekly estimates for Quotes",
      digits = 0, expect = "absent")
claim_evidence(desc("desc_repeat_ad_quotes_increases", "evidence"))

# Figure S1 ----
# The panels print no numbers, so what the figure states is its own shape.
# covers: figure_s1_n_panels
claim("figure_s1_n_panels", n_distinct(figure_s1$ad_id), "Figure S1, panels")
# covers: figure_s1_n_weekly_estimates
claim("figure_s1_n_weekly_estimates", nrow(figure_s1),
      "Figure S1, weekly estimates plotted")

# Appendix C and Table S2 ----
# Every published cell of the heterogeneity table, at the four decimals the page prints.
# covers: table_s2_*
table_s2_quantities <- c(est = "estimate", se = "std.error", p = "p.value",
                         tau2 = "tau2", tau = "tau")

for (estimand_label in c("sates", "cates")) {
  for (dv_label in c("Favorability", "Vote Choice")) {
    dv_slug <- str_remove_all(str_to_lower(dv_label), " ")
    for (suffix in names(table_s2_quantities)) {
      claim(str_glue("table_s2_{estimand_label}_{dv_slug}_{suffix}"),
            s2(estimand_label, dv_label, table_s2_quantities[[suffix]]),
            str_glue("Table S2, {estimand_label}, {dv_label}, {table_s2_quantities[[suffix]]}"))
    }
  }
}

# Appendix E and Table S3 ----
# Every printed cell of the assignment table, including its row and column totals. A cell
# the published table leaves blank is a condition not fielded that week, and the pipeline
# leaves it missing rather than zero.
# covers: table_s3_*
table_s3_long <-
  table_s3 |>
  pivot_longer(-date_formatted, names_to = "condition", values_to = "n") |>
  drop_na(n) |>
  mutate(
    week_slug      = str_replace_all(str_to_lower(date_formatted), "[^a-z0-9]+", "_"),
    condition_slug = str_replace_all(str_to_lower(condition), "[^a-z0-9]+", "_")
  )

for (row in seq_len(nrow(table_s3_long))) {
  cell <- table_s3_long[row, ]
  claim(str_glue("table_s3_{cell$week_slug}_{cell$condition_slug}"), cell$n,
        str_glue("Table S3, {cell$date_formatted}, {cell$condition}"))
}

# Gates and summary ----
# assert_claims() stops on any MISMATCH, STALE, DRIFT or MISSING, on a claim a quantity
# erratum names that did not score corrected, and on any difference between the claims
# printed and the claims the extraction marks needs_block. A DRIFT has two causes: the
# pipeline has moved off the value the erratum publishes, or errata.qmd has not been
# re-rendered since it last moved. Re-render before investigating.
assert_claims()

# The exemptions are counted, never merely allowed: a claim scored [shape], [derived] or
# [absent] is one this file declines to assert.
invisible(claim_summary())
