###### Calanda community data functions ####
#Chelsea Chisholm, 11.03.2019

load_cover_CH_Calanda <- function(){
  #import data
  dat <- read.csv('./data/CH_Calanda/CH_Calanda_commdata/relevee_database.csv', sep=';', stringsAsFactors = FALSE)
  cover <- dat %>% 
    select(year, Treatment, Block, plot_id, Site, turf_type, Species_Name, Cov_Rel1, Botanist_Rel1)
  
  return(cover)
}
