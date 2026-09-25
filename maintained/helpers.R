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
#
# The covariate list is pruned to the covariates that vary in the data handed in.
# pid_3_pre == "Independent" is exactly pid_7_pre == 4, so in the CATE call sites,
# which group by pid_3_pre, pid_7_pre is a constant inside the Independent subgroup:
# collinear with the intercept, estimable in no specification, and returned as NA by
# lm_robust (and silently by the archive's lm()). Pruning it moves no estimate and
# no standard error; it only stops the fit from asking for a coefficient that cannot
# exist. The SATE call sites hand in the whole sample, where all three covariates
# vary, so they fit the full specification.
estimate_ad_effects <- function(data, dv) {
  covariates <- c("pid_7_pre", "ideo5_pre", "female_pre")
  data <- data |> filter(!is.na(.data[[dv]]))
  varying <- covariates[map_lgl(covariates, \(v) n_distinct(data[[v]], na.rm = TRUE) > 1)]
  fml <- formula(paste(dv, "~", paste(c("ad_id_fac", varying), collapse = " + ")))
  data |>
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

# Blank a figure PDF's embedded timestamps ----
# R's pdf() device stamps /CreationDate and /ModDate with the wall clock, so an
# otherwise deterministic pipeline writes a different file on every run. The epoch
# string is the same width as what it replaces, which keeps the cross-reference byte
# offsets valid, and a file with no timestamp is left alone.
blank_pdf_timestamps <- function(path) {
  epoch <- charToRaw("D:19700101000000")
  raw_pdf <- readBin(path, "raw", file.size(path))
  hits <- grepRaw("D:[0-9]{14}", raw_pdf, all = TRUE)
  if (length(hits) == 0) return(invisible(path))
  for (h in hits) raw_pdf[h:(h + length(epoch) - 1L)] <- epoch
  writeBin(raw_pdf, path)
  invisible(path)
}
