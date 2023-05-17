# checking the differences in the exposed incidence group between 
# pre-matched exposed groups and post-matched exposed group
library(tidyverse)
library(data.table)
options(datatable.fread.datatable=FALSE)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd('../')

# Read in exposed population
################################################################################
# Load data for exposed and control population
################################################################################
# Read in exposed population
exposed <- fread('output/cis_exposed.csv') %>% 
  mutate(exposed = 1)

# Read in control population
control <- fread('output/cis_control.csv') %>% 
  mutate(exposed = 0)

# Temporary rbind() while type of outcome is determined
population <- rbind(exposed, control)

################################################################################
# Create different outcome groups per exposed and control population
# 2 types of outcome
################################################################################


### (1) Incidence group (new onset) ###
# No history of mental illness

incidence <- population %>% 
  mutate(mh_history = ifelse(cmd_history == 1 | cmd_history_hospital == 1 |
                               smi_history == 1 | smi_history_hospital == 1 |
                               other_mood_disorder_diagnosis_history == 1 | other_mood_disorder_hospital_history == 1 |
                               self_harm_history == 1 | self_harm_history_hospital == 1, 1, 0)) %>% 
  filter(mh_history == 0) %>% 
  select(-mh_history)

incidence_pre_exposed <- incidence %>% 
  filter(exposed == 1) %>% select(patient_id, 
                             visit_date, 
                             date_positive, 
                             end_date, 
                             exposed,
                             result_mk,
                             visit_num,
                             last_linkage_dt,
                             is_opted_out_of_nhs_data_share)

incidence_control <- incidence %>% 
  filter(exposed == 0)

rm(exposed, control, population, incidence)
gc()

# now load post-matching data 

incidencee_post_exposed <- fread('output/incidence_group.csv') %>% 
  select(patient_id, 
         visit_date, 
         date_positive, 
         end_date, 
         exposed,
         group_id,
         result_mk,
         visit_num,
         last_linkage_dt,
         is_opted_out_of_nhs_data_share) %>%
  filter(exposed== 1)



# now we want to  anti join to find unmatched records
# number of rows 
print('Number of PRE matched population - incidence')
nrow(incidence_pre_exposed)

print('Number of PRE matched population DISTINCT - incidence')
n_distinct(incidence_pre_exposed$patient_id)


print('Number of POST matched population - incidence')
nrow(incidencee_post_exposed)

print('Number of POST matched population DISTINCT - incidence')
n_distinct(incidencee_post_exposed$patient_id)

print('NEW - Number of POST matched population - incidence BY YEAR')
incidencee_post_exposed %>% group_by(year=year(date_positive)) %>% count() %>% print(n=100)


unmatched_records <- anti_join(incidence_pre_exposed, incidencee_post_exposed, by="patient_id") %>%
  arrange(date_positive)

# number of rows 
print('Number of unmatched exposed population - incidence')
nrow(unmatched_records)

# dates - index dates 
print('Summary of the index date (date_positive) variable in the UNMATCHED GROUP')
summary(unmatched_records$date_positive) 


#print all dates in order
print('index dates in the unmatched in order in the UNMATCHED GROUP') 
dates_exposed<- data.frame(unmatched_records$date_positive)


print('Count of index dates by year in the UNMATCHED GROUP') 
unmatched_records %>% group_by(year=year(date_positive)) %>% count() %>% print(n=100)

print('Count of index dates by month and year in the UNMATCHED GROUP') 
unmatched_records %>% group_by(year=year(date_positive), month=month(date_positive)) %>% count() %>% print(n=100)




print('Count of index dates by year in the EXPOSED PRE MATCH - INC') 
incidence_pre_exposed %>% group_by(year=year(date_positive), month=month(date_positive)) %>% count()  %>% print(n=100)

print('Count of index dates by year in the EXPOSED POST MATCH - INC') 
incidencee_post_exposed %>% group_by(year=year(date_positive), month=month(date_positive)) %>% count() %>% print(n=100)

################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
################################################################################

# check the remaining control population to see if there are no more possible matches
#incidence_control

incidencee_post_control <- fread('output/incidence_group.csv') %>% 
  select(patient_id, 
         visit_date, 
         date_positive, 
         end_date, 
         exposed,
         group_id,
         result_mk,
         visit_num,
         last_linkage_dt,
         is_opted_out_of_nhs_data_share) %>%
  filter(exposed == 0)



# now we want to  anti join to find unmatched records
#incidence_pre_exposed
#incidencee_post_exposed

unmatched_records <- anti_join(incidence_control, incidencee_post_control, by="patient_id") %>%
  arrange(date_positive)

# number of rows 
print('Number of unmatched control population - incidence')
nrow(unmatched_records)

# dates - visit dates 
print('Summary of the index date (date_positive) variable-control in the UNMATCHED GROUP')
summary(unmatched_records$date_positive)


#print all dates in order
print('index dates in the unmatched in order-control') 
dates_control<- data.frame(unmatched_records)  %>% select(visit_date, date_positive) # THIS SHOULD BE VISIT DATE AS CONTROLS HAVE VISIT DATE NOT DATE POSITIVE


print('Count of index dates by year-control') 
unmatched_records %>% group_by(year=year(visit_date)) %>% count() %>% print(n=100)

print('Count of index dates by month and year-control') 
unmatched_records %>% group_by(year=year(visit_date), month=month(visit_date)) %>% count() %>% print(n=100)


write_csv(dates_control, 'output/dates_order_control.csv')
write_csv(dates_exposed, 'output/dates_order_exposed.csv')














