/* Simple data handling example with SAS using open data 
from sotkanet.fi */

/* The datasets contain information on alcohol beverage sales and 
antidepressant reimbursements at hospital district level in Finland 
from 2015 to 2023. */


/* import alcohol data */
/* Sale of alcoholic beverages per capita, as litres of pure alcohol */
filename csv url "https://sotkanet.fi/sotkanet/fi/csv?indicator=s05KBAA=&region=s7YssM7SM4y3BAA=&year=sy5zsbbQ0zUEAA==&gender=t&abs=f&color=f&buildVersion=3.1.1&buildTimestamp=202407081245&order=G" encoding='utf-8';
proc import datafile=csv 
	out=work.alcohol_data 
	dbms=csv 
	replace;
	getnames=no;
	delimiter=';'; 
run;

/* import depression data */
/* Reimbursements for depression medicines, 
recipients aged 18-64 per 1000 persons of same age */
filename csv url "https://sotkanet.fi/sotkanet/fi/csv?indicator=s3YMBgA=&region=s7YssM7SM4y3BAA=&year=sy5zsbbQ0zUEAA==&gender=t&abs=f&color=f&buildVersion=3.1.1&buildTimestamp=202407081245&order=G" encoding='utf-8';

proc import datafile=csv
	out=work.depression_data
   	dbms=csv 
    replace;
 	getnames=no;
 	delimiter=';'; 
run;

/* get a glance at the datas, 
let's start with the alcohol data */
proc print data=alcohol_data(obs=5);
run;

/* rename variables */
data alcohol_data;
    set alcohol_data;
	rename 
		VAR3 = hospital_district
		VAR6 = year
		VAR7 = alcohol_per_capita;
run;
	
/* keep only relevant variables */
data alcohol_data;
	set alcohol_data;
	keep
		hospital_district 
		year 
		alcohol_per_capita;
run;

/* check that we have all hospital districts*/
proc freq data=alcohol_data;
	tables hospital_district / out=unique_values;
run;

/* ...and years */
proc freq data=alcohol_data;
	tables year / out=unique_values;
run;

/* check the alcohol sale variable for missing values*/
proc means data=alcohol_data n nmiss;
	var alcohol_per_capita;
run; /* no missing values */

/* the same procedure for depression data */
proc print data=depression_data(obs=5);
run;

/* rename variables */
data depression_data;
    set depression_data;
	rename 
		VAR3 = hospital_district
		VAR6 = year
		VAR7 = depression_reimburs;
run;
	
/* keep only relevant variables */
data depression_data;
	set depression_data;
	keep 
		hospital_district 
		year 
		depression_reimburs;
run;

/* check that we have all hospital districts*/
proc freq data=depression_data;
	tables hospital_district / out=unique_values;
run;

/* ...and years */
proc freq data=depression_data;
	tables year / out=unique_values;
run;

/* check the depression reimbursement variable for missing values*/
proc means data=depression_data n nmiss;
	var depression_reimburs;
run; /* no missing values */

/* let's merge the two data sets */
data merged_data;
	merge depression_data alcohol_data;
	by hospital_district year;
run;

proc print data=merged_data(obs=10);
run;

/* check the correlation between the variables of interest*/
proc corr data=merged_data;
	var alcohol_per_capita depression_reimburs;
run; /* no significant correlation */

/* let's calculate the mean value of alcohol sales 
in 2015-2023 by hospital districts */
proc sql;
	create table mean_output as
	select 
    	hospital_district,
    	avg(alcohol_per_capita) as mean_alcohol
	from merged_data
	group by hospital_district;
quit;

/* tabulate the results */
proc print data=mean_output;
	title "Averages sale of alcohol per capita, as litres of pure alcohol";
run;

/* show results in a bar chart */
proc sgplot data=mean_output;
	vbar hospital_district / response=mean_alcohol;
	xaxis label="Hospital district";
	yaxis label="Alcohol";
run;
title; 

/* let's say we want to generate a new dataset that includes
only those hospital districts by year whose values of antidepressant 
reimbursements were above the national average of the same year */

/* first calculate the yearly averages */
proc sql;
	create table yearly_averages as
	select 
    	avg(depression_reimburs) as average_value,
		year
	from merged_data
	group by year;
quit;

proc print data=yearly_averages;
run;

/* create the final data */
proc sql;
	create table combined as
	select *
	from merged_data t
	join yearly_averages a ON t.year = a.year
	where t.depression_reimburs >= a.average_value;
quit;

proc print data=combined;
run;

/* let's tabulate the hospital districts by the number of years 
in which antidepressant reimbursements exceeded the national average */
proc sql;
	select hospital_district, count(*) as district_count
	from combined
	group by hospital_district
	order by district_count desc;
quit;
