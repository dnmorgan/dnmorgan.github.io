library(plyr)
library(reshape)
library(haven)
library(devtools)
library(RCurl)
library(utils)
library(crunch)
options(stringsAsFactors = FALSE)
options(download.file.method="curl")

user <- 'daniel.morgan'

devtools::load_all(paste0('/Volumes/projects/',user,'/spg_repo/spg/crunchops'))

login(paste0(user,'@yougov.com'))

switch(Sys.info()[['sysname']],
       Linux = {startpath <- '/Volumes/projects'},
       Windows = {startpath <- '/vfs01/projects'},
       Darwin = {startpath <- '/Volumes/projects'})


base <- 'messaging_tracker'
wave <- c('202104')
proj <- paste0(base,wave)

setwd(paste(startpath, '/External Projects/', proj, '/Data', sep=''))


##########################################################################################
# Generate needed lists
# We are going to get an appList

#update for previous wave refield

appList   <- sort(unique(gsub('Q.+_brand1_','',grep('Q.+_brand1_',names(ds),value=TRUE))))

# We need an question list
varList <- c("Q8", "Q9", "Q10", "Q10A", "Q11", "Q12", "Q13",  "Q14",  "Q15",  "Q16",  "Q17",  "Q18",  "Q19",
             "Q20", "Q25")

lblList <- c("CAU","GFW","Fun","Useful","NEW Control",
             "NEW Privacy","Transparency","Ease of use","NEW Reliability","NEW Findability_by_others",
             "NEW Finding_people","NEW Speed_closest","NEW Non_text_expression","NEW Perceived_reach","NEW Secure messages")

lbl_lookup <- data.frame(varRoot=varList,labelRoot=lblList)

existingVars <- aliases(allVariables(ds))

# create the desired variables
# Now it may seem silly to create all of these variables when
# a specific market will only have some of these apps.
# However, we are trying to replicate the original QSL.
# We create variables even if they won't be filled. In
# this maner, unasked brands will have all 9's (not asked) 
# instead of -1 (No data).

xx <- lapply(appList, function (app){
             print(paste0("Processing: ",app))

             x <- lapply(varList, function (varRoot) {
                         # gather necessary information to create variables
                         varLabel <- paste0(lbl_lookup$labelRoot[lbl_lookup$varRoot %in% c(varRoot)]," ",app)
                         varAlias <- paste0(varRoot,"_",app)
                         varRef   <- paste0(varRoot,"_brand1_",app)

                         # Grab the description/categories from the _brand1_version
                         varDesc  <- description(ds[[varRef]])
                         varCats  <- categories(ds[[varRef]])

                         # create the variable if it doesn't exist
                         if (! varAlias %in% existingVars) {
                             ds[[varAlias]] <- VariableDefinition(name=varLabel, alias=varAlias, 
                                                                  description=varDesc, type='categorical', 
                                                                  categories=varCats,
                                                                  data=rep(9,nrow(ds)))
                             print(paste0(" - Created: ",varAlias))
                         }
                        })
             print("====================================")
            })
ds <- refresh(ds)
# Because this was so slow to run, we will save the version
ds <- saveVersion(ds,"Variables added")
##########################################################################################



##########################################################################################
# Fill in the variables we created
# Ideally we would have wanted to only fill in the apps asked for a specific market.
# Unfortunately, there is no categorical variable to rely on. BRAND1 and BRAND2 are text
# variables. So we are going to have to loop through all of the apps and determine if
# we have non-missing values for them. If so, we can write things back (a time consuming operation)
ds <- restoreVersion(ds,"Variables added")
ds <- refresh(ds)

# For speed, filling in will go faster if we don't use any exclusion rules
excl <- exclusion(ds)
excl
exclusion(ds) <- NULL

xx <- lapply(appList, function (app){
             print(paste0("Processing: ",app))

             x <- lapply(varList, function (varRoot) {
                         # gather necessary information to create variables
                         varAlias <- paste0(varRoot,"_",app)
                         varRef1   <- paste0(varRoot,"_brand1_",app)
                         varRef2   <- paste0(varRoot,"_brand2_",app)

                         x1 <- as.vector(ds[[varRef1]],mode="id")
                         x2 <- as.vector(ds[[varRef2]],mode="id")

                         x1 <- ifelse(x1<0, 9,x1)
                         x2 <- ifelse(x2<0, 9,x2)

                         xvals <- apply(cbind(x1,x2),1,min)                         
                         # To speed things along, only write data if the min
                         if (min(xvals) < 9) {
                             ds[[varAlias]] <- xvals
                             print(paste0(" - Backfilled: ",varAlias))
                         }
                        })
             print("====================================")
            })
ds <- refresh(ds)

# Restore exclusion rules
exclusion(ds) <- excl

# Again, because it takes a while to run, save a version
ds <- saveVersion(ds,"Variables backfilled")
ds <- refresh(ds)