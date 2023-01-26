library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

source('analysis/cov_dist_cat.R')
source('analysis/cov_dist_cont.R')

incidence <- fread('output/adjusted_incidence_group.csv')
prevalence <- fread('output/adjusted_prevalence_group.csv')

# Need to read in matched person level data
# Only need to consider participants characteristics at the index date
# 100% of cases and 0% controls should have result_mk == 1

# Create bmi category variable
create_bmi_categories <- function(df){
  df <- df %>% 
    mutate(bmi_category = case_when(
      bmi == 0 ~ 'unknown or outlier', 
      bmi < 18.5 ~ 'underweight',
      bmi >= 18.5 & bmi < 25 ~ 'ideal',
      bmi >= 25 & bmi < 30 ~ 'overweight',
      bmi >= 30 ~ 'obese'))
  
  return(df)
}

incidence <- create_bmi_categories(incidence)
prevalence <- create_bmi_categories(prevalence)

cat_vars <- c("alcohol", 
              "obese_binary_flag", 
              "cancer", 
              "digestive_disorder",
              "hiv_aids", 
              "metabolic_disorder", 
              "kidney_disorder",
              "respiratory_disorder",
              "mental_behavioural_disorder",
              "CVD", 
              "musculoskeletal", 
              "neurological", 
              "bmi_category",
              "sex",
              "mh_history",
              "mh_outcome")

continuous_vars <- c('age')

if (nrow(incidence) > 0){
  incidence_cat_stats <- cov.dist.cat(vars = cat_vars, dataset = incidence, exposure = 'exposed')
  incidence_con_stats <- cov.dist.cont(vars = continuous_vars, dataset = incidence, exposure = 'exposed')
  write_csv(incidence_cat_stats, 'output/1_descriptives_incidence_cat.csv')
  write_csv(incidence_con_stats, 'output/2_descriptives_incidence_con.csv')
} else{
  write_csv(data.frame(1), 'output/1_descriptives_incidence_cat.csv')
  write_csv(data.frame(1), 'output/2_descriptives_incidence_con.csv')
}

if (nrow(prevalence) > 0){
  prevalence_cat_stats <- cov.dist.cat(vars = cat_vars, dataset = prevalence, exposure = 'exposed')
  prevalence_con_stats <- cov.dist.cont(vars = continuous_vars, dataset = prevalence, exposure = 'exposed')
  write_csv(prevalence_cat_stats, 'output/3_descriptives_prevalence_cat.csv')
  write_csv(prevalence_con_stats, 'output/4_descriptives_prevalence_con.csv')
} else{
  write_csv(data.frame(1), 'output/3_descriptives_prevalence_cat.csv')
  write_csv(data.frame(1), 'output/4_descriptives_prevalence_con.csv')
}
# bmi seperately as i had to filter out 0s

function_get_bmi_descriptives <- function(dataset){
 
  ds3 <- dataset %>% filter(exposed == 0)
  ds4 <- dataset %>% filter(exposed == 1)
  
  
  all <- dataset %>%  summarise(
    mean_bmi = mean(bmi[bmi > 0]),
    sd_bmi = sd(bmi[bmi>0]),
    variance_bmi = var(bmi[bmi>0]))
  
  all$type <- "all" 
  
  not_ex <- ds3 %>%  summarise(
    mean_bmi = mean(bmi[bmi > 0]),
    sd_bmi = sd(bmi[bmi>0]),
    variance_bmi = var(bmi[bmi>0]))
  
  not_ex$type <- "not exposed" 
  
  exposed <- ds4 %>%  summarise(
    mean_bmi = mean(bmi[bmi > 0]),
    sd_bmi = sd(bmi[bmi>0]),
    variance_bmi = var(bmi[bmi>0]))
  
  exposed$type <- "exposed" 
  
  bmi_desc <- rbind(all,not_ex,exposed) 

  return(bmi_desc)
}

incidence_bmi <- function_get_bmi_descriptives(incidence)
prevalence_bmi <- function_get_bmi_descriptives(prevalence)

#write_csv(incidence_bmi, 'output/incidence_cont_bmi_stats.csv')
#write_csv(prevalence_bmi, 'output/prevalence_cont_bmi_stats.csv')

#abs_std_diff <- abs((mu1 - mu0) / sqrt((var1 + var0) / 2))

# Poisson.test - to see rate with CIs