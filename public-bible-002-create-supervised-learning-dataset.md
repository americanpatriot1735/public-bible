---
title: "Create the supervised learning dataset"
author: "Lincoln Mullen"
date: "May 3, 2016"
output: html_document
---

---
author: Lincoln Mullen
date: 'May 3, 2016'
output: 'html\_document'
title: Create the supervised learning dataset
---

``` {.r}
library(dplyr)
library(feather)
library(tokenizers)
library(stringr)
library(purrr)
library(readr)

scores <- read_feather("temp/all-features.feather")
load("temp/bible.rda")
```

``` {.r}
set.seed(3442)
assign_likelihood <- function(p) {
  ifelse(p >= 0.20, "yes", ifelse(p <= 0.05, "no", "possibly"))
}
sample_matches <- scores %>% 
  mutate(likely = assign_likelihood(probability)) %>% 
  group_by(likely) %>% 
  sample_n(400) %>% 
  ungroup() %>% 
  sample_frac(1) 
```

``` {.r}
my_stops <- c(stopwords(), "he", "his", "him", "them", "have", "do", "from", 
              "which", "who", "she", "her", "hers", "they", "theirs")
get_url_words <- function(x) {
  words <- tokenize_words(x, stopwords = my_stops)
  map_chr(words, str_c, collapse = "+")
}

chronam_url <- function(page, words) {
  base <- "http://chroniclingamerica.loc.gov/lccn/"
  str_c(base, page, "#words=", words, collapse = TRUE)
}


bible_verses <- bible_verses %>% 
  select(-tokens) %>% 
  mutate(words = get_url_words(verse))

sample_matches <- sample_matches %>%
  left_join(bible_verses, by = "reference")

urls <- map2_chr(sample_matches$page, sample_matches$words, chronam_url)

sample_matches <- sample_matches %>% 
  mutate(url = urls,
         match = "") %>% 
  select(reference, verse, url, match, likely, token_count, probability, tfidf, tf, 
         position_range, position_sd, everything()) %>% 
  select(-words)
```

``` {.r}
write_csv(sample_matches, "data/matches-for-model-training.csv")
```