############################################
# Combine filtered EC data and full Biomet #
#  Ameriflux submission: No gapfill or U*  #
#           written by: M. Mauritz         #
#             August 2019                  #
############################################

# 20200427: update with timestamp corrected biomet and flux data

library(data.table)
library(lubridate)
library(ggplot2)
library(bit64)

# import filtered flux data file from Eddy Pro as data table
# filtered in: Jornada_EddyPro_Output_Fluxnext_2010_2019.R
setwd("~/Desktop/TweedieLab/Projects/Jornada/EddyCovariance/JER_Out_EddyPro_filtered")

# import data that was filtered by 3SD filter with timestamp corrected
load("JER_flux_2010_2019_EddyPro_Output_filtered_SD_TIMEcorr_20200427.Rdata")

# rename columns
# TIMESTAMP_START = TIMESTAMP_START_correct
# TIMESTAMP_END = TIMESTAMP_END_correct
setnames(flux_filter_sd,c("TIMESTAMP_START_correct","TIMESTAMP_END_correct"),
         c("TIMESTAMP_START","TIMESTAMP_END"))

# convert date to POSIXct and get a year, day, hour column
# if this step doesn't work, make sure bit64 library is loaded otherwise the timestamps import in a non-sensical format
flux_filter_sd[,date_time := NULL]
flux_filter_sd[,':=' (date_time = parse_date_time(TIMESTAMP_END,"YmdHM",tz="UTC"))]

# there's duplicated data in 2012 DOY 138
flux <- (flux_filter_sd[!(duplicated(flux_filter_sd, by=c("date_time")))])


# import biomet2 which contains all sensors as individual datastreams
setwd("~/Desktop/TweedieLab/Projects/Jornada/EddyCovariance/MetDataFiles_EP/Biomet2_20200415")

biometfiles <- list.files(path="~/Desktop/TweedieLab/Projects/Jornada/EddyCovariance/MetDataFiles_EP/Biomet2_20200415",
                          full.names=TRUE, pattern="_wide_") 

# read files and bind them into one file. fill=TRUE because of the missing columns in 2011
biomet_all <- do.call("rbind", lapply(biometfiles, header = TRUE, fread, sep=",",fill=FALSE))

biomet_all <- (biomet_all[!(duplicated(biomet_all, by=c("date_time")))])

                                   
biomet_all[,':=' (date_time = parse_date_time(date_time,"Ymd HMS",tz="UTC"))]

# merge the flux data and biomet2 data
# first remove the biomet columns from the flux data
exclude_cols <- c("TA_1_1_1", "RH_1_1_1", "PA_1_1_1", "WD_1_1_1", "MWS_1_1_1", "PPFD_IN_1_1_1", "PPFD_OUT_1_1_1", 
                  "P_RAIN_1_1_1", "SWC_1_1_1", "TS_1_1_1", "G_1_1_1", "G_1_2_1", "G_2_1_1", "G_2_2_1",
                  "LW_IN_1_1_1", "LW_OUT_1_1_1", "SW_OUT_1_1_1", "SW_IN_1_1_1", "NETRAD_1_1_1", "date_orig",
                  "month_orig","year_orig") 

flux <- flux[,!c(exclude_cols),with=FALSE]

flux.biomet <- merge(flux,biomet_all, by="date_time", all.x=TRUE)


# format all columns to be in the same order: 
names_all <- colnames(flux.biomet[,!c("TIMESTAMP_START","TIMESTAMP_END"),with=FALSE])
names_output <- c("TIMESTAMP_START","TIMESTAMP_END",names_all)

setcolorder(flux.biomet,names_output)

# save to upload to ameriflux: 
# <SITE_ID>_<RESOLUTION>_<TS-START>_<TS-END>_<OPTIONAL>.csv
setwd("~/Desktop/TweedieLab/Projects/Jornada/EddyCovariance/Ameriflux/20200514")

# Don't save this version. Just takes up space.
#write.table(flux.biomet[,!c("date_time"),with=FALSE], paste("USJo1_HH",min(flux.biomet$TIMESTAMP_END),max(flux.biomet$TIMESTAMP_END),
#                               "20200514submit.csv",sep="_"), sep=',', dec='.', row.names=FALSE)


# save by years
for (i in 2010:2019){
  # subset each year
  dat.save <- flux.biomet[year(date_time)==i,]
  
  write.table (dat.save[,!c("date_time"),with=FALSE],
             file= paste("US-Jo1_HH",min(dat.save$TIMESTAMP_END),max(dat.save$TIMESTAMP_END),
                         "20200514submit.csv",sep="_"),
             sep =',', dec='.', row.names=FALSE, na="-9999", quote=FALSE)
}


