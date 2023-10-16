library(tidyverse)
library(dplyr)
library(GISTools)
library(sf)
library(ggmap)
library(dplyr)
library(tidygeocoder)


#Read in the CSV files of methadone treatment program locations. 
origAddress <- read.csv("/Users/emilypeterson/Dropbox/INFO 532/Opioid Analysis/TreatmentProgram.csv") %>%
  dplyr::select(c("Street", "City", "State", "Zipcode")) %>%
  mutate(addresses = paste0(Street, ", ", City, ", ", State))
#Convert csv into data frame with address infomation
origAddress <- data.frame(origAddress)


#Geo-code clinic locations to give lat and long coordinates for each clinic using geocode() function.
geo_code_locations <- origAddress %>%
  tidygeocoder::geocode(address  = addresses, method = "arcgis", lat = latitude, long = longitude, full_results = FALSE)

#Write to RDS file to be save in your directory. 
saveRDS(geo_code_locations, "/Users/emilypeterson/Dropbox/INFO 532/Opioid Analysis/GA_clinic_coords.RDS" )

#Download the 2020 Opioid death data from GADPH

  #This gives county-age-grp specific rates.
excel_data <- readxl::read_excel("/Users/emilypeterson/Dropbox/SASUModel/data/2020 Opioid-Involved Deaths by County & Age Group_10.17.22.xlsx", col_names = F)
agegrps <- as.vector(excel_data[2,-1])
excel_data <- excel_data[-c(1,2),]
colnames(excel_data) = c("county", agegrps)

#Create a long data format.
long_data <- excel_data %>%
 tidyr::pivot_longer(cols ="15-19":"TOTAL", names_to="agegrp" )


#Assign age-groups for each row
age_grp <- rep(NA, length(long_data$county))

for(i in 1:length(age_grp)){
  if(long_data$agegrp[i] == "15-19"){ age_grp[i] <- "15-19"}
  if(long_data$agegrp[i] == "20-24"){ age_grp[i] <- "20-24"}
  if(long_data$agegrp[i] == "25-29"){ age_grp[i] <- "25-29"}
  if(long_data$agegrp[i] =="30-34"){ age_grp[i] <- "30-34"}
  if(long_data$agegrp[i] %in% c("35-39", "40-44")){ age_grp[i] <- "35-44"}
  if(long_data$agegrp[i] %in% c("45-49", "50-54")){ age_grp[i] <- "45-54"}
  if(long_data$agegrp[i] %in% c("55-59", "60-64")){ age_grp[i] <- "55-64"}
  if(long_data$agegrp[i] %in% c("65-69", "70-74")){ age_grp[i] <- "65-74"}
  if(long_data$agegrp[i] %in% c("75-79", "80-84")){ age_grp[i] <- "75-84"}
  if(long_data$agegrp[i] == "85+"){ age_grp[i] <- "85+"}
}

long_data$age_grp <- age_grp
long_data$county_name <- paste(long_data$county, "County, Georgia")
long_data$count <- as.numeric(ifelse(long_data$value == "-", 0, long_data$value))


count_data <- long_data %>%
  filter(agegrp != "TOTAL") %>%
  select(c(county_name, age_grp, count)) %>%
  group_by(county_name) %>%
  summarize(death_count = sum(count, na.rm=T))

saveRDS(count_data, "/Users/emilypeterson/Dropbox/INFO 532/Opioid Analysis/GA_opioid_death_counts.RDS")

#Read in population counts for each county/age-group from census data.
fixed_data <- readRDS(paste("/Users/emilypeterson/Dropbox/GAcounty_data_processing/complete_agestrat_data.RDS", sep="")) 

temp <- fixed_data %>%
  select(c(county_name, GEOID, age_grp, pep_pop, ice_wbhinc, geometry, endyear)) %>%
  unique() %>%
  group_by(county_name) %>%
  summarize(pop_count = sum(pep_pop, na.rm=T),
            ice = mean(ice_wbhinc, na.rm=T)) 
tt <- fixed_data %>%
  select(c(county_name, geometry)) %>%
  unique()

temp2 <- temp %>%
  right_join(tt)
saveRDS(temp2, "/Users/emilypeterson/Dropbox/INFO 532/Opioid Analysis/population_data.RDS")

#Merge opioid counts with population counts to calculate rates (count/total pop).
mdata <- merge(temp, count_data, by = c("county_name")) %>%
  mutate(rate_per_10000 = (death_count/pop_count) * 10000)

#Include the geometry/spatial features in the final dataset to be written to RDS
ga_geo <- fixed_data %>%
  select(c(county_name, GEOID, geometry)) %>%
           unique()

ga_final <- merge(mdata, ga_geo, by = c("county_name"))
  
#Save GA opioid data as RDS file to working directory.       
saveRDS(ga_final, "/Users/emilypeterson/Dropbox/INFO 532/Opioid Analysis/GA_opioid_death_rates.RDS")

