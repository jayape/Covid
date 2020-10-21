# script for all Covid data

library(lubridate)
library(dplyr)
library(data.table)
library(tibble)

start_date <- as.Date('2020-01-22')
results <- data.frame()
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


# Save data
write.table(data1, file = './CovidData/data1.csv')
write.table(data2, file = './CovidData/data2.csv')
write.table(data3, file = './CovidData/data3.csv')
write.table(data4, file = './CovidData/data4.csv')

# Read saved data
one <- read.csv('./CovidData/data1.csv', sep='')
two <- read.csv('./CovidData/data2.csv', sep='')
three <- read.csv('./CovidData/data3.csv', sep='')
four <- read.csv('./CovidData/data4.csv', sep='')


one <- one %>% add_column(FIPS = NA, Admin2 = NA, Latitude = NA, Longitude = NA, Active = NA, Combined.Key = NA,  Incident.Rate = NA, Case.Fatality_Ratio = NA)
one <- one[, c('FIPS', 'Admin2', 'Province.State', 'Country.Region', 'Last.Update', 'Latitude', 'Longitude', 'Confirmed', 'Deaths', 'Recovered', 'Active', 'Combined.Key', 'Incident.Rate', 'Case.Fatality_Ratio')]
two <- two %>% add_column(FIPS = NA, Admin2 = NA, Active = NA, Combined.Key = NA,  Incident.Rate = NA, Case.Fatality_Ratio = NA)
two <- two[, c('FIPS', 'Admin2', 'Province.State', 'Country.Region', 'Last.Update', 'Latitude', 'Longitude', 'Confirmed', 'Deaths', 'Recovered', 'Active', 'Combined.Key', 'Incident.Rate', 'Case.Fatality_Ratio')]
three <- three %>% add_column(Incident.Rate = NA, Case.Fatality_Ratio = NA)
three <- three[, c('FIPS', 'Admin2', 'Province.State', 'Country.Region', 'Last.Update', 'Latitude', 'Longitude', 'Confirmed', 'Deaths', 'Recovered', 'Active', 'Combined.Key', 'Incident.Rate', 'Case.Fatality_Ratio')]


CovidData <- rbind(one, two, three, four)

library(RODBC)

connectionString <-  "Driver={SQL Server};
                      Server=PERTELL01,1433;
                      Database=Covid;
                      Integrated Security=SSPI;"

myConn <- odbcDriverConnect(connectionString)

sqlSave(myConn, CovidData, "CovidData", append = TRUE, rownames = FALSE)
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
