library(splines)
library(ggplot2)
library(survival)
library(survminer)
library(data.table)
library(tidyverse)



#rm(list=ls())

#setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
#setwd('../')
options(datatable.fread.datatable=FALSE)

dat <- fread('output/incidence_t.csv')

### creating exposure, modifier and outcome variables
### for simplicity, I'm creating a binary outcome rather than a time-to-event outcome
### in this example, I'm exploring whether the relationship between gender (exposure) and
### diabetes (outcome) varies by continuous age (modifier)

#dat$exposure <- ifelse(dat$exposed=="M", 1, 0) #don't need that as "exposed" is already binary
#dat$modifier <- dat$index_time_to_start_date
#dat$outcome <- ifelse(!is.na(dat$mh_outcome) & dat$mh_outcome== 1, 1, 0)

### fit the model
### I don't have covariates besides the exposure and modifier variables, but you'll have
### all the covariates in the fully adjusted model
### I'm using a logistic regression model rather than Cox given the binary outcome, but
### exactly the same idea applies

#mod <- glm(
#  outcome ~ exposure * ns(modifier,
#                          df=2,
#                          Boundary.knots=quantile(modifier, c(0.1,0.9))) ,
#  family = binomial,
#  data = dat)
# Chnage index_dates to numeric
start_date <- as.Date("2020/01/24") 
start_date_numeric <- as.numeric(start_date) #this is converted into days

dat$index_numeric <- as.numeric(dat$date_positive) 
dat$index_time_to_start_date <- dat$index_numeric - start_date_numeric  

mod_cox <- coxph(
  Surv(t, mh_outcome) ~ exposed*ns(index_time_to_start_date, 
                                   df = 2, 
                                   Boundary.knots = c(quantile(index_time_to_start_date, 0.1), 
                                                      quantile(index_time_to_start_date, 0.9))) + 
    ns(age, df = 2, Boundary.knots = c(quantile(age,0.1), quantile(age, 0.9))) +
    cluster(patient_id) + 
    alcohol + 
    obese_binary_flag + 
    cancer + 
    digestive_disorder + 
    hiv_aids + 
    kidney_disorder + 
    respiratory_disorder + 
    metabolic_disorder + 
    sex + 
    ethnicity + 
    region + 
    hhsize + 
    work_status_new + 
    CVD + 
    musculoskeletal + 
    neurological + 
    mental_behavioural_disorder + 
    imd +
    rural_urban + 
    self_isolating +
    vaccination_status,
  data = dat)

### extract coefficients from the fitted model
coeffs <- coef(mod_cox)
NROW(coeffs)

### drop the intercept (you won't need to do this as no intercept in a Cox model)
#coeffs <- coeffs[-1]
### pick out the coefficients for the exposure main effect and the two modifier terms
b1 <- coeffs[1]
b4 <- coeffs[46]
b5 <- coeffs[47]

### derive the spline-transformed values of the modifier(index_time_to_start_date) variable (same as used in the model)
spline_matrix <- as.data.frame(
  ns(dat$index_time_to_start_date,
     df=2,
     Boundary.knots=quantile(dat$index_time_to_start_date, c(0.1,0.9)))
)

### pick out each spline-transformed term
s1 <- spline_matrix[,1]
s2 <- spline_matrix[,2]

### calculate change in the linear predictor
lp_change <- b1 + b4*s1 + b5*s2

### convert the change in the linear predictor to an odds ratio (you'll have a hazard ratio
### rather than an odds ratio)
hr <- exp(lp_change)

### extract variance-covariance matrix of the model
mod_vcov <- as.data.frame(vcov(mod_cox))

### drop the intercept from the vcov (you won't need to do this as no intercept)
#mod_vcov <- mod_vcov[-1,-1]

### extract variance for each coefficient (i.e. diagonal elements of the vcov)
var_b1 <- mod_vcov[1,1]
var_b4 <- mod_vcov[4,4]
var_b5 <- mod_vcov[5,5]

### extract pairs of covariances between the coefficients (i.e. off-diagonal elements)
cov_b1_b4 <- mod_vcov[1,4]
cov_b1_b5 <- mod_vcov[1,5]
cov_b4_b5 <- mod_vcov[4,5]

### calculate the variance of the change in the linear predictor
lp_change_var <- var_b1 + (s1^2)*var_b4 + (s2^2)*var_b5 +
  2*s1*cov_b1_b4 + 2*s2*cov_b1_b5 + 2*s1*s2*cov_b4_b5

### calculate the standard error of the change in the linear predictor
lp_change_se <- sqrt(lp_change_var)

### calculate 95% CI around the OR
hr_lcl <- exp(lp_change - 1.96*lp_change_se)
hr_ucl <- exp(lp_change + 1.96*lp_change_se)

### bring results together
hr_df <- data.frame(
  index_time_to_start_date = dat$index_time_to_start_date,
  lp_change,
  lp_change_se,
  hr,
  hr_lcl,
  hr_ucl)

write_csv(hr_df, 'output/100_hazard_ratios_by_modifier_incidence.csv')

### plots the odds ratio by the modifier variable
p<- ggplot(data = hr_df, aes(x = index_time_to_start_date, y=hr)) +
  geom_line(linewidth = 0.8 , colour="red") +
  geom_ribbon(aes(ymin=hr_lcl, ymax=hr_ucl), fill="red", colour=NA, alpha=0.2) +
  geom_hline(yintercept=1, linetype=2)

ggsave("output/100_hazard_ratios_by_modifier_variable.jpg",p)


