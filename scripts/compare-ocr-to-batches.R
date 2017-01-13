# Compare all batches to OCR bulk data

library(jsonlite)

# A fast, consistent tool for working with data frame like objects, both in memory and out of memory.
library(dplyr)

# Purrr makes your pure functions purr by completing R's functional programming tools with important features from other languages, in the style of the JS packages underscore.js, lodash and lazy.js.
library(purrr)

# A consistent, simple and easy to use set of wrappers around the fantastic 'stringi' package. All function and argument names (and positions) are consistent, all functions deal with "NA"'s and zero length vectors in the same way, and the output from one function is easy to feed into the input of another.
library(stringr)

library(mullenMisc)

# Simple utility functions to read from and write to the Windows, OS X, and X11 clipboards.
library(clipr)

# Wrappers around the 'xml2' and 'httr' packages to make it easy to download, then manipulate, HTML and XML.
library(rvest)

# TODO: Figure out where 57 comes from
num_pages <- 57

# Create a vector equal to the number of pages
# mode - character string naming an atomic mode or "list" or "expression" or (except for vector) "any". Currently, is.vector() allows any type (see typeof) for mode, and when mode is not "any", is.vector(x, mode) is almost the same as typeof(x) == mode.
batches_l <- vector(mode = "list", length = num_pages)

# Retrieve data from chroniclingamerica website.
get_batch_json <- function(i) {
  # Concatenate the three parameters into the variable url
  url <- paste0("http://chroniclingamerica.loc.gov/batches/",
                i, ".json")
  # message() function generates diagnostic message from its arguments.
  message("Getting ", url)
  # SAMPLE
  # {
  #"batches": [
  #  {
  #    "name": "batch_nvln_caliente_ver02", 
  #    "url": "http://chroniclingamerica.loc.gov/batches/batch_nvln_caliente_ver02.json", 
  #    "page_count": 12722, 
  #    "awardee": {
  #      "url": "http://chroniclingamerica.loc.gov/awardees/nvln.json", 
  #      "name": "University of Nevada Las Vegas University Libraries"
  #    }, 
  #    "lccns": [
  #      "sn86091346", 
  #      "2015270825", 
  #      "sn86091348", 
  #      "sn86091349", 
  #      "sn86076215", 
  #      "sn84022048"
  #    ], 
  #    "ingested": "2017-01-13T23:11:42-05:00"
  #  }, 
  batch <- fromJSON(url)

  # select() keeps only the variables you mention; rename() keeps all variables.
  # Create a data frame that contains name, url, page_count, and ingested.
  df <- batch$batches %>%
    select(name, url, page_count, ingested) %>%
    # Forwards the argument to as_data_frame.
    # as.data.frame is effectively a thin wrapper around data.frame, and hence is rather slow (because it calls data.frame on each element before cbinding together).
    tbl_df()
  message("Got ", nrow(df), " rows")
  df
}

# Iterate over the length of batches_l (length being 57) and execute the get_batch_json function for thenumbers 1-57. Store the returned value in the vector batches_l
for (i in seq_along(batches_l)) {
  batches_l[[i]] <- get_batch_json(i)
}

# Combine the results into a singe data frame
batches <- bind_rows(batches_l)
# {
  #"ocr": [
  #  {
  #    "url": "http://chroniclingamerica.loc.gov/data/ocr/batch_wvu_pepper_ver01.tar.bz2", 
  #    "sha1": "c45cb0b5bac2dd68b4a133d060ab9941805766e5", 
  #    "size": 811120623, 
  #    "name": "batch_wvu_pepper_ver01.tar.bz2", 
  #    "created": "2016-12-24T17:37:47-05:00"
  #  }, 
ocr <- fromJSON("http://chroniclingamerica.loc.gov/ocr.json")
ocr <- ocr$ocr %>%
  tbl_df() %>%
  # str_replace(string, pattern, replacement)
  # Create a new column called batch_id and store the name without the .tar.bz2.
  mutate(batch_id = str_replace(name, "\\.tar.bz2", ""))

#[ICO]	Name	Last modified	Size	Description
#[DIR]	Parent Directory	 	-	 
#[   ]	batch_az_acacia_ver01.tar.bz2	18-Mar-2014 11:54	550M	 
#[   ]	batch_az_agave_ver01.tar.bz2	11-Jul-2013 16:26	683M	 
#[   ]	batch_az_apachetrout_ver01.tar.bz2	11-Jul-2013 16:44	833M	 
#[   ]	batch_az_blackwidow_ver01.tar.bz2	11-Jul-2013 16:34	791M	 
#[   ]	batch_az_bobcat_ver01.tar.bz2	11-Jul-2013 16:51	932M	 
#[   ]	batch_az_bobwhite_ver01.tar.bz2	18-Mar-2014 12:21	387M	 
#[   ]	batch_az_cholla_ver01.tar.bz2	18-Mar-2014 12:54	480M	 
ocr_downloads <- read_html("http://chroniclingamerica.loc.gov/data/ocr/") %>%
  html_table()
ocr_downloads <- ocr_downloads[[1]]

# > head(ocr_downloads)
#                                   Name     Last modified Size Description
#1 NA                                                                    NA
#2 NA                   Parent Directory                      -          NA
#3 NA      batch_az_acacia_ver01.tar.bz2 18-Mar-2014 11:54 550M          NA
#4 NA       batch_az_agave_ver01.tar.bz2 11-Jul-2013 16:26 683M          NA
#5 NA batch_az_apachetrout_ver01.tar.bz2 11-Jul-2013 16:44 833M          NA
#6 NA  batch_az_blackwidow_ver01.tar.bz2 11-Jul-2013 16:34 791M          NA


# > head(ocr_downloads[-c(1, 2, 1402), 2:4])
#                                Name     Last modified Size
#3      batch_az_acacia_ver01.tar.bz2 18-Mar-2014 11:54 550M
#4       batch_az_agave_ver01.tar.bz2 11-Jul-2013 16:26 683M
#5 batch_az_apachetrout_ver01.tar.bz2 11-Jul-2013 16:44 833M
#6  batch_az_blackwidow_ver01.tar.bz2 11-Jul-2013 16:34 791M
#7      batch_az_bobcat_ver01.tar.bz2 11-Jul-2013 16:51 932M
#8    batch_az_bobwhite_ver01.tar.bz2 18-Mar-2014 12:21 387M

# Looks like the first two lines are being eliminated and only using the Name, Last modified, and Size columns. Also adding a batch_id field.
ocr_downloads <- ocr_downloads[-c(1, 2, 1402), 2:4] %>%
  mutate(batch_id = str_replace(Name, "\\.tar.bz2", ""))


missing_from_ocr <- anti_join(batches, ocr, by = c("name" = "batch_id"))
missing_from_ocr_dir <- anti_join(batches, ocr_downloads, by = c("name" = "batch_id"))

batches$name %>% length()
ocr$batch_id %>% length()
ocr_dir$batch_id %>% length()

setdiff(batches$name, ocr$batch_id)
setdiff(batches$name, ocr_dir$batch_id)

downloaded_df <- data_frame(batch_file = downloaded) %>%
  mutate(batch_id = str_replace_all(batch_file, "\\.tar\\.bz2", ""),
         batch_without_ver = str_replace_all(batch_id, "_ver\\d+", ""),
         version = str_extract(batch_id, "_ver\\d_"))

# missing names
write_clip(missing$name)

# missing pages
sum(missing$page_count)

# data range
missing$ingested %>% as.Date() %>% range()
