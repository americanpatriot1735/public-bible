#!/usr/bin/env Rscript --vanilla

# Read and write feather files, a lightweight binary columnar data store designed for maximum speed.
# Feather is a fast, lightweight, and easy-to-use binary file format for storing data frames.
suppressPackageStartupMessages(library(feather))

# A fast, consistent tool for working with data frame like objects, both in memory and out of memory.
suppressPackageStartupMessages(library(dplyr))

# Purrr makes your pure functions purr by completing R's functional programming tools with important features from other languages, in the style of the JS packages underscore.js, lodash and lazy.js.
suppressPackageStartupMessages(library(purrr))

# This function produces a list containing the names of files in the named directory. dir is an alias.
# list.files(path, pattern=NULL, all.files=FALSE,
# 	full.names=FALSE)
# path	a character vector of full path names.
# pattern	an optional regular expression. Only file names which match the regular expression will be returned.
# all.files	a logical value. If FALSE, only the names of visible files are returned. If TRUE, all file names will be returned.
# full.names	a logical value. If TRUE, the directory path is prepended to the file names. If FALSE, only the file names are returned.
feature_files <- list.files("data/sample", pattern = "features\\.feather$", full.names = TRUE, recursive = TRUE)

# map in part of the Purrr module - the read_feather function will be applied to each feature_files
# bind_rows is part of the dplyr module - Binding many data frames into one
df <- map(feature_files, read_feather) %>% bind_rows()

# Write all the features to a single file.
write_feather(df, "data/all-features.feather")
