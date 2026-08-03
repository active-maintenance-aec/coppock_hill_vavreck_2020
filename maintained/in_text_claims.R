# coppock_hill_vavreck_2020/maintained/in_text_claims.R
# Output: printed to the console; no file
# Depends on: everything in output/, and ground_truth/published_claims.csv for the
#             precision at which the article prints a quantity
# Description: Every number the article and its supplementary materials print, paired
#   with the sentence that prints it and with the value this pipeline produces, in the
#   article's own units and rounding, in the order a reader meets them.
#
#   This file recomputes. It reads the same output/ files the ground truth reads and
#   does its own selection, unit conversion and rounding, so the two arrive at each
#   number by separate paths and a disagreement between them is a finding rather than a
#   coincidence. It never reads the ground-truth CSV and it never refits a model: the
#   pipeline has already produced the numbers.
#
#   Each block carries the article's sentence verbatim, then the value. Float cells
#   carry no sentence, because they are read off a table rather than out of a sentence,
#   and their blocks print every cell of the float.
#
#   Every printed line has the form
#     CLAIM <claim_id> = <value> || <label>
#   and ground_truth/build_ground_truth.R runs this file non-interactively, counts those
#   lines, checks the set of claim_ids against ground_truth/published_claims.csv, and
#   compares every printed value against the one it derived for itself. A block that
#   errors, or that quietly stops printing, fails that gate; the "# covers:" comments
#   alone could not catch either.
#
#   Definitional, structural and transcribed claims carry no block. Nothing in the
#   pipeline can move a scale endpoint, an IRB number, a section heading or a line of an
#   advertisement's script, and giving one a block would mean typing a published number
#   into this file, which the maintained code may not contain.
#
#   cat() is used here and nowhere else in this repository, per the house rule for
#   in-text claims files.

source(here::here("maintained", "helpers.R"))

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

# The precision at which the article prints a quantity ----
# Read from the extraction rather than asserted, because how many decimals a page
# carries is a property of the article. Reading the extraction is not reading the
# comparison: this file still never sees the ground truth.
published_claims <- read_csv(here::here("ground_truth", "published_claims.csv"),
                             show_col_types = FALSE)

paper_digits <- function(claim_id) {
  printed <- published_claims$value_paper[published_claims$claim_id == claim_id]
  stopifnot(length(printed) == 1, !is.na(printed))
  decimals <- str_extract(printed, "(?<=\\.)[0-9]+")
  if_else(is.na(decimals), 0L, nchar(decimals))
}

# Printing ----
# One line per claim, carrying the claim_id the gate reads, the value at the article's
# own precision, and a label so the output is scannable beside the sentences above it.
# The digits written at each call site are the article's rounding read off the page; the
# assertion below is what keeps that reading and the transcription from drifting apart.
report <- function(claim_id, label, value, digits) {
  stopifnot(digits == paper_digits(claim_id))
  cat("CLAIM ", claim_id, " = ", sprintf(paste0("%.", digits, "f"), value),
      " || ", label, "\n", sep = "")
}

# A descriptive claim that reduces to a verdict prints the verdict and its evidence.
# One that does not reduce prints "not reducible" and its evidence, because inventing
# a threshold the sentence never set would put a number in the article's mouth.
report_verdict <- function(claim_id, label) {
  holds <- desc(claim_id, "holds")
  verdict <- if (is.na(holds)) "not reducible" else if (holds == 1) "holds" else "fails"
  cat("CLAIM ", claim_id, " = ", verdict, " || ", label, "\n", sep = "")
  cat("    evidence: ", desc(claim_id, "evidence"), "\n", sep = "")
}

# Title ----

# "The small effects of political advertising are small regardless of context, message,
# sender, or receiver: Evidence from 59 real-time randomized experiments"
# covers: title_n_experiments
report("title_n_experiments", "Title, advertisement-week experiments", txt("n_ad_week_deployments"), 0)

# Abstract ----

# "We tested 49 political advertisements in 59 unique experiments on 34,000 people."
# covers: abstract_n_ads
report("abstract_n_ads", "Abstract, distinct advertisements tested", txt("n_unique_ads"), 0)
# covers: abstract_n_experiments
report("abstract_n_experiments", "Abstract, unique experiments", txt("n_ad_week_deployments"), 0)
# covers: abstract_n_respondents
report("abstract_n_respondents", "Abstract, respondents", txt("n_respondents"), 0)

# Introduction ----

# "We have designed a series of unique tests spanning 8 months in which the sample,
# design, instrument, and analysis are all held constant."
# covers: intro_months_span
report("intro_months_span", "Introduction, months spanned by the fielding period",
       txt("months_spanned"), 0)

# "We measure the effects of 49 unique presidential advertisements made by professional
# ad makers during the 2016 presidential election among large, nationally representative
# samples using randomized experiments (we tested some of the 49 unique advertisements in
# multiple weeks)."
# covers: intro_n_ads
report("intro_n_ads", "Introduction, distinct advertisements measured", txt("n_unique_ads"), 0)
# covers: intro_n_ads_multiweek
report("intro_n_ads_multiweek", "Introduction, distinct advertisements, restated",
       txt("n_unique_ads"), 0)

# "We estimate an average treatment effect of presidential advertising on candidate
# favorability of 0.05 scale points on a five-point scale, with an SD across experiments
# of 0.07 scale points. On vote choice, the average effect is 0.7 percentage points with
# an SD of 2 points."
# covers: intro_fav_ate
report("intro_fav_ate", "Introduction, pooled favorability effect (scale points)",
       s2("sates", "Favorability", "estimate"), 2)
# covers: intro_fav_sd
report("intro_fav_sd", "Introduction, SD of favorability effects across experiments",
       s2("sates", "Favorability", "tau"), 2)
# covers: intro_vc_ate
report("intro_vc_ate", "Introduction, pooled vote choice effect (percentage points)",
       100 * s2("sates", "Vote Choice", "estimate"), 1)
# covers: intro_vc_sd
report("intro_vc_sd", "Introduction, SD of vote choice effects (percentage points)",
       100 * s2("sates", "Vote Choice", "tau"), 0)

# "Advertising effects do vary around small average effects, but the distribution of
# advertising effects in our experiments excludes large persuasive effects."
# covers: desc_effects_exclude_large
report_verdict("desc_effects_exclude_large", "Introduction, the spread of the weekly estimates")

# Materials and Methods ----

# "Each week for 29 (not always consecutive) weeks, a representative sample of Americans
# was divided at random into groups and assigned to watch campaign advertisements or a
# placebo advertisement before answering a short survey."
# covers: methods_n_weeks
report("methods_n_weeks", "Methods, weeks of fielding", txt("n_weeks"), 0)

# "Our subjects were recruited by YouGov, which furnished samples of exactly 1000 (or
# 2000, depending on the week) complete responses."
# covers: methods_weekly_n_small
report("methods_weekly_n_small", "Methods, smallest weekly sample", txt("weekly_n_min"), 0)
# covers: methods_weekly_n_large
report("methods_weekly_n_large", "Methods, largest weekly sample", txt("weekly_n_max"), 0)

# "Some subjects (42%, on average) started the survey but did not finish, which can cause
# bias away from our inferential target, the U.S. population average treatment effect."
# covers: methods_attrition_rate
report("methods_attrition_rate", "Methods, share starting but not finishing (%)",
       100 * txt("attrition_rate"), 0)

# "Specifically, we conduct separate chi-squared tests of the dependence between response
# and treatment assignment within each week of the study. Of the 29 tests, three return
# unadjusted P values that are statistically significant. When we adjust for multiple
# comparisons using the Holm or Benjamini-Hochberg corrections (32, 33), none of the tests
# remain significant."
# covers: methods_n_attrition_tests
report("methods_n_attrition_tests", "Methods, attrition tests conducted",
       txt("n_attrition_tests"), 0)
# covers: methods_n_sig_unadjusted
report("methods_n_sig_unadjusted", "Methods, tests significant unadjusted",
       txt("n_sig_unadjusted"), 0)
# covers: methods_n_sig_holm
report("methods_n_sig_holm", "Methods, tests significant after Holm", txt("n_sig_holm"), 0)
# covers: methods_n_sig_benjamini_hochberg
report("methods_n_sig_benjamini_hochberg", "Methods, tests significant after Benjamini-Hochberg",
       txt("n_sig_benjamini_hochberg"), 0)

# "In total, we tested 30 advertisements attacking Republican candidate Donald Trump, 11
# attacking Democratic candidate Hillary Clinton, 8 promoting Clinton, and 3 promoting
# Trump."
#
# The counts are of advertisement-week deployments, not of distinct advertisements: the
# distinct counts are 24, 11, 6 and 3.
# covers: methods_n_deployments_anti_trump
report("methods_n_deployments_anti_trump", "Methods, anti-Trump advertisement deployments",
       txt("n_deployments_anti_trump"), 0)
# covers: methods_n_deployments_anti_clinton
report("methods_n_deployments_anti_clinton", "Methods, anti-Clinton advertisement deployments",
       txt("n_deployments_anti_clinton"), 0)
# covers: methods_n_deployments_pro_clinton
report("methods_n_deployments_pro_clinton", "Methods, pro-Clinton advertisement deployments",
       txt("n_deployments_pro_clinton"), 0)
# covers: methods_n_deployments_pro_trump
report("methods_n_deployments_pro_trump", "Methods, pro-Trump advertisement deployments",
       txt("n_deployments_pro_trump"), 0)

# "We are confident that treatments were delivered as intended: Tiny fractions of the
# control groups claimed to have seen campaign advertisements (2 to 4%) compared with
# large majorities of the treatment groups (92 to 95%)."
#
# The range is across the ten waves in which the manipulation check was asked, and the
# shares are unweighted, as in the deposited code. Weighting by the survey weights gives
# a wider range in both groups.
# covers: methods_manip_control_min
report("methods_manip_control_min", "Methods, control group manipulation check, minimum (%)",
       100 * txt("manip_check_control_min"), 0)
# covers: methods_manip_control_max
report("methods_manip_control_max", "Methods, control group manipulation check, maximum (%)",
       100 * txt("manip_check_control_max"), 0)
# covers: methods_manip_treated_min
report("methods_manip_treated_min", "Methods, treatment group manipulation check, minimum (%)",
       100 * txt("manip_check_treated_min"), 0)
# covers: methods_manip_treated_max
report("methods_manip_treated_max", "Methods, treatment group manipulation check, maximum (%)",
       100 * txt("manip_check_treated_max"), 0)

# "The treatment effects in any single 1000-person study are estimated with a fair amount
# of sampling variability, but pooling across weeks via random-effects meta-analysis
# allows us to sharpen the estimates considerably."
# covers: methods_single_study_n
report("methods_single_study_n", "Methods, respondents in a single weekly study",
       txt("weekly_n_min"), 0)

# Results ----

# "In Figure 1, we plot average treatment effect estimates (and 95% confidence intervals)
# for each of our 59 experimental comparisons for our two dependent variables."
# covers: results_n_experiments
report("results_n_experiments", "Results, experimental comparisons plotted in Figure 1",
       sum(figure_1$est_type == "Weekly estimates" & figure_1$dv == "Favorability"), 0)

# "On average, the advertisements moved target candidate favorability 0.049 scale points
# (1 to 5 scale) in the "correct" direction", the analysis being scaled so that the
# treatment effect of promotional advertisements is in the direction of favorability and
# that of attack advertisements is in the opposite direction.
# covers: results_fav_meta_estimate
report("results_fav_meta_estimate", "Results, pooled favorability effect (scale points)",
       f1_meta("Favorability", "estimate"), 3)

# "This estimate, though small, is statistically significant owing to the large size of
# our study."
# covers: desc_fav_meta_significant
report_verdict("desc_fav_meta_significant", "Results, is the pooled favorability effect significant")

# "The effect on target candidate vote choice is also small at 0.7 percentage points, but
# is not statistically significant."
# covers: results_vc_meta_estimate
report("results_vc_meta_estimate", "Results, pooled vote choice effect (percentage points)",
       100 * f1_meta("Vote Choice", "estimate"), 1)
# covers: desc_vc_meta_not_significant
report_verdict("desc_vc_meta_not_significant", "Results, is the pooled vote choice effect insignificant")

# "Using formal tests, we fail to reject the null of homogeneity in both cases
# (favorability, P = 0.09; vote choice, P = 0.07)."
# covers: results_fav_homogeneity_p
report("results_fav_homogeneity_p", "Results, favorability SATE homogeneity p-value",
       s2("sates", "Favorability", "p.value"), 2)
# covers: results_vc_homogeneity_p
report("results_vc_homogeneity_p", "Results, vote choice SATE homogeneity p-value",
       s2("sates", "Vote Choice", "p.value"), 2)

# "If only statistically significant results were published, then we would be left with
# one large negative result (nearly -0.5 points on favorability in early May), one large
# positive result toward the end of the campaign in October (more than +0.5 points), and
# two other negative results in October."
# covers: desc_large_negative_early_may
report("desc_large_negative_early_may",
       "Results, largest significant negative favorability estimate in May",
       desc("desc_large_negative_early_may", "computed"), 1)
cat("    evidence: ", desc("desc_large_negative_early_may", "evidence"), "\n", sep = "")
# covers: desc_large_positive_october
report("desc_large_positive_october",
       "Results, largest significant positive favorability estimate in October",
       desc("desc_large_positive_october", "computed"), 1)
cat("    evidence: ", desc("desc_large_positive_october", "evidence"), "\n", sep = "")
# covers: desc_two_other_negative_october
report("desc_two_other_negative_october",
       "Results, other significant negative favorability estimates in October",
       desc("desc_two_other_negative_october", "computed"), 0)
cat("    evidence: ", desc("desc_two_other_negative_october", "evidence"), "\n", sep = "")

# "The main story of the graph is that treatment effects are similarly small over time,
# but sample sizes of 1000 or 2000 generate week-to-week sampling variability."
# covers: results_sample_size_small
report("results_sample_size_small", "Results, smallest weekly sample", txt("weekly_n_min"), 0)
# covers: results_sample_size_large
report("results_sample_size_large", "Results, largest weekly sample", txt("weekly_n_max"), 0)

# "Turning first to features of receiver, we see that the differences in treatment
# response across Democrats, Independents, and Republicans are small, with SEs greater
# than coefficients."
# covers: desc_partisan_ses_exceed_coefficients
report_verdict("desc_partisan_ses_exceed_coefficients",
               "Results, do the partisanship SEs exceed their coefficients in all eight cells")

# "Independents do not appear to be more malleable than partisans, and neither partisan
# group is more responsive than the other."
# covers: desc_independents_not_more_malleable
report_verdict("desc_independents_not_more_malleable",
               "Results, is any partisanship coefficient distinguishable from zero")

# "Of the three features of context, the slope with respect to the timing of the
# advertisement is negative in three of four specifications and statistically distinct
# from zero in one."
# covers: desc_time_slope_negative_count
report("desc_time_slope_negative_count", "Results, specifications with a negative time slope",
       desc("desc_time_slope_negative_count", "computed"), 0)
cat("    evidence: ", desc("desc_time_slope_negative_count", "evidence"), "\n", sep = "")
# covers: desc_time_slope_significant_count
report("desc_time_slope_significant_count",
       "Results, specifications with a time slope distinguishable from zero",
       desc("desc_time_slope_significant_count", "computed"), 0)
cat("    evidence: ", desc("desc_time_slope_significant_count", "evidence"), "\n", sep = "")

# "Difference in effectiveness for subjects who do and do not live in battleground states
# is 0.008 scale points."
#
# The Results section gives the magnitude; the coefficient itself is negative.
# covers: results_battleground_difference
report("results_battleground_difference",
       "Results, battleground difference in favorability (scale points, magnitude)",
       abs(t1("Candidate favorability (1)", "battleground_d", "estimate")), 3)

# "On average, general election advertisements move candidate favorability by 0.121 scale
# points more than primary advertisements, although the estimate is not precise enough to
# achieve statistical significance."
# covers: results_general_election_coefficient
report("results_general_election_coefficient",
       "Results, general election coefficient (scale points)",
       t1("Candidate favorability (1)", "general_d", "estimate"), 3)
# covers: desc_general_election_not_significant
report_verdict("desc_general_election_not_significant",
               "Results, is the general election coefficient insignificant")

# "The upper bound of the 95% confidence interval for the average difference between
# primary and general election advertisements is about 0.25 scale points on a five-point
# favorability scale."
# covers: results_general_election_ci_upper
report("results_general_election_ci_upper",
       "Results, upper bound of the general election interval (scale points)",
       t1("Candidate favorability (1)", "general_d", "conf.high"), 2)

# "We find that attack advertisements are about as effective in achieving their goals as
# promotional advertisements and that PAC- or SuperPAC-sponsored advertisements are no
# more effective than those sponsored by candidates."
# covers: desc_attack_and_pac_not_significant
report_verdict("desc_attack_and_pac_not_significant",
               "Results, is any tone or sponsor coefficient distinguishable from zero")

# "While pro-Clinton advertisements tended to be more effective than advertisements in
# support of or in opposition to other candidates, these differences cannot be
# distinguished from zero."
# covers: desc_pro_clinton_more_effective
report_verdict("desc_pro_clinton_more_effective",
               "Results, sign of the target candidate coefficients")
# covers: desc_pro_clinton_differences_not_significant
report_verdict("desc_pro_clinton_differences_not_significant",
               "Results, is any target candidate coefficient distinguishable from zero")

# "Figure 2 provides partial support for the "partisan match" theory: Democratic subjects
# respond more strongly to pro-Democratic advertisements than to pro-Republican
# advertisements. However, we do not observe a corresponding pattern among Republican
# respondents: Both pro-Democratic and pro-Republican advertisements have approximately
# the same small, positive, nonsignificant effect."
# covers: desc_partisan_match_democrats
report_verdict("desc_partisan_match_democrats",
               "Results, do Democratic respondents respond more to pro-Democratic advertisements")
# covers: desc_partisan_match_republicans
report_verdict("desc_partisan_match_republicans",
               "Results, do Republican respondents respond similarly to both")

# "For the sample average treatment effects (SATEs) across experiments, P values from
# tests against the null of treatment effect homogeneity are 0.09 for favorability and
# 0.07 for vote choice. For the set of conditional average treatment effects (CATEs), P
# values are 0.0002 and 0.96."
# covers: results_s2_sate_fav_p
report("results_s2_sate_fav_p", "Results, SATE favorability homogeneity p-value, restated",
       s2("sates", "Favorability", "p.value"), 2)
# covers: results_s2_sate_vc_p
report("results_s2_sate_vc_p", "Results, SATE vote choice homogeneity p-value, restated",
       s2("sates", "Vote Choice", "p.value"), 2)
# covers: results_s2_cate_fav_p
report("results_s2_cate_fav_p", "Results, CATE favorability homogeneity p-value",
       s2("cates", "Favorability", "p.value"), 4)
# covers: results_s2_cate_vc_p
report("results_s2_cate_vc_p", "Results, CATE vote choice homogeneity p-value",
       s2("cates", "Vote Choice", "p.value"), 2)

# "While we fail to reject the null hypothesis of treatment effect homogeneity in three of
# four opportunities, we do not affirm that null."
# covers: desc_fail_reject_three_of_four
report("desc_fail_reject_three_of_four",
       "Results, homogeneity tests failing to reject at the 5 per cent level",
       desc("desc_fail_reject_three_of_four", "computed"), 0)
cat("    evidence: ", desc("desc_fail_reject_three_of_four", "evidence"), "\n", sep = "")

# "The square root of the tau-squared statistic is an estimate of the true SD of the
# treatment effects. We estimate this value to be 0.07 (SATEs) and 0.15 (CATEs) for
# favorability on a five-point scale and 0.02 and 0.02 for the vote choice."
# covers: results_tau_sate_favorability
report("results_tau_sate_favorability", "Results, tau, favorability SATEs",
       s2("sates", "Favorability", "tau"), 2)
# covers: results_tau_cate_favorability
report("results_tau_cate_favorability", "Results, tau, favorability CATEs",
       s2("cates", "Favorability", "tau"), 2)
# covers: results_tau_sate_vote_choice
report("results_tau_sate_vote_choice", "Results, tau, vote choice SATEs",
       s2("sates", "Vote Choice", "tau"), 2)
# covers: results_tau_cate_vote_choice
report("results_tau_cate_vote_choice", "Results, tau, vote choice CATEs",
       s2("cates", "Vote Choice", "tau"), 2)

# Discussion ----

# "Our 59 experiments demonstrate this."
# covers: discussion_n_experiments
report("discussion_n_experiments", "Discussion, experiments", txt("n_ad_week_deployments"), 0)

# "The present study is unusual in its size (34,000 nationally representative subjects)
# and breadth of treatments (a purposive sample of 49 of the highest-profile presidential
# advertisements fielded in the midst of the 2016 presidential election), allowing us to
# systematically investigate how variations in message, context, sender, or receiver
# condition persuasive effects".
# covers: discussion_n_respondents
report("discussion_n_respondents", "Discussion, respondents", txt("n_respondents"), 0)
# covers: discussion_n_ads
report("discussion_n_ads", "Discussion, distinct advertisements", txt("n_unique_ads"), 0)

# Figure 1 ----
# The figure prints two annotations, one per facet, each an estimate with its standard
# error in parentheses.
# covers: figure_1_fav_estimate
report("figure_1_fav_estimate", "Figure 1, favorability meta-analytic estimate",
       f1_meta("Favorability", "estimate"), 3)
# covers: figure_1_fav_se
report("figure_1_fav_se", "Figure 1, favorability meta-analytic standard error",
       f1_meta("Favorability", "std.error"), 3)
# covers: figure_1_vc_estimate
report("figure_1_vc_estimate", "Figure 1, vote choice meta-analytic estimate",
       f1_meta("Vote Choice", "estimate"), 3)
# covers: figure_1_vc_se
report("figure_1_vc_se", "Figure 1, vote choice meta-analytic standard error",
       f1_meta("Vote Choice", "std.error"), 3)

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
    report(est_id, str_glue("Table 1, model {i}, {term_name}, estimate"),
           t1(table_1_models[i], term_name, "estimate"), paper_digits(est_id))
    report(se_id, str_glue("Table 1, model {i}, {term_name}, standard error"),
           t1(table_1_models[i], term_name, "std.error"), paper_digits(se_id))
  }
  report(str_glue("table_1_m{i}_nobs"),
         str_glue("Table 1, model {i}, number of observations"),
         t1(table_1_models[i], "intrcpt", "nobs"), 0)

}

# The three cells the published table marks with an asterisk.
# covers: desc_table_1_m1_intrcpt_star
report_verdict("desc_table_1_m1_intrcpt_star", "Table 1, model 1 average effect starred")
# covers: desc_table_1_m2_intrcpt_star
report_verdict("desc_table_1_m2_intrcpt_star", "Table 1, model 2 average effect starred")
# covers: desc_table_1_m3_date_d_star
report_verdict("desc_table_1_m3_date_d_star", "Table 1, model 3 time slope starred")

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
  report(str_glue("{stem}_est"),
         str_glue("Figure 2, {ids$outcome_variable}, {ids$respondent_pid}, {ids$ad_type}, estimate"),
         f2(ids$outcome_variable, ids$respondent_pid, ids$ad_type, "estimate"), 3)
  report(str_glue("{stem}_se"),
         str_glue("Figure 2, {ids$outcome_variable}, {ids$respondent_pid}, {ids$ad_type}, standard error"),
         f2(ids$outcome_variable, ids$respondent_pid, ids$ad_type, "std.error"), 3)
}

# Appendix A: Treatments ----

# "Table S1 shows the name and target of the 50 unique advertisements and the week they
# were deployed."
#
# Two of the 49 distinct advertisements share the title "Sacrifice" and the week of
# 5 September, so the table's body carries 48 distinct names.
# covers: appendix_a_n_unique_ads
report("appendix_a_n_unique_ads", "Appendix A, distinct advertisements", txt("n_unique_ads"), 0)

# "Some advertisements ("America," "Love/Kindness," "Man of People," "Mirrors," "Quotes,"
# "Real Life," "Role Model," "Speak") were shown in multiple weeks, enabling us to
# estimate how the effect of the same advertisement may vary with the changing electoral
# context."
# covers: appendix_a_n_repeat_ads_named
report("appendix_a_n_repeat_ads_named", "Appendix A, advertisements fielded in more than one week",
       txt("n_ads_fielded_more_than_once"), 0)

# "Including the ads we deployed more than once, we tested 28 ads that attacked Trump,
# nine attacks on Clinton, nine Clinton promotional ads, and three promotional Trump ads."
# covers: appendix_a_n_anti_trump
report("appendix_a_n_anti_trump", "Appendix A, anti-Trump deployments",
       txt("n_deployments_anti_trump"), 0)
# covers: appendix_a_n_anti_clinton
report("appendix_a_n_anti_clinton", "Appendix A, anti-Clinton deployments",
       txt("n_deployments_anti_clinton"), 0)
# covers: appendix_a_n_pro_clinton
report("appendix_a_n_pro_clinton", "Appendix A, pro-Clinton deployments",
       txt("n_deployments_pro_clinton"), 0)
# covers: appendix_a_n_pro_trump
report("appendix_a_n_pro_trump", "Appendix A, pro-Trump deployments",
       txt("n_deployments_pro_trump"), 0)

# Table S1 ----
# The table itself carries no coefficients. What it states is its own shape: one row per
# week of the study, and one entry per advertisement fielded in that week.
# covers: table_s1_n_weeks
report("table_s1_n_weeks", "Table S1, weeks listed", nrow(table_s1), 0)
# covers: table_s1_n_ad_entries
report("table_s1_n_ad_entries", "Table S1, advertisement-week entries",
       sum(!is.na(as.matrix(select(table_s1, -date_formatted)))), 0)

# Appendix B: Repeat advertisements ----

# "In this section, we present an analysis of the seven ads that we fielded more than
# once, first in the week they were released by the campaigns and then again in later
# weeks."
# covers: appendix_b_n_repeat_ads
report("appendix_b_n_repeat_ads", "Appendix B, advertisements fielded more than once",
       txt("n_ads_fielded_more_than_once"), 0)

# "However, as Figure S1 shows, the effects of ads are remarkably consistent over time. In
# no case does the estimate of an ad's effectiveness significantly vary with the week of
# experiment."
# covers: desc_repeat_ads_no_significant_variation
report_verdict("desc_repeat_ads_no_significant_variation",
               "Appendix B, does any repeat advertisement vary significantly across weeks")

# "In the case of "Quotes," the estimate appears to increase in size as Trump's treatment
# of women increases in salience mid-year (the end of the primaries) perhaps in concert
# with a CNN interview on the topic, but this is entirely speculative."
# covers: desc_repeat_ad_quotes_increases
report_verdict("desc_repeat_ad_quotes_increases", "Appendix B, the weekly estimates for Quotes")

# Figure S1 ----
# The panels print no numbers, so what the figure states is its own shape.
# covers: figure_s1_n_panels
report("figure_s1_n_panels", "Figure S1, panels", n_distinct(figure_s1$ad_id), 0)
# covers: figure_s1_n_weekly_estimates
report("figure_s1_n_weekly_estimates", "Figure S1, weekly estimates plotted", nrow(figure_s1), 0)

# Appendix C and Table S2 ----
# Every published cell of the heterogeneity table, at the four decimals the page prints.
# covers: table_s2_*
table_s2_quantities <- c(est = "estimate", se = "std.error", p = "p.value",
                         tau2 = "tau2", tau = "tau")

for (estimand_label in c("sates", "cates")) {
  for (dv_label in c("Favorability", "Vote Choice")) {
    dv_slug <- str_remove_all(str_to_lower(dv_label), " ")
    for (suffix in names(table_s2_quantities)) {
      report(str_glue("table_s2_{estimand_label}_{dv_slug}_{suffix}"),
             str_glue("Table S2, {estimand_label}, {dv_label}, {table_s2_quantities[[suffix]]}"),
             s2(estimand_label, dv_label, table_s2_quantities[[suffix]]), 4)
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
  report(str_glue("table_s3_{cell$week_slug}_{cell$condition_slug}"),
         str_glue("Table S3, {cell$date_formatted}, {cell$condition}"),
         cell$n, 0)
}
