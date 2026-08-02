# coppock_hill_vavreck_2020/maintained/figure_s1_repeat_ads.R
# Output: output/figure_s1_repeat_ads.pdf, .png, output/figure_s1_repeat_ads.csv
# Depends on: original/exps.rds, original/ad_df.csv, helpers.R
# Description: Figure S1: weekly effects of the seven advertisements fielded more than once.

source(here::here("maintained", "helpers.R"))

exps  <- read_rds(here::here("original", "exps.rds"))
ad_df <- read_csv(here::here("original", "ad_df.csv"), show_col_types = FALSE)

# Panel definitions, taken verbatim from the archive's figure_S1.R ----
# The outcome is not a function of the advertisement's valence: "Real Life" is a
# pro-Clinton advertisement scored against Trump favorability while "Love/Kindness"
# is a pro-Clinton advertisement scored against Clinton favorability. That is the
# published choice and the rewrite keeps it.
panels <- tribble(
  ~ad_id, ~outcome,
       8, "favorDT_rev",
       9, "favorDT_rev",
      11, "favorBS_rev",
      30, "favorHC_rev",
      33, "favorDT_rev",
      47, "favorDT_rev",
      63, "favorDT_rev"
)

# The panel set is exactly the set of advertisements fielded in more than one week ----
repeat_ads <-
  exps |>
  filter(!is.na(ad_id), ad_id != 3) |>
  distinct(ad_id, date) |>
  count(ad_id) |>
  filter(n > 1) |>
  pull(ad_id)

stopifnot(setequal(repeat_ads, panels$ad_id))

# Each panel compares one advertisement against the placebo, in every week in which
# that advertisement was fielded. These regressions are unweighted, as in the
# archive's figure_S1.R; the weighted specification is used everywhere else.
fit_one_ad <- function(focal_ad_id, outcome) {
  focal_waves <- unique(exps$wave[exps$ad_id == focal_ad_id])
  exps |>
    filter(wave %in% focal_waves, ad_id %in% c(3, focal_ad_id)) |>
    group_by(date) |>
    reframe(tidy(lm_robust(
      formula(paste0(outcome, " ~ as.factor(ad_id) + pid_7_pre + ideo5_pre + female_pre")),
      data = pick(everything())
    ))) |>
    mutate(ad_id = focal_ad_id)
}

gg_df <-
  map2(panels$ad_id, panels$outcome, fit_one_ad) |>
  list_rbind() |>
  filter(str_detect(term, fixed("as.factor(ad_id)"))) |>
  left_join(ad_df, by = "ad_id")

breaks <- as.Date(c(
  "2016-04-01", "2016-05-01", "2016-06-01", "2016-07-01",
  "2016-08-01", "2016-09-01", "2016-10-01", "2016-11-01"
))

g <-
  ggplot(gg_df, aes(date, estimate)) +
  geom_point() +
  geom_linerange(aes(ymin = conf.low, ymax = conf.high)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_vline(xintercept = as.Date("2016-06-10"), linetype = "dotted") +
  scale_x_date(breaks = breaks, date_labels = "%B") +
  coord_cartesian(ylim = c(-0.6, 0.6)) +
  facet_wrap(~ad_title, nrow = 4) +
  theme_bw() +
  theme(
    strip.background = element_blank(),
    axis.title.x     = element_blank(),
    panel.grid.minor = element_blank(),
    text             = element_text(size = 10),
    axis.text.x      = element_text(size = 6)
  ) +
  ylab("Average treatment effect estimate and 95% confidence interval")

ggsave(here::here("maintained", "output", "figure_s1_repeat_ads.pdf"),
       plot = g, width = 7, height = 9)
ggsave(here::here("maintained", "output", "figure_s1_repeat_ads.png"),
       plot = g, width = 7, height = 9, dpi = 300)

write_csv(
  gg_df |>
    select(ad_id, ad_title, ad_valence, date, outcome, estimate, std.error,
           conf.low, conf.high, p.value),
  here::here("maintained", "output", "figure_s1_repeat_ads.csv")
)
