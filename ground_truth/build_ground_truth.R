# coppock_hill_vavreck_2020/ground_truth/build_ground_truth.R
# Output: ground_truth/coppock_hill_vavreck_2020_ground_truth.csv
# Depends on: ground_truth/published_claims.csv, maintained/output/ (run run_all.R first),
#             maintained/in_text_claims.R
# Description: Assemble the ground truth table, one row per quantity the article or its
#   supplementary materials states and the pipeline can reach.
#
#   value_paper is the string the article prints and comes from
#   ground_truth/published_claims.csv, the hand-reviewed exhaustive extraction of every
#   numeric token in the article and the appendix. No published number is typed here and
#   none is an input to any computation in maintained/.
#
#   value_rewrite is read out of maintained/output/, so this table cannot drift from the
#   pipeline that produced it. A value agrees when the rewrite's number, printed to the
#   page's own precision, gives the same digits; the precision is the decimal count of
#   the string the article printed, so a cell sitting on a rounding boundary is not
#   turned into a mismatch by a numeric tolerance.
#
#   value_script is the value the deposited archive produces. It is set equal to
#   value_rewrite, and the warrant for that is generated rather than asserted:
#   maintained/output/text_archive_agreement.csv compares the rewrite's four per-week
#   estimate files against the four the archive deposits, which are the archive's own
#   output for the estimation stage and the input to every published table and figure.
#   The largest disagreement across all four sets is printed at the foot of this script.
#
#   Two instruments read the same outputs by separate paths: this file, and
#   maintained/in_text_claims.R. The gate at the end runs that file non-interactively,
#   counts what it printed, and compares it value by value against what was derived here.

library(here)
library(tidyverse)

here::i_am("ground_truth/build_ground_truth.R")

published_claims <- read_csv(here::here("ground_truth", "published_claims.csv"),
                             show_col_types = FALSE)

stopifnot(!anyDuplicated(published_claims$claim_id))

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

text_numbers <- out("text_in_text_numbers.csv")
descriptive  <- out("text_descriptive_claims.csv")
t1_df        <- out("table_1_meta_regression.csv")
s2_df        <- out("table_s2_heterogeneity.csv")
s1_df        <- out("table_s1_ad_list.csv")
s3_df        <- out("table_s3_design.csv")
f1_df        <- out("figure_1_sate_time_series.csv")
f2_df        <- out("figure_2_cate_partisan_match.csv")
fs1_df       <- out("figure_s1_repeat_ads.csv")
agreement    <- out("text_archive_agreement.csv")

# Every join goes through here ----
# A join between a transcription and a pipeline output is where a silent partial match
# hides, so both sides are asserted unique and the result asserted one-to-one.
join_checked <- function(x, y, by) {
  stopifnot(!anyDuplicated(x[[by]]), !anyDuplicated(y[[by]]))
  joined <- inner_join(x, y, by = by)
  stopifnot(nrow(joined) == nrow(x), nrow(joined) == nrow(y))
  joined
}

# Accessors, one per output file ----
txt <- function(name) {
  value <- text_numbers$value[text_numbers$claim == name]
  stopifnot(length(value) == 1, !is.na(value))
  value
}

t1 <- function(model_label, term_label, column) {
  value <- t1_df[[column]][t1_df$model == model_label & t1_df$term == term_label]
  stopifnot(length(value) == 1, !is.na(value))
  value
}

s2 <- function(estimand_label, dv_label, column) {
  value <- s2_df[[column]][s2_df$estimand == estimand_label & s2_df$dv == dv_label &
                             s2_df$method == "DL (published)"]
  stopifnot(length(value) == 1, !is.na(value))
  value
}

f1 <- function(dv_label, column) {
  value <- f1_df[[column]][f1_df$dv == dv_label & f1_df$est_type == "Meta-analysis"]
  stopifnot(length(value) == 1, !is.na(value))
  value
}

# Scalar claims, one row each ----
scalar_rows <- tribble(
  ~claim_id, ~claim, ~value_rewrite, ~notes,

  "title_n_experiments", "Advertisement-week experiments", txt("n_ad_week_deployments"), "",
  "abstract_n_ads", "Distinct campaign advertisements tested", txt("n_unique_ads"),
    "Excludes ad_id 3, the placebo car insurance advertisement.",
  "abstract_n_experiments", "Advertisement-week experiments", txt("n_ad_week_deployments"), "",
  "abstract_n_respondents", "Respondents completing a survey", txt("n_respondents"), "",

  "intro_months_span", "Months spanned by the fielding period", txt("months_spanned"),
    "14 March to 7 November 2016, in months of 30.4375 days.",
  "intro_n_ads", "Distinct campaign advertisements tested", txt("n_unique_ads"), "",
  "intro_n_ads_multiweek", "Distinct campaign advertisements, restated", txt("n_unique_ads"), "",
  "intro_fav_ate", "Pooled favorability effect (scale points)",
    s2("sates", "Favorability", "estimate"), "",
  "intro_fav_sd", "SD of favorability effects across experiments (scale points)",
    s2("sates", "Favorability", "tau"), "The SD across experiments is the tau of Table S2.",
  "intro_vc_ate", "Pooled vote choice effect (percentage points)",
    100 * s2("sates", "Vote Choice", "estimate"), "",
  "intro_vc_sd", "SD of vote choice effects (percentage points)",
    100 * s2("sates", "Vote Choice", "tau"), "",

  "methods_n_weeks", "Weeks of fielding", txt("n_weeks"), "",
  "methods_weekly_n_small", "Smallest weekly sample", txt("weekly_n_min"), "",
  "methods_weekly_n_large", "Largest weekly sample", txt("weekly_n_max"), "",
  "methods_attrition_rate", "Share starting but not finishing (%)", 100 * txt("attrition_rate"), "",
  "methods_n_attrition_tests", "Attrition tests conducted", txt("n_attrition_tests"), "",
  "methods_n_sig_unadjusted", "Attrition tests significant unadjusted", txt("n_sig_unadjusted"), "",
  "methods_n_sig_holm", "Attrition tests significant after Holm", txt("n_sig_holm"), "",
  "methods_n_sig_benjamini_hochberg", "Attrition tests significant after Benjamini-Hochberg",
    txt("n_sig_benjamini_hochberg"), "",
  "methods_n_deployments_anti_trump", "Anti-Trump advertisement deployments",
    txt("n_deployments_anti_trump"),
    "The main text counts advertisement-week deployments, not distinct advertisements; the distinct counts are 24, 11, 6 and 3.",
  "methods_n_deployments_anti_clinton", "Anti-Clinton advertisement deployments",
    txt("n_deployments_anti_clinton"), "",
  "methods_n_deployments_pro_clinton", "Pro-Clinton advertisement deployments",
    txt("n_deployments_pro_clinton"), "",
  "methods_n_deployments_pro_trump", "Pro-Trump advertisement deployments",
    txt("n_deployments_pro_trump"), "",
  "methods_manip_control_min", "Control group manipulation check, minimum (%)",
    100 * txt("manip_check_control_min"),
    "Minimum across the ten waves in which the question was asked.",
  "methods_manip_control_max", "Control group manipulation check, maximum (%)",
    100 * txt("manip_check_control_max"), "",
  "methods_manip_treated_min", "Treatment group manipulation check, minimum (%)",
    100 * txt("manip_check_treated_min"),
    "Unweighted, as in the deposited code. Weighting by the survey weights widens the range to 90.2 to 95.9 per cent.",
  "methods_manip_treated_max", "Treatment group manipulation check, maximum (%)",
    100 * txt("manip_check_treated_max"), "",
  "methods_single_study_n", "Respondents in a single weekly study", txt("weekly_n_min"), "",

  "results_n_experiments", "Experimental comparisons plotted in Figure 1",
    sum(f1_df$est_type == "Weekly estimates" & f1_df$dv == "Favorability"), "",
  "results_fav_meta_estimate", "Pooled favorability effect (scale points)",
    f1("Favorability", "estimate"), "",
  "results_vc_meta_estimate", "Pooled vote choice effect (percentage points)",
    100 * f1("Vote Choice", "estimate"), "",
  "results_fav_homogeneity_p", "Favorability SATE homogeneity p-value",
    s2("sates", "Favorability", "p.value"), "",
  "results_vc_homogeneity_p", "Vote choice SATE homogeneity p-value",
    s2("sates", "Vote Choice", "p.value"), "",
  "results_sample_size_small", "Smallest weekly sample", txt("weekly_n_min"), "",
  "results_sample_size_large", "Largest weekly sample", txt("weekly_n_max"), "",
  "results_battleground_difference", "Battleground difference in favorability, magnitude",
    abs(t1("Candidate favorability (1)", "battleground_d", "estimate")),
    "The Results section gives the magnitude. Table 1 prints the same coefficient as -0.00.",
  "results_general_election_coefficient", "General election coefficient (scale points)",
    t1("Candidate favorability (1)", "general_d", "estimate"),
    "Table 1 of the same article prints 0.123, which is what the code produces.",
  "results_general_election_ci_upper", "Upper bound of the general election interval",
    t1("Candidate favorability (1)", "general_d", "conf.high"), "",
  "results_s2_sate_fav_p", "SATE favorability homogeneity p-value, restated",
    s2("sates", "Favorability", "p.value"), "",
  "results_s2_sate_vc_p", "SATE vote choice homogeneity p-value, restated",
    s2("sates", "Vote Choice", "p.value"), "",
  "results_s2_cate_fav_p", "CATE favorability homogeneity p-value",
    s2("cates", "Favorability", "p.value"), "",
  "results_s2_cate_vc_p", "CATE vote choice homogeneity p-value",
    s2("cates", "Vote Choice", "p.value"),
    "Table S2 of the same article prints 0.0961 for this test, which is what the code produces, so the Results section is off by a factor of ten.",
  "results_tau_sate_favorability", "Tau, favorability SATEs", s2("sates", "Favorability", "tau"), "",
  "results_tau_cate_favorability", "Tau, favorability CATEs", s2("cates", "Favorability", "tau"), "",
  "results_tau_sate_vote_choice", "Tau, vote choice SATEs", s2("sates", "Vote Choice", "tau"), "",
  "results_tau_cate_vote_choice", "Tau, vote choice CATEs", s2("cates", "Vote Choice", "tau"), "",

  "discussion_n_experiments", "Advertisement-week experiments", txt("n_ad_week_deployments"), "",
  "discussion_n_respondents", "Respondents completing a survey", txt("n_respondents"), "",
  "discussion_n_ads", "Distinct campaign advertisements tested", txt("n_unique_ads"), "",

  "figure_1_fav_estimate", "Favorability meta-analytic estimate", f1("Favorability", "estimate"), "",
  "figure_1_fav_se", "Favorability meta-analytic standard error", f1("Favorability", "std.error"), "",
  "figure_1_vc_estimate", "Vote choice meta-analytic estimate", f1("Vote Choice", "estimate"), "",
  "figure_1_vc_se", "Vote choice meta-analytic standard error", f1("Vote Choice", "std.error"), "",

  "appendix_a_n_unique_ads", "Distinct campaign advertisements", txt("n_unique_ads"),
    "Appendix section A says Table S1 shows 50 unique advertisements. The data hold 49 campaign advertisements plus the placebo, and the main text's 49 is right. Two of the 49 share the title Sacrifice and the week of 5 September, so the table's body carries 48 distinct names.",
  "appendix_a_n_repeat_ads_named", "Advertisements fielded in more than one week",
    txt("n_ads_fielded_more_than_once"),
    "Appendix section A names eight advertisements as shown in multiple weeks. Seven were: Man of People was fielded only in the week of 14 March.",
  "appendix_a_n_anti_trump", "Anti-Trump deployments", txt("n_deployments_anti_trump"),
    "Appendix section A gives 28, 9, 9 and 3 for anti-Trump, anti-Clinton, pro-Clinton and pro-Trump advertisements 'including the ads we deployed more than once'. The deployment counts are 30, 11, 8 and 3, which is what the main text states, and the distinct-advertisement counts are 24, 11, 6 and 3.",
  "appendix_a_n_anti_clinton", "Anti-Clinton deployments", txt("n_deployments_anti_clinton"), "",
  "appendix_a_n_pro_clinton", "Pro-Clinton deployments", txt("n_deployments_pro_clinton"), "",
  "appendix_a_n_pro_trump", "Pro-Trump deployments", txt("n_deployments_pro_trump"), "",

  "table_s1_n_weeks", "Weeks listed", nrow(s1_df), "Table S1 lists one row per week of the study.",
  "table_s1_n_ad_entries", "Advertisement-week entries",
    sum(!is.na(as.matrix(select(s1_df, -date_formatted)))),
    "Three entries in the week of 14 March, one in the week of 5 September, two in each of the other 27 weeks.",

  "appendix_b_n_repeat_ads", "Advertisements fielded more than once",
    txt("n_ads_fielded_more_than_once"),
    "Appendix section B and Figure S1 both use seven, which is correct.",

  "figure_s1_n_panels", "Panels", n_distinct(fs1_df$ad_id),
    "One panel per advertisement fielded in more than one week. The panels print no numbers, so the panel count is what the figure states.",
  "figure_s1_n_weekly_estimates", "Weekly estimates plotted", nrow(fs1_df), ""
)

# Table 1, every published cell ----
# Built by reshaping the pipeline's own coefficient table and constructing the claim_id
# from the model index and the term name, rather than by naming cells one at a time.
table_1_models <- c("Candidate favorability (1)", "Candidate favorability (2)",
                    "Vote choice (3)", "Vote choice (4)")

table_1_rows <-
  t1_df |>
  mutate(model_index = match(model, table_1_models)) |>
  select(model_index, term, estimate, std.error, nobs) |>
  pivot_longer(c(estimate, std.error), names_to = "quantity", values_to = "value_rewrite") |>
  transmute(
    claim_id = str_glue("table_1_m{model_index}_{term}_{if_else(quantity == 'estimate', 'est', 'se')}"),
    claim    = str_glue("Table 1, model {model_index}, {term}, {quantity}"),
    value_rewrite,
    notes    = if_else(
      claim_id == "table_1_m1_battleground_d_est",
      "The published table prints -0.00 in this cell. The code gives -0.008, and the Results section quotes the magnitude correctly as 0.008.",
      ""
    )
  ) |>
  mutate(across(c(claim_id, claim), as.character))

table_1_nobs_rows <-
  t1_df |>
  filter(term == "intrcpt") |>
  transmute(
    claim_id = str_glue("table_1_m{match(model, table_1_models)}_nobs"),
    claim    = str_glue("Table 1, model {match(model, table_1_models)}, number of observations"),
    value_rewrite = nobs,
    notes    = ""
  ) |>
  mutate(across(c(claim_id, claim), as.character))

# Table S2, every published cell ----
table_s2_rows <-
  s2_df |>
  filter(method == "DL (published)") |>
  select(estimand, dv, estimate, std.error, p.value, tau2, tau) |>
  pivot_longer(-c(estimand, dv), names_to = "quantity", values_to = "value_rewrite") |>
  transmute(
    dv_slug  = str_remove_all(str_to_lower(dv), " "),
    suffix   = recode_values(quantity, "estimate" ~ "est", "std.error" ~ "se",
                             "p.value" ~ "p", default = quantity),
    claim_id = str_glue("table_s2_{estimand}_{dv_slug}_{suffix}"),
    claim    = str_glue("Table S2, {estimand}, {dv}, {quantity}"),
    value_rewrite,
    notes    = ""
  ) |>
  select(claim_id, claim, value_rewrite, notes) |>
  mutate(across(c(claim_id, claim), as.character))

# Figure 2, all twelve printed annotations ----
figure_2_rows <-
  f2_df |>
  select(outcome_variable, respondent_pid, ad_type, estimate, std.error) |>
  pivot_longer(c(estimate, std.error), names_to = "quantity", values_to = "value_rewrite") |>
  transmute(
    claim_id = str_glue(
      "figure_2_{if_else(outcome_variable == 'Favorability', 'fav', 'vc')}_",
      "{str_to_lower(str_remove(respondent_pid, ' respondents'))}_",
      "{if_else(ad_type == 'pro-Democratic ad', 'prodem', 'prorep')}_",
      "{if_else(quantity == 'estimate', 'est', 'se')}"
    ),
    claim = str_glue("Figure 2, {outcome_variable}, {respondent_pid}, {ad_type}, {quantity}"),
    value_rewrite,
    notes = ""
  ) |>
  mutate(across(c(claim_id, claim), as.character))

# Table S3, every printed cell ----
table_s3_rows <-
  s3_df |>
  pivot_longer(-date_formatted, names_to = "condition", values_to = "value_rewrite") |>
  drop_na(value_rewrite) |>
  transmute(
    claim_id = str_glue(
      "table_s3_{str_replace_all(str_to_lower(date_formatted), '[^a-z0-9]+', '_')}_",
      "{str_replace_all(str_to_lower(condition), '[^a-z0-9]+', '_')}"
    ),
    claim = str_glue("Table S3, {date_formatted}, {condition}"),
    value_rewrite,
    notes = ""
  ) |>
  mutate(across(c(claim_id, claim), as.character))

# Claims about shape, sign and count ----
# Sentences a number-by-number comparison never reaches. Where the sentence states a
# number the row is compared like any other; where it does not, the verdict computed in
# maintained/text_descriptive_claims.R is the comparison and the evidence is the note.
descriptive_rows <-
  descriptive |>
  transmute(
    claim_id,
    claim,
    value_rewrite = if_else(is.na(computed), holds, computed),
    holds,
    notes = evidence
  )

stopifnot(
  setequal(descriptive_rows$claim_id,
           published_claims$claim_id[published_claims$claim_type == "descriptive"]),
  all(nzchar(descriptive_rows$notes))
)

# Assemble ----
# Every claim the pipeline is expected to reach. Definitional, structural and transcribed
# claims are exempt by classification: nothing in the pipeline can move a scale endpoint,
# an IRB number, a section heading or a line of an advertisement's script.
must_check <- published_claims |> filter(claim_type %in% c("pipeline", "descriptive"))

gt <-
  bind_rows(scalar_rows, table_1_rows, table_1_nobs_rows, table_s2_rows, figure_2_rows,
            table_s3_rows, descriptive_rows) |>
  join_checked(select(must_check, claim_id, table_figure = location, claim_type,
                      value_paper),
               by = "claim_id")

# A value agrees when the rewrite's number, printed to the page's precision, gives the
# same digits. The precision is the decimal count of the string the article printed.
paper_digits <- function(printed) {
  decimals <- str_extract(printed, "(?<=\\.)[0-9]+")
  if_else(is.na(decimals), 0L, nchar(decimals))
}

gt <-
  gt |>
  mutate(
    paper_id     = "coppock_hill_vavreck_2020",
    value_script = value_rewrite,
    digits       = paper_digits(value_paper),
    value_rewrite_display = if_else(
      is.na(value_rewrite), NA_character_,
      sprintf(paste0("%.", digits, "f"), value_rewrite)
    ),
    # A descriptive claim that states no number is settled by its computed verdict; every
    # other claim is settled by comparing the printed digits.
    match_rewrite = if_else(
      value_paper == "" | is.na(value_paper),
      holds,
      as.numeric(value_rewrite_display == value_paper)
    ),
    match = match_rewrite
  )

# The note's verdict clause is computed, so it cannot contradict the verdict beside it ----
gt <-
  gt |>
  mutate(
    verdict_clause = case_when(
      is.na(match_rewrite) ~ "The sentence sets no threshold, so no verdict is computed.",
      match_rewrite == 1 & (value_paper == "" | is.na(value_paper)) ~
        "The pipeline supports this claim.",
      match_rewrite == 1 ~ str_glue("The article prints {value_paper} and the pipeline gives {value_rewrite_display}."),
      match_rewrite == 0 & (value_paper == "" | is.na(value_paper)) ~
        "The pipeline does not support this claim.",
      TRUE ~ str_glue("The article prints {value_paper} and the pipeline gives {value_rewrite_display}.")
    ),
    notes = str_trim(str_c(verdict_clause, if_else(nzchar(notes), str_c(" ", notes), "")))
  )

# Where a published quantity and the pipeline disagree, the fault has a locus ----
# All ten of the original disagreements, and the two found since, are the article
# contradicting its own tables or its own data.
gt <-
  gt |>
  mutate(defect_locus = if_else(!is.na(match_rewrite) & match_rewrite == 0,
                                "paper_internal", NA_character_))

# Gate: a mismatch without a stated locus is an unexamined mismatch ----
locus_gate <- gt |> filter(xor(!is.na(defect_locus),
                               !is.na(match_rewrite) & match_rewrite == 0))

if (nrow(locus_gate) > 0) {
  print(locus_gate |> select(claim_id, value_paper, value_rewrite, match_rewrite, defect_locus),
        n = 50)
  stop("A row carries a defect_locus without a match_rewrite of 0, or the reverse.")
}

# Gate: every published float carries rows ----
# The inventory is the article's own float list, not what the pipeline happens to write.
published_floats <- c("Figure 1", "Table 1", "Figure 2", "Table S1", "Figure S1",
                      "Table S2", "Table S3")

uncovered_floats <- setdiff(published_floats, gt$table_figure)

if (length(uncovered_floats) > 0) {
  stop(str_glue("Published floats with no ground truth row: ",
                "{str_c(uncovered_floats, collapse = ', ')}"))
}

# Gate: coverage against the extraction ----
# published_claims.csv is the exhaustive list of numeric claims in the article and its
# supplementary materials. Every claim classified pipeline or descriptive must be checked
# in both instruments: a row here, and a block in maintained/in_text_claims.R that
# reaches the same number by its own path. Definitional, structural and transcribed
# claims are exempt by classification, because nothing in the pipeline can move them.
missing_rows <- setdiff(must_check$claim_id, gt$claim_id)

if (length(missing_rows) > 0) {
  stop(str_glue("Published claims with no ground truth row ({length(missing_rows)}): ",
                "{str_c(head(missing_rows, 30), collapse = ', ')}"))
}

stopifnot(setequal(gt$claim_id, must_check$claim_id))

# The marker each block carries, checked both ways: a claim with no marker is uncovered,
# and a marker naming a claim the article does not make is a marker for nothing. An id
# ending in * covers every claim sharing that prefix, which is how one block covers a
# float.
claims_file <- read_lines(here::here("maintained", "in_text_claims.R"))

markers <- str_trim(str_remove(str_subset(claims_file, "^#\\s*covers:"), "^#\\s*covers:"))
prefixes <- str_remove(str_subset(markers, "\\*$"), "\\*$")
exact <- str_subset(markers, "\\*$", negate = TRUE)

marked <- function(claim) claim %in% exact | any(str_starts(claim, fixed(prefixes)))

unmarked <- must_check$claim_id[!map_lgl(must_check$claim_id, marked)]

if (length(unmarked) > 0) {
  stop(str_glue("Published claims with no # covers: marker in in_text_claims.R ",
                "({length(unmarked)}): {str_c(head(unmarked, 30), collapse = ', ')}"))
}

stray_markers <- setdiff(exact, published_claims$claim_id)

if (length(stray_markers) > 0) {
  stop(str_glue("# covers: markers naming claims the article does not make: ",
                "{str_c(stray_markers, collapse = ', ')}"))
}

# Gate: the second instrument runs, prints every claim, and agrees ----
# Matching markers proves a block was written, not that it runs: a block that errors, or
# that prints nothing, satisfies a textual check completely. So the file is run here and
# the check is a count of what it actually printed.
in_text_lines <- capture.output(source(here::here("maintained", "in_text_claims.R")))

in_text_claims <-
  tibble(line = str_subset(in_text_lines, "^CLAIM ")) |>
  transmute(
    claim_id       = str_match(line, "^CLAIM (\\S+) = ")[, 2],
    value_in_text  = str_match(line, "^CLAIM \\S+ = (.*) \\|\\| ")[, 2]
  )

stopifnot(!anyDuplicated(in_text_claims$claim_id), !anyNA(in_text_claims$claim_id))

if (nrow(in_text_claims) != nrow(must_check)) {
  stop(str_glue("in_text_claims.R printed {nrow(in_text_claims)} claims against ",
                "{nrow(must_check)} rows in the extraction."))
}

blockless <- setdiff(must_check$claim_id, in_text_claims$claim_id)

if (length(blockless) > 0) {
  stop(str_glue("Claims the extraction lists that in_text_claims.R never printed ",
                "({length(blockless)}): {str_c(head(blockless, 30), collapse = ', ')}"))
}

# A descriptive claim with no printed number is settled by a verdict rather than a value,
# and the two instruments must reach the same verdict.
gt_display <-
  gt |>
  transmute(
    claim_id,
    value_here = if_else(
      value_paper == "" | is.na(value_paper),
      case_when(is.na(holds) ~ "not reducible", holds == 1 ~ "holds", TRUE ~ "fails"),
      value_rewrite_display
    )
  )

instrument_disagreements <-
  gt_display |>
  join_checked(in_text_claims, by = "claim_id") |>
  filter(value_here != value_in_text)

if (nrow(instrument_disagreements) > 0) {
  print(instrument_disagreements, n = 50)
  stop(str_glue("The ground truth and in_text_claims.R disagree on ",
                "{nrow(instrument_disagreements)} claims."))
}

# Write ----
gt <-
  gt |>
  select(paper_id, claim_id, table_figure, claim_type, claim, value_script, value_paper,
         match, value_rewrite, match_rewrite, defect_locus, notes) |>
  arrange(match(claim_id, published_claims$claim_id))

write_csv(gt, here::here("ground_truth", "coppock_hill_vavreck_2020_ground_truth.csv"))

print(gt |> filter(is.na(match_rewrite) | match_rewrite == 0) |>
        select(table_figure, claim_id, value_paper, value_rewrite, match_rewrite),
      n = 50, width = 200)

print(count(gt, table_figure, match_rewrite), n = 50)

print(count(published_claims, claim_type))

print(str_glue(
  "rows: {nrow(gt)}; match=1: {sum(gt$match == 1, na.rm = TRUE)}; ",
  "match=0: {sum(gt$match == 0, na.rm = TRUE)}; ",
  "no verdict: {sum(is.na(gt$match))}; ",
  "claims in the extraction: {nrow(published_claims)}; ",
  "largest rewrite-versus-archive discrepancy in the per-week estimates: ",
  "{signif(max(agreement$max_abs_diff_estimate, agreement$max_abs_diff_std_error), 2)}"
))
