*Get LARC information for supplement:
1) Amount of time between start of enrollment and LARC insertion
2) Average length of enrollment among those with and without LARC insertions; 

*Code provided by Alan for the class;
options ps=500 ls=220 nodate nocenter nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes mprint;proc template;edit Base.Freq.OneWayList;edit Frequency;format=8.0;end;edit Percent;format = 5.1;end;edit CumPercent;format = 5.1;end;end;run;
 
*Code that tells SAS to pull all the macros that we have in our macros folder;
options source source2 msglevel=I mcompilenote=all mautosource mprint
     sasautos=(SASAUTOS "/local/projects/marketscanccae/larc_descrip/programs/macros");

*Run the set-up macro that Virginia provided for all projects completed on the
	 N2 server. This facilitates running the analysis on the full MarketScan
	 sample.;
%setup(full, 1_primary_analysis, saveLog=Y);


*Map local mirrors for all remote libraries using LOCAL SUBMIT (plain ol' running man button, or F3);
*libname ldata slibref=data server=server;
*libname lshare slibref=share server=server;
*libname loutproj slibref=outproj server=server;
libname lwork slibref=work server=server;
libname lout slibref=out server=server;

data cohort;
set out.month_primary_cohort4;
run; 

*Create dataset for larc insertions only, create variable that measures amount of time
between enrollment start and larc insertion date;

data larcdate;
set cohort;
	insert_enrollment=start-svcdate;
	enrollment_time = end-start;
where larc_insert=1;
run; 

*Statistics for supplementary table; 
proc univariate data=larcdate;
var insert_enrollment enrollment_time;
run; 



*Run enrollment variable among those without larc insertions; 
data nolarc;
set cohort;
enrollment_time = end-start;
where larc_insert=0;
run; 

proc univariate data=nolarc;
var enrollment_time;
run; 


*Note 7/5/23
We discovered there are 38 people who have a positive value for larc_enrollment, indicating their LARC insertion occurred before their qualifying enrollment period
This happend because when merging insertions onto enrollment, we only matched by year and month, not by exact date.
The people with insertions before their enrollment either had a gap >7 days between enrolled periods or had their insertion during a enrollment period that didn't technically meet our criteria.
E.g., we have enrollment periods 2,5 but not the ones in between and record an insertion claim in between enrollment periods -- likely during an enrollment period that didn't meet our definition of
6 months with 7 days in between. 

Taking out these 38 people would not change our results and these people had their LARC covered even without meeting our enrollment criteria. Therefore, we are leaving this as as. 

*look into those with insertions before enrollment;
data larcpos (keep= enrolid start end period svcdate);
set larcdate;
where insert_enrollment>0;
run;

data check_larc (keep= enrolid start end period svcdate);
set cohort; 
where enrolid in (57166801, 738975301, 739569801, 865294301, 1009083201, 1597852801);
run; 

proc sort data=check_larc;
by enrolid start end period;
run; 



/**Code we didn't end up using:


*Merge it so that each row is a continuous enrollment period;
proc sql;
	create table out.cont_enrl_row as
	select enrolid, start, end, svcdate
	from out.month_primary_cohort4
	group by enrolid, start
	; quit;



data test;
set out.month_primary_cohort4 (keep = enrolid dtstart start svcdate);
	diff = start - dtstart;
	insert_enrollment=start-svcdate;
run;

proc univariate data=test;
	var diff insert_enrollment;
run;

data larcrow;
set out.cont_enrl_row;
where not missing(svcdate);
run; 


data larcrow2;
set larcrow;
enrollment_time = end-start;
insert_enrollment=start-svcdate;
run; 

proc univariate data=larcrow2;
var enrollment_time insert_enrollment;
run;

*Same results as in main cohort without rolling up enrollment periods 

proc contents data=larcrow;
run; 

*/
