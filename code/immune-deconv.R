# Author: Komal S. Rathi
# Date: 11/11/2019
# Function: 
# Script to perform immune characterization using xCell etc.

# load libraries
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(immunedeconv))

setwd('~/Projects/Mai-Dang-Medullo/')

option_list <- list(
  make_option(c("-p", "--polyaexprs"), type = "character",
              help = "PolyA Expression data: HUGO symbol x Sample identifiers (.RDS)"),
  make_option(c("-s", "--strandedexprs"), type = "character",
              help = "Stranded Expression data: HUGO symbol x Sample identifiers (.RDS)"),
  make_option(c("-c", "--clin"), type = "character",
              help = "Clinical file (.TSV)"),
  make_option(c("-m", "--method"), type = "character",
              help = "Deconvolution Method"),
  make_option(c("-b", "--cibersortbin"), type = "character", 
              help = "Path to Cibersort binary (CIBERSORT.R)"),
  make_option(c("-g", "--cibersortgenemat"), type = "character", 
              help = "Path to Cibersort signature matrix (LM22.txt)"),
  make_option(c("-o","--outputfile"), type = "character",
              help = "Deconv Output (.RData)")
)

# parse parameters
opt <- parse_args(OptionParser(option_list = option_list))
polya <- opt$polyaexprs
stranded <- opt$strandedexprs
clin.file <- opt$clin
deconv.method <- opt$method
cibersort_bin <- opt$cibersortbin 
cibersort_mat <- opt$cibersortgenemat 
output.file <- opt$outputfile

# for multiple methods, convert to character vector
deconv.method <- trimws(strsplit(deconv.method,",")[[1]]) 

# TIMER specifically for adult and needs specification on what tumor type it is
# so we will remove it from the recommended methods
rec_methods <- grep('timer', deconvolution_methods, invert = TRUE, value = TRUE)

# Check model parameter - must be in recommended methods (immunedeconv accepted options)
if (!is.null(deconv.method)){
  if (!(all(deconv.method %in% rec_methods))) {
    stop( paste(c("Error: Specified method not available. Must be one of the following: ", rec_methods), collapse=" ") )
  }
}

# if cibersort_bin and cibersort_mat are defined
# then, set path to cibersort binary and matrix
print(cibersort_bin)
print(cibersort_mat)
if(cibersort_bin != "NA" & cibersort_mat != "NA"){
  set_cibersort_binary(cibersort_bin)
  set_cibersort_mat(cibersort_mat)
}

# merge expression from polya and stranded data on common genes
polya <- readRDS(polya)
stranded <- readRDS(stranded)
common.genes <- intersect(rownames(polya), rownames(stranded))
polya <- polya[common.genes,]
stranded <- stranded[common.genes,]
expr.input <- cbind(polya, stranded)

# read clinical data
clin <- read.delim(clin.file, stringsAsFactors = F)
clin  <- clin %>% 
  filter(Kids_First_Biospecimen_ID %in% colnames(expr.input))

# function to run immunedeconv
deconv <- function(expr.input, method){
  
  # subset to medullo samples only
  expr.input <- expr.input[,colnames(expr.input) %in% clin$Kids_First_Biospecimen_ID]
  print(dim(expr.input))
  
  # deconvolute using specified method
  res <- deconvolute(gene_expression = as.matrix(expr.input), method = method)
  res$method <- method # assign method name 
  
  # merge output with clinical data
  res <- res %>%
    gather(sample, fraction, -c(cell_type, method)) %>%
    as.data.frame()
  res <- merge(res, clin, by.x = 'sample', by.y = 'Kids_First_Biospecimen_ID')
  
  return(res)
}

# deconvolute using method(s) of choice
deconv.res <- lapply(deconv.method, FUN = function(x) 
  deconv(expr.input = expr.input, 
         method = x))

# combine results from one or more methods
deconv.res <- do.call(rbind.data.frame, deconv.res) 

# save output to RData object 
print("Writing output to file..")
save(deconv.res, file = output.file)
print("Done!")
