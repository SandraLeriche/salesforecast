# Summary

**Task**: Given a dataset of sales transactions of the past 4 years for 10 different industries and 10 different locations of company X, predict the sales for the upcoming month (December 2016). 

This report is written with the purpose of presenting the results of the forecast and method used to a sales manager - without code excerpts - following the [CRISP-DM methodology](https://www.sv-europe.com/crisp-dm-methodology/). 

To have a look at the commented code check the R [scripts](https://github.com/SandraLeriche/salesforecast/tree/master/scripts) folder. 

Here are the key steps followed in this project:

 1. Explore dataset
 2. Visually represent dataset
 3. Identify potential outliers
 4. Transform data set to suit model purpose
 5. Train model on 1 industry and 1 location
 6. Evaluate model 
 7. Apply preferred model to the remaining industries and locations
 8. Output sales predictions as CSV file

Data: [transactions](https://github.com/SandraLeriche/salesforecast/blob/master/data/transactions.csv), [evalutations](https://github.com/SandraLeriche/salesforecast/blob/master/data/evaluations.csv), [predictions](https://github.com/SandraLeriche/salesforecast/blob/master/data/predictions.csv) 

## Report

### BUSINESS OBJECTIVES

The objective is to provide an accurate prediction of the sales for the upcoming month December 2016.

To determine the accuracy of the prediction, the performance of the model used will be evaluated using known data which are the sales [transactions](https://github.com/SandraLeriche/salesforecast/blob/master/data/transactions.csv) from January 2013 to November 2016.

Insights on the performance of the different industries and locations will also be drawn from an exploration of the existing data.

**Assumptions, limitations and risks**

As the transaction file includes multiple industries and locations it can be assumed that the sales volume and the trends may vary based on these two variables.  
  
It contains 47 months of data for most industries but some have limited sales history with 36 months of information and less. 

There is no information on reasons behind potential outliers (marketing/sales initiatives, close of business etc.) and no ability to contact the subject matter expert while completing the project.
  
The prediction will not include any inflation or recession period as the operating country of the business is unknown.  

It will not include any fluctuation from opportunities currently in the sales' team's pipeline or marketing decisions as well as facts out of control that may disrupt the industry the business is in (ie. worldwide pandemic).  
  
## Data Exploration

The transactions dataset contains 94248 observations and 5 variables (Data, customer id, industry, location, monthly amount) from the 1st of January 2013 to the 30th of November 2016.

The monthly amount across all locations and industries is between 0 (March 2015) and 100 000 000  (October 2016). Both records in industry 6 which is the industry with the least transactions.  
  
These two values require further investigation; it could be erroneous or valid if there was no sale in March 2015 and one month recorded exactly 100 000 000 in sales.

405 observations with 5 standard deviations from the mean are identified in industries 1, 2, and 3 (4.3% of the dataset) which could be potential outliers.

Without context and any precision on how likely these sales records are to occur again in the future and whether they are indeed "outliers", these observations will remain in the dataset to perform the prediction.

There is no explanation for the missing data in industry 6, location 2 to 10. It could be an error during the extraction of the data, it could be that this industry is only operating in 1 location.

**We can identify two insights based on the visualisations of each industry and location combination**  - [Graphs](https://github.com/SandraLeriche/salesforecast/tree/master/images)

There is imbalance in the data (some only have transactions up to 2015 some only have 2016 data).  

To account for the missing data, industries and locations will need to have at least 3 years (36 months) of past transactions to be used in the model and make a prediction for December 2016.

Industry 1 location 1 is showing seasonality, with a dip of sales in December. 
Industries (1 and 2) have the highest volume of transactions.

## Data preparation

To assist in building the model and account for seasonality the date column is split into two variables: month and year.

Each industry and location is grouped by monthly_amount and aggregating the monthly amount to a mean_monthly_amount.  
  
The customer_ID column is dropped since the information is not needed for prediction.

## Modelling

This forecasting method is using previous data to predict future values.  

Previous years are important for seasonality and data used to train the model needs to include some of the 2016 months to account for a yearly upward or downward trend.

For this reason, the data is split in a 90/10 train/test split in chronological order (as opposed to randomly selecting 90% of the dataset).  

The variables "month" and "year" are used as factors (categories) for each combination of month + year to be considered a different period and include seasonality for this multiple linear regression.

For industries and locations that have 47 months of data this includes the first 42 months of data to train the model and 5 to test.

The model will only run on industries and locations with a minimum of 36 months of data.

The linear regression model has an adjusted r-square of 0.80 on the trainset of industry 1, location 1 with an MAE (Mean Absolute Error) of 5.17 % which is a statistically significant value to confirm the model is a good fit.


## Evaluation

The model has made predictions for 78 industry and location combinations available in the [predictions](https://github.com/SandraLeriche/salesforecast/blob/master/data/predictions.csv) table.

Out of these 78 combinations, 45 are forecasting a monthly amount for December 2016 with an MAE below 10%.  

33 combinations of industries and locations are forecasting a monthly amount for December 2016 with an error margin of 10.3% and above.  

**How confident are we in these predictions?**  
Mean Absolute Error is the selected metric to evaluate the model on the test-set, it is the absolute value of the difference between the forecasted value and the actual value.

MAE (and Root Mean Squared Error (RMSE)) for each industry location combination are available in the [evaluations] (https://github.com/SandraLeriche/salesforecast/blob/master/data/evaluations.csv)' table.

The MAE was selected as a measure to evalute as the model is applied to a reasonable sized dataset (medium) and it is widely used for forecast models. It observes the magnitude of the errors.  

**The model is performing poorly on industry 8 location 5 and industry 9 location 7,** even though they have 47 months of data have very few transactions recorded in 2013.

**Unable to make an accurate prediction for:**  
Industry 3, location 6, 8, 10.  
Industry 6 locations from 2 to 10  
Industry 9 locations 5, 6, 8, 10  
industry 10 locations, 1, 3, 4, 6, 9, 10 as they have 36 or less months of data available.  
These have been excluded from the final predictions report. 

In the future, more specific eligibility criteria could be defined to decide which industry or location is relevant to be included for forecasting. 

**Examples of future revision:**  
- Industry - location combinations that do not have any sales recorded for the year in which the model is predicting (2016) would not be included as the business might be closed and there is not going to be any sales.  

- Include any public holiday period - requires to know the country and whether or not the business was closed - it could be identified that sales following a day the business was closed increased and account for it in the predictions of these days.
- 
- To add confidence in the results, only predict for industries and locations that have complete data (47 months in this instance).


# Business Impact
Forecasting and analysing previous sales records is highly beneficial to any company as it is an indicator of the expected cash influx.

With this information, it is possible to plan sales ahead and optimise the supply of products based on the forecasted demand and overall manage the business more effectively.

Ensure the workforce is optimised by hiring and training for temporary staff during busier periods based on industries and locations.

It is also useful from a financial perspective to plan for overall growth and adjust expenses in quieter months.