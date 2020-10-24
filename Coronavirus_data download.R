# This script gets all Covid-19 data from the John Hopkins University
# It can store it in a SQL databasae as well as locally. 

library(lubridate)
library(dplyr)
library(data.table)
library(tibble)
library(tidyr)
library(RODBC)

start_date <- as.Date('2020-01-22')
data1 <- data.frame()
data2 <- data.frame()
data3 <- data.frame()
data4 <- data.frame()

dataNames1 <- c('Province.State', 'Country.Region', 'Last.Update', 'Confirmed', 'Deaths', 'Recovered' )
dataNames2 <- c('Province.State', 'Country.Region', 'Last.Update', 'Confirmed', 'Deaths', 'Recovered', 'Latitude', 'Longitude')
dataNames3 <- c('FIPS', 'Admin2', 'Province.State', 'Country.Region', 'Last.Update', 'Latitude', 'Longitude', 'Confirmed', 'Deaths', 'Recovered', 'Active', 'Combined.Key')
dataNames4 <- c('FIPS', 'Admin2', 'Province.State', 'Country.Region', 'Last.Update', 'Latitude', 'Longitude', 'Confirmed', 'Deaths', 'Recovered', 'Active', 'Combined.Key', 'Incident.Rate', 'Case.Fatality_Ratio')

while (start_date <= Sys.Date() - days(1)) {
  temp <- format(start_date, '%m-%d-%Y')
  url <- capture.output(cat
                        ('https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/', temp, '.csv',sep=""))
  data <- read.csv(url, sep = ",")

  if (ncol(data) == 6) {
    names(data) <- dataNames1
    data1 <- rbind(data1, data)
  } else if (ncol(data) == 8) {
    names(data) <- dataNames2
    data2 <- rbind(data2, data)
  } else if (ncol(data) == 12) {
    names(data) <- dataNames3
    data3 <- rbind(data3, data)
  } else {
    names(data) <- dataNames4
    data4 <- rbind(data4, data)
  }
  start_date <- start_date + days(1)  
}

# The next 2 blocks are if I save the data to .csv files, otherwise not needed.
# For single day file I'll change read/write to include datye in the file name
# Save data
write.table(data1, file = './CovidData/data1.csv')
write.table(data2, file = './CovidData/data2.csv')
write.table(data3, file = './CovidData/data3.csv')
write.table(data4, file = './CovidData/data4.csv')

# Read saved data
#data1 <- read.csv('./CovidData/data1.csv', sep='', stringsAsFactors = FALSE)
#data2 <- read.csv('./CovidData/data2.csv', sep='', stringsAsFactors = FALSE)
#data3 <- read.csv('./CovidData/data3.csv', sep='', stringsAsFactors = FALSE)
#data4 <- read.csv('./CovidData/data4.csv', sep='', stringsAsFactors = FALSE)
# End write/read .csv files

# This block ensures that the number of columns is consistent and in the same order before combining
data1 <- data1 %>% add_column(FIPS = NA, Admin2 = NA, Latitude = NA, Longitude = NA, Active = NA, Combined.Key = NA,  Incident.Rate = NA, Case.Fatality_Ratio = NA, Updated = NA)
data1 <- data1[, c('FIPS', 'Admin2', 'Province.State', 'Country.Region', 'Last.Update', 'Updated', 'Latitude', 'Longitude', 'Confirmed', 'Deaths', 'Recovered', 'Active', 'Combined.Key', 'Incident.Rate', 'Case.Fatality_Ratio')]
data2 <- data2 %>% add_column(FIPS = NA, Admin2 = NA, Active = NA, Combined.Key = NA,  Incident.Rate = NA, Case.Fatality_Ratio = NA, Updated = NA)
data2 <- data2[, c('FIPS', 'Admin2', 'Province.State', 'Country.Region', 'Last.Update', 'Updated', 'Latitude', 'Longitude', 'Confirmed', 'Deaths', 'Recovered', 'Active', 'Combined.Key', 'Incident.Rate', 'Case.Fatality_Ratio')]
data3 <- data3 %>% add_column(Incident.Rate = NA, Case.Fatality_Ratio = NA, Updated = NA)
data3 <- data3[, c('FIPS', 'Admin2', 'Province.State', 'Country.Region', 'Last.Update', 'Updated', 'Latitude', 'Longitude', 'Confirmed', 'Deaths', 'Recovered', 'Active', 'Combined.Key', 'Incident.Rate', 'Case.Fatality_Ratio')]
data4 <- data4 %>% add_column(Updated = NA)
data4 <- data4[, c('FIPS', 'Admin2', 'Province.State', 'Country.Region', 'Last.Update', 'Updated', 'Latitude', 'Longitude', 'Confirmed', 'Deaths', 'Recovered', 'Active', 'Combined.Key', 'Incident.Rate', 'Case.Fatality_Ratio')]

CovidData <- rbind(data1, data2, data3, data4)

# Convert Last.Updated to a date field
# CovidData$Updated <- strptime(CovidData$Last.Update, "%Y-%m-%d")

CovidData$Updated <-as.POSIXct(CovidData$Updated)

tempNA <- filter(CovidData, is.na(Updated) == TRUE)
tempNotNA <- filter(CovidData, is.na(Updated) == FALSE)

tempNA$Updated <- as.Date(as.POSIXct(tempNA$Last.Update, format = "%m/%d/%y"))

allData <- rbind(tempNA, tempNotNA)

allData <- allData[,c(1:4, 6:15)]
names(allData)[5] <- 'Last.Update'

# Add to local database. Changing to Azure later
connectionString <-  "Driver={SQL Server};
                      Server=PERTELL01,1433;
                      Database=Covid;
                      Integrated Security=SSPI;"

myConn <- odbcDriverConnect(connectionString)

sqlSave(myConn, allData, "CovidData", append = TRUE, rownames = FALSE)
close(myConn)



# Extra stuff

KenoshaData <- filter(CovidData, Province.State == 'Wisconsin'& Last.Update %like% '2020-10-16')
sum(KenoshaData$Confirmed)


latestData <- filter(CovidData, Country.Region == 'US' & Last.Update %like% '2020-10-16')

allData <- latestData %>%
  group_by(Province.State) %>%
  summarize_at(vars(Confirmed), list(name = sum))

View(allData)


KenoshaData <- filter(data4, Province.State == 'Wisconsin' & Last.Update %like% '2020-10-16')

table(KenoshaData)

View(KenoshaData)
latest <- filter(results, Last.Update %like% '2020-03-16')
USData <- filter(results, Province.State %like% 'WI')

url <- 'https://https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv'
#url <- 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/03-13-2020.csv'


#data <- read.csv(url, sep = ",")

ncol(results)

results$Longitude <- NA

url


parse_date_time('1/22/2020 17:00', orders = c('ymd', 'dmy', 'mdy'))
