---
title: "Get supervised learning dataset for model making"
author: "Lincoln Mullen"
date: "May 7, 2016"
output: html_document
---

---
author: Lincoln Mullen
date: 'May 7, 2016'
output: 'html\_document'
title: Get supervised learning dataset for model making
---

``` {.r}
library(dplyr)
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

``` {.r}
library(readr)
library(feather)
```

Earlier I created a sample of possible matches. I've uploaded this to
Google documents, and my RA and I have categorized the matches as
genuine or not. This labeled data will be the basis for training a
supervised classification model.

First I have to download the labeled data. It is the fact of a match or
not that matters in this data, *not* the specific features that were
extracted to tell us whether or not it was a match. The features that I
have been extracting change over time as I make improvements to that
part. So we will download the labeled data and get the matches, then
join it to the features that we have extracted.

Here is the [Google
sheet](https://docs.google.com/spreadsheets/d/1_hcNdWPMSaQvLlfLZH2UEk5gMI9qkVJaATU5d79QAEM/edit?usp=sharing)
where the data is being labeled.

Download the file. (The downloaded file is under version control.)

``` {.r}
download.file("https://docs.google.com/spreadsheets/d/1_hcNdWPMSaQvLlfLZH2UEk5gMI9qkVJaATU5d79QAEM/pub?gid=1028340440&single=true&output=csv", destfile = "data/labeled-data.csv")
```

Read the file in and get just the columns we want.

``` {.r}
labeled <- read_csv("data/labeled-data.csv") %>% 
  select(reference, page, match) %>% 
  filter(!is.na(match))
```

Let's do some sanity checking. It is possible that we labeled the same
match more than once. So we will get the distinct rows. Then, if we have
a match to the same newspaper page and verse which is marked as both
TRUE and FALSE, that is a definite error and we should fail noisily.

``` {.r}
labeled <- labeled %>% distinct(reference, page, match)

error_checking <- labeled %>% count(reference, page) %>% `$`("n")
stopifnot(!any(error_checking > 1))
```

Now we can load in the most recent feature data.

``` {.r}
features <- read_feather("temp/all-features.feather")
```

Merge in the labels to the feature data by page ID and verse reference,
then keep only the data that is labeled.

``` {.r}
labeled_features <- features %>% 
  left_join(labeled, by = c("reference", "page")) %>% 
  filter(!is.na(match))
```

And write the labeled features to disk.

``` {.r}
write_feather(labeled_features, "data/labeled-features.feather")
```