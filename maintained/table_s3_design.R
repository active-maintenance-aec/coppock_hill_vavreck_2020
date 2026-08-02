# coppock_hill_vavreck_2020/maintained/table_s3_design.R
# Output: output/table_s3_design.csv, output/table_s3_design.tex
# Depends on: original/exps.rds, helpers.R
# Description: Table S3: completed respondents per condition per week.

source(here::here("maintained", "helpers.R"))

exps <-
  read_rds(here::here("original", "exps.rds")) |>
  mutate(
    date_formatted = format(date, format = "%B %d"),
    date_formatted = fct_reorder(factor(date_formatted), date)
  )

design_table <-
  exps |>
  tabyl(date_formatted, assignment) |>
  adorn_totals(where = c("row", "col"))

# A condition not fielded in a given week is blank rather than zero, as published.
design_table[design_table == 0] <- NA

write_csv(design_table, here::here("maintained", "output", "table_s3_design.csv"))

tex <-
  design_table |>
  rename(Week = date_formatted) |>
  mutate(across(where(is.numeric), \(x) if_else(is.na(x), "", as.character(x)))) |>
  kable(format = "latex", booktabs = TRUE,
        caption = "Number of completed responses by week and condition") |>
  kable_styling(latex_options = c("hold_position", "scale_down"))

write_lines(tex, here::here("maintained", "output", "table_s3_design.tex"))
