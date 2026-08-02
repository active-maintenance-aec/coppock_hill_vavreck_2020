# coppock_hill_vavreck_2020/maintained/text_archive_agreement.R
# Output: output/text_archive_agreement.csv
# Depends on: original/*.rds, the four cleaned estimate files in output/, helpers.R
# Description: Compare the rewrite's per-week estimates against the archive's own deposited
#   estimate objects. Those four objects are the archive's output for the estimation stage
#   and the input to every published table and figure, so an agreement measured here is an
#   agreement on everything downstream. Reported as a number rather than asserted in prose.

source(here::here("maintained", "helpers.R"))

# Both objects are compared row for row: the rewrite builds them in the archive's order,
# and the join keys below assert that rather than assuming it.
compare_one <- function(set, keys) {
  archive <- read_rds(here::here("original", paste0(set, ".rds")))
  rewrite <- read_rds(here::here("maintained", "output", paste0(set, ".rds")))

  stopifnot(nrow(archive) == nrow(rewrite))
  walk(keys, \(k) stopifnot(identical(archive[[k]], rewrite[[k]])))

  tibble(
    set = set,
    k = nrow(rewrite),
    max_abs_diff_estimate  = max(abs(rewrite$estimate - archive$estimate)),
    max_abs_diff_std_error = max(abs(rewrite$std.error - archive$std.error)),
    max_abs_diff_ci_lower  = max(abs(pmin(rewrite$conf.low, rewrite$conf.high) -
                                     pmin(archive$conf.low, archive$conf.high))),
    max_abs_diff_ci_upper  = max(abs(pmax(rewrite$conf.low, rewrite$conf.high) -
                                     pmax(archive$conf.low, archive$conf.high))),
    # The archive negates each confidence bound in place when it flips the sign of an
    # attack advertisement's effect, so its conf.low holds the upper end on those rows.
    # The rewrite swaps the two. This counts the rows on which that relabelling shows.
    n_rows_bounds_relabelled = sum(archive$conf.low > archive$conf.high)
  )
}

agreement <-
  bind_rows(
    compare_one("favorability_sates", c("date", "ad_id", "outcome")),
    compare_one("vote_choice_sates",  c("date", "ad_id", "outcome")),
    compare_one("favorability_cates", c("date", "ad_id", "outcome", "pid_3_pre", "battleground")),
    compare_one("vote_choice_cates",  c("date", "ad_id", "outcome", "pid_3_pre", "battleground"))
  )

print(agreement, width = 200)

write_csv(agreement, here::here("maintained", "output", "text_archive_agreement.csv"))
