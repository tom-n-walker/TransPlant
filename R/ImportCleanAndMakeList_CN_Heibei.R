####################
### CN_Heibei  ###
####################

#### Import Community ####

ImportCommunity_CN_Heibei <- function(){
  community_CN_Heibei_raw<-read_excel(file_in("data/CN_Heibei/CN_Heibei_commdata/data to J Ecology.xlsx"))
  return(community_CN_Heibei_raw)
} 



#### Cleaning Code ####
# Cleaning Heibei community data

CleanCommunity_CN_Heibei <- function(community_CN_Heibei_raw){
  dat <- community_CN_Heibei_raw %>% 
    rename(SpeciesName = `species` , Cover = `Coverage(%)` , PlotID = Treatment , destSiteID = `away` , originSiteID = `home`, Year = year, destPlotID = `replicate`)%>% 
    filter(!(destSiteID == 3600 | originSiteID == 3600)) %>% 
    mutate(originSiteID = as.character(originSiteID),
           destSiteID = as.character(destSiteID)) %>% 
    mutate(Treatment = case_when(destSiteID =="3200" & originSiteID == "3200" ~ "LocalControl" , 
                                 destSiteID =="3400" & originSiteID == "3400" ~ "LocalControl" , 
                                 destSiteID =="3800" & originSiteID == "3800" ~ "LocalControl" , 
                                 destSiteID =="3200" & originSiteID == "3400" ~ "Warm" , 
                                 destSiteID =="3200" & originSiteID == "3800" ~ "Warm" , 
                                 destSiteID =="3400" & originSiteID == "3200" ~ "Cold" , 
                                 destSiteID =="3400" & originSiteID == "3800" ~ "Warm" , 
                                 destSiteID =="3800" & originSiteID == "3200" ~ "Cold" ,
                                 destSiteID =="3800" & originSiteID == "3400" ~ "Cold")) %>% 
    mutate(UniqueID = paste(Year, originSiteID, destSiteID, destPlotID, sep='_')) %>%
    group_by(UniqueID, Year, originSiteID, destSiteID, destPlotID, Treatment) %>%
    select(-PlotID) %>% ungroup() %>%
    mutate(destPlotID = as.character(destPlotID), destBlockID = if (exists('destBlockID', where = .)) as.character(destBlockID) else NA)
  
  dat2 <- dat %>%  
    filter(!is.na(Cover)) %>%
    group_by_at(vars(-SpeciesName, -Cover)) %>%
    summarise(SpeciesName = "Other",Cover = 100 - sum(Cover)) %>%
    bind_rows(dat) %>% 
    filter(Cover > 0)  %>% #omg so inelegant
    mutate(Total_Cover = sum(Cover), Rel_Cover = Cover / Total_Cover)
  
  comm <- dat2 %>% filter(!SpeciesName %in% c('Other'))
  cover <- dat2 %>% filter(SpeciesName %in% c('Other')) %>% 
    select(UniqueID, SpeciesName, Cover, Rel_Cover) %>% group_by(UniqueID, SpeciesName) %>% summarize(OtherCover=sum(Cover), Rel_OtherCover=sum(Rel_Cover)) %>%
    rename(CoverClass=SpeciesName)
  return(list(comm=comm, cover=cover)) 

}


# Clean metadata

CleanMeta_CN_Heibei <- function(community_CN_Heibei){
  dat2 <- community_CN_Heibei %>% 
  select(-SpeciesName, -Cover) %>% 
    distinct()%>% 
    mutate(Elevation = as.numeric(destSiteID), 
           Gradient = 'CN_Heibei',
           Country = 'China',
           YearEstablished = 2007,
           PlotSize_m2 = 1
    )
  
  
  return(dat2)
}

# Cleaning Heibei species list

CleanTaxa_CN_Heibei <- function(community_CN_Heibei){
  taxa<-unique(community_CN_Heibei$SpeciesName)
  return(taxa)
}


#### IMPORT, CLEAN AND MAKE LIST #### 
ImportClean_CN_Heibei <- function(){
  
  
  ### IMPORT DATA
  community_CN_Heibei_raw = ImportCommunity_CN_Heibei()
  
  ### CLEAN DATA SETS
  cleaned_CN_Heibei = CleanCommunity_CN_Heibei(community_CN_Heibei_raw)
  community_CN_Heibei = cleaned_CN_Heibei$comm
  cover_CN_Heibei = cleaned_CN_Heibei$cover
  meta_CN_Heibei = CleanMeta_CN_Heibei(community_CN_Heibei) 
  taxa_CN_Heibei = CleanTaxa_CN_Heibei(community_CN_Heibei)
  
  
  # Make list
  CN_Heibei = list(meta = meta_CN_Heibei,
                    community = community_CN_Heibei,
                    cover = cover_CN_Heibei,
                    taxa = taxa_CN_Heibei)
  
  return(CN_Heibei)
}

