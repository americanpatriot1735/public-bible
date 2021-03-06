# This Makefile builds the project from almost scratch. Tasks that involve
# downloading large amounts of data from Chronicling America have to be run
# deliberately. In general, these are the order that steps should be taken.
# Most of these will be run by creating the `all` task.
#
# 1. Download data from Chronicling America (not part of `make all`)
# 2. Extract data
# 3. Generate sample from the data and copy to local directory
# 4. Create Bible DTM and other objects necessary for feature extraction
# 5. Run feature extraction on sample data
# 6. Sample the potential matches for labelling
# 7. Label the sample data in Google Sheets
# 8. Download labeled data and create the version for model training
# 9. Train the model
# 10. Download the newspaper metadata
# 11. Count the words in the newspaper pages
#
# Most of these pieces are run from scripts as detailed below. The rest are run
# Rmd notebook files.

# Define variables
# -----------------------------------------------------------------------------
# Variables for notebooks
NOTEBOOKS := $(patsubst %.Rmd, %.md, $(wildcard *.Rmd))
NOTEBOOK_DIR := ~/acad/notebook2

# Variables for downloading Chronicling America
chronicling_dir := /media/lmullen/data/chronicling-america
chronicling_ocr := $(chronicling_dir)/ocr
chronicling_url := http://chroniclingamerica.loc.gov/data/ocr/
chronicling_tars = $(wildcard $(chronicling_dir)/chroniclingamerica.loc.gov/data/ocr/*.tar.bz2)
chronicling_untars = $(addsuffix .EXTRACTED, $(chronicling_tars))


# Define `all` task: runs scripts and generates notebooks
# -----------------------------------------------------------------------------
all : $(NOTEBOOKS) data/labeled-features.feather data/newspaper-metadata.rda data/newspaper-wordcounts.csv bin/prediction-model.rds

# Also tasks to clean and clobber
clean :
	rm -rf $(NOTEBOOKS)
	rm -rf *_files
	temp/pub-years.txt

clobber-all : clobber-metadata clobber-features clobber-wordcounts

# Tasks to build notebooks
# -----------------------------------------------------------------------------
%.md : %.Rmd $(INCLUDES)
	R --slave -e "set.seed(100); rmarkdown::render('$(<F)')"

public-bible-004-modeling.md : data/labeled-features.feather

# Copy notebooks to wiki
wiki : $(NOTEBOOKS)
	cp $(NOTEBOOKS) $(NOTEBOOK_DIR)/_note/
	mkdir -p $(NOTEBOOK_DIR)/figures/$*/
	cp -r *_files $(NOTEBOOK_DIR)/figures/

# Tasks to download newspaper metadata
# -----------------------------------------------------------------------------
LCCN := $(shell cat data/all-lccn.txt)
LCCN := $(addsuffix .json, $(LCCN))
LCCN := $(addprefix data/newspapers/, $(LCCN))

data/newspaper-metadata.rda : data/all-lccn.txt $(LCCN)
	./scripts/gather-newspaper-metadata.R

data/all-lccn.txt :
	./scripts/download-newspaper-list.R

data/newspapers/%.json : data/all-lccn.txt
	curl http://chroniclingamerica.loc.gov/lccn/$*.json > $@ && sleep 0.5

clobber-metadata :
	rm -rf data/newspaper-metadata.rda
	rm -rf data/all-lccn.txt

# Tasks related to feature extraction
# -----------------------------------------------------------------------------
# Run the feature extraction script on each publication in the sample
PUBLICATIONS := $(shell find ./data/sample -mindepth 1 -maxdepth 1 -type d)
FEATURES := $(addsuffix /features.feather, $(PUBLICATIONS))

bin/bible.rda :
	Rscript --vanilla ./scripts/create-bible-dtm.R

data/sample/%.feather : bin/bible.rda
	./scripts/extract-features.R $(patsubst %/features.feather,%, $@) $@

data/all-features.feather : $(FEATURES)
	./scripts/collect-features.R

data/matches-for-model-training.csv : data/all-features.feather
	./scripts/create-supervised-learning-data.R

data/labeled-features.feather : data/matches-for-model-training.csv
	./scripts/download-labeled-data.R

bin/prediction-model.rds : bin/bible.rda data/labeled-features.feather
	./scripts/train-model.R

clobber-features :
	rm -rf $(FEATURES)
	rm -rf data/all-features.feather
	rm -rf data/labeled-data.csv
	rm -rf bin/bible.rda
	rm -rf data/labeled-features.feather
	rm -rf data/matches-for-model-training.csv
	rm -rf bin/prediction-model.rds

# Tasks to create word counts of each page
# ----------------------------------------------------------------------------
PUBLICATION_MONTHS := $(shell find $(chronicling_ocr) -mindepth 3 -maxdepth 3 -type d)
WORDCOUNTS := $(addsuffix /wordcounts.csv, $(PUBLICATION_MONTHS))

data/newspaper-wordcounts.csv : # $(WORDCOUNTS)
	echo "wordcount,page" > $@
	find $(chronicling_ocr) -iname *wordcounts.csv -type f -exec cat {} >> $@ \;

%/wordcounts.csv : %
	./scripts/wordcounter.sh $^

clobber-wordcounts :
	rm -rf data/newspaper-wordcounts.csv
	rm -rf $(WORDCOUNTS)

# Tasks to create data frames of the text
# ----------------------------------------------------------------------------
PUBLICATION_YEARS := $(shell find $(chronicling_ocr) -mindepth 2 -maxdepth 2 -type d)
TEXT_DF := $(subst $(chronicling_ocr)/,, $(PUBLICATION_YEARS))
TEXT_DF := $(subst /,-,$(TEXT_DF))
TEXT_DF := $(addsuffix .rds, $(TEXT_DF))
TEXT_DF := $(addprefix $(chronicling_dir)/df/, $(TEXT_DF))

df : $(TEXT_DF)

$(chronicling_dir)/df/%.rds :
	Rscript --vanilla ./scripts/textdir2dataframe.R $@ $(chronicling_ocr) $(chronicling_dir)/df


# Tasks to create a sample dataset
# ----------------------------------------------------------------------------
sample-data : temp/sample-files.txt
	./scripts/copy-sample-files.sh

temp/sample-files.txt : temp/pub-years.txt
	Rscript --vanilla ./scripts/generate-sample-pages.R

temp/pub-years.txt :
	./scripts/generate-publication-years.sh > $@

# Tasks to download and extract Chronicling America data
# -----------------------------------------------------------------------------
extract : $(chronicling_untars)

%.tar.bz2.EXTRACTED : %.tar.bz2
	tar --overwrite -xf $^ -C $(chronicling_ocr) --wildcards '*.txt' \
		&& touch $@

download :
	wget --continue --progress=bar --mirror --no-parent \
		--directory-prefix=$(chronicling_dir) $(chronicling_url)

# Tasks to send files to VRC
# -----------------------------------------------------------------------------
transfer-vrc :
	rsync --archive -P --exclude '*.log' bin/* vrc:/data/chronicling-america/scripts

vrc-results :
	rsync --archive -P --ignore-exisiting vrc:/data/chronicling-america/out/* /media/lmullen/data/chronicling-america/out

.PHONY : clean clobber-metadata clobber-features clobber-wordcounts clobber-all extract download
