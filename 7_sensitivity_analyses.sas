/****************************************************************************
	Name: Clara Busse, Mekhala Dissanayake, Chase Latour
	Class: EPID 766 / DPOP 766
	Submit Date: 20210223
	Purpose: Run all of the sensitivity analyses.
	Program path:
		/mnt/files/users/cdlatour/project
	Input paths:	
		/mnt/files/class/random1pct
	Output path:	
		/mnt/files/users/cdlatour/project


In order to use this file, you should have already run file3 and have the macros

cpt_gap
hcpc_gap
mergedata 

The dataset

  first_larc_hcpc_cptrem_formerge

is the numerator restricted to insertions with matching hcpcs and no removals within 30 days

The dataset
 first_larc_hcpc_cptrem2

is the numerator with flags for those variables, but not restricted
***********************************
You should also have run 
And file2 and have the macro

numdenmerge

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
%setup(random1pct, 1_primary_analysis, saveLog=N);

*This will set up all the remote libraries that we need.;

****
****;

*Map local mirrors for all remote libraries using LOCAL SUBMIT (plain ol' running man button, or F3);
libname lraw slibref=raw server=server;
*libname lshare slibref=share server=server;
*libname loutproj slibref=outproj server=server;
libname lwork slibref=work server=server;



/****************************************************************************
SENSITIVITY ANALYSIS 1 - Remove the requirement of a HCPCS code associated
with the CPT code.

- get rid of the inclusion criteria that requires a matching hcpc
****************************************************************************/

*Start with dataset that has the flag, restrict to only larcs without a removal in 30 days;
*Drop hcpc variables;
data first_larc_cptrem_formerge(drop= hcpc_proc1  hcpc_svcdate hcpcimp hcpchiud hcpcnhiud hcpc_gap);
set out.first_larc_hcpc_cptrem2; 
	where larc_remove_flag=0;
run; 

*14,060 larc insertions;

*Create new dataset that merges this new numerator to the enrollment file;

%numdenmerge(first_larc_cptrem_formerge, temp.enrlstratalong, firstlarcenrl_sens);

*The last dataset this macro will create will be named output4, so here it is firstlarcenrl_sens4;
/*
proc freq data=firstlarcenrl_sens4;
tables larc_insert;
run; 
*/
*14,049 larc insertions (11 did not merge onto a qualifying enrolmment period);


/***************************************************************************
Calculate the incidence proportion of first LARC insertions over the 
enrollment period.

This code is just slightly modified from the code used to create the output
for the primary analyses. The main difference is that there is no 
differentiation by LARC type.
****************************************************************************/

*Create a summary n and proportion dataset for each year;
%nlarcyearsens1(firstlarcenrl_sens4, 2010);
%nlarcyearsens1(firstlarcenrl_sens4, 2011);
%nlarcyearsens1(firstlarcenrl_sens4, 2012);
%nlarcyearsens1(firstlarcenrl_sens4, 2013);
%nlarcyearsens1(firstlarcenrl_sens4, 2014);
%nlarcyearsens1(firstlarcenrl_sens4, 2015);
%nlarcyearsens1(firstlarcenrl_sens4, 2016);
%nlarcyearsens1(firstlarcenrl_sens4, 2017);
%nlarcyearsens1(firstlarcenrl_sens4, 2018);

*merge all this information together - stack the datasets;
PROC SQL;
	CREATE TABLE overallsummarysens1 AS
	SELECT * FROM prop2010
	UNION CORR
	SELECT * FROM prop2011
	UNION CORR
	SELECT * FROM prop2012
	UNION CORR
	SELECT * FROM prop2013
	UNION CORR
	SELECT * FROM prop2014
	UNION CORR
	SELECT * FROM prop2015
	UNION CORR
	SELECT * FROM prop2016
	UNION CORR
	SELECT * FROM prop2017
	UNION CORR
	SELECT * FROM prop2018
	;
	QUIT;

*Make the wider dataset - put the larc insertions and non-insertions
	on one row for each year;
DATA overalllarc1;
SET overallsummarysens1 ;
	WHERE larc_insert = 1;
	RENAME count = nlarc;
	RENAME percent = incidenceperc;
RUN;
PROC SORT DATA = overalllarc1; BY year; RUN;
DATA overalllarc0;
SET overallsummarysens1;
	WHERE larc_insert = 0;
	RENAME count = nnolarc;
RUN;
PROC SORT DATA = overalllarc0; BY year; RUN;

*Join the datasets and create the needed variables;
PROC SQL;
	CREATE TABLE overallsummary2sens1 AS 
	SELECT a.year, a.nlarc, a.incidenceperc, b.nnolarc
	FROM overalllarc1 as a FULL JOIN overalllarc0 as b
	ON a.year = b.year;
	QUIT;
DATA out.overallcrudesens1;
SET overallsummary2sens1;
	total = nlarc + nnolarc;
	incidenceper1000 = 10 * incidenceperc;
RUN;
/*Check the dataset output
PROC PRINT DATA = overallcrudesens1;
	VAR year nlarc incidenceperc incidenceper1000 total;
RUN;
*/

/****************************************************************************
Calculate the stratified incidence proportions over each region and then
over the age groups within each region.
****************************************************************************/

*Need to calculate the stratified dataset so that we can merge it with the
cross-classified (agexregion) probabilities in 2010 so that we can 
standardize the incidence estimates.;

*Run the macros to create the age-stratified datasets for each region. These will
then be merged together to make a totally merged stratified dataset
--Note that we have deleted region = 5 because these individuals are not included for the 
standardization;
%regionagestratasens1(out.firstlarcenrl_sens4, '1', 1);
%regionagestratasens1(out.firstlarcenrl_sens4, '2', 2);
%regionagestratasens1(out.firstlarcenrl_sens4, '3', 3);
%regionagestratasens1(out.firstlarcenrl_sens4, '4', 4);

*Stack the datasets on top of each other to create one large
stratified dataset, which will be used for standardization;
PROC SQL;
	CREATE TABLE ana.stratifiedsens1 AS 
	SELECT * FROM region1
	UNION CORR
	SELECT * FROM region2
	UNION CORR
	SELECT * FROM region3
	UNION CORR
	SELECT * FROM region4
	;
	QUIT;


/****************************************************************************
Calculate cross-tabulated probabilities of the regions with the age categories
that we have proposed for calendar year 2010. This is the year that we're 
going to use to standardize over the entire dataset.
****************************************************************************/

	*Calculate probabilities and the associated weights

-- Right now standardizing to the at-risk population in 2018. I assume that
this is the appropriate target -- CHECK;
*Use the PROC FREQ statement to output the dataset necessary to get the
probabilities needed and their associated weights
Going to use these probabilities - that sum to 100 - as the weights,
as done in lab 7.
-- We remove those individuals where the region is unknown specifically for
standardization;
PROC FREQ DATA = out.firstlarcenrl_sens4 NOPRINT;
	WHERE year = 2010 & atrisk = 1;
	TABLES region * agecat / OUT = strata2010sens1;
RUN;

*Create a percent variable that is a proportion;
DATA strata2010sens1;
SET strata2010sens1;
	proportion = percent / 100;
RUN;

/****************************************************************************
Calculate standardized yearly incidence proportions - proportions based
off of the year 2018.
****************************************************************************/

*To standardize, going to need the 'stratified' dataset from above;

*Make the variable regionnum, which is the numerical version of region
so that they can merge together;
DATA ana.strata2010sens1;
SET strata2010sens1;
	regionnum = 1 * region;
RUN;

*Merge that dataset with the percentages/weights calculated in the previous
step through the PROC FREQ statement - the dataset 'strata2018';

PROC SQL;
	CREATE TABLE ana.stratifiedweightssens1 AS
	SELECT a.*, b.percent, b.proportion
	FROM ana.stratifiedsens1 as a LEFT JOIN ana.strata2010sens1 as b
	ON a.agecat = b.agecat AND a.region = b.regionnum
	WHERE a.region ne 5 /*Remove those individuals with missing region for standardization*/
	;
	QUIT;


*Sort the dataset so that can do the weighted averages that we need to do of
	the incidence proportions;
PROC SORT DATA = ana.stratifiedweightssens1;
	BY year region agecat;
RUN;

/*Check that the weights add up to about 100 for each year, minus some rounding error
PROC MEANS DATA =stratifiedweights SUM;
	BY year;
	VAR percent;
RUN;
All add up to almost exactly 100. - Should we be concerned that some don't sum up to 
exactly 100?*/

*Calculate each year-level standardized incidence proportion. This is done by taking 
a weighted-average of the age x region stratified incidence proportions according
to probabilities calculated in the 2018 MarketScan dataset for our population criteria 
(of those at-risk);
DATA standardizedincsens1;
SET ana.stratifiedweightssens1;
	BY year;
	*Going to output this variable which will contain a year's standardized proportion;
	RETAIN standardprop;

	IF first.year THEN DO;
			standardprop = incidenceperc * proportion;
			*multiply the incidence proportion times 100 with the probability from the 2010 data

			incidenceprop100 = incidence proportion of LARC insertions for the age and region
			strata of the year we are wanting to standardize

			proportion = proportion of the population of 2010 in that age and region strata;
			END;
		ELSE DO;
			standardprop = standardprop + (incidenceperc * proportion);
			*Add each year probability;
			END;

	IF last.year THEN DO;
		standardprop = standardprop + (incidenceperc * proportion);
		OUTPUT;
		END;
RUN;
*Keep just the year and standardized incidence proportion
All other variables reflect the specific agexregion strata that they were pulled from
and do not reflect the year-level information.
Also create a rounded stanadrdized proportion estimate;
DATA ana.standardizedincsens1;
SET standardizedincsens1 (KEEP = year standardprop);
	standardpropround = round(standardprop, 0.01);
	standardper1000round = round(10 * standardprop, 0.1);
RUN;

*Round incidence prop for simplicity when reading;
DATA out.overallcrudesens1;
SET out.overallcrudesens1;
	incidencepercround = round(incidenceperc, 0.01);
	incidenceper1000round = round(10 * incidenceperc, 0.1);
RUN;

/****************************************************************************
Create the dataset that we would like to output.
****************************************************************************/

PROC SQL;
	CREATE TABLE out.finalsens1 AS
	SELECT a.year, a.nlarc, a.total, a.incidencepercround, a.incidenceper1000round,
	b.standardpropround, b.standardper1000round
	FROM out.overallcrudesens1 as a FULL JOIN ana.standardizedincsens1 as b
	ON a.year = b.year
	;
	QUIT;
PROC PRINT DATA = out.finalsens1;
	VAR year incidenceper1000round standardper1000round;
RUN;

/***************************************************************************
Create the descriptive dataset of the population for this sensitivity
analysis.
****************************************************************************/

%TABLE1(out.firstlarcenrl_sens4);

********************************************************************************************;




/*

STOPPED EDITING HERE

NEED TO CHECK THE LIBRARIES THAT DATASETS ARE POINTING TO.

*/






/****************************************************************************
SENSITIVITY ANALYSIS 2 - Change the HCPCS gap.

HCpc gap macro was written in the identify outpatient LARC insertion file
****************************************************************************/


/* For sensitivty analysis, we are testing a gap of 60 days*/

%hcpcgap(cohort_outptserv5, hcpc_formerge_60, 60);

/* Merge new hcpc dataset to first*/

*Merge hcpc to first larc, then that merged dataset to cpt rem;
%mergedata(hcpc_formerge_60, first_larc, first_larc_hcpc_sens2, hcpc_gap); 
*Merge removals to hcpc_larc;
%mergedata(larc_removals_merge_30, first_larc_hcpc_sens2, first_larc_hcpc_cptrem_sens2, cptrem_svcdate); 

*make tabulations easier; 
data first_larc_hcpc_cptrem_sens3;
set first_larc_hcpc_cptrem_sens2;
	*bc hcpc and cpt datasets were merged to 1)hcpc matches and 2) cpt removals, respectively,
	and absence of a flag means that there was not a match or was not a removal within 30 days
	so can be coded to zero; 
	if hcpc_proc1 ="" then hcpc_cpt_match=0;
	if cptrem_proc1 ="" then larc_remove_flag=0;
run; 

data sens2_formerge;
set first_larc_hcpc_cptrem_sens3; 
	where hcpc_cpt_match=1 & larc_remove_flag=0;
run;

*Merge to denominator; 

 %numdenmerge(sens2_formerge, enrlstratalong, firstlarcenrl_sens2);

*after data processing, final dataset is actually firstlarcenrl_sens24; 
 proc freq data=firstlarcenrl_sens24;
 tables larc_insert;
 run;

/****************************************************************************/








/**************************************************************************
SENSITIVITY ANALYSIS 3 - LARC removal gap
****************************************************************************/

*Info run from identify larc outpatient, but copied here;
/*
data removals_test (keep=svcdate firstinsert cpt_gap rem30 rem60);
set larc_removals2;
	where removal_flag=0;
	if -60<= cpt_gap <=-31 then rem30=1;
	else rem30=0;
	if -90<= cpt_gap <=-61 then rem60=1;
	else rem60=0;
run;


proc freq data=removals_test;
	tables rem30 rem60;
run; 

/**********************************************************************                                                                                                                                     
                                  Cumulative    Cumulative                                            
rem60    Frequency     Percent     Frequency      Percent                                             
----------------------------------------------------------                                            
    0         760       88.2            760        88.2                                               
    1         102       11.8            862       100.0    

                                  Cumulative    Cumulative                                            
rem90    Frequency     Percent     Frequency      Percent                                             
----------------------------------------------------------                                            
    0         809       93.9            809        93.9                                               
    1          53        6.1            862       100.0                                               
                                                          

 If we had updated our definition to 60 days, we might have caught 102 additional removals, 90 days, 155.

 We also need to check how this would've merged to cpts though. Run cptgap macro and merge macro to test this */

*60 day gap;
 %cptgap(cohort_outptserv5, larc_removals_merge_60, -60);

 *Merge to first larc insertion; 
 options mprint;
 %mergedata(larc_removals_merge_60, first_larc, first_larc_cpt60, cptrem_svcdate); 

proc freq data=first_larc_cpt60;
	tables larc_remove_flag;
run;

/*
                                             Cumulative    Cumulative                                 
larc_remove_flag    Frequency     Percent     Frequency      Percent                                  
---------------------------------------------------------------------                                 
               1        2113      100.0           2113       100.0     

91 actually merged on (meaning 11 were duplicates)
*/

*90 day gap; 

 %cptgap(cohort_outptserv5, larc_removals_merge_90, -90);

 *Merge to first larc insertion;
%mergedata(larc_removals_merge_90, first_larc, first_larc_cpt90, cptrem_svcdate);

proc freq data=first_larc_cpt90;
tables larc_remove_flag;
run;

/*
                                            Cumulative    Cumulative                                 
larc_remove_flag    Frequency     Percent     Frequency      Percent                                  
---------------------------------------------------------------------                                 
               1        2158      100.0           2158       100.0   

136 merged on, meaning 19 were duplicates
*/ 


/****************************************************************************/





/****************************************************************************
SENSITIVITY ANALYSIS 4 - Vary the continuous enrollment criteria.

- Need to have run the enrollment file before this so that have access
to the macros from there -- this is file 2.
****************************************************************************/

*Get the number of individuals identified in the primary analysis enrollment
criteria - 30 day continuous enrollment, 7 day gap;
*Get the number of unique people identified.;
PROC SQL;
	SELECT COUNT (DISTINCT enrolid)
	FROM enrlprimary
	;
	QUIT;
*Get the number of qualifying enrollment periods identified;
PROC SQL;
	SELECT COUNT (enrolid)
	FROM enrlprimary
	;
	QUIT;

*30 day continuous enrollment, 30 day gap;
%contenrl(enrl, enrl3030gap, 30, 30);
*Get the number of unique people identified.;
PROC SQL;
	SELECT COUNT (DISTINCT enrolid)
	FROM enrl3030gap
	;
	QUIT;
*Get the number of qualifying enrollment periods identified;
PROC SQL;
	SELECT COUNT (enrolid)
	FROM enrl3030gap
	;
	QUIT;

*30 day continuous enrollment, 1 day gap;
%contenrl(enrl, enrl130gap, 1, 30);
*Get the number of unique people identified.;
PROC SQL;
	SELECT COUNT (DISTINCT enrolid)
	FROM enrl130gap
	;
	QUIT;
*Get the number of qualifying enrollment periods identified;
PROC SQL;
	SELECT COUNT (enrolid)
	FROM enrl130gap
	;
	QUIT;

*14 day continuous enrollment, 1 day gap;
%contenrl(enrl, enrl114gap, 1, 14);
*Get the number of unique people identified.;
PROC SQL;
	SELECT COUNT (DISTINCT enrolid)
	FROM enrl114gap
	;
	QUIT;
*Get the number of qualifying enrollment periods identified;
PROC SQL;
	SELECT COUNT (enrolid)
	FROM enrl114gap
	;
	QUIT;

/****************************************************************************/



