
options ps=500 ls=220 nodate nocenter nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes mprint;proc template;edit Base.Freq.OneWayList;edit Frequency;format=8.0;end;edit Percent;format = 5.1;end;edit CumPercent;format = 5.1;end;end;run;
 
/****************************************************************************
	Name: Clara Busse, Mekhala Dissanayake, Chase Latour
	Class: EPID 766 / DPOP 766
	Submit Date: 20210223
	Purpose: Identify the outpatient LARC insertions in the outpatient services file.
	Program path:
		/local/projects/marketscanccae/larc_descrip/programs/2_outpatient_larc.sas
	Input paths:	
		/local/data/master/marketscanccae/&sample/ccae
	Output path for data:	
		/local/projects/marketscanccae/larc_descrip/data
*****************************************************************************/
/*Comment out for run from master file


*Map local mirrors for all remote libraries using LOCAL SUBMIT (plain ol' running man button, or F3);
libname ldata slibref=data server=server;
libname lshare slibref=share server=server;
libname loutproj slibref=outproj server=server;
libname lwork slibref=work server=server;




/*Merged all outpatient services claims over the years, 2009-2018, regardless of enrollment,
limiting to services between 15 and 49 among female patients

*Output 25,148,492 rows. - 3/4/21*/

proc sql;
        create table cohort_outptserv as
        select *, "O" as filetype /* O = outpatient services file */
                from 
					(
						select enrolid, proc1, proctyp, age, sex, svcdate
                        from raw.outptserv2009 /*previously data.*/
						where 15 <= age <= 54 and sex = '2'

				outer union corresponding
						select enrolid, proc1, proctyp, age, sex, svcdate
                        from raw.outptserv2010 /*previously data.*/
						where 15 <= age <= 54 and sex = '2'

				outer union corresponding
                        select enrolid, proc1, proctyp, age, sex, svcdate
                        from raw.outptserv2011 /*previously data.*/
						where 15 <= age <= 54 and sex = '2'

				outer union corresponding
                        select enrolid, proc1, proctyp, age, sex, svcdate
                        from raw.outptserv2012 /*previously data.*/
						where 15 <= age <= 54 and sex = '2'

				outer union corresponding
                        select enrolid, proc1, proctyp, age, sex, svcdate
                        from raw.outptserv2013 /*previously data.*/
						where 15 <= age <= 54 and sex = '2'

				outer union  corresponding 
                        select enrolid, proc1, proctyp, age, sex, svcdate
                        from raw.outptserv2014 /*previously data.*/
						where 15 <= age <= 54 and sex = '2'

				outer union  corresponding 
                        select enrolid, proc1, proctyp, age, sex, svcdate
                        from raw.outptserv2015 /*previously data.*/
						where 15 <= age <= 54 and sex = '2'

				outer union  corresponding 
                        select enrolid, proc1, proctyp, age, sex, svcdate
                        from raw.outptserv2016 /*previously data.*/
						where 15 <= age <= 54 and sex = '2'

				outer union  corresponding 
                        select enrolid, proc1, proctyp, age, sex, svcdate
                        from raw.outptserv2017 /*previously data.*/
						where 15 <= age <= 54 and sex = '2'

				outer union  corresponding 
                        select enrolid, proc1, proctyp, age, sex, svcdate
                        from raw.outptserv2018 /*previously data.*/
						where 15 <= age <= 54 and sex = '2'

				outer union  corresponding 
                        select enrolid, proc1, proctyp, age, sex, svcdate
                        from raw.outptserv2019 /*previously data.*/
						where 15 <= age <= 54 and sex = '2'

				outer union  corresponding 
                        select enrolid, proc1, proctyp, age, sex, svcdate
                        from raw.outptserv2020 /*previously data.*/
						where 15 <= age <= 54 and sex = '2'
	)
        order by enrolid;

		quit;



*Run the procedures() macro to identify all outpatient LARC insertions
		File can be found in ProjLib/programs/macros;
options mprint;
%procedures(library=work, dataset=cohort_outptserv, OUTPUT=cohort_outptserv2);

PROC DATASETS LIB=WORK NOLIST NODETAILS; DELETE COHROT_OUTPTSERV; RUN; QUIT;
/* Look at the breakdown of the codes
PROC FREQ DATA = cohort_outptserv2;
	TABLES CPTINS CPTREM CPTREINS HCPCIMP HCPCHIUD HCPCNHIUD;
RUN;

25145632 - rows in the dataset

19576 - CPT insertion codes
2860 - HCPCS for implants
11566 - HCPCS for hormonal IUDs
2419 - HCPCS for non-hormonal IUDs
*/



*Remove insertions from 2009 because they are not of interest in our study (we only need removals from 2009;
*We want to do this before we sort on type;
/*
proc freq data=cohort_outptserv2;
tables cptins;
run; 
*/
*19576 insertions;


data cohort_outptserv2_;
set cohort_outptserv2;
year=year(svcdate);
month=month(svcdate);
if year=2009 and cptins=1 then delete;
run; 

PROC DATASETS LIB=WORK NOLIST NODETAILS; DELETE COHROT_OUTPTSERV2; RUN; QUIT;
/*
proc freq data=cohort_outptserv2_;
tables cptins;
run;
*18,312 insertions;

proc freq data=cohort_outptserv2_;
tables year*cptins;
run; 
*/
*Create dataset of just LARC related codes to identify the numerator;
DATA cohort_outptserv3;
	SET cohort_outptserv2_;
	WHERE CPTINS = 1 OR CPTREM = 1 OR CPTREINS = 1 OR
	HCPCIMP = 1 OR HCPCHIUD = 1 OR HCPCNHIUD = 1;

	*Create  flag for the procedure type;

	IF CPTINS = 1 THEN type = 1;
		ELSE IF CPTREM = 1 THEN type = 2;
		ELSE IF CPTREINS = 1 THEN type = 3;
		*We want to make sure when we sort by this variable, the HCPC code is last, but also dont want to identify
		this as a cpt variable (which would happen if we made this missing; 
		ELSE type = 777;

RUN;

PROC DATASETS LIB=WORK NOLIST NODETAILS; DELETE COHROT_OUTPTSERV2_; RUN; QUIT;
*47,954 observations in this dataset;
/* Check;
proc sort data=cohort_outptserv3;
by year;
run; */

/*Update 10/27/22
 58684 observations read from the data set WORK.COHORT_OUTPTSERV2_.
      WHERE (CPTINS=1)
*/ 

PROC SORT DATA = cohort_outptserv3 OUT = cohort_outptserv4;
	BY ENROLID TYPE SVCDATE;
RUN;

PROC DATASETS LIB=WORK NOLIST NODETAILS; DELETE COHROT_OUTPTSERV3; RUN; QUIT;


DATA cohort_outptserv5;
	SET cohort_outptserv4;
	BY enrolid type svcdate;
	
	retain firstinsert;

	*Identifying the first CPT insertion code and then will
	use that to 1) identify a corresponding HCPC and 2) identify removals within 30 days. If someone doesnt have
	a corresponding HCPC for the CPT code, they will not be included
	in the cohort - Going to flag those individuals for now.;

	*Because of the way we specified the type variable, if there is an insertion it will be first
	to be first. So, the first service date will be in reference to an insertion;
	if first.enrolid then do;
		if cptins=1 then firstinsert = svcdate;
	 *If there are no insertions (so just a removal or an unassigned hcpc), an insertion wont be first
		so we will assign everything else as missing;
		else firstinsert=.;

	 *Flag variable for the first_larc_insertion, everything else is zero; 
		if cptins=1 then first_larc_insertion=1;
		else first_larc_insertion=0;

	 *Also flag if the first observation in the period is a removal or a reinsertion, not an insertion
		again, bc of the way type was sorted, if an insertion is present it will show up first;
		if cptrem=1 then first_rem=1;
		else cptrem=0; 
		if cptreins=1 then first_reins=1;
		else cptreins=0; 
		end;
	else do;
		*For all other rows by enrolid, copy the value for the first insertion date; 
		firstinsert = firstinsert;
		*Any subsequent insertions are not the first insertion; 
		first_larc_insertion=0; 
		end;

	FORMAT firstinsert MMDDYY10.;

	*Calculating the gap over all of the service dates and then going
	to specify to those of interest with flag variables.;
if HCPCIMP = 1 OR HCPCHIUD = 1 OR HCPCNHIUD = 1 then do;
	hcpc_gap = svcdate - firstinsert;
	*For hcpcs, it does not matter to us if a hcpc comes 30 days after or before, so
	we calculate the absolute value to make things easier;
	hcpc_gap = abs(hcpc_gap);
end;  
 if cptrem =1 then do;
 *for cpt codes, it really does matter if a removal is before or after an insertion
 if removals before, we want to flag so we can identify if a first larc is truly a first larc
 we do not care about removals after; 
	cpt_gap = svcdate-firstinsert; 
end; 
RUN;


 

*Output dataset as a separate dataset to run sensitivity analyses on HCPC code;


/*data out.cohort_outptserv5;*/
/*set cohort_outptserv5;*/
/*run; */
/*
proc freq data=cohort_outptserv5;
tables cptins*first_larc_insertion;
run; 
*Of the 18,312 larc insertions in the period, 2230 are 16,082 are flagged as first insertions (2230 are subsequent insertions);

*Update 10/27/22:

Of the 22, 687 larc insertions in the period, 19545 are flagged as first insertions while 3142 are subseqent insertions 

/*Check that codes other than insertion codes did not get flagged as a first insertion;
proc freq data=cohort_outptserv5;
tables first_larc_insertion;
where cptrem=1 | cptreins=1 | HCPCIMP = 1 OR HCPCHIUD = 1 OR HCPCNHIUD = 1;
run;


proc freq data=cohort_outptserv5;
tables first_larc_insertion;
where cptins=1;
run;

*Most are first larc insertions within the period

*/

*From that dataset, we are just going to pull out those rows where a HCPC
code exists;

/*******************************************
*Deal with HCPC gaps**

Use the %hcpcgap() macro saved in the
macros folder.
*****************************************/

options mprint;
*30 day gap = original decision (will vary for sensitivity analysis)
Updated to 180 days after; 

%hcpcgap(dataset=cohort_outptserv5, output=hcpc_formerge_180, gap=180);

*Number with 30 day gap
16927

*Number with 180 day gap 
17271
*there are people with a gap sum of >1 where there are multiple hcpc codes that match the first larc insertion
upon visual inspection of data, it appears that when people do have these multiple codes, they are the same
we are going to make the assumption that they are the same;

/***********************************************************
*Identify removals within 30 days of insertion;

Use the %cptgap() macro in the macros folder.
*******************************************************

/*check which removals i should be looking at;
proc print data=cohort_outptserv5 (obs=20);
where cpt_gap<0 and cpt_gap ne . ;
var proc1 enrolid svcdate firstinsert cpt_gap;
run; 

*Confirmed that if the gap is negative, the removal happened before the insertion;
*/

*The gap in this macro should be a negative number (unlike hcpc gap, which uses the absolute value of the gap between service date
and larc insertion date);

*Main analysis decision is to remove insertions with a removal within 30 days; 
%cptgap(cohort_outptserv5, larc_removals_merge_180, -180);


  /* 
Basic statistics of the removal gaps

proc freq data=larc_removals2;
tables removal_flag/ missing;
run; 

10/27/22
30 day gap  
                                         Cumulative    Cumulative                         
removal_flag    Frequency     Percent     Frequency      Percent                          
-----------------------------------------------------------------                         
           0        1086       28.1           1086        28.1                            
           1        2782       71.9           3868       100.0                            
                                                                   

Most of the removals that occurred before the first insertion occurred within 30 days

180 days
                                         Cumulative    Cumulative                         
removal_flag    Frequency     Percent     Frequency      Percent                          
-----------------------------------------------------------------                         
           0         761       19.7            761        19.7                            
           1        3107       80.3           3868       100.0  

*Identify 325 more removals 
                                                                
*Previous run of data
proc univariate data=larc_removals2;
var cpt_gap;
run; 

/*Quantiles (Definition 5)                                                                              
                                                                                                      
Level         Quantile                                                                                
                                                                                                      
100% Max             0                                                                                
99%                  0                                                                                
95%                  0                                                                                
90%                  0                                                                                
75% Q3               0                                                                                
50% Median           0                                                                                
25% Q1             -49                                                                                
10%               -423                                                                                
5%                -631                                                                                
1%               -1376                                                                                
0% Min           -2332                                                                                
                       
*lots of  same day;


proc univariate data=larc_removals2;
var cpt_gap;
where removal_flag=0;
run; 



ODS PDF FILE = "/mnt/files/class/projects/cbmdcl/removals_gap_removal0.pdf" STARTPAGE=NO;
TITLE 'Histogram of gaps between removal and insertion among removals that were not flagged';

proc univariate data=larc_removals2 noprint;
histogram cpt_gap;
where removal_flag=0;
run; 
title;
ods pdf close;
*/


****************************************************************************************************************
********Merge datasets
*******************************************************************



*Game plan
Make a separate dataset that identifies first larc insertions
and merge the two separate hcpc and cpt datasets onto this dataset 
so that the information is on one line by larc insertion date and enrolid; 


data first_larc (keep = month age year enrolid proc1 proctyp svcdate cptins type firstinsert first_larc_insertion); 
set cohort_outptserv5;
	*keep only first larc insertions; 
	where first_larc_insertion=1;
run; 

proc sort data=first_larc;
	by enrolid firstinsert;
run;

/*Check -- 
proc sql;
	select count(distinct enrolid) as total_claims
	from first_larc;
	quit; 
*/
*all distinct rows, 16,082; 

/*This macro will merge whatever dataset we want (e.g., hcpcs) onto whatever substrate (e.g. , first larc insertion)
	There were duplicates in both the hcpc and cptremoval datasets (because there is only ever one first insertion, but potentially multiple hcpcs and removals)
	in this macro, we will only merge the hcpc or insertion with the smallest gap, because that is most relevant to our study question
	The datasets we will be merging have already been restricted to hcpcs within 30 days and removals within 30 days in the main analysis
	If there are two hcpcs or two removals within 30 days, this macro will pick the closest one to the larc insertion date merge

Macro in the macros folder.*/

options mprint;
*Merge hcpc to first larc;
%mergedata(hcpc_formerge_180, first_larc, first_larc_hcpc, hcpc_gap); 
*Merge removals to hcpc_larc;
%mergedata(larc_removals_merge_180, first_larc_hcpc, first_larc_hcpc_cptrem, cptrem_svcdate); 



*make tabulations easier; 
data first_larc_hcpc_cptrem2;
set first_larc_hcpc_cptrem;
	*bc hcpc and cpt datasets were merged to 1)hcpc matches and 2) cpt removals, respectively,
	and absence of a flag means that there was not a match or was not a removal within 30 days
	so can be coded to zero; 
	if hcpc_proc1 ="" then hcpc_cpt_match=0;
	if cptrem_proc1 ="" then larc_remove_flag=0;

   	IF 15 <= age < 20 THEN agecat = 1;
			ELSE IF 20 <= age < 25 THEN agecat = 2;
			ELSE IF 25 <= age < 30 THEN agecat = 3;
			ELSE IF 30 <= age < 35 THEN agecat = 4;
			ELSE IF 35 <= age < 40 THEN agecat = 5;
			ELSE IF 40 <= age < 45 THEN agecat = 6;
			ELSE IF 45 <= age <= 49 THEN agecat = 7;
			ELSE IF 50 <= age <= 54 THEN agecat = 8;
			ELSE IF 55 <= age <= 59 THEN agecat = 9;
			ELSE IF 60 <= age <= 64 THEN agecat = 10;

run;

*Table by agegroup;
/*proc freq data=first_larc_hcpc_cptrem2;*/
/*	tables agecat;*/
/*	where hcpc_cpt_match=1 & larc_remove_flag=0;*/
/*run; */

 /*agecat    Frequency     Percent     Frequency      Percent                                
-----------------------------------------------------------                               
     1        1764       12.4           1764        12.4                                  
     2        2974       21.0           4738        33.4                                  
     3        2970       20.9           7708        54.3                                  
     4        2769       19.5          10477        73.9                                  
     5        1929       13.6          12406        87.5                                  
     6        1082        7.6          13488        95.1                                  
     7         539        3.8          14027        98.9                                  
     8         139        1.0          14166        99.9                                  
     9          16        0.1          14182       100.0                                  
    10           4        0.0          14186       100.0                                  
                                                                */ 

/*proc freq data=first_larc_hcpc_cptrem2;*/
/*	tables hcpc_cpt_match;*/
/*	where agecat<9; */
/*run; */
/*10/27/22
                                                                                          
                                           Cumulative    Cumulative                       
hcpc_cpt_match    Frequency     Percent     Frequency      Percent                        
-------------------------------------------------------------------                       
             0        2834       14.5           2834        14.5                          
             1       16649       85.5          19483       100.0                          
                                                                   
/*
proc freq data=out.first_larc_hcpc_cptrem2;
tables hcpc_cpt_match larc_remove_flag;
run; 

proc freq data=out.first_larc_hcpc_cptrem2;
tables year*hcpc_cpt_match year*larc_remove_flag;
tables year*hcpc_cpt_match*hcpchiud year*hcpc_cpt_match*hcpcnhiud year*hcpc_cpt_match*hcpcimp;
run;

proc freq data=out.first_larc_hcpc_cptrem2;
tables proc1;
run; 
*/
/*
data first_larc_hcpc_cptrem3;
set first_larc_hcpc_cptrem2;
*identify insertions by cpt code: implant vs iud to see if one is missing hcpcs more than the other;
if proc1 = "58300" then ins_iud=1;
else ins_iud=0;
if proc1= "11981" then ins_impt=1;
else ins_impt=0;
run; 
*.
/*
*Both implants and IUDS have lower proportions of hcpc matches over time;
proc freq data= first_larc_hcpc_cptrem3;
tables year*ins_iud*hcpc_cpt_match year*ins_impt*hcpc_cpt_match/ missing;
run; 
*/
*Of the 16,082 first larc insertions, only 83.3% have a matching cpt code within 30 days (13,401)
*Additionally, 2022 have a removal within 30 days; 
*Change after adding  Kyleena: now 84.3% have matches;



*Final dataset
*Keep only hcpc matches and no removal;
*could get rid of condition for hcpc match if we wanted to keep that as a flag in the future; 

*Added the temp. directory so that this could be saved as a temporary dataset on the server.

This way, Virginia can run the full sample over the course of a few sessions, if needed.
(i.e., doesn't need the working directory to stay active that long

Eventually removed this temp call;

*Keep only insertions from people <55 years of age;
data first_larc_hcpc_cptrem_formerge;
set first_larc_hcpc_cptrem2; 
	where hcpc_cpt_match=1 & larc_remove_flag=0 & agecat<9;
run; 
*11,841 with cpt match and without removal code; 

*10/27/22 with 180 day lookback
*14186;


*Output main analysis numerator; 
data out.first_larc_hcpc_cptrem_formerge;
set first_larc_hcpc_cptrem_formerge;
run; 


*Output dataset without flags for cpt match so that we can run sens analysis on cpts without hcpcs; 
data out.numerator_sens_analysis;
set first_larc_hcpc_cptrem2;
where agecat<9 & larc_remove_flag=0;
run; 


/*proc delete data=cohort_outptserv; run;*/
/*proc delete data=cohort_outptserv2; run;*/
/*proc delete data=cohort_outptserv3; run;*/
/*proc delete data=cohort_outptserv4; run;*/
proc delete data=hcpc_formerge;run;
proc delete data=hcpc_formerge2;run;
proc delete data=larc_removals; run;
proc delete data=larc_removals2; run;
proc delete data=larc_removals_merge2; run;

		



/*NEXT STEPS;
Merge to enrollment!
- */



/*END*/
