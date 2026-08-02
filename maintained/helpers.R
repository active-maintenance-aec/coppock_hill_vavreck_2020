# coppock_hill_vavreck_2020/maintained/helpers.R
# Output: (sourced by every script in maintained/)
# Description: Shared packages and helper functions for the maintained rewrite.

library(here)
library(tidyverse)
library(estimatr)
library(metafor)
library(modelsummary)
library(janitor)
library(broom)
library(knitr)
library(kableExtra)

# Anchors the project root when a script is run on its own rather than through run_all.R.
here::i_am("maintained/helpers.R")

# kableExtra rather than the tinytable default, so the LaTeX modelsummary writes is
# plain booktabs and needs no tabularray package to compile.
options(modelsummary_factory_latex = "kableExtra")
options(modelsummary_format_numeric_latex = "plain")

# Per-week (or per-subgroup-week) treatment effects for one dependent variable ----
# Fits the paper's covariate-adjusted OLS specification separately within each date
# and returns one tidy row per coefficient. The survey weights live in a column
# literally called weights, so lm_robust finds them in the data frame.
estimate_ad_effects <- function(data, dv) {
  fml <- formula(paste0(dv, " ~ ad_id_fac + pid_7_pre + ideo5_pre + female_pre"))
  data |>
    filter(!is.na(.data[[dv]])) |>
    group_by(date) |>
    reframe(tidy(lm_robust(fml, weights = weights, data = pick(everything()))))
}

# Meta-analytic pooling of a set of estimates and their standard errors ----
# Returns the pooled estimate with its standard error and 95% confidence interval,
# the p-value of the Q test against the null of effect homogeneity (Woolf's test,
# which is the test the appendix reports), the between-study variance and its root.
# method has no default, so every call site names the estimator it is using.
# method = "DL" is the DerSimonian-Laird estimator behind every published number
# here; it reproduces rmeta::meta.summaries(method = "random") to machine precision.
pool_effects <- function(estimate, std_error, method) {
  fit <- rma(yi = estimate, sei = std_error, method = method)
  tibble(
    estimate  = as.numeric(fit$beta),
    std.error = fit$se,
    conf.low  = fit$ci.lb,
    conf.high = fit$ci.ub,
    p.value   = fit$QEp,
    tau2      = fit$tau2,
    tau       = sqrt(fit$tau2)
  )
}

# "0.049 (0.020)" style annotation used on both figures and in Table S2 ----
make_se_entry <- function(estimate, std_error, digits) {
  sprintf(paste0("%.", digits, "f (%.", digits, "f)"), estimate, std_error)
}
