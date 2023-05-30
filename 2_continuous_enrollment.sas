
/****************************************************************************
	Name: Clara Busse, Mekhala Dissanayake, Chase Latour
	Class: EPID 766 / DPOP 766
	Submit Date: 20210223
	Purpose: Project - Identify periods of continuous enrollment

	- This program will be able to run with an %include macro
	Program path:
		/mnt/files/users/cdlatour/project
	Input paths:	
		/mnt/files/class/random1pct
	Output path:	
		/mnt/files/users/cdlatour/project
*****************************************************************************/

/*Comment out so that we can call these from the overall project file --

This is now run via the %SETUP macro. Definitely shouldn't run these.

*Map important libraries on the server using REMOTE SUBMIT (running man on a notepad button);
libname data '/mnt/files/class/random1pct' access=readonly;
libname share '/mnt/files/class/share' access=readonly;	
libname outproj '/mnt/files/class/projects/cbmdcl';

*Map local mirrors for all remote libraries using LOCAL SUBMIT (plain ol' running man button, or F3);
libname ldata slibref=data server=server;
libname lshare slibref=share server=server;
libname loutproj slibref=outproj server=server;
libname lwork slibref=work server=server;

*/

**********************************************************************
Identify periods of continuous enrollment for each individual.
**********************************************************************/

*Run the macro for each of the included study periods;
%enr(2009);
%enr(2010);
%enr(2011);
%enr(2012);
%enr(2013); 
%enr(2014);
%enr(2015);
%enr(2016);
%enr(2017); 
%enr(2018);
%enr(2019);
%enr(2020);

**Now, set these records for all years of interest into one dataset, 
with one record per person per month with >1 day enrolled.;
proc sql;
	create table enrl as
	select * from enroll2009
	outer union corr
	select * from enroll2010
	outer union corr
	select * from enroll2011
	outer union corr
	select * from enroll2012
	outer union corr
	select * from enroll2013
	outer union corr
	select * from enroll2014
	outer union corr
	select * from enroll2015
	outer union corr
	select * from enroll2016
	outer union corr
	select * from enroll2017
	outer union corr
	select * from enroll2018
	outer union corr
	select * from enroll2019
	outer union corr
	select * from enroll2020
	;
	quit;

*Create the terr variable from Alan Kinlaw's code to describe the geographic territoeis for each enrollee;
data enrl;
set enrl;
	if egeoloc in ("01","02","03","10","14","15","21","29","30","40","45","50","51","60","") then terr="NON-SPEC";
	else if egeoloc = "04" then terr = "CT";
	else if egeoloc = "05" then terr = "ME";
	else if egeoloc = "06" then terr = "MA";
	else if egeoloc = "07" then terr = "NH";
	else if egeoloc = "08" then terr = "RI";
	else if egeoloc = "09" then terr = "VT";
	else if egeoloc = "11" then terr = "NJ";
	else if egeoloc = "12" then terr = "NY";
	else if egeoloc = "13" then terr = "PA";
	else if egeoloc = "16" then terr = "IL";
	else if egeoloc = "17" then terr = "IN";
	else if egeoloc = "18" then terr = "MI";
	else if egeoloc = "19" then terr = "OH";
	else if egeoloc = "20" then terr = "WI";
	else if egeoloc = "22" then terr = "IA";
	else if egeoloc = "23" then terr = "KS";
	else if egeoloc = "24" then terr = "MN";
	else if egeoloc = "25" then terr = "MO";
	else if egeoloc = "26" then terr = "NE";
	else if egeoloc = "27" then terr = "ND";
	else if egeoloc = "28" then terr = "SD";
	else if egeoloc = "31" then terr = "DC";
	else if egeoloc = "32" then terr = "DE";
	else if egeoloc = "33" then terr = "FL";
	else if egeoloc = "34" then terr = "GA";
	else if egeoloc = "35" then terr = "MD";
	else if egeoloc = "36" then terr = "NC";
	else if egeoloc = "37" then terr = "SC";
	else if egeoloc = "38" then terr = "VA";
	else if egeoloc = "39" then terr = "WV";
	else if egeoloc = "41" then terr = "AL";
	else if egeoloc = "42" then terr = "KY";
	else if egeoloc = "43" then terr = "MS";
	else if egeoloc = "44" then terr = "TN";
	else if egeoloc = "46" then terr = "AR";
	else if egeoloc = "47" then terr = "LA";
	else if egeoloc = "48" then terr = "OK";
	else if egeoloc = "49" then terr = "TX";
	else if egeoloc = "52" then terr = "AZ";
	else if egeoloc = "53" then terr = "CO";
	else if egeoloc = "54" then terr = "ID";
	else if egeoloc = "55" then terr = "MT";
	else if egeoloc = "56" then terr = "NV";
	else if egeoloc = "57" then terr = "NM";
	else if egeoloc = "58" then terr = "UT";
	else if egeoloc = "59" then terr = "WY";
	else if egeoloc = "61" then terr = "AK";
	else if egeoloc = "62" then terr = "CA";
	else if egeoloc = "63" then terr = "HI";
	else if egeoloc = "64" then terr = "OR";
	else if egeoloc = "65" then terr = "WA";
	else if egeoloc = "97" then terr = "PR";
	else if egeoloc = "98" then terr = "VI"; /*Virgin Islands. Not in Alan's code*/
run;

*Code to get the number of people prior to applying continuous enrollment
	criteria for the flow chart for cohort building.

Want to be able to reference this later - should print into the log;
PROC SQL;
	SELECT COUNT(DISTINCT enrolid) AS total_people
	FROM enrl
	;
	QUIT;

	

*Delete all the enrollment datasets from the working directory once
	merged;
PROC DELETE DATA = enroll2009; RUN;
PROC DELETE DATA = enroll2010; RUN;
PROC DELETE DATA = enroll2011; RUN;
PROC DELETE DATA = enroll2012; RUN;
PROC DELETE DATA = enroll2013; RUN;
PROC DELETE DATA = enroll2014; RUN;
PROC DELETE DATA = enroll2015; RUN;
PROC DELETE DATA = enroll2016; RUN;
PROC DELETE DATA = enroll2017; RUN;
PROC DELETE DATA = enroll2018; RUN;
PROC DELETE DATA = enroll2019; RUN;
PROC DELETE DATA = enroll2020; RUN;




/*************************************************************************************************
Create the continuous enrollment file, or files, of interest.
**************************************************************************************************/


*Make the continuous enrollment file for the primary analysis of interest
	7-day gap and 180-day continuous enrollment period;
options mprint;
%contenrl(enrl, enrlprimary, 7, 180);

/* Code to get the number of people in the denominator total after applying enrollment criteria

Should print in log*/
PROC SQL;
	SELECT COUNT(DISTINCT enrolid) AS claims_after_enrl
	FROM /*temp.*/enrlprimary
	;
	QUIT;


/*************************************************************************************************
Identify the age and terr information of interest for stratifying analyses.

Specifically, we want to create a long dataset where each row is a month of a qualifying 
	continuous enrollment period

Use the macro %strata()
**************************************************************************************************/

options mprint;
%strata(enrlprimary, enrl, enrlstratalong);










