# This script downloads the previous day's Covid-19 data from the John Hopkins site.
# It stores the data in a SQL database and/or locally.

# When running on another machine, change as needed. 
# Only needed if you read or write the daily data set (recommended).
setwd('D:/OneDrive - Pertell/Code/Covid')


library(lubridate)
library(dplyr)
library(data.table)
library(tibble)
library(tidyr)
library(RODBC)

CovidData <- data.frame()

dataNames <- c('FIPS', 'Admin2', 'Province.State', 'Country.Region', 'Last.Update', 'Latitude', 'Longitude', 'Confirmed', 'Deaths', 'Recovered', 'Active', 'Combined.Key', 'Incident.Rate', 'Case.Fatality_Ratio')

start_date <- Sys.Date() - days(1)
temp <- format(start_date, '%m-%d-%Y')
url <- capture.output(cat
                     ('https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/', temp, '.csv',sep=""))
  
CovidData <- read.csv(url, sep = ",")
names(CovidData) <- dataNames  

# The next 2 blocks are if I save the data to .csv files, otherwise not needed.
fileName <- paste('./CovidData/', start_date, '.csv', sep = '')
write.table(CovidData, file = fileName)
CovidData <- read.csv(fileName, sep='', stringsAsFactors = FALSE)
# End write/read .csv files

CovidData <- CovidData %>% add_column(Updated = NA)
CovidData <- CovidData[, c('FIPS', 'Admin2', 'Province.State', 'Country.Region', 'Last.Update', 'Updated', 'Latitude', 'Longitude', 'Confirmed', 'Deaths', 'Recovered', 'Active', 'Combined.Key', 'Incident.Rate', 'Case.Fatality_Ratio')]

# Convert Last.Updated to a date field
CovidData$Updated <-as.POSIXct(CovidData$Updated)

allData <- CovidData[,c(1:4, 6:15)]
names(allData)[5] <- 'Last.Update'

# Add to Azure database. 
connectionString <-  "Driver={ODBC Driver 13 for SQL Server};
                      Server=<<Your Server>>;
                      Database=<<Your Database>>;
                      Uid=<<Your Login>>;
                      Pwd=<<Your Password>>;
                      Encrypt=yes;
                      TrustServerCertificate=no;
                      Connection Timeout=30;"

myConn <- odbcDriverConnect(connectionString)

sqlSave(myConn, allData, "CovidData", append = TRUE, rownames = FALSE)
close(myConn)


