# coppock_hill_vavreck_2020/maintained/figure_1_sate_time_series.R
# Output: output/figure_1_sate_time_series.pdf, .png, output/figure_1_sate_time_series.csv
# Depends on: output/favorability_sates.rds, output/vote_choice_sates.rds, helpers.R
# Description: Figure 1: weekly treatment effect estimates and their meta-analytic summary.

source(here::here("maintained", "helpers.R"))

favorability_sates <- read_rds(here::here("maintained", "output", "favorability_sates.rds"))
vote_choice_sates  <- read_rds(here::here("maintained", "output", "vote_choice_sates.rds"))

sates_df <-
  bind_rows(
    Favorability  = favorability_sates,
    `Vote Choice` = vote_choice_sates,
    .id = "dv"
  ) |>
  mutate(est_type = "Weekly estimates")

summary_df <-
  sates_df |>
  group_by(dv) |>
  reframe(pool_effects(estimate, std.error, method = "DL")) |>
  mutate(
    date     = as.Date("2018-01-15"),
    est_type = "Meta-analysis"
  )

# Two invisible points fixing the width of the meta-analysis panel ----
# They carry no estimate, so both geoms drop them with a warning. That is expected.
blank_df <-
  tibble(date = as.Date(c("2018-01-01", "2018-01-30"))) |>
  mutate(est_type = "Meta-analysis", dv = "Favorability")

gg_df <-
  bind_rows(sates_df, summary_df, blank_df) |>
  mutate(
    est_type  = factor(est_type, c("Weekly estimates", "Meta-analysis")),
    est_entry = make_se_entry(estimate, std.error, digits = 3),
    entry_y   = estimate * 5
  )

breaks <- as.Date(c(
  "2016-04-01", "2016-05-01", "2016-06-01", "2016-07-01",
  "2016-08-01", "2016-09-01", "2016-10-01", "2016-11-01"
))

# The strip prints the published page's `Vote choice`; the `dv` key stays `Vote Choice` ----
# because in_text_claims.R and text_descriptive_claims.R filter the csv on it.

# The start of the general election campaign, drawn only in the weekly panel ----
# The archive draws it with a bare geom_vline. Under ggplot2 4.x an unfaceted
# annotation layer joins the free x scale of every panel, which stretches the
# meta-analysis panel from a 30 day range to one of nineteen months and, through
# space = "free_x", hands it most of the plot width. Restricting the layer to the
# weekly panel restores the published proportions and changes nothing plotted.
general_start <- tibble(
  est_type   = factor("Weekly estimates", c("Weekly estimates", "Meta-analysis")),
  xintercept = as.Date("2016-06-10")
)

g <-
  ggplot(gg_df, aes(date, estimate, group = ad_id)) +
  geom_point(alpha = 0.8, stroke = 0, position = position_dodge(5)) +
  geom_linerange(aes(ymin = conf.low, ymax = conf.high),
                 alpha = 0.5, position = position_dodge(5)) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  geom_vline(data = general_start, aes(xintercept = xintercept), linetype = "dotted") +
  geom_text(
    data = \(d) filter(d, est_type == "Meta-analysis", !is.na(estimate)),
    aes(y = entry_y, label = est_entry),
    size = 2
  ) +
  facet_grid(
    rows = vars(dv), cols = vars(est_type), scales = "free", space = "free_x",
    labeller = labeller(dv = c(Favorability = "Favorability", `Vote Choice` = "Vote choice"))
  ) +
  scale_x_date(breaks = breaks, date_labels = "%B") +
  theme_bw() +
  theme(
    strip.background = element_blank(),
    axis.title.x     = element_blank(),
    panel.grid.minor = element_blank(),
    text             = element_text(size = 8)
  ) +
  ylab("Average treatment effect estimate and 95% confidence interval")

ggsave(here::here("maintained", "output", "figure_1_sate_time_series.pdf"),
       plot = g, width = 7, height = 5)
ggsave(here::here("maintained", "output", "figure_1_sate_time_series.png"),
       plot = g, width = 7, height = 5, dpi = 300)

# The plotted values, so the two annotations on the figure are traceable ----
write_csv(
  gg_df |>
    filter(!is.na(estimate)) |>
    select(dv, est_type, date, ad_id, ad_title, ad_valence, estimate, std.error,
           conf.low, conf.high, est_entry),
  here::here("maintained", "output", "figure_1_sate_time_series.csv")
)
