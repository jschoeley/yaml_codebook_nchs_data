# Read, label and concatenate data on US births, infant- and fetal deaths
#
# Jonas Schöley
# 2020-10-06
#
# (1) Read NCHS data into R applying variable specifications stored
#     in custom codebook
# (2) Concatenate NCHS data across multiple years

# Init ------------------------------------------------------------

library(dplyr)

memory.limit(64000)

cnst <- list()

# path to raw data on births, infant and fetal deaths
cnst$paths <- list()
cnst$paths$infant_data <-
  'dat/00-raw_nchs_data/nchs-us_cohort_linked_infant_deaths_births/'
cnst$paths$fetal_data <-
  'dat/00-raw_nchs_data/nchs-us_fetal_deaths/'

# path to codebooks
cnst$paths$infant_cbook <-
  'src/codebook-us_cohort_linked_infant_deaths_births.yaml'
cnst$paths$fetal_cbook  <-
  'src/codebook-us_period_fetal_deaths.yaml'

# codebook function
source('src/00-codebook.R')

# Read codebook ---------------------------------------------------

fetal_cbook <- ReadCodebook(cnst$paths$fetal_cbook)
infant_cbook <- ReadCodebook(cnst$paths$infant_cbook)

# Read data into R and apply varspecs -----------------------------

# the 2003 file LinkCO03US.zip is corrupted and can't be read
# I have a version from 2016 that works
infants <- ReadFromZip(infant_cbook, cnst$paths$infant_data)

fetus <- ReadFromZip(fetal_cbook, cnst$paths$fetal_data)

# Concatenate data ------------------------------------------------

# merge data on births, fetal- and infant deaths cross years
fetoinfants <-
  bind_rows(
    infant = bind_rows(infants),
    fetus = bind_rows(fetus),
    .id = 'type'
  )

# Save ------------------------------------------------------------

save(
  fetoinfants,
  file = 'dat/01-processed_nchs_data/fetoinfants.RData'
)
