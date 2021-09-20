library(plyr)
library(reshape)
library(haven)
library(devtools)
library(RCurl)
library(utils)
library(crunch)
devtools::load_all('/Volumes/projects/daniel.morgan/spg_repo/spg/crunchops')
options(stringsAsFactors = FALSE)
options(download.file.method="curl")

user <- 'daniel.morgan'

login(email=paste0(user,'@yougov.com'))

switch(Sys.info()[['sysname']],
       Linux = {startpath <- '/Volumes/projects'},
       Windows = {startpath <- '/vfs01/projects'},
       Darwin = {startpath <- '/Volumes/projects'})


proj <- 'brand_tracking'

setwd(paste(startpath, '/External Projects/', proj, '/Data', sep=''))


# Load the dataset
ds_old <- loadDataset('brand_tracker_us_202102')


# Create a Fork
ds <- forkDataset(ds_old,"brand_tracking fork")


# This is used for filling in the variables

appList <- c('Amazon','Apple','Facebook','FacebookMessenger','Google','Hike',
             'Imo','Instagram','Kakaotalk','Line','Microsoft','Snapchat','Telegram',
             'Twitter','Viber','WeChat','WhatsApp','YouTube','Zalo','TikTok')


varName2 <- c("CQ3","CQ4_a","CQ4_b","CQ4_e","CQ5","CQ6","CQ7","CQ8","CQ9","CQ10","CQ11",
             "CQ12","WQ1","WQ10","WQ3","WQ4","WQ5","MRQ7a","MRQ8","MRQ9",
             "MRQ10","MRQ11","MRQ12","MRQ13","MRQ14")


# We need to construct a dataframe
# so we grab the brand1 variables need
vlist1 <- do.call(cbind,lapply(varName2,function(vname) {
                      if (vname %in% c("CQ4_a","CQ4_b","CQ4_e")) {
                          as.vector(ds$CQ4_brand1_grid[[paste0(vname,'_brand1')]],mode="id")
                      } else {
                          as.vector(ds[[paste0(vname,'_brand1')]],mode="id")
                      }
}))
colnames(vlist1) <- paste0(varName2,'_brand1')

# so we grab the brand2 variables need
vlist2 <- do.call(cbind,lapply(varName2,function(vname) {
                      if (vname %in% c("CQ4_a","CQ4_b","CQ4_e")) {
                          as.vector(ds$CQ4_brand2_grid[[paste0(vname,'_brand2')]],mode="id")
                      } else {
                          as.vector(ds[[paste0(vname,'_brand2')]],mode="id")
                      }
}))
colnames(vlist2) <- paste0(varName2,'_brand2')
          
# Make the dataframe          
df <- data.frame(caseid=as.vector(ds$caseid),
                 brand1=as.vector(ds$BRAND1),
                 brand2=as.vector(ds$BRAND2),
                 vlist1,
                 vlist2, stringsAsFactors=FALSE)

# Use this dataframe to fill in the variables
xx <- lapply(appList,function(appName) {
            idxCr1 <- as.vector(ds$caseid[ds$BRAND1 %in% c(appName)])
            idxCr2 <- as.vector(ds$caseid[ds$BRAND2 %in% c(appName)])
            idxDf <- as.vector(df$caseid)
            yy <- lapply(varName2, function(vroot) {
                   vtarg <- paste0(vroot,"_",appName)
                   val1  <- df[match(idxCr1,idxDf),paste0(vroot,"_brand1")]
                   val2  <- df[match(idxCr2,idxDf),paste0(vroot,"_brand2")]
                   val1  <- ifelse(val1 %in% c(1,2,3,4,5),val1,9)
                   val2  <- ifelse(val2 %in% c(1,2,3,4,5),val2,9)
                   
                   ds[[vtarg]][ds$BRAND1 %in% c(appName)] <- val1
                   ds[[vtarg]][ds$BRAND2 %in% c(appName)] <- val2
             })
})
##########################################################################################
##########################################################################################

# Done!
