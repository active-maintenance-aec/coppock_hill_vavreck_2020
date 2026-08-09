# coppock_hill_vavreck_2020/run_all.R
# Runs the whole reproduction in order: fetch and verify the deposited archive, rebuild
# the four sets of per-week treatment effect estimates, then every published table and
# figure, then the in-text quantities.
# Every script is self-contained and can also be run on its own.

library(here)
here::i_am("run_all.R")

# Deposited archive ----
# Downloads from Dataverse on a fresh clone; verifies checksums either way.
source(here::here("download_original.R"))

# Per-week estimates ----
# These rebuild the four intermediate estimate files that the archive also deposits.
# Everything downstream reads them from maintained/output/, not from original/.
source(here::here("maintained", "clean_favorability_sates.R"))
source(here::here("maintained", "clean_favorability_cates.R"))
source(here::here("maintained", "clean_vote_choice_sates.R"))
source(here::here("maintained", "clean_vote_choice_cates.R"))

# Tables ----
source(here::here("maintained", "table_1_meta_regression.R"))
source(here::here("maintained", "table_s1_ad_list.R"))
source(here::here("maintained", "table_s2_heterogeneity.R"))
source(here::here("maintained", "table_s3_design.R"))

# Figures ----
source(here::here("maintained", "figure_1_sate_time_series.R"))
source(here::here("maintained", "figure_2_cate_partisan_match.R"))
source(here::here("maintained", "figure_s1_repeat_ads.R"))

# In-text quantities ----
source(here::here("maintained", "text_in_text_numbers.R"))
source(here::here("maintained", "text_repeat_ad_homogeneity.R"))
source(here::here("maintained", "text_descriptive_claims.R"))
source(here::here("maintained", "text_archive_agreement.R"))

# Figure timestamps ----
# R's pdf() device stamps a wall-clock /CreationDate and /ModDate into every figure it
# writes, and those two fields are the only reason two runs of this pipeline produce
# differing files. Blanking them lets the determinism check cover every file the
# pipeline writes rather than all but the figures.
source(here::here("maintained", "helpers.R"))
walk(
  list.files(here::here("maintained", "output"), pattern = "\\.pdf$", full.names = TRUE),
  blank_pdf_timestamps
)

# Ground truth ----
# Reads the published values it compares against out of the outputs above, so the
# table cannot drift from the pipeline. Runs last for that reason.
source(here::here("ground_truth", "build_ground_truth.R"))

# In-text claims ----
# Every number the article prints, beside the sentence that prints it and the value this
# pipeline gives for it. build_ground_truth.R has already run this file and gated on what
# it printed; running it here again is what puts the audit trail in the run's own log.
source(here::here("maintained", "in_text_claims.R"))

# Deposited archive, again ----
# The check at the top of this file is a precondition: it says original/ was intact
# before anything ran. Nothing above writes to original/, and this second pass is what
# demonstrates it rather than assuming it. Nothing is downloaded; the files are already
# present and are re-checked against the manifest on checksum, byte size and membership.
source(here::here("download_original.R"))
