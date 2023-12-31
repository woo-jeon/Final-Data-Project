#read data
library(readr)
life_expectancy_data_full = read_csv("Life Expectancy Data.csv")


#remove rows with empty vals
life_expectancy_data = na.omit(life_expectancy_data_full)
View(life_expectancy_data)

#convert Status (levels: Developing, Developed) to factor variable
life_expectancy_data$Status = as.factor(life_expectancy_data$Status)


#convert Country to factor variable
life_expectancy_data$Country = as.factor(life_expectancy_data$Country)
#levels(life_expectancy_data$Country)

#check structure of dataset to ensure correct factors
str(life_expectancy_data)

#--------Exploratory Analysis ---------------

#Pairs plot is very large, so we create a Correlogram to view correlations 
#pairs(life_expectancy_data)

#find pairwise correlations between all numeric variables in dataset
numeric_cols =  unlist(lapply(life_expectancy_data, is.numeric))
life_expectancy_data_numeric = life_expectancy_data[ , numeric_cols]
View(life_expectancy_data_numeric)

correlations = cor(life_expectancy_data_numeric)

#plot correlogram (positive correlations are blue, negative correlations are red)
install.packages("corrplot")
library(corrplot)

corrplot(correlations)

#-----------------------------------

#create initial additive model with all predictors

additive_model = lm(life_expectancy_data$`Life expectancy` ~ ., data = life_expectancy_data)
#summary(additive_model)

#------ Analyze Model -------------
# Function to calculate model metrics
calc_model_metrics = function(model) {
  # Calculate adjusted R squared
  model_adjr2 = summary(model)$adj.r.squared
  
  # Calculate RMSE
  model_rmse = sqrt(mean(resid(model) ^ 2))
  
  # Calculate LOOCV RMSE
  model_loocv_rmse = sqrt(mean((resid(model) / (1 - hatvalues(model))) ^ 2))
  
  # Calculate AIC
  model_AIC = extractAIC(model)[2] # get only the AIC value, not the degrees of freedom
  
  # Return a list containing the calculated metrics
  list(Adj_R_Squared = model_adjr2, RMSE = model_rmse, LOOCV_RMSE = model_loocv_rmse, AIC = model_AIC)
}


#Check adjusted R squared
additive_model_adjr2 = summary(additive_model)$adj.r.squared

#Calculate RMSE
additive_model_rmse = sqrt(mean(resid(additive_model) ^ 2))

#Calculate LOOCV RMSE
calc_loocv_rmse = function(model) {
  sqrt(mean((resid(model) / (1 - hatvalues(model))) ^ 2))
}

additive_model_loocv_rmse = calc_loocv_rmse(additive_model)

#Calculate AIC
additive_model_AIC = extractAIC(additive_model)
#it is very large (bad)!
additive_model_AIC

#------- Check model assumptions -------------

#Fitted vs Residuals Plot

plot(fitted(additive_model), resid(additive_model), col = "grey", pch = 20,
     xlab = "Fitted", ylab = "Residuals", main = "Data from Model 1")
abline(h = 0, col = "darkorange", lwd = 2)

#Q-Q Plot

qqnorm(resid(additive_model), main = "Normal Q-Q Plot, fit_1", col = "darkgrey")
qqline(resid(additive_model), col = "dodgerblue", lwd = 2)

#confirm issues via more formal tests

library(lmtest)
bptest(additive_model)
#result shows data violates constant variance assumption!

shapiro.test(resid(additive_model))
#result shows data violates normality assumption!

#---------- Next step -------------------------------

#We will attempt to fix these issues by removing highly correlated predictors
#under 5 death & infant deaths : cor = 0.997
#thinness 1-19 years & thinness 5-9 years : cor = 0.928
#We'll remove one from each of the above pairs of predictors and reassess model

#Removing infant deaths and thinness 1-19 years
corr_removed_data_1 = life_expectancy_data[ , !(names(life_expectancy_data) %in% c('infant deaths', 'thinness 1-19 years'))]
corr_removed_model_1 = lm(`Life expectancy` ~ ., data = corr_removed_data_1)
corr_removed_metrics_1 = calc_model_metrics(corr_removed_model_1)


#Removing infant deaths and thinness 5-9 years
corr_removed_data_2 = life_expectancy_data[ , !(names(life_expectancy_data) %in% c('infant deaths', 'thinness 5-9 years'))]
corr_removed_model_2 = lm(`Life expectancy` ~ ., data = corr_removed_data_2)
corr_removed_metrics_2 = calc_model_metrics(corr_removed_model_2)


#Removing under 5 deaths and thinness 1-19 years
corr_removed_data_3 = life_expectancy_data[ , !(names(life_expectancy_data) %in% c('under 5 death', 'thinness 1-19 years'))]
corr_removed_model_3 = lm(`Life expectancy` ~ ., data = corr_removed_data_3)
corr_removed_metrics_3 = calc_model_metrics(corr_removed_model_3)

#Removing under 5 deaths and thinness 5-9 years
corr_removed_data_4 = life_expectancy_data[ , !(names(life_expectancy_data) %in% c('under 5 death', 'thinness 5-9 years'))]
corr_removed_model_4 = lm(`Life expectancy` ~ ., data = corr_removed_data_4)
corr_removed_metrics_4 = calc_model_metrics(corr_removed_model_4)

# Create a data frame summarizing the model metrics
model_summary = data.frame(
  Variables_Removed = c("infant deaths + thinness 1-19", "infant deaths + thinness 5-9", "under 5 deaths + thinness 1-19", "under 5 deaths + thinness 5-9 years"),
  Adjusted_R_Squared = c(corr_removed_metrics_1$Adj_R_Squared, corr_removed_metrics_2$Adj_R_Squared, corr_removed_metrics_3$Adj_R_Squared, corr_removed_metrics_4$Adj_R_Squared),
  RMSE = c(corr_removed_metrics_1$RMSE, corr_removed_metrics_2$RMSE, corr_removed_metrics_3$RMSE, corr_removed_metrics_4$RMSE),
  LOOCV_RMSE = c(corr_removed_metrics_1$LOOCV_RMSE, corr_removed_metrics_2$LOOCV_RMSE, corr_removed_metrics_3$LOOCV_RMSE, corr_removed_metrics_4$LOOCV_RMSE),
  AIC = c(corr_removed_metrics_1$AIC, corr_removed_metrics_2$AIC, corr_removed_metrics_3$AIC, corr_removed_metrics_4$AIC)
)

library(knitr)
knitr::kable(model_summary, caption = "Model Summary", digits = 4)
# removing under 5 deaths + thinness 1-19 is the best option



#---------- Next step -------------------------------
#We will attempt to further improve the model by log transforming certain predictor variables (Population & GDP??)

log_transform_1 = lm(`Life expectancy` ~ . + log(Population) + log(GDP), data = life_expectancy_data)
log_transformed_metrics_1 = calc_model_metrics(log_transform_1)

log_transform_2 = lm(`Life expectancy` ~ . + log(GDP), data = life_expectancy_data)
log_transformed_metrics_2 = calc_model_metrics(log_transform_2)

log_transform_3 = lm(`Life expectancy` ~ . + log(Population), data = life_expectancy_data)
log_transformed_metrics_3 = calc_model_metrics(log_transform_3)


log_model_summary = data.frame(
  Variables_Log_Transformed = c("Population + GDP", "GDP", "Population"),
  Adjusted_R_Squared = c(log_transformed_metrics_1$Adj_R_Squared, log_transformed_metrics_2$Adj_R_Squared, log_transformed_metrics_3$Adj_R_Squared),
  RMSE = c(log_transformed_metrics_1$RMSE, log_transformed_metrics_2$RMSE, log_transformed_metrics_3$RMSE),
  LOOCV_RMSE = c(log_transformed_metrics_1$LOOCV_RMSE, log_transformed_metrics_2$LOOCV_RMSE, log_transformed_metrics_3$LOOCV_RMSE),
  AIC = c(log_transformed_metrics_1$AIC, log_transformed_metrics_2$AIC, log_transformed_metrics_3$AIC)
)

knitr::kable(log_model_summary, caption = "Log Transformed Model Summary", digits = 4)

#log(GDP) is the best result, although it is only a very minimal improvement

#---------- Next step --------------------------------

#We will use AIC and BIC backwards search to attempt to further improve the model