##################
### CN_GONGGA  ###
##################

#' Load transplant community 
#'
#' @param con connection to database
#' @param cover logical cover or subturf frequency (only cover implemented)
#' 

## ---- load_comm

load_comm <- function(con, cover = TRUE) {
  
  ##cover data
  coverQ <-
    "SELECT sites.siteID AS originSiteID, blocks.blockID AS originBlockID, plots.plotID AS originPlotID, turfs.turfID, plots_1.plotID AS destPlotID, blocks_1.blockID AS destBlockID, sites_1.siteID AS destSiteID, turfs.TTtreat, turfCommunity.year, turfCommunity.species, turfCommunity.cover, turfCommunity.flag, taxon.speciesName
  FROM blocks, sites, plots, turfs, turfCommunity, plots AS plots_1, blocks AS blocks_1, sites AS sites_1, taxon
  WHERE blocks.siteID = sites.siteID AND plots.blockID = blocks.blockID AND turfs.originPlotID = plots.plotID AND turfCommunity.turfID = turfs.turfID AND turfs.destinationPlotID = plots_1.plotID AND blocks_1.siteID = sites_1.siteID AND plots_1.blockID = blocks_1.blockID AND turfCommunity.species = taxon.species"
  
  cover.thin <- tbl(con, sql(coverQ)) %>% 
    collect()
  
  #recode TTtreat
  cover.thin <- cover.thin %>% mutate(
    TTtreat = plyr::mapvalues(TTtreat,
                              from = c("C", "O", "1", "2", "3", "4", "OTC")  ,
                              to  = c("control", "local", "warm1", "cool1", "warm3", "cool3", "OTC")
    ), 
    TTtreat = factor(
      TTtreat,
      levels = c("control", "local", "warm1", "cool1", "warm3", "cool3", "OTC")
    ),
    originSiteID = factor(originSiteID, levels = c("H", "A", "M", "L")),
    destSiteID = factor(destSiteID, levels = c("H", "A", "M", "L"))
  ) %>% 
    as_tibble()
  
  cover.thin
}

#### Import Community ####
ImportCommunity_CN_Gongga <- function(){
  
  ## ---- load_community
  con <- src_sqlite(path = "data/CN_Gongga/transplant.sqlite", create = FALSE)
  # need to move all code to dplyr for consistancy
  
  #load cover data and metadata
  cover_thin_CN_Gongga <- load_comm(con = con)
  
  return(cover_thin_CN_Gongga)
}


#get taxonomy table
ImportTaxa_CN_Gongga <- function(){

  ## ---- load_community
  con <- src_sqlite(path = "data/CN_Gongga/transplant.sqlite", create = FALSE)
  
  # need to move all code to dplyr for consistancy
  taxa_CN_Gongga <- tbl(con, "taxon") %>%
  collect()
return(taxa_CN_Gongga)
}


#### Cleaning Code ####
# Clean trait data
# CleanTrait_CN_Gongga <- function(dat){
#   dat2 <- dat %>% 
#     filter(Project %in% c("LOCAL", "0", "C")) %>% 
#     mutate(Treatment = plyr::mapvalues(Project, c("C", "0", "LOCAL"), c("C", "O", "Gradient"))) %>% 
#     mutate(Taxon = trimws(Taxon)) %>% 
#     mutate(Year = year(Date),
#            Country = "CH",
#            Gradient = as.character(1),
#            Project = "T") %>% 
#     rename(BlockID = Location) %>%
#     mutate(PlotID = paste(BlockID, Treatment, sep = "-"),
#            ID = paste(Site, Treatment, Taxon, Individual_number, Leaf_number, sep = "_")) %>% 
#     select(Country, Year, Site, Gradient, BlockID, PlotID, Taxon, Wet_Mass_g, Dry_Mass_g, Leaf_Thickness_Ave_mm, Leaf_Area_cm2, SLA_cm2_g, LDMC, C_percent, N_percent , CN_ratio, dN15_percent, dC13_percent, P_AVG, P_Std_Dev, P_Co_Var) %>% 
#     gather(key = Trait, value = Value, -Country, -Year, -Site, -Gradient, -BlockID, -PlotID, -Taxon) %>% 
#     filter(!is.na(Value)) 
#   return(dat2)
# }

# Cleaning community data
CleanCommunity_CN_Gongga <- function(community_CN_Gongga_raw){
  dat <- community_CN_Gongga_raw %>% 
    filter(TTtreat != c("OTC")) %>% 
    rename(Year = year, Treatment = TTtreat, Cover = cover, SpeciesName = speciesName) %>% 
    mutate(Gradient = "CN_Gongga",
                      Country = as.character("China"),
           Treatment = recode(Treatment, "control" = "Control", "local" = "LocalControl", "warm1" = "Warm", "cool1" = "Cold", "warm3" = "Warm", "cool3" = "Cold")) %>% 
    mutate(SpeciesName = recode(SpeciesName, "Potentilla stenophylla var. emergens" = "Potentilla stenophylla")) %>% 
    filter(!is.na(Cover), !Cover == 0) %>% 
    select(-flag, -species, -Gradient, -Country) %>%
    mutate(UniqueID = paste(Year, originSiteID, destSiteID, destBlockID, Treatment, destPlotID, turfID, sep='_')) %>% 
    mutate(destPlotID = as.character(destPlotID), destBlockID = if (exists('destBlockID', where = .)) as.character(destBlockID) else NA) %>% 
    ungroup()
  
  dat2<- dat %>%  
    filter(!is.na(Cover)) %>%
    group_by_at(vars(-SpeciesName, -Cover)) %>%
    summarise(SpeciesName = "Other",Cover = 100 - sum(Cover)) %>%
    bind_rows(dat) %>% 
    filter(Cover > 0) %>% #omg so inelegant
    mutate(Total_Cover = sum(Cover), Rel_Cover = Cover / Total_Cover) %>%
    ungroup()
  
  comm <- dat2 %>% filter(!SpeciesName %in% c('Other')) 
  cover <- dat2 %>% filter(SpeciesName %in% c('Other')) %>% 
    select(UniqueID, destSiteID, SpeciesName, Cover, Rel_Cover) %>% group_by(UniqueID, destSiteID, SpeciesName) %>% summarize(OtherCover=sum(Cover), Rel_OtherCover=sum(Rel_Cover)) %>%
    rename(CoverClass=SpeciesName)
  return(list(comm=comm, cover=cover)) 

}

  
# Cleaning China Meta community (class cover) data
# CleanMetaCommunity_CN_Gongga <- function(metaCommunity_CN_Gongga_raw){
#   dat2 <- metaCommunity_CN_Gongga_raw %>% 
#     select(PlotID, Year, Moss, Lichen2, Litter, BareGround, Rock, Vascular, Bryophyte, Lichen, MedianHeight_cm, MedianMossHeight_cm) %>% 
#     #recode(Bryophyte=Moss, )
#     mutate(Gradient = "CN_Gongga",
#            destBlockID = NA,
#            Country = as.character("China"))
#   return(dat2)
# }

CleanMeta_CN_Gongga <- function(){
   
  meta_CN_Gongga <- tibble(Gradient = rep(x = "CN_Gongga", 4),
                           Country = rep(x = "China", 4), 
                              destSiteID = c("L", "M", "A", "H"),
                              Elevation = c(3000, 3500, 3850, 4100),
                           Latitude = c(29.84347, 29.86192, 29.88911, 29.90742),
                              Longitude = c(102.0343, 102.0360, 102.0173, 102.0118),
                              YearEstablished = rep(2012, 4),
                              PlotSize_m2 = rep(0.0625, 4),
                              destBlockID= rep(NA, 4))
  
  return(meta_CN_Gongga)
}



#### IMPORT, CLEAN AND MAKE LIST #### 
ImportClean_CN_Gongga <- function(){
  
  ### IMPORT DATA
  #metaCommunity_CN_Gongga_raw = get(load(file = file_in("data/CN_Gongga/metaCommunityCN_Gongga_2012_2016.Rdata")))
  #meta_CN_Gongga_raw = get(load(file = file_in("data/CN_Gongga/metaCN_Gongga.Rdata")))
  community_CN_Gongga_raw = ImportCommunity_CN_Gongga()
  taxa_CN_Gongga = ImportTaxa_CN_Gongga()
  #trait_CN_Gongga_raw = get(load(file = file_in("data/CN_Gongga/traits_2015_2016_China.Rdata")))

  ### CLEAN DATA SETS
  ## CN_Gongga
  meta_CN_Gongga = CleanMeta_CN_Gongga()
  taxa_CN_Gongga = ImportTaxa_CN_Gongga() %>% .$speciesName
  #trait_CN_Gongga = CleanTrait_CN_Gongga(trait_CN_Gongga_raw)
  
  cleaned_CN_Gongga = CleanCommunity_CN_Gongga(community_CN_Gongga_raw) 
  community_CN_Gongga = cleaned_CN_Gongga$comm
  cover_CN_Gongga = cleaned_CN_Gongga$cover
  
  
  # Make list
  CN_Gongga = list(meta = meta_CN_Gongga,
                   cover = cover_CN_Gongga,
                   community = community_CN_Gongga,
                   taxa = taxa_CN_Gongga)
  
  return(CN_Gongga)
}

