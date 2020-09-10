# Author: Komal S. Rathi
# Date: 11/11/2019
# Function: Summarise results and create plots

# load libraries
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(pheatmap))
suppressPackageStartupMessages(library(corrplot))

# source plotting theme
source('../Utils/pubTheme.R')

option_list <- list(
  make_option(c("-i", "--input"), type = "character",
              help = "Immunedeconv output from 01-immune.deconv.R (.RData)")
)

# output directory
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
outputDir <- file.path(root_dir, "results", "immune-deconv")
source(file.path(root_dir, "util", "corrplot.R"))
source(file.path(root_dir, "util", "create_heatmap.R"))

# parse parameters
opt <- parse_args(OptionParser(option_list = option_list))
deconvout <- opt$input
output <- opt$output
load(deconvout) 

# methods
methods <- unique(deconv.res$method)

# plot correlation plots between all combination of methods used
methods.comb <- combn(methods, m = 2, simplify = FALSE) 
lapply(methods.comb, 
       FUN = plot.corrplot, 
       deconv.out.format = deconv.res, 
       outputDir = outputDir)  

# create heatmaps for all deconvolution methods
lapply(methods, 
       FUN = create.heatmap, 
       deconv.out.format = deconv.res,
       outputDir = outputDir)
