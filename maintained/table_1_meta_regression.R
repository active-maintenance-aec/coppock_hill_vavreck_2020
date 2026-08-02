# coppock_hill_vavreck_2020/maintained/table_1_meta_regression.R
# Output: output/table_1_meta_regression.csv, output/table_1_meta_regression.tex
# Depends on: output/favorability_cates.rds, output/vote_choice_cates.rds, helpers.R
# Description: Table 1: meta-regression of conditional average treatment effects on
#   context, message, sender and receiver moderators.

source(here::here("maintained", "helpers.R"))

favorability_cates <- read_rds(here::here("maintained", "output", "favorability_cates.rds"))
vote_choice_cates  <- read_rds(here::here("maintained", "output", "vote_choice_cates.rds"))

# Every moderator is demeaned in the cleaning scripts, so each intercept is the
# average treatment effect rather than the effect in the omitted category.
fit_1 <- rma.uni(
  yi = estimate, sei = std.error,
  mods = ~ date_d + general_d + attack_d + democrat_d + independent_d + battleground_d + pac_d,
  data = favorability_cates
)

fit_2 <- rma.uni(
  yi = estimate, sei = std.error,
  mods = ~ date_d + pro_sanders_d + pro_trump_d + pro_cruz_d + pro_kasich_d +
           anti_clinton_d + anti_trump_d + democrat_d + independent_d + battleground_d + pac_d,
  data = favorability_cates
)

fit_3 <- rma.uni(
  yi = estimate, sei = std.error,
  mods = ~ date_d + attack_d + democrat_d + independent_d + battleground_d + pac_d,
  data = vote_choice_cates
)

fit_4 <- rma.uni(
  yi = estimate, sei = std.error,
  mods = ~ date_d + pro_trump_d + anti_clinton_d + anti_trump_d +
           democrat_d + independent_d + battleground_d + pac_d,
  data = vote_choice_cates
)

fits <- list(
  "Candidate favorability (1)" = fit_1,
  "Candidate favorability (2)" = fit_2,
  "Vote choice (3)"            = fit_3,
  "Vote choice (4)"            = fit_4
)

# Full coefficient table, at full precision ----
coefs <-
  imap(fits, function(fit, label) {
    tibble(
      model     = label,
      term      = rownames(fit$beta),
      estimate  = as.numeric(fit$beta),
      std.error = fit$se,
      statistic = fit$zval,
      p.value   = fit$pval,
      conf.low  = fit$ci.lb,
      conf.high = fit$ci.ub,
      nobs      = fit$k
    )
  }) |>
  list_rbind()

write_csv(coefs, here::here("maintained", "output", "table_1_meta_regression.csv"))

# Display table, in the published row order ----
coef_labels <- c(
  intercept      = "Average effect",
  democrat_d     = "Democratic respondent (versus Republican)",
  independent_d  = "Independent respondent (versus Republican)",
  battleground_d = "Battleground state (versus non-battleground)",
  pac_d          = "PAC sponsor (versus campaign sponsor)",
  date_d         = "Time (scaled in months)",
  attack_d       = "Attack advertisement (versus promotional advertisement)",
  general_d      = "General election (versus primary election)",
  pro_trump_d    = "Pro-Trump advertisement (versus pro-Clinton advertisement)",
  anti_clinton_d = "Anti-Clinton advertisement (versus pro-Clinton advertisement)",
  anti_trump_d   = "Anti-Trump advertisement (versus pro-Clinton advertisement)",
  pro_sanders_d  = "Pro-Sanders advertisement (versus pro-Clinton advertisement)",
  pro_cruz_d     = "Pro-Cruz advertisement (versus pro-Clinton advertisement)",
  pro_kasich_d   = "Pro-Kasich advertisement (versus pro-Clinton advertisement)"
)

modelsummary(
  fits,
  output    = here::here("maintained", "output", "table_1_meta_regression.tex"),
  coef_map  = coef_labels,
  statistic = "({std.error})",
  stars     = c("*" = 0.05),
  gof_map   = tibble(raw = "nobs", clean = "Number of observations", fmt = 0),
  fmt       = 3,
  title     = "Meta-analysis of average treatment effects of advertisements on target candidate favorability and vote choice."
)
