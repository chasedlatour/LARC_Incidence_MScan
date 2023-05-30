
/****************************************************************************
	Name: Clara Busse, Mekhala Dissanayake, Chase Latour
	Class: EPID 766 / DPOP 766
	Submit Date: 20210223
	Purpose: Calculate the numbers needed for the primary analysis results.
	This should be run after all the code in 
	1_primary_cohort.sas has been run. That will ensure
	that all of the required SAS datasets have been created for these
	analyses.


*****************************************************************************/


********
Options settings that should be run at the beginning of the file PRIOR TO 
ANYTHING ELSE
********;

*Code provided by Alan for the class;
options ps=500 ls=220 nodate nocenter nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes mprint;proc template;edit Base.Freq.OneWayList;edit Frequency;format=8.0;end;edit Percent;format = 5.1;end;edit CumPercent;format = 5.1;end;end;run;
 
*Code that tells SAS to pull all the macros that we have in our macros folder;
options source source2 msglevel=I mcompilenote=all mautosource 
     sasautos=(SASAUTOS "/local/projects/marketscanccae/larc_descrip/programs/macros");

*Run the set-up macro that Virginia provided for all projects completed on the
	 N2 server. This facilitates running the analysis on the full MarketScan
	 sample.;
*%setup(random1pct, 5_primary_analysis_numbers, saveLog=N);
%setup(full, 5_primary_analysis_numbers, saveLog=N);

*This will set up all the remote libraries that we need.;

****
****;


*Map local mirrors for all remote libraries using LOCAL SUBMIT (plain ol' running man button, or F3);
/*libname lraw slibref=raw server=server;*/
*libname lshare slibref=share server=server;
*libname loutproj slibref=outproj server=server;
/*libname lwork slibref=work server=server;*/
libname lout slibref=out server=server;
libname lwork slibref=work server=server;






/****************************************************************************
Calculate the incidence proportion of first LARC insertions over the 
enrollment period.

This analysis will give the crude incidence of naive LARC insertions for
each calendar year, as well as the percentage of the insertions that are
attributed to each of the included LARC types.

The goal is to output one final dataset that is easy to look at, read,
and copy the results from.

This must be run prior to the other codes, regardless of what you're doing
because the age categorization is included in the nlarcyear macro. While
not the most convenient, this is done because it ensured that this variable
would be created in any dataset used for sensitivity analyses.
****************************************************************************/


/****************************************************************************
Add age category variable.
****************************************************************************/
data ana.month_primary_cohort5;
set out.month_primary_cohort4;

	IF 15 <= age < 20 THEN agecat = 1;
			ELSE IF 20 <= age < 25 THEN agecat = 2;
			ELSE IF 25 <= age < 30 THEN agecat = 3;
			ELSE IF 30 <= age < 35 THEN agecat = 4;
			ELSE IF 35 <= age < 40 THEN agecat = 5;
			ELSE IF 40 <= age < 45 THEN agecat = 6;
			ELSE IF 45 <= age <= 49 THEN agecat = 7;
			ELSE IF 50 <= age <= 54 THEN agecat = 8;
			*ELSE IF 55 <= age <= 59 THEN agecat = 9;
			*ELSE IF 60 <= age <= 64 THEN agecat = 10;

run;
	


*Grab the distinct month_yr values, and
Create dataset with these values

Only needs to be run once. This file is now
saved.

These values will be used for plotting;
/*proc sql;*/
/*	create table out.month_yr as*/
/*	select distinct(month_yr), year, month*/
/*	from out.month_primary_cohort4*/
/*	;*/
/*	quit;*/
/**/
/*proc sort data=out.month_yr;*/
/*	where year > 2009;*/
/*	by year month;*/
/*run;*/
/**/
/*data out.month_yr;*/
/*set out.month_yr;*/
/*	count = _n_;*/
/*run;*/

 





/****************************************************************************
Calculate overall crude estimates.

This calculates month-level LARC insertion incidence estimates without
any standardization to the age distribution or terr.
****************************************************************************/


*Calculate the month-level prevalence estimates;
proc freq data=ana.month_primary_cohort5 noprint;
	where atrisk=1 and year > 2009;
	tables year * month * larc_insert / out=ana.month_prev_crude outpct;
run;

*Count the total number of included LARC insertions;
proc means data=ana.month_prev_crude sum;
	where larc_insert=1;
	var count;
run;


*Need to reorganize the frequency data so that we have denominators
and can output it for prevalence estimation
Above was just getting counts

This creates a dataset with the number with and without a LARC insertoin for each 
year and month combo - there are two rows for each year and month combo;
proc sort data=ana.month_prev_crude out=test2;
	by year month larc_insert;
run;

*Collapses year and month data so that the denominator is correct and on the same row
as the numerator.;
data test3;
set test2;

	by year month larc_insert;

	retain n_total;
	if first.month then n_total = count;
		else n_total = count + n_total;

	if last.month then output;

	*if larc_insert = 0 then delete;
run;

*Deal with those situations where there is no one in the numerator.
Manually set their numerator to zero and the row percent to 0;
data ana.crude_overall_incidence;
set test3;
	
		if larc_insert = 0 then do;
			pct_row = 0;
			count = 0;
		end;

run;








/****************************************************************************
Calculate overall stratified estimates of LARC insertion incidence 
for each year and month. These will be stratified by age and terr.

Need this dataset for standardization.
****************************************************************************/


*Calculate the month-level prevalence estimates for each age * terr;
proc freq data=ana.month_primary_cohort5 noprint;
	where atrisk=1 and year > 2009;
	tables year * month * terr /*region*/ * agecat * larc_insert / out=ana.larc_inc_strat outpct;
run;

/*data num;*/
/*set test;*/
/*	where region ne '5';*/
/*run;*/
/**/
/*proc freq data=num;*/
/*	where larc_insert = 0;*/
/*	tables year month agecat region;*/
/*run;*/

*Follow the same logic as above but with additional stratification by age and terr;

proc sort data=ana.larc_inc_strat out=test2;
	by year month terr agecat larc_insert;
run;

data test3;
set test2;

	by year month terr agecat larc_insert;

	retain n_total;
	if first.agecat then n_total = count;
		else n_total = count + n_total;
		* deal with missing count;

	if last.agecat then output;

	drop percent pct_tabl pct_col;

run;

data ana.stratified_overall_incidence;
set test3;
	
		if larc_insert = 0 then do;
			pct_row = 0;
			count = 0;
		end;

run;






/****************************************************************************
Calculate proportions of people per terr * age strata in January 2010.

All monthly LARC insertion incidence estimates will be standardized to this
distribution.
****************************************************************************/

proc freq data=ana.month_primary_cohort5 noprint;
	where year = 2010 and month = 1;
	tables terr /*region*/ * agecat / out=ana.jan2010_age_terr_strat;
run;

data ana.age_terr_prop;
set ana.jan2010_age_terr_strat;
	proportion = percent / 100;
	rename count=standard_n percent=standard_pct proportion = standard_prop;
run;

/* Sum this up to make sure that the sum is 1:
proc means data=out.age_region_prop sum;
	var standard_prop;
run;
*/






/****************************************************************************
Combine the datasets so that each incidence is combined with the 
standardization proportions.
****************************************************************************/

proc sql;
	create table overall_strat as 
	select a.*, b.standard_prop
	from ana.stratified_overall_incidence as a
	left join ana.age_terr_prop as b
	on a.terr = b.terr and a.agecat = b.agecat
	;
	quit;

data ana.overall_strat;
set overall_strat (rename = (pct_row = larc_pct));
run;




/****************************************************************************
Calculate the monthly, age and region standardized incidence values.
****************************************************************************/

data overall_strat2;
set overall_strat;
	
	*stand_incidence is a proportion, not percent;
	stand_incidence = (count/n_total) * standard_prop;

run;

proc sort data=overall_strat2;
	by year month terr /*region*/ agecat;
run;

*month_incidence is a proportion;

*Sum the standardized incidences across the agecat and terr
distribution to get the total for that month;
data ana.overall_standardized;
set overall_strat2;

	by year month terr /*region*/ agecat;

	retain month_incidence;

	if first.month then month_incidence = stand_incidence;

	else do;
		month_incidence = SUM(month_incidence, stand_incidence);
		end;

	if last.month then output;

run;




/****************************************************************************
Combine the crude and standardized overall estimates into one dataset.
****************************************************************************/

*Incidence per 10,000;

proc sql;
	create table ana.overall_incidence_primary as
	select a.year, a.month, a.month_incidence * 10000 as std_incidence, 
		   b.pct_row * 100 as crude_incidence, c.count as time_counter
	from ana.overall_standardized as a 
	left join ana.crude_overall_incidence as b
	on a.year = b.year and a.month = b.month
	left join out.month_yr as c
	on a.year = c.year and a.month = c.month
	;
	quit;

/* Calculate year-level incidence estimates to compare with our original results

We want to calculate the average yearly incidence using the month-level incidence
	estimates in each month.*/
data ana.crude_std_avg_monthly_incidence;
set ana.overall_incidence_primary;
	by year month;
	
	retain year_sum_std year_sum_crude year_std_mean year_crude_mean;
	
	if first.year then do;
		year_sum_std = std_incidence;
		year_sum_crude = crude_incidence;
		year_std_mean = 0;
		year_crude_mean = 0;
		end;

	else do;
		year_sum_std = SUM(year_sum_std, std_incidence);
		year_sum_crude = SUM(year_sum_crude, crude_incidence);
		year_std_mean = year_sum_std/12;
		year_crude_mean = year_sum_crude/12;
		end;

	if last.year then output;

	keep year_std_mean year_crude_mean year ; 
run;



/****************************************************************************
Create a year-level table with all the people in the denominator.

Want to calculate the average number of people included in the denominator
for each month-level incidence calculation for the year.
****************************************************************************/

data yearly_total;
set ana.crude_overall_incidence;
	by year month;
	
	retain year_sum_n year_n_mean;
	
	if first.year then do;
		year_sum_n = n_total;
		year_n_mean = 0;
		end;

	else do;
		year_sum_n = SUM(year_sum_n, n_total);
		year_n_mean = round(year_sum_n/12);
		end;

	if last.year then output;

	keep year year_n_mean; 
run;



/****************************************************************************
Calculate the proportion of LARC insertions attributed to each LARC type.

Calculated as: crude # of type of insertion / total # of insertions
****************************************************************************/

*Limit the dataset to those rows where larc_insert = 1 and keep
only those variables we need;
data ana.larc_eq_1;
set ana.month_primary_cohort5 (KEEP = year larc_insert hcpcimp hcpchiud hcpcnhiud);
	where larc_insert = 1;

	if hcpcnhiud = 1 then larc_type = "Non-Hormonal IUD";
		else if hcpchiud = 1 then larc_type = "Hormonal IUD";
		else if hcpcimp = 1 then larc_type = "Implant";

run;

*Calculate the proportions for each IUD by each year;
proc freq data=ana.larc_eq_1 noprint;
	tables larc_type * year / out=ana.larc_props_yr outpct;;
run;

*Make dataset for Implant;
data implant;
set ana.larc_props_yr (keep = larc_type year pct_col);
	where larc_type = "Implant";
	pct_col = round(pct_col, 0.01);
	rename pct_col = hcpcimp_pct;
	drop larc_type;
run;

*Make dataset for Hormonal IUD;
data hiud;
set ana.larc_props_yr (keep = larc_type year pct_col);
	where larc_type = "Hormonal IUD";
	pct_col = round(pct_col, 0.01);
	rename pct_col = hcpchiud_pct;
	drop larc_type;
run;

*Make dataset for Hormonal IUD;
data nhiud;
set ana.larc_props_yr (keep = larc_type year pct_col);
	where larc_type = "Non-Hormonal IUD";
	pct_col = round(pct_col, 0.01);
	rename pct_col = hcpcnhiud_pct;
	drop larc_type;
run;

*Output the final table with average, monthly incidence values over each year;
proc sql;
	create table ana.primary_year_overall as
	select distinct a.hcpcimp_pct label="Implant Pct", b.hcpchiud_pct label="Hormonal IUD Pct", c.hcpcnhiud_pct label="Non-Hormonal IUD Pct", d.year, 
					round(d.year_std_mean, 0.01) as std_mean_inc label="Standardized Incidence per 10,000",
					round(d.year_crude_mean, 0.01) as crude_mean_inc label = "Crude Incidence per 10,000", e.year_n_mean as n
	from implant as a
	left join hiud as b
	on a.year=b.year
	left join nhiud as c
	on a.year = c.year
	left join ana.crude_std_avg_monthly_incidence as d
	on a.year = d.year
	left join yearly_total as e
	on a.year = e.year
	;
	quit;

**We will output this dataset using RMD;
	








/****************************************************************************
Calculate the monthly, age-stratified, territory-standardized incidence 
	estimates.
****************************************************************************/

*Sort the dataset by terr first and then age. SO that we can sum the 
	proportions for standardization over age wtihin each terr category.;
proc sort data= ana.age_terr_prop out=test;
	by terr /*region*/ agecat;
run;

*Sum the proportions within terr over age, so that we have proportoins of
region that sum to 1

This means that each age-stratified estimate is standardizaed to the overall
region distribution in January 2010;
data ana.terr_prop;
set test;

	by terr /*region*/ agecat;
	
	retain terr_prop;

	if first.terr then  terr_prop = standard_prop;

	else terr_prop = SUM(terr_prop, standard_prop);

	if last.terr then output;

run;


*Add in the proportions for age standardization to the stratified
incidence estiamtes dataset;
proc sql;
	create table overall_age_strat as 
	select a.*, b.terr_prop
	from ana.stratified_overall_incidence as a
	left join ana.terr_prop as b
	on a.terr = b.terr
	;
	quit;


*Multiply the region and age stratified incidence by the region proportions;
data test;
set overall_age_strat;

	terr_std_prop = (count / n_total) * terr_prop;

run;

proc sort data=test;
	by year month agecat terr;
run;


* Sum the standardized proportions over region within each age category;
data ana.age_strat_terr_std;
set test;

	by year month agecat terr;

	retain age_strat_incidence;

	if first.agecat then age_strat_incidence = terr_std_prop;

	else do;
		age_strat_incidence = SUM(age_strat_incidence, terr_std_prop);
		end;

	if last.agecat then output;

run;

proc sql;
	create table ana.age_strat_terr_std_my as
	select a.*, b.month_yr, b.count as time_counter
	from ana.age_strat_terr_std as a
	left join out.month_yr as b
	on a.year = b.year and a.month = b.month
	;
	quit;

data ana.age_strat_terr_std_my;
set ana.age_strat_terr_std_my;
	age_strat_incidence_10000 = 10000*age_strat_incidence;
run;
*Output the dataset that we will be using for plotting;





	









	








/**/
/*%nlarcyear(firstlarcenrl4, 2010);*/
/*%nlarcyear(firstlarcenrl4, 2011);*/
/*%nlarcyear(firstlarcenrl4, 2012);*/
/*%nlarcyear(firstlarcenrl4, 2013);*/
/*%nlarcyear(firstlarcenrl4, 2014);*/
/*%nlarcyear(firstlarcenrl4, 2015);*/
/*%nlarcyear(firstlarcenrl4, 2016);*/
/*%nlarcyear(firstlarcenrl4, 2017);*/
/*%nlarcyear(firstlarcenrl4, 2018);*/

*merge all this information together into one dataset that
contains incidence numbers and larc type proportions for each
included calendar year;
/*PROC SQL;*/
/*	CREATE TABLE overallsummary AS*/
/*	SELECT * FROM propsum2010*/
/*	UNION CORR*/
/*	SELECT * FROM propsum2011*/
/*	UNION CORR*/
/*	SELECT * FROM propsum2012*/
/*	UNION CORR*/
/*	SELECT * FROM propsum2013*/
/*	UNION CORR*/
/*	SELECT * FROM propsum2014*/
/*	UNION CORR*/
/*	SELECT * FROM propsum2015*/
/*	UNION CORR*/
/*	SELECT * FROM propsum2016*/
/*	UNION CORR*/
/*	SELECT * FROM propsum2017*/
/*	UNION CORR*/
/*	SELECT * FROM propsum2018*/
/*	;*/
/*	QUIT;*/

*Make the wider dataset

The previous dataset contains information for the number of LARC insertions
	and the number of individuals that didn't get a LARC insertion during
	the year that they were at risk. The below code aims to combine this
	information into 1 row per calendar year

Split the dataset into insertions and non-insertions first and then sort 
	by year.;
/*DATA overalllarc1;*/
/*SET overallsummary ;*/
/*	WHERE larc_insert = 1;*/
/*	RENAME count = nlarc;*/
/*	RENAME percent = incidenceprop;*/
/*RUN;*/
/*PROC SORT DATA = overalllarc1; BY year; RUN;*/
/*DATA overalllarc0;*/
/*SET overallsummary;*/
/*	WHERE larc_insert = 0;*/
/*	RENAME count = nnolarc;*/
/*RUN;*/
/*PROC SORT DATA = overalllarc0; BY year; RUN;*/
/**/
*Join the datasets so that the information is contained on one row for each calendar year.;
/*PROC SQL;*/
/*	CREATE TABLE overallsummary2 AS */
/*	SELECT a.year, a.nlarc, a.incidenceprop, b.nnolarc, b.nhcpcimp, b.nhcpchiud, b.nhcpcnhiud */
/*	FROM overalllarc1 as a FULL JOIN overalllarc0 as b*/
/*	ON a.year = b.year;*/
/*	QUIT;*/
/**/
/**Calculate the numbers that need in this table.;*/
/*DATA out.overallcrude;*/
/*SET overallsummary2;*/
/**/
/*	total = nlarc + nnolarc;*/
/**/
/*	*Sum over the individual LARC types to ensure that everything is correct*/
/*	If this doesn't match the total, it means that something is wrong.;*/
/*	sumlarctype = nhcpcimp + nhcpchiud + nhcpcnhiud;*/
/**/
/*	*Calculate the proportion of each LARC type - Rounded*/
/**/
/*	Note that incidenceprop is already 100 times the decimal We later*/
/*	decided to report these numbers as per 1,000 individuals as */
/*	opposed to per 100. However, this was just calculated by moving*/
/*	the decimal over one place from what was calculated here.;*/
/*	propimp = 100 * nhcpcimp / nlarc;*/
/*	propimpround = round(propimp, 0.01);*/
/*	prophiud = 100 * nhcpchiud / nlarc;*/
/*	prophiudround = round(prophiud, 0.01);*/
/*	propnhiud = 100 * nhcpcnhiud / nlarc;*/
/*	propnhiudround = round(propnhiud, 0.01);*/
/**/
/*	*Calculate incidence per 1,000 individuals just to check numbers*/
/*	calculated by hand;*/
/*	incidenceper1000 = 10 *incidenceprop;*/
/*RUN;*/
/**/
*Print the dataset so that can easily view and trnasport into an analysis table

This is combined with standardized incidence for the Table 1 output at the bottom of
this file, so I have commented it out here.;
/*
PROC PRINT DATA = out.overallcrude;
	VAR year nlarc incidenceprop incidenceper1000 total propimpround prophiudround propnhiudround;
RUN;
*/

	

*Delete the datasets that don't need to keep the work library clean;
/*PROC DELETE DATA = propsum2010; RUN;*/
/*PROC DELETE DATA = propsum2011; RUN;*/
/*PROC DELETE DATA = propsum2012; RUN;*/
/*PROC DELETE DATA = propsum2013; RUN;*/
/*PROC DELETE DATA = propsum2014; RUN;*/
/*PROC DELETE DATA = propsum2015; RUN;*/
/*PROC DELETE DATA = propsum2016; RUN;*/
/*PROC DELETE DATA = propsum2017; RUN;*/
/*PROC DELETE DATA = propsum2018; RUN;*/
/*PROC DELETE DATA = overallsummary; RUN;*/
/*PROC DELETE DATA = overallsummary2; RUN;*/
/*PROC DELETE DATA = overalllarc1; RUN;*/
/*PROC DELETE DATA = overalllarc0; RUN;*/
/**/
/**/
/**/





/****************************************************************************
Calculate the stratified incidence proportions over each region and then
over the age groups within each region.

This dataset will later be combined with the age x region distribution in
the 2010 data to calcualte the standardized incidence for each calendar year.
****************************************************************************/

*Run the macros from the macro folderto create a summary region, 
stratified by age category, for each region

NEED TO CONFIRM WHICH REGIONS WE ARE LOOKING AT -- ONLY 5;
/*%regionagestrata(firstlarcenrl4, '1', 1);*/
/*%regionagestrata(firstlarcenrl4, '2', 2);*/
/*%regionagestrata(firstlarcenrl4, '3', 3);*/
/*%regionagestrata(firstlarcenrl4, '4', 4);*/
/*%regionagestrata(firstlarcenrl4, '5', 5);*/

*Stack all the region datasets from above

- We now have a combined, stratified dataset. Going to need
this for the standardization;
/*PROC SQL;*/
/*	CREATE TABLE stratified AS */
/*	SELECT * FROM region1*/
/*	UNION CORR*/
/*	SELECT * FROM region2*/
/*	UNION CORR*/
/*	SELECT * FROM region3*/
/*	UNION CORR*/
/*	SELECT * FROM region4*/
/*	UNION CORR*/
/*	SELECT * FROM region5*/
/*	;*/
/*	QUIT;*/
/**/
*Create the variable incidenceprop - the incidence proportion for each of the strata
	based on the total at-risk in that strata

	Also create incidenceper1000, which is the incidence of naive LARC insertions per 1,000
	individuals in the at-risk population;
/*DATA out.stratified;*/
/*SET stratified;*/
/*	incidenceprop = nlarc / total;*/
/*	incidenceperc = 100 * incidenceprop;*/
/*	incidenceper1000 = 1000 * incidenceprop;*/
/*RUN;*/


*This stratified dataset will be used to calculate the standardized
incidence rates next and will also be used to create the age-stratified
one-year incidence for each region's figure for the paper.

These figures are created in the file --
Busse_Dissanayake_Latour_PP5_file6;







	
/****************************************************************************
Calculate cross-tabulated probabilities of the regions with the age categories
that we have proposed for calendar year 2010. This is the year that we're 
going to use to standardize over the entire dataset.

Standardizing the calendar-year incidence rate to the age and region 
distribution in 2010.
****************************************************************************/

*Calculate probabilities and the associated weights for a weighted mean;

*Use the PROC FREQ statement to output the dataset necessary to get the
probabilities needed and their associated weights
Going to use these probabilities - that sum to 100 - as the weights,
as done in lab 7.
-- We remove those individuals where the region is unknown specifically for
standardization;
/*PROC FREQ DATA = out.firstlarcenrl4 NOPRINT;*/
/*	WHERE year = 2010 & atrisk = 1 & region ne '5';*/
/*	TABLES region * agecat / OUT = strata2010;*/
/*RUN;*/


/* Think that it looks exactly like it should - each row is one proportion
PROC PRINT DATA = strata2018;
RUN;

PROC FREQ DATA = FIRSTLARCENRL4;
	TABLES year * region / MISSING;
RUN;

PROC MEANS DATA = strata2010 SUM;
	VAR percent;
RUN;
*/

*Create a percent variable that is the proportion associated with the percent
calculated in PROC FREQ;
/*DATA strata2010;*/
/*SET strata2010;*/
/*	proportion = percent / 100;*/
/*RUN;*/








/****************************************************************************
Calculate standardized yearly incidence proportions - proportions based
off of the year 2010.

Combines the stratified dataset with the probabilities/proportions/weights
calcualted for 2010
****************************************************************************/

*To standardize, going to need the 'stratified' dataset from above;

*Make the variable regionnum, which is the numerical version of region
so that they can merge together;
/*DATA strata2010;*/
/*SET strata2010;*/
/*	regionnum = 1 * region;*/
/*RUN;*/

*Merge that dataset with the percentages/weights calculated in the previous
step through the PROC FREQ statement - the dataset 'strata2018';

/*PROC SQL;*/
/*	CREATE TABLE stratifiedweights AS*/
/*	SELECT a.*, b.percent, b.proportion*/
/*	FROM out.stratified as a LEFT JOIN strata2010 as b*/
/*	ON a.agecat = b.agecat AND a.region = b.regionnum*/
/*	WHERE a.region ne 5 /*Remove those individuals with missing region for standardization*/*/
/*	;*/
/*	QUIT;*/


*Sort the dataset so that can do the weighted averages that we need to do of
	the incidence proportions;
/*PROC SORT DATA = stratifiedweights OUT=out.stratifiedweights;*/
/*	BY year region agecat;*/
/*RUN;*/

/*Check that the weights add up to about 100 for each year, minus some rounding error
PROC MEANS DATA =stratifiedweights SUM;
	BY year;
	VAR percent;
RUN;
All add up to almost exactly 100. - Should we be concerned that some don't sum up to 
exactly 100?*/



*Calculate each year-level standardized incidence proportion. This is done by taking 
a weighted-average of the age x region stratified incidence proportions according
to probabilities calculated in the 2010 MarketScan dataset for our population criteria 
(of those at-risk);
/*DATA temp.standardizedinc;*/
/*SET stratifiedweights;*/
/*	BY year;*/
/*	*Going to output this variable which will contain a year's standardized proportion;*/
/*	RETAIN standardprop;*/
/**/
/*	IF first.year THEN DO;*/
/*			*Originally were planning to report -- */
/*			multiply the incidence proportion times 100 with the probability from the 2010 data;*/
/*			standardprop = incidenceperc * proportion;*/
/*			*/
/**/
/*			*incidenceprop100 = incidence proportion of LARC insertions for the age and region*/
/*			strata of the year we are wanting to standardize per 100 people in the population*/
/**/
/*			incidenceper1000 = incidence proportion of LARC inesrtions for the age and region */
/*			strata of the year we are wanting to standardize per 1000 people in the population*/
/**/
/*			proportion = proportion of the population of 2010 in that age and region strata;*/
/*			END;*/
/*		ELSE DO;*/
/*			standardprop = standardprop + (incidenceperc * proportion);*/
/*			*Add each year probability;*/
/*			END;*/
/**/
/*	IF last.year THEN DO;*/
/*		standardprop = standardprop + (incidenceperc * proportion);*/
/*		OUTPUT;*/
/*		END;*/
/*RUN;*/
/**Keep just the year and standardized incidence proportion*/
/*All other variables reflect the specific agexregion strata that they were pulled from*/
/*and do not reflect the year-level information.*/
/*Also create a rounded stanadrdized proportion estimate;*/
/*DATA out.standardizedinc;*/
/*SET standardizedinc (KEEP = year standardprop);*/
/*	standardpropround = round(standardprop, 0.01);*/
/*	*Calculate standardized incidence per 1,000 persons;*/
/*	standardper1000round = round(10 * standardprop, 0.1);*/
/*RUN;*/
/**/
/**Round incidence prop for simplicity when reading;*/
/*DATA out.overallcrude;*/
/*SET overallcrude;*/
/*	incidencepropround = round(incidenceprop, 0.01);*/
/*	*Calculate rounded incidence per 1,000 persons;*/
/*	incidenceper1000round = round(incidenceper1000, 0.1);*/
/*RUN;*/


*We have now created all of the datasets/variables that we need to 
output the data in the form that we desire.;



/****************************************************************************
Calculate population descriptive information for the paper.
****************************************************************************/

*Calculate the n for describing the population -- Descriptive statistics of the
numerator and denominator. Here teh denominator represents risk periods,
which is why it is higher than the total number of individuals at risk over
the period;
/*TITLE 'Individuals who had naive LARC insertion';*/
/*PROC FREQ DATA = out.firstlarcenrl4;*/
/*	WHERE atrisk = 1 & larc_insert = 1;*/
/*	TABLES year agecat region;*/
/*RUN;*/
/**/
/*TITLE 'Individuals at risk of naïve LARC insertion';*/
/*PROC FREQ DATA = out.firstlarcenrl4;*/
/*	WHERE atrisk = 1 & year ne 2009;*/
/*	*Remove the enrollment periods during 2009;*/
/*	TABLES year agecat region;*/
/*RUN;*/
/*TITLE ;*/



/****************************************************************************
Create a table that contains all of the crude incidence and standardized
incidence information for the primary analysis. This will be combined
with proportions of LARCs by type.
****************************************************************************/

*Macro to calculate the n for table 2 -- crude and standardized
incidence proportions. Percentages of the LARCs - represent the
percent of the total LARC insertions

crude - this dataset should contain the crude incidence proportion
as well as the HCPC information
standardized - this dataset should contain the standardized
incidence proportion;

/*PROC SQL;*/
/*	CREATE TABLE ana.primaryincidence AS*/
/*	SELECT a.year, a.nlarc, a.nhcpcimp, a.nhcpchiud, a.nhcpcnhiud, a.total, */
/*			a.incidencepropround, a.incidenceper1000round, a.propimp, a.prophiud, */
/*			a.propnhiud, b.standardpropround, b.standardper1000round*/
/*	FROM out.overallcrude as a FULL JOIN standardizedinc as b */
/*	ON a.year = b.year*/
/*	;*/
/*	QUIT;*/
/**/
/**Print the information that we want for the paper so that we can easily see it;*/
/*PROC PRINT DATA = primaryincidence;*/
/*	VAR year incidenceper1000round propimp prophiud propnhiud standardper1000round;*/
/*RUN;*/
/**/



*Stratified data are only going to be viewed in figures. See file 6;







