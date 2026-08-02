# coppock_hill_vavreck_2020/maintained/figure_2_cate_partisan_match.R
# Output: output/figure_2_cate_partisan_match.pdf, .png, output/figure_2_cate_partisan_match.csv
# Depends on: output/favorability_cates.rds, output/vote_choice_cates.rds, helpers.R
# Description: Figure 2: meta-analytic effects by respondent partisanship and advertisement target.

source(here::here("maintained", "helpers.R"))

favorability_cates <- read_rds(here::here("maintained", "output", "favorability_cates.rds"))
vote_choice_cates  <- read_rds(here::here("maintained", "output", "vote_choice_cates.rds"))

fav_meta_cates <-
  favorability_cates |>
  group_by(ad_match, pid_3_pre, pro_democrat) |>
  reframe(pool_effects(estimate, std.error, method = "DL"))

vc_meta_cates <-
  vote_choice_cates |>
  group_by(ad_match, pid_3_pre, pro_democrat) |>
  reframe(pool_effects(estimate, std.error, method = "DL"))

gg_df <-
  bind_rows(
    "Favorability" = fav_meta_cates,
    "Vote choice"  = vc_meta_cates,
    .id = "outcome_variable"
  ) |>
  mutate(
    respondent_pid = case_when(
      pid_3_pre == "Democrat"    ~ "Democratic respondents",
      pid_3_pre == "Independent" ~ "Independent respondents",
      pid_3_pre == "Republican"  ~ "Republican respondents"
    ),
    ad_type  = if_else(pro_democrat == 1, "pro-Democratic ad", "pro-Republican ad"),
    se_entry = make_se_entry(estimate, std.error, digits = 3)
  )

g <-
  ggplot(gg_df, aes(x = estimate, y = respondent_pid)) +
  geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5) +
  geom_point() +
  geom_linerange(aes(xmin = conf.low, xmax = conf.high)) +
  geom_text(aes(label = se_entry), nudge_y = 0.3, size = 3) +
  facet_grid(rows = vars(outcome_variable), cols = vars(ad_type)) +
  theme_bw() +
  theme(
    axis.title.y     = element_blank(),
    strip.background = element_blank()
  ) +
  xlab("Meta-analytic conditional average treatment effects")

ggsave(here::here("maintained", "output", "figure_2_cate_partisan_match.pdf"),
       plot = g, width = 7, height = 5)
ggsave(here::here("maintained", "output", "figure_2_cate_partisan_match.png"),
       plot = g, width = 7, height = 5, dpi = 300)

write_csv(
  gg_df |>
    select(outcome_variable, respondent_pid, ad_type, estimate, std.error,
           conf.low, conf.high, p.value, tau2, tau, se_entry),
  here::here("maintained", "output", "figure_2_cate_partisan_match.csv")
)
