# Codebook functions
#
# Functions to read custom YAML codebook specifications.
#
# Jonas Schöley
# 2020-05-14

# Functions to read codebook --------------------------------------

# Read Codebook from Path
ReadCodebook <- function (path) {
  cbook <- yaml::yaml.load_file(input = path)
  cbook$files <- OrderVarByStartPosition(cbook)
  return(cbook)
}

# Construct Get Function
GetConstructor <- function (cbook_file, secondary, tertiary) {
  sapply(
    cbook_file[[secondary]],
    function (cbook_file) {
      unlist(getElement(cbook_file, name = tertiary))
    })
}

# Get File Names of Files Defined in Codebook
GetFileName <- function(cbook) {
  unlist(lapply(cbook$files, getElement, name = 'filename'))
}
# Get URL of Files Defined in Codebook
GetURL <- function(cbook) {
  unlist(lapply(cbook$files, getElement, name = 'url'))
}
# Get Variable Names from Codebook File Node
GetVarName <- function (cbook_file) {
  names(cbook_file$variables)
}
# Get Variable Start Position from Codebook File Node
GetVarStart <- function (cbook_file) {
  GetConstructor(cbook_file, 'variables', 'start')
}
# Get Variable End Position from Codebook File Node
GetVarEnd <- function (cbook_file) {
  GetConstructor(cbook_file, 'variables', 'end')
}
# Get Variable Type from Codebook File Node
GetVarType <- function (cbook_file) {
  GetConstructor(cbook_file, 'variables', 'type')
}

# Order the Variable Specifications Within Each File
# by Column Start Position
OrderVarByStartPosition <- function (cbook) {
  # the variables must be read in order of column
  # start position or otherwise readr gets confused
  cbook$files <-
    lapply(
      cbook$files, function (x)  {
        within(x, {variables = variables[order(GetVarStart(x))]})
      }
    )
}

# Functions to read from Zip files --------------------------------

ReadFromZip <- function (cbook, local_path) {
  # get file names from codebook
  file_names = GetFileName(cbook)
  archive_names = sapply(strsplit(GetURL(cbook), '/'),
                         function(x) rev(x)[1])
  # initiate list to hold data
  dat = vector('list', length(file_names))
  names(dat) = file_names
  # read data
  for (i in seq_along(file_names)) {
    data_source <- readr::datasource(
      unz(paste0(local_path, archive_names[i]), file_names[i])
    )
    temp <- CBookrFWF(data_source, cbook_file = cbook$files[[i]])
    dat[[i]] <- ApplyVarSpec(temp, cbook$files[[i]]); rm(temp)
  }
  return(dat)
}

# Functions to apply codebook specs -------------------------------

# Read Fixed Width File Using Codebook Specification
CBookrFWF <- function (path, cbook_file) {
  cat(paste('Reading file', cbook_file$filename, '\n'))
  
  # column positions of variables
  colpos <- readr::fwf_positions(
    start = GetVarStart(cbook_file),
    end = GetVarEnd(cbook_file),
    col_names = GetVarName(cbook_file)
  )
  # number of variables
  nvar <- length(GetVarName(cbook_file))
  
  # depends on readr >= 1.0.0 for the
  # capability to read column subsets
  dat <- readr::read_fwf(
    file = path[[1]],
    col_positions = colpos,
    # read everything as character
    col_types = paste0(rep('c', nvar), collapse = ''),
    # keep whitespace as it may be significant coding
    trim_ws = FALSE,
    # don't treat anything as NA. NA's are handled later
    na = character(),
    skip_empty_rows = FALSE
  )
  cat(paste('Lines:', nrow(dat), 'Fields:', ncol(dat), '\n'))
  return(dat)
}

# Apply Variable Specifications from Codebook To Data Frame
ApplyVarSpec <- function (x, cbook_file) {
  vars <- cbook_file$variables
  for (i in 1:ncol(x)) { # for all the variables in the data
    cat(paste(names(vars)[i], paste0(unlist(x[1:5,i]), collapse = ', '), '\n'))
    # if NAs are available apply NAs
    if (!is.null(vars[[i]]$missing_values)) {
      cat(paste('  Defining NAs as', vars[[i]]$missing_values, '\n'))
      x[,i] <- ifelse(
        unlist(x[,i]) %in% vars[[i]]$missing_values,
        NA,
        unlist(x[,i])
      )
    }
    # if variable type is integer, convert column to integer
    if (vars[[i]]$type == 'integer') {
      cat(paste('  Convert to integer', '\n'))
      x[,i] <- as.integer(unlist(x[,i]))
    }
    # if variable type is double, convert column to double
    if (vars[[i]]$type == 'double') {
      cat(paste('  Convert to double', '\n'))
      x[,i] <- as.double(unlist(x[,i]))
    }
    # if variable type is factor and categories are given,
    # convert column to factor and apply factor levels and labels
    if (vars[[i]]$type == 'factor' & (!is.null(vars[[i]]$categories))) {
      cat(paste('  Convert to factor', '\n'))
      # extract levels and labels
      level <- names(vars[[i]]$categories)
      label <- unlist(vars[[i]]$categories)
      cat(paste0('    ', level, ': ', label, '\n', collapse = ''))
      # include only levels and labels which don't appear in missing values
      # so that NAs stay NAs
      level_rmna <- level[!(level %in% vars[[i]]$missing_values)]
      label_rmna <- label[!(level %in% vars[[i]]$missing_values)]
      x[,i] <- factor(unlist(x[,i]),
                      levels  = level_rmna,
                      labels  = label_rmna)
      if(vars[[i]]$scale == 'ordinal') {
        x[,i] <- as.ordered(unlist(x[,i]))
      }
    }
    # if variable type is date and format is given,
    # convert column to date
    if (vars[[i]]$type == 'date' & (!is.null(vars[[i]]$format))) {
      cat(paste('  Convert to date', '\n'))
      x[,i] <- readr::parse_date(as.character(unlist(x[,i])),
                                 format = vars[[i]]$format)
    }
  }
  return(x)
}
