
/****************************************************************************
	Name: Clara Busse, Mekhala Dissanayake, Chase Latour
	Class: EPID 766 / DPOP 766
	Submit Date: 20210223
	Purpose: Project
	Program path:
		/mnt/files/users/cdlatour/project
	Input paths:	
		/mnt/files/class/random1pct
	Output path:	
		/mnt/files/users/cdlatour/project*/


*Sensitivity analysis: use LARCs with CPT codes but without matching HCPCs to identify insertions

*Outputted previously: numerator_sens_analysis;



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
%setup(full, 8_sens_analysis_cpt, saveLog=N);

*This will set up all the remote libraries that we need.;

****
****;

*Map local mirrors for all remote libraries using LOCAL SUBMIT (plain ol' running man button, or F3);
libname lraw slibref=raw server=server;
*libname lshare slibref=share server=server;
*libname loutproj slibref=outproj server=server;
libname lwork slibref=work server=server;
libname lout slibref=out server=server;


**********************************************************************
Implement periods of continuous enrollment.

This file was written to derive the enrollment datasets that are
necessary for identifying the denominator. Run this with the remote
submit.
**********************************************************************;

*%include '/local/projects/marketscanccae/larc_descrip/programs/2_continuous_enrollment.sas';


**********************************************************************
Now identify LARCS. A numerator for the sensitivity analysis has only
been outputted. Only restriction is excluding insertions with a removal code
within 30 days.
**********************************************************************;

*1) Read in numerator into working library so that it can be merged;

data numerator_sens_analysis;
set out.numerator_sens_analysis;
run;


**********************************************************************
Now merge the numerator and denominator files.

This code merges the LARC insertion information with the enrollment 
information and removes the risk periods that are no-longer at risk
if a person experience an earlier LARC inesrtion in the data. Run
this with a remote submit.
**********************************************************************;

*Once mapped over the macro, this file contained nothing but the 
macro running, so I have included that here.;
options mprint;
*%numdenmerge(numerator_sens_analysis, enrlstratalong, month_sens_analysis_cohort);


*Figure out how many LARC insertions did not match to a continuous enrollment period;

*First, the number of unique people in the numerator file;
proc sql;
	select count(distinct enrolid) as premerge_n_sens
	from out.numerator_sens_analysis;
	run;


*Calculate the sum of the LARC insertions from month_primary_cohort4;
proc sql;
	select SUM(larc_insert) as n_larc_insert
	from out.month_sens_analysis_cohort4;
	quit;



*Analysis;




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
data ana.month_sens_analysis_cohort5;
set out.month_sens_analysis_cohort4;

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
	


*Grab the distinct month_yr values
Create dataset with these values

Only needs to be run once.;
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
****************************************************************************/


*Calculate the month-level prevalence estimates;
proc freq data=ana.month_sens_analysis_cohort5 noprint;
	where atrisk=1 and year > 2009;
	tables year * month * larc_insert / out=ana.month_prev_crude_sens outpct;
run;

*Need to reorganize the frequency data so that we have denominators
and can output it for prevalence estimation
Above was just getting counts

This creates a dataset with the number with and without a LARC insertoin for each 
year and month combo - there are two rows for each year and month combo;
proc sort data=ana.month_prev_crude_sens out=test2;
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
data ana.crude_sens_analysis_incidence;
set test3;
	
		if larc_insert = 0 then do;
			pct_row = 0;
			count = 0;
		end;

run;





/****************************************************************************
Calculate overall stratified estimates for each year and month.
****************************************************************************/


*Calculate the month-level prevalence estimates for each age * terr;
proc freq data=ana.month_sens_analysis_cohort5 noprint;
	where atrisk=1 and year > 2009;
	tables year * month * terr * agecat * larc_insert / out=ana.larc_inc_strat_sens outpct;
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

*Follow the same logic as above but with additional stratification by age and region;

proc sort data=ana.larc_inc_strat_sens out=test2;
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

data ana.stratified_sens_incidence;
set test3;
	
		if larc_insert = 0 then do;
			pct_row = 0;
			count = 0;
		end;

run;






/****************************************************************************
Calculate proportions of people per region * age strata in January 2010.
****************************************************************************/

proc freq data=ana.month_sens_analysis_cohort5 noprint;
	where year = 2010 and month = 1;
	tables terr * agecat / out=ana.jan2010_age_terr_strat_sens;
run;

data ana.age_terr_prop_sens_analysis;
set ana.jan2010_age_terr_strat_sens;
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
	from ana.stratified_sens_incidence as a
	left join ana.age_terr_prop_sens_analysis as b
	on a.terr = b.terr and a.agecat = b.agecat
	;
	quit;

data ana.sens_analysis_strat;
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
	by year month terr agecat;
run;

*month_incidence is a proportion;

data ana.sens_analysis_standardized;
set overall_strat2;

	by year month terr agecat;

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
	create table ana.sens_incidence_primary as
	select a.year, a.month, a.month_incidence * 10000 as std_incidence, 
		   b.pct_row * 100 as crude_incidence, c.count as time_counter
	from ana.sens_analysis_standardized as a 
	left join ana.crude_sens_analysis_incidence as b
	on a.year = b.year and a.month = b.month
	left join out.month_yr as c
	on a.year = c.year and a.month = c.month
	;
	quit;

/* Calculate year-level incidence estimates to compare with our original results
Decided that this was wrong to get yearly estimates because denominators and numerators
	are different each month.*/
data ana.sens_std_avg_monthly_incidence;
set ana.sens_incidence_primary;
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
Create a year-level table with all the people in the denominator
****************************************************************************/

data yearly_total;
set ana.crude_sens_analysis_incidence;
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


/*Don't do this for sensitivity analysis because not all CPT codes have a matching HCPC
****************************************************************************
Calculate the proportion LARC insertions attributed to each LARC type.

Calculated as: crude # of type of insertion / total # of insertions
****************************************************************************

*Limit the dataset to those rows where larc_insert = 1 and keep
only those variables we need;
data test;
set out.month_primary_cohort4 (KEEP = year larc_insert hcpcimp hcpchiud hcpcnhiud);
	where larc_insert = 1;

	if hcpcnhiud = 1 then larc_type = "Non-Hormonal IUD";
		else if hcpchiud = 1 then larc_type = "Hormonal IUD";
		else if hcpcimp = 1 then larc_type = "Implant";

run;

*Calculate the proportions for each IUD by each year;
proc freq data=test;
	tables larc_type * year / out=test2 outpct;;
run;

*Make dataset for Implant;
data implant;
set test2 (keep = larc_type year pct_col);
	where larc_type = "Implant";
	pct_col = round(pct_col, 0.01);
	rename pct_col = hcpcimp_pct;
	drop larc_type;
run;

*Make dataset for Hormonal IUD;
data hiud;
set test2 (keep = larc_type year pct_col);
	where larc_type = "Hormonal IUD";
	pct_col = round(pct_col, 0.01);
	rename pct_col = hcpchiud_pct;
	drop larc_type;
run;

*Make dataset for Hormonal IUD;
data nhiud;
set test2 (keep = larc_type year pct_col);
	where larc_type = "Non-Hormonal IUD";
	pct_col = round(pct_col, 0.01);
	rename pct_col = hcpcnhiud_pct;
	drop larc_type;
run;
*/

*Output the final table with average, monthly incidence values over each year;
proc sql;
	create table ana.sens_year_overall as
	select distinct d.year, 
					round(d.year_std_mean, 0.01) as std_mean_inc label="Standardized Incidence per 10,000",
					round(d.year_crude_mean, 0.01) as crude_mean_inc label = "Crude Incidence per 10,000", e.year_n_mean as n

	from ana.sens_std_avg_monthly_incidence as d
	left join yearly_total as e
	on d.year = e.year
	;
	quit;
	
