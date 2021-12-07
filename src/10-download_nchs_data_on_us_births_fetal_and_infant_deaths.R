# Download data on US births, infant- and fetal deaths
#
# Jonas Schöley
# 2020-06-10
#
# Download data on US births, fetal and infant deaths from the web.

# Init ------------------------------------------------------------

# large timeout for large files to download
options(timeout = max(600, getOption("timeout")))

# path to save data
infant_path = 'dat/00-raw_nchs_data/nchs-us_cohort_linked_infant_deaths_births/'
fetal_path  = 'dat/00-raw_nchs_data/nchs-us_fetal_deaths/'

# files to download
infant_files <-
  list(
    data =
      c(
        paste0(
          'ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/DVS/cohortlinkedus/',
          'LinkCO', c(89:91), '.zip'    
        ),
        paste0(
          'ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/DVS/cohortlinkedus/',
          'LinkCO', c(95:99, paste0(0, 0:9), 10:15), 'US', '.zip'
        )
      ),
    guides =
      paste0(
        'ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/DVS/cohortlinked/',
        'LinkCO', c(89:91, 95:99, paste0(0, 0:9), 10:15), 'Guide', '.pdf'
      )
  )
fetal_files <-
  list(
    data =
      paste0(
        'ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/DVS/fetaldeathus/',
        'Fetal', 1982:2017, 'US', '.zip'
      ),
    guides =
      paste0(
        'ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/DVS/fetaldeath/',
        1982:2017, 'FetalUserGuide', '.pdf'
      )
  )

# Functions to download data --------------------------------------

# download and save files
DownloadFiles <- function (url, save_path) {
  for (i in url) {
    cat("Download", i)
    download.file(
      url = i,
      destfile =
        # save using the filename on server
        paste0(save_path, rev(strsplit(i, '/')[[1]])[1]),
      mode = 'wb',
    )
  }
}

# Download data -----------------------------------------------------------

# download US cohort linked infant birth / death data and guides
DownloadFiles(
  infant_files$data, infant_path
)
DownloadFiles(
  infant_files$guides, infant_path
)

# download US period fetal death data and guides
DownloadFiles(
  fetal_files$data, fetal_path
)
DownloadFiles(
  fetal_files$guides, fetal_path
)
