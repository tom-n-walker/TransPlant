#############################
### TRANSPLANT DRAKE PLAN ###
#############################


# Load library
library("drake")
library("tidyverse")
library("readxl")
library("lubridate")
library("e1071")
library("DBI")
library("RSQLite")
library("visNetwork")

# drake configurations
pkgconfig::set_config("drake::strings_in_dots" = "literals")

# trick
pn <- . %>% print(n = Inf)

# source cleaning scripts
source("R/ImportCleanAndMakeList_CH_Calanda.R")
#source("R/ImportCleanAndMakeList_CH_Calanda2.R")
source("R/ImportCleanAndMakeList_CH_Lavey.R")
source("R/ImportCleanAndMakeList_CN_Damxung.R")
source("R/ImportCleanAndMakeList_CN_Gongga.R")
source("R/ImportCleanAndMakeList_DE_Grainau.R")
source("R/ImportCleanAndMakeList_DE_Susalps.R")
source("R/ImportCleanAndMakeList_FR_AlpeHuez.R")
source("R/ImportCleanAndMakeList_FR_Lautaret.R")
source("R/ImportCleanAndMakeList_IN_Kashmir.R")
source("R/ImportCleanAndMakeList_NO_Norway.R")
source("R/ImportCleanAndMakeList_SE_Abisko.R")
source("R/ImportCleanAndMakeList_US_Colorado.R")
source("R/ImportCleanAndMakeList_US_Montana.R")
source("R/ImportCleanAndMakeList_IT_MatschMazia.R")
source("R/ImportCleanAndMakeList_US_Arizona.R")
source("R/ImportCleanAndMakeList_CN_Heibei.R")

#Source downstream scripts
source("R/merge_community.R")

# Import Data
ImportDrakePlan <- drake_plan(

  NO_Ulvhaugen = ImportClean_NO_Norway(g = 1), 
  NO_Lavisdalen = ImportClean_NO_Norway(g = 2),
  NO_Gudmedalen = ImportClean_NO_Norway(g = 3),
  NO_Skjellingahaugen = ImportClean_NO_Norway(g = 4),
  
  CH_Lavey = ImportClean_CH_Lavey(),
  CH_Calanda = ImportClean_CH_Calanda(),
#  CH_Calanda2 = ImportClean_CH_Calanda2(), 

  US_Colorado = ImportClean_US_Colorado(), 
  US_Montana = ImportClean_US_Montana(), 
  US_Arizona = ImportClean_US_Arizona(), 

  CN_Gongga = ImportClean_CN_Gongga(), 
  CN_Damxung = ImportClean_CN_Damxung(), 
  IN_Kashmir = ImportClean_IN_Kashmir(), 
  CN_Heibei = ImportClean_CN_Heibei(),

  DE_Grainau = ImportClean_DE_Grainau(), 
  DE_Susalps = ImportClean_DE_Susalps(),
  FR_AlpeHuez = ImportClean_FR_AlpeHuez(), 
  SE_Abisko = ImportClean_SE_Abisko(),
  FR_Lautaret = ImportClean_FR_Lautaret(), 
  IT_MatschMazia = ImportClean_IT_MatschMazia() 
)

#Make taxa vectors all a dataframe with column name 'SpeciesName', keep consistent across all dataframes
#destBlockID needs to be added to Norway data, Gongga, etc. destBlockID <- NA


MergeDrakePlan <- drake_plan(
  dat = merge_comm_data(alldat = tibble::lst(NO_Ulvhaugen, NO_Lavisdalen, NO_Gudmedalen, NO_Skjellingahaugen, 
    CH_Lavey, CH_Calanda, #CH_Calanda2,
    US_Colorado, US_Montana, US_Arizona,
    CN_Damxung, IN_Kashmir, CN_Gongga, CN_Heibei, 
    DE_Grainau, DE_Susalps, FR_AlpeHuez, SE_Abisko, FR_Lautaret, IT_MatschMazia))
)

MyPlan <- bind_rows(ImportDrakePlan, MergeDrakePlan)

conf <- drake_config(MyPlan)
conf
make(MyPlan)

# loadd(dat)
# map(dat, ~sum(is.na(.)))
