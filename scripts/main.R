### Sales Forecasting using Linear Regression ###
### Objective: Prediction of December 2016 ###

# clear environment
rm(list = ls())

# Load packages
library(tidyverse)
library(lubridate)
library(hydroGOF)
library(funModeling)

# read data
transactions <- read.csv("transactions.csv")

#### Exploratory Data Analysis ####
summary(transactions) # Monthly Amount shows min of 0 and max of 1 000 000 000, 10 industries and 10 locations, mean monthly amount of 395 397, data from Jan 2013 to Nov 2016
str(transactions) # 94248 sales records, 4464 unique customer IDs
df_status(transactions) # Check for missing values - No NAs

### variable transformation ###
# Split date into year and month to help with visualisation and model
transactions$date <- as.Date(transactions$date, format = "%d/%m/%y")
transactions <- transactions %>%
  mutate(year = lubridate::year(date),
         month = lubridate::month(date))

# Visual exploration of all industries and locations combination
# Sort Industry and Location to print graphs in order
transactions <- transactions %>% arrange(industry)
transactions <- transactions %>% arrange(location)

# Put 4 graphs on a page
par(mfrow=c(2, 2))

for (industry in unique(transactions$industry)) {
  # loop through all locations
  for (location in unique(transactions$location)) {
    # Pick a subset of the data based on the looped industry and location
    transactions.subset <- transactions[ which(transactions$industry == industry & transactions$location == location), ]
    
    # check if this industry has valid data to plot or out put message in console
    if (is.data.frame(transactions.subset) && nrow(transactions.subset)==0) {
      print(paste("Insufficient data for Industry:", industry, "Location:", location, sep=" "))
      # Skip this location, not enough data
      next 
    }
    # get the overall trend for that industry and location based on monthly amount
    transactions.subset.lm.linear <- lm(formula = monthly_amount ~ date, data = transactions.subset)
    
    # plot points and trend from Jan 2013 to Dec 2016 on the x-axis
    plot(transactions.subset$date, transactions.subset$monthly_amount, xlim=c(as.Date("2013-01-01"), as.Date("2016-12-01")), xlab="Dates", ylab="Montly Amount", main=paste("Plot for - Industry:", industry, "Location:", location, sep=" "), las=1)
    abline(transactions.subset.lm.linear, lwd=2, col="green")
  }
}

# identify potential outliers - check 5 std from mean per industry per location per year per month to consider seasonality and volume of each industry / location. 

outliers <- transactions[0,]

for (industry in unique(transactions$industry)) {
  for (location in unique(transactions$location)) {
    for (year in unique(transactions$year)) {
      for (month in unique(transactions$month)) {
        ts <- transactions[ which(transactions$industry == industry & transactions$location == location & transactions$year == year & transactions$month == month), ]
        sds <- sd(ts$monthly_amount)
        mean <- mean(ts$monthly_amount)
        tmp <- subset(ts, (monthly_amount < mean - (sds*5)) | (monthly_amount > mean + (sds*5)))
        outliers <- rbind(outliers, tmp)
            }
   }
  }
}

# Run below line to remove outliers from transactions - keeping them for now
# transactions <- transactions %>% anti_join(outliers)

#### end of exploration ####

# clean environment
rm(tmp, ts, transactions.subset, transactions.subset.lm.linear, sds, month, year, industry, location, mean)

# Create an aggregated data set using date, industry, location, mean of monthly amount
t_mean <- transactions %>%
  group_by(date, industry, location, year, month) %>%
  summarize(
    mean_monthly_amount = mean(monthly_amount)
  )

# Exploring industry 1 location 1 using subset
t_11 <- subset(t_mean, industry == 1 & location == 1)

# Remove industry and location variables
t_11 <- t_11[,-c(2:3)]

# plot industry 1 location 1
ggplot(t_11, aes(date, mean_monthly_amount)) + geom_line() + geom_point() + geom_smooth(method = "lm", se = F, col = "red")

# Convert month and year to factors to create dummy variable
t_11$month <- as.factor(t_11$month)
t_11$year <-  as.factor(t_11$year)

#### Prepare data for modelling on industry 1 location 1 only ####
# Split between train and test 
# 90 train 10 test to capture data in 2016, from floor to keep the chronological order

split <- round(nrow(t_11) * 0.90)
trainset <- t_11[1:split, ]
testset <- t_11[(split + 1):nrow(t_11), ]

# Single linear regression on train set
t11_model = lm(formula =  mean_monthly_amount ~ date, data = trainset)

# Analyse model output
summary(t11_model)$adj.r.squared  # adjusted r-square 0.44

# Multiple linear regression with month + year as factors - Seasonality
t11_model2 <- lm(formula = mean_monthly_amount ~ month + year, data = trainset) 

# Analyse model output 
summary(t11_model2)$adj.r.squared # adjusted r-square 0.8024

# Predictions on test set using multiple linear regression
prediction <- predict.lm(t11_model2, testset, type="response", interval="confidence", level=0.95)


# Compare actuals vs predictions
# Evaluate model using MAE 
testset$fit <- as.data.frame(prediction)$fit
testset$error <- testset$mean_monthly_amount-testset$fit
mae <- mean(abs(testset$error))
mae/mean(testset$mean_monthly_amount)
rmse(testset$mean_monthly_amount, testset$fit)

# Compare actuals vs predicted on testset
par(mfrow=c(2, 2))
plot(testset$date, testset$mean_monthly_amount,
     main = "Actuals vs Predicted", 
     xlab = "Date", 
     ylab = "Mean Monthly Amount")
lines(testset$date, testset$mean_monthly_amount, col = "blue")
lines(testset$date, testset$fit, col = "orange")
legend("topleft", inset = .05,c("actuals", "predicted"), fill = c("blue", "orange"), horiz = TRUE)

# Forecast December 2016 using model trained on all actual data
t11_model3 <- lm(formula = mean_monthly_amount ~ month + year, data = t_11)
summary(t11_model3)$adj.r.squared # 0.7893

dec_2016 <- data.frame(date = as.Date("2016-12-01"), mean_monthly_amount = 0, year = as.factor(2016), month = as.factor(12))
fcast_dec_2016 <- predict(t11_model3, newdata = dec_2016)

# plot forecast on graph
plot(t_11$date, t_11$mean_monthly_amount, xlim=c(as.Date("2013-01-01"), as.Date("2016-12-01")), xlab="Dates", ylab="Montly Amount", main=paste("Forecast December 2016, Industry 1 Location 1 "), las=1)
lines(t_11$date, t_11$mean_monthly_amount, col = "grey", lwd = 2)
points(as.Date("2016-12-01"), fcast_dec_2016, col = "red")
segments(as.Date("2016-11-01"), tail(t_11,1)$mean_monthly_amount, as.Date("2016-12-01"), fcast_dec_2016, col = "red")
         

#### Apply model to all industries and locations ####
# Create evaluation and predictions empty dataframe
evaluation_table <- data.frame(
                            industry = integer(),
                            location = integer(),
                            train_num_rows = integer(),
                            mae = numeric(),
                            adj_r_squared = numeric(),
                            rmse = numeric(),
                            forecast = numeric()
                          )

predictions_table <- data.frame(
                            Industry = integer(),
                            Location = integer(),
                            Month = numeric(),
                            Year = numeric(),
                            Actuals = numeric(),
                            Predictions = numeric(),
                            Difference = numeric(),
                            December_2016 = numeric()
                          )

# For loop to apply model to all industry + location combinations with min 36 months of sales records
for (ind in unique(t_mean$industry)) {
  for (loca in unique(t_mean$location)) {
    ts <- subset(t_mean, industry == ind & location == loca)
    ts$month <- as.factor(ts$month)
    ts$year <- as.factor(ts$year)
    if (is.data.frame(ts) && nrow(ts) <= 36) {
      print(paste("Insufficient data for Industry:", ind, "Location:", loca, sep=" "))
         next
      
    }
    ts.split <- round(nrow(ts) * 0.90)
    ts.trainset <- ts[1:ts.split, ]
    ts.testset <- ts[(ts.split + 1):nrow(ts), ]
    ts.lm.linear <- lm(formula = mean_monthly_amount ~ month + year, data = ts.trainset) 
    ts.testset$fit <- as.data.frame(predict.lm(ts.lm.linear, ts.testset, type="response", interval="confidence", level=0.95))$fit
    ts.testset$error <- ts.testset$mean_monthly_amount-ts.testset$fit
    ts.dec_2016 <- data.frame(date = as.Date("2016-12-01"), mean_monthly_amount = 0, year = as.factor(2016), month = as.factor(12))
    fcast.ts.dec_2016 <- predict(lm(formula = mean_monthly_amount ~ month + year, data = ts), newdata = ts.dec_2016)
                                
    ts.testset$industry = ind
    ts.testset$location = loca
    ts.testset$december_2016 = fcast.ts.dec_2016
    
    # Fill evaluation table with selected measures
    evaluation_table <- rbind(evaluation_table, list(
                                industry = ind,
                                location = loca,
                                train_num_rows = nrow(ts.trainset),
                                mae = (mean(abs(ts.testset$error))/mean(ts.testset$mean_monthly_amount))*100,
                                adj_r_squared = summary(ts.lm.linear)$adj.r.squared,
                                rmse = rmse(ts.testset$mean_monthly_amount, ts.testset$fit),
                                forecast = fcast.ts.dec_2016)
                               )

    # Fill predictions table with forecast
    predictions_table <- rbind(predictions_table, list(
                            Industry = ts.testset$industry,
                            Location = ts.testset$location,
                            Month = month.abb[ts.testset$month],
                            Year = ts.testset$year,
                            Actuals = ts.testset$mean_monthly_amount,
                            Predictions = ts.testset$fit,
                            Difference = ts.testset$error,
                            December_2016 = ts.testset$december_2016)
                              )
  }
}

# Export evaluations and predictions as csv
write.csv(evaluation_table, "./evaluations.csv", row.names = FALSE)
write.csv(predictions_table,"./predictions.csv", row.names = FALSE)
