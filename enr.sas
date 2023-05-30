**********************************************************************
Identify periods of continuous enrollment for each individual.
**********************************************************************;

*macro from lab 3;
%macro enr (year); 
proc sql;
     create table enroll&year. as
         select enrolid, 
				enrdet&year..dtstart,			
				enrdet&year..dtend,
				enrdet&year..age /*as age&year.*/,
				enrdet&year..region /*as region&year.*/,
				enrdet&year..egeoloc
		 from raw.enrdet&year.
		 /*from data.enrdet&year.*/ /*Was this prior ot %setup macro*/
		 where sex = '2' & 15 <= age <= 54 /*limited to females and between 15 and 54 years*/
		 /*we originally didn't eliminate based upon age. however, i think
		 that it makes sense to eliminate claims that are no longer in the
		 specified age group because they shouldn't be in the denominator

		 so, just a note that someone could be removed from the cohort if they disenroll
		 or age out of the cohort

		 we removed the rx = 1 requirement*/
         order by enrolid;
quit;

data enroll&year.;
set enroll&year.;
	year = &year.;
run;

%mend enr; 
