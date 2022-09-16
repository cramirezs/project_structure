#!/usr/bin/R

# ------------------------------------------------------------------------------
# title: Project set.
# purpose: This script sets the environment and structure for a project.
# author: Ciro Ramírez-Suástegui
# email: ksuastegui@gmail.com
# date: 2021-10-31
# ------------------------------------------------------------------------------

# Rscript ~/Documents/rstudio/project_set.R -n titu -p "tidyverse, tidytuesdayR"

if (!requireNamespace("optparse", quietly = TRUE))
 install.packages("optparse", repos = "https://cloud.r-project.org")
i <- dirname(gsub(".*=(.*)", "\\1", grep("--file=", base::commandArgs(), value = TRUE)))
optlist <- list(
 optparse::make_option(
   opt_str = c("-n", "--name"), type = "character",
   help = "Name of your project."
 ),
 optparse::make_option(
   opt_str = c("-p", "--packages"), type = "character", default = "crayon, here",
   help = "Packages to install separated by commas.\n\t\tDefault: crayon, here."
 ),
 optparse::make_option(
   opt_str = c("-o", "--output_dir"), type = "character", default = i,
   help = paste("Directory where to deposit the project.\n\t\tDefault:", i)
 ),
 optparse::make_option(
   opt_str = c("-b", "--body"), type = "logical",
   help = "Create directory structure."
 )
)
optparse <- optparse::OptionParser(option_list = optlist)
opt <- optparse::parse_args(optparse)

output_dir <- gsub("\\/{2,}", "/", paste0(opt$output_dir, "/", opt$name))
cat("\nOutput directory:", output_dir, "\n")
if(dir.exists(output_dir) && length(list.files(output_dir))>0){
  # fails when the terminal sends multiple lines with at least a commnet line
  cat("Directory not empty. Do you want to continue? y/n: ")
  ask <- if(interactive()) readline("") else readLines("stdin", n = 1)
  if(grepl("^n", ask)){ cat("... aborting\n"); q("no") }
}
dir.create(output_dir, showWarnings = FALSE)
setwd(output_dir); system("ls -hola")

if(requireNamespace("crayon", quietly = TRUE)){
  cyan = crayon::cyan; redb = crayon::red$bold
  greb = crayon::green$bold; yelo = crayon::yellow
}else{ cyan = redb = greb = yelo = c }

if (!requireNamespace("remotes", quietly = TRUE))
 install.packages("remotes", repos = "https://cloud.r-project.org")
if (!requireNamespace("renv", quietly = TRUE)){
  cat(yelo("Installing renv\n"))
  remotes::install_github("rstudio/renv")
}
if(!file.exists("renv.lock")) renv::init()
renv::activate()

cat(redb("------- Loading libraries ---------------------------------------\n"))
opt$packages <- paste0("crayon, here, ", opt$packages)
if(isTRUE(opt$python)) opt$packages <- paste0("reticulate, ", opt$packages)
packages_funcs = unique(unlist(strsplit(gsub(" ", "", opt$packages), ",")))
i <- !gsub(".*\\/|@.*", "", packages_funcs) %in% installed.packages()[, "Package"]
if(any(i)) cat(redb("Not installed:"), packages_funcs[i], sep = "\n ")
for (i in packages_funcs){
  cat("*", yelo(i), "\n")
  i_name <- gsub(".*\\/|@.*", "", i)
  if(!file.exists(i)){
    if (!requireNamespace(i_name, quietly = TRUE)){
      cat(" - installing\n")
      if(grepl("\\/", i)){
        remotes::install_github(i) # install from github if username/pckg
      }else{
        install.packages(i, repos = "https://cloud.r-project.org")
      }
    }
    temp = suppressMessages(
      require(package = i_name, quietly = TRUE, character.only = TRUE)
    )
    if(isFALSE(temp)){
      if (!require("BiocManager", quietly = TRUE))
        install.packages("BiocManager")
      BiocManager::install(i_name)
      temp = suppressMessages(
        require(package = i_name, quietly = TRUE, character.only = TRUE)
      )
    }
    if(isTRUE(temp)) cat(greb("Success!\n"))
  }else{ source(i) }
}

if(isTRUE(opt$body)){
  cat(cyan("------- Directories structure -----------------------------------\n"))
  dirs_include = c("info", "code/R", "code/python", "data", "img", "results")
  for (i in dirs_include){
    cat("*", i, "\n"); dir.create(i, showWarnings = FALSE, recursive = TRUE)
  }
}

if(isTRUE(opt$python)){
  cat(greb("Python:"), Sys.which("python"), "\n")
  for (i in 1:2) {
    ask <- "randomstring123"
    temp <- c("an environment", "python")
    fun <- if(i == 1) reticulate::use_virtualenv else reticulate::use_python
    while(!file.exists(ask)){
      cat(yelo("Would you like to specify", temp[i], "? no/path: "))
      ask <- if(interactive()) readline("") else readLines("stdin", n = 1)
      if(grepl("^n", ask)) break
    }; if(file.exists(ask)){ fun(ask); break }
  }
}

temp <- paste("open -na Rstudio", output_dir)
cat(temp, greb("\nDo you want to use Rstudio to continue? y/n: "))
ask <- if(interactive()) readline("") else readLines("stdin", n = 1)
if(grepl("^y", ask)) i <- try(system(temp))
