# coppock_hill_vavreck_2020/ground_truth/run_archive.R
# Output: ground_truth/archive_run_status.csv, ground_truth/archive_overwrites.csv
# Depends on: original/ (run download_original.R first)
# Description: Runs every deposited script, unmodified, in a scratch copy of the deposit,
#   and records what each one does. The deposit is flat and every script addresses its
#   inputs by bare file name, so the scratch copy needs no folder tree.
#
#   Two passes. The stripped pass withholds the four .rds estimate files the deposit
#   ships beside the code that makes them, which is the only way to see whether the
#   downstream scripts pass on the deposit's own work or on an intermediate it ships. The
#   as_shipped pass runs the deposit exactly as it is served. Each script runs in its own
#   process, in the order the deposit's README lists them, and helpers.R, which is only
#   ever sourced by the other scripts, gets no row.
#
#   archive_overwrites.csv records what a pass did to the files: a deposited file
#   written over (detected by its modification time, since every file starts the pass
#   byte-identical to the deposit), a withheld file rebuilt or left withheld, and a file
#   no deposited script ships but a run leaves behind.
#
#   This script is not part of run_all.R. It is not needed to rebuild anything the
#   maintained code produces, and it is rerun only when the record of what the deposit
#   does on current R has to be refreshed. Nothing it does writes to original/.

library(here)
library(tidyverse)

here::i_am("ground_truth/run_archive.R")

deposit <- here::here("original")
stopifnot(dir.exists(deposit))

# The deposit's scripts, in the order its README lists them ----
estimation_scripts <- c("estimate_favorability_cates.R", "estimate_favorability_sates.R",
                        "estimate_vote_choice_cates.R", "estimate_vote_choice_sates.R")

analysis_scripts <- c("table_1.R", "figure_1.R", "figure_2.R", "in_text_numbers.R",
                      "table_S1.R", "table_S2.R", "table_S3.R", "figure_S1.R")

# The four estimate files the deposit ships and the estimation scripts also write.
shipped_intermediates <- c("favorability_cates.rds", "favorability_sates.rds",
                           "vote_choice_cates.rds", "vote_choice_sates.rds")

script_roles <- tibble(
  script = c(estimation_scripts, analysis_scripts),
  role = rep(c("cleaning", "analysis"),
             times = c(length(estimation_scripts), length(analysis_scripts)))
)

stopifnot(all(file.exists(file.path(deposit, script_roles$script))))

# A scratch copy of the deposit for one pass ----
stage <- function(pass, withhold) {
  # normalizePath, because tempdir() can carry a doubled slash and macOS resolves it
  # through /private, either of which would defeat the path scrubbing below.
  root <- file.path(normalizePath(tempdir(), winslash = "/", mustWork = FALSE),
                    str_c("coppock_hill_vavreck_2020_", pass))
  unlink(root, recursive = TRUE)
  dir.create(root, recursive = TRUE)
  shipped <- setdiff(list.files(deposit), withhold)
  stopifnot(all(file.copy(file.path(deposit, shipped), root, copy.date = TRUE)))
  root
}

# One script in its own process ----
# The message is kept as a short block, because an rlang condition puts its detail on
# the lines after "Error in", and the scratch path is removed so the record is not
# machine specific.
run_one <- function(root, script, timeout = 1800) {
  log_file <- file.path(root, str_replace(script, "\\.R$", ".runlog"))
  expr <- str_c("setwd(", deparse(root), "); source(", deparse(script),
                ", print.eval = TRUE)")
  status <- system2(file.path(R.home("bin"), "Rscript"), args = c("-e", shQuote(expr)),
                    stdout = log_file, stderr = log_file, timeout = timeout)
  lines <- read_lines(log_file)
  first <- which(str_starts(lines, "Error"))
  stopped_at <- if (length(first) == 0) {
    NA_character_
  } else {
    lines[first[1]:min(first[1] + 3, length(lines))] |>
      discard(\(x) str_detect(x, "Execution halted")) |>
      str_c(collapse = " ") |>
      str_remove(" In addition:.*$") |>
      str_replace_all(fixed(root), "<archive>") |>
      str_replace_all(fixed(str_remove(root, "^/private")), "<archive>") |>
      str_squish() |>
      str_trunc(220)
  }
  outcome <- case_when(
    status == 124 ~ "timeout",
    status == 0 ~ "clean",
    .default = "error"
  )
  if (outcome == "timeout") stopped_at <- str_glue("No exit within {timeout} seconds.")
  tibble(script = script, exit_status = status, outcome = outcome, stopped_at = stopped_at)
}

# Whether a file a pass left behind holds what the deposit ships ----
matches_deposit <- function(root, file) {
  fresh <- file.path(root, file)
  if (!file.exists(fresh)) return(NA)
  isTRUE(all.equal(read_rds(fresh), read_rds(file.path(deposit, file)),
                   check.attributes = FALSE, tolerance = 1e-12))
}

run_pass <- function(pass, withhold) {
  root <- stage(pass, withhold)
  before <- tibble(file = list.files(root), mtime = file.mtime(file.path(root, file)))

  status <- map(script_roles$script, \(s) run_one(root, s)) |>
    list_rbind() |>
    mutate(pass = pass, .before = 1)

  after <- tibble(file = setdiff(list.files(root), list.files(root, pattern = "\\.runlog$"))) |>
    mutate(mtime = file.mtime(file.path(root, file)))

  overwritten <- before |>
    inner_join(after, by = "file", suffix = c("_before", "_after")) |>
    filter(mtime_after != mtime_before) |>
    transmute(file, effect = "overwritten")

  withheld <- tibble(file = withhold) |>
    mutate(effect = if_else(file %in% after$file, "rebuilt", "withheld"))

  added <- tibble(file = setdiff(after$file, c(before$file, withhold)), effect = "added")

  deleted <- tibble(file = setdiff(before$file, after$file), effect = "deleted")

  overwrites <- bind_rows(overwritten, withheld, added, deleted) |>
    mutate(
      pass = pass,
      matches_deposit = map2_lgl(file, effect, \(f, e) {
        if (e %in% c("overwritten", "rebuilt") && str_ends(f, "\\.rds")) {
          matches_deposit(root, f)
        } else {
          NA
        }
      }),
      .before = 1
    )

  list(status = status, overwrites = overwrites)
}

stripped <- run_pass("stripped", withhold = shipped_intermediates)
as_shipped <- run_pass("as_shipped", withhold = character(0))

# The two archive tables, in the canonical long form ----
run_status <- bind_rows(stripped$status, as_shipped$status) |>
  left_join(script_roles, by = "script") |>
  select(pass, script, role, exit_status, outcome, stopped_at)

overwrites <- bind_rows(stripped$overwrites, as_shipped$overwrites) |>
  select(pass, file, effect, matches_deposit)

stopifnot(
  nrow(run_status) == 2 * nrow(script_roles),
  !anyNA(run_status$role),
  all(run_status$outcome %in% c("clean", "error", "timeout", "not_run")),
  all(overwrites$effect %in% c("added", "overwritten", "rebuilt", "withheld", "deleted"))
)

write_csv(run_status, here::here("ground_truth", "archive_run_status.csv"))
write_csv(overwrites, here::here("ground_truth", "archive_overwrites.csv"))

print(run_status |> select(pass, script, role, outcome, stopped_at), n = nrow(run_status),
      width = 200)
print(overwrites, n = nrow(overwrites))
