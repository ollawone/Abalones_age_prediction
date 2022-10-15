##----------- set working directory

setwd("~/R_code/AgeofAbalone/Abalones_Age_Prediction")

##------------load data
data <- read.csv("abalone_data.csv", header=TRUE)

head(data)
str(data)

## split the data into training and testing sets
intrain<- createDataPartition(data$Rings,p=0.60,list=FALSE)
set.seed(127)
training<- data[intrain,]
testing<- data[-intrain,]

##------------------ EDA
library(GGally)
png(file = "Corr_matrix_densityplot.png")

# density and scatter plot of quantitative variables
ggpairs(data, columns =2:9, title = "Abalones Physical Attributes")

# Saving the file
dev.off()

library(ggplot2)
# Explore the categorical variable
# construct barchart
p1 <- ggplot(data, aes(x=Sex)) + ggtitle("Sex") + xlab("Sex") +
  geom_bar(aes(y = 100*(..count..)/sum(..count..)), width = 0.5) + ylab("Percentage") + coord_flip() + theme_minimal()

# Output to be present as PNG file
png(file = "Distribution_Abalones_Sex.png")

# Plot the chart
p1

# Saving the file
dev.off()

##-------- Prediction

## Fitting the Multiple Linear Regression Model:
MLModel <- lm(Rings ~ .,data=training)
print(summary(MLModel))
# Adjusted R-squared:  0.5482
# Make predictions
predictions <- MLModel %>% predict(testing)

# Model performance
modelPerfomance = data.frame(
  RMSE = RMSE(predictions, testing$Rings),
  R2 = R2(predictions, testing$Rings)
)
print(modelPerfomance)
#     RMSE        R2
# 1 2.281611 0.5161642

# How well does the model fit the data?
RBW <- colorRampPalette(c("darkred","white","darkblue"))
# Output to be present as PNG file
png(file = "residual_histogram.png")

# Plot the chart
ggplot(data=training) +
  geom_histogram(aes(MLModel$residuals),
                 bins = 2508,
                 color = "grey10",
                 fill= RBW(2508)) +
  theme(panel.background = element_rect(fill = "white"),
        axis.line.x=element_line(),
        axis.line.y=element_line()) +
  ggtitle("Histogram for LM Model Residuals")


# Saving the file
dev.off()

#Checking the variance table for examination of feature importance
anova(MLModel, test="Chisq")
# Results:  Whole.weight is not significant

# Test with polynomial regression
## Fitting the Multiple Linear Regression Model:
MLModelpl <- lm(Rings~ poly(Length, degree=2, raw=TRUE)+
                  poly(Diameter, degree=2, raw=TRUE)+
                  poly(Height, degree=2, raw=TRUE)+
                  poly(Whole.weight, degree = 2, raw=TRUE)+
                  poly(Shucked.weight, degree = 2, raw=TRUE)+
                  poly(Viscera.weight, degree = 2, raw=TRUE)+
                  poly(Shell.weight, degree = 2, raw=TRUE)
                , data=training)
print(summary(MLModelpl))
# Adjusted R-squared:  0.5673 

# Make predictions
predictions2 <- MLModelpl %>% predict(testing)

# Model performance
modelPerfomance2 = data.frame(
  RMSE = RMSE(predictions2, testing$Rings),
  R2 = R2(predictions2, testing$Rings)
)
print(modelPerfomance2)
#    RMSE        R2
# 1 2.187928 0.5552416

# How well does the model fit the data?
# Output to be present as PNG file
png(file = "polynomial_model_residual.png")

# Plot the chart
ggplot(data=training) +
  geom_histogram(aes(MLModelpl$residuals),
                 bins = 2508,
                 color = "grey10",
                 fill= RBW(2508)) +
  theme(panel.background = element_rect(fill = "white"),
        axis.line.x=element_line(),
        axis.line.y=element_line()) +
  ggtitle("Histogram for Polynomial Regression Model Residuals")
# Saving the file
dev.off()

#Checking the variance table for examination of feature importance
anova(MLModelpl, test="Chisq")


# Model with interaction
library(tidyverse)
ndata <- data %>%
  select(-Sex)
ndata<- ndata %>%
  mutate(
    Leng_by_Diam = Length*Diameter,
    Leng_by_Heig = Length*Height,
    Diam_by_Heig = Diameter*Height,
    )

## split the data into training and testing sets
intrain<- createDataPartition(ndata$Rings,p=0.60,list=FALSE)
set.seed(127)
ntraining<- ndata[intrain,]
ntesting<- ndata[-intrain,]


## Fitting the Multiple Linear Regression Model:
MLModelx <- lm(Rings ~ .,data=ntraining)
print(summary(MLModelx))
# Adjusted R-squared:  0.5489 
# Make predictions
predictions3 <- MLModelx %>% predict(ntesting)

# Model performance
modelPerfomance3 = data.frame(
  RMSE = RMSE(predictions3, ntesting$Rings),
  R2 = R2(predictions3, ntesting$Rings)
)
print(modelPerfomance3)
#       RMSE        R2
# 1 2.180328 0.5278718

# How well does the model fit the data?
png(file = "residual_with_interactions.png")

# Plot the chart
ggplot(data=ntraining) +
  geom_histogram(aes(MLModelx$residuals),
                 bins = 2508,
                 color = "grey10",
                 fill= RBW(2508)) +
  theme(panel.background = element_rect(fill = "white"),
        axis.line.x=element_line(),
        axis.line.y=element_line()) +
  ggtitle("Histogram for LM Model With Interaction Residuals")
# Saving the file
dev.off()

#Checking the variance table for examination of feature importance
anova(MLModelx, test="Chisq")
# Results:  Whole.weight, LengthbyHeight and DiameterbyHeigth not significant


# Lets try Random fores regression
library(randomForest)
RFModel <- randomForest(Rings ~ .,data=ntraining, ntree =1000, importance= TRUE)
# Print regression model
print(RFModel)

# randomForest(formula = Rings ~ ., data = ntraining, ntree = 1000,      importance = TRUE) 
#Type of random forest: regression
#Number of trees: 1000
#No. of variables tried at each split: 3
#Mean of squared residuals: 4.941648
#% Var explained: 53.43

# Make predictions
predictions4 <- RFModel %>% predict(ntesting)

# Model performance
modelPerfomance4 = data.frame(
  RMSE = RMSE(predictions4, ntesting$Rings),
  R2 = R2(predictions4, ntesting$Rings)
)
print(modelPerfomance4)
#    RMSE        R2
# 1 2.162787 0.5353087

# Output to be present as PNG file
png(file = "randomForestRegression.png")

# Plot the error vs the number of trees graph
plot(RFModel)

# Saving the file
dev.off()

# Get variable importance from the model fit
ImpData <- as.data.frame(importance(RFModel))
ImpData$Var.Names <- row.names(ImpData)

# Output to be present as PNG file
png(file = "RF_variable_imp_plot.png")

# Visualize variable importance data
ggplot(ImpData, aes(x=Var.Names, y=`%IncMSE`)) +
  geom_segment( aes(x=Var.Names, xend=Var.Names, y=0, yend=`%IncMSE`), color="skyblue") +
  geom_point(aes(size = IncNodePurity), color="blue", alpha=0.6) +
  theme_light() +
  coord_flip() +
  theme(
    legend.position="bottom",
    panel.grid.major.y = element_blank(),
    panel.border = element_blank(),
    axis.ticks.y = element_blank()
  )
# Saving the file
dev.off()
# Shucked.Weight is the most important followed by Shell.Weight for predicting Age as captured by Rings

# Output to be present as PNG file
png(file = "RFModel_VarimpTop5.png")

# Visualize variable importance Top 5
varImpPlot(RFModel, sort=T, n.var = 5, main = 'Top 5 Important Features')
  
# Saving the file
dev.off()         

# Polynomial Test with the interactions dataset
MLModelxpl<- lm(Rings~ poly(Length, degree=2, raw=TRUE)+
                     poly(Diameter, degree=2, raw=TRUE)+
                     poly(Height, degree=2, raw=TRUE)+
                     poly(Whole.weight, degree = 2, raw=TRUE)+
                     poly(Shucked.weight, degree = 2, raw=TRUE)+
                     poly(Viscera.weight, degree = 2, raw=TRUE)+
                     poly(Shell.weight, degree = 2, raw=TRUE)+
                     poly(Leng_by_Diam, degree = 2, raw=TRUE)+
                     poly(Leng_by_Heig, degree = 2, raw=TRUE)+
                     poly(Diam_by_Heig, degree = 2, raw=TRUE),
                   data = ntraining)

print(summary(MLModelxpl))
# Adjusted R-squared:  0.5737 

# Make predictions
predictions5 <- MLModelxpl %>% predict(ntesting)

# Model performance
modelPerfomance5 = data.frame(
  RMSE = RMSE(predictions5, ntesting$Rings),
  R2 = R2(predictions5, ntesting$Rings)
)
print(modelPerfomance5)
#      RMSE        R2
# 1 2.125845 0.5514829

# Output to be present as PNG file
png(file = "polynomial_residual_with_interactions.png")

# Plot the chart

# How well does the model fit the data?

ggplot(data=ntraining) +
  geom_histogram(aes(MLModelxpl$residuals),
                 bins = 2508,
                 color = "grey10",
                 fill= RBW(2508)) +
  theme(panel.background = element_rect(fill = "white"),
        axis.line.x=element_line(),
        axis.line.y=element_line()) +
  ggtitle("Histogram for Polynomial Regression Model With Interaction Residuals")

# Saving the file
dev.off()

#Checking the variance table for examination of feature importance
anova(MLModelxpl, test="Chisq")



# Comparing all the models
anova(MLModel, MLModelpl, MLModelx, MLModelxpl, test = "Chisq")

# Combining performances on test data
Performances <- rbind(modelPerfomance, modelPerfomance2, modelPerfomance3, modelPerfomance4,
                      modelPerfomance5)
rownames(Performances) = c("MLModel",
                           "MLModelpl",
                           "MLModelx",
                           "RFModel",
                           "MLModelxpl")
print(Performances)
#            RMSE        R2
#MLModel    2.272095 0.4991430
#MLModelpl  2.375174 0.4715894
#MLModelx   2.180328 0.5278718
#RFModel    2.162787 0.5353087
#MLModelxpl 2.125845 0.5514829

# Model using polynomials and interactions performed the best based on the R2 and RMSE values
# when test data were introduced