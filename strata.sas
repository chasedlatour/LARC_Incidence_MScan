/*************************************************************************************************
Create a macro that identifies the stratifying variables of interest - age and terr. Originally,
this focused on year-level incidence, but we now focus on month-level.
INPUT -- 
- dataset - The input dataset that want to identify the age and region values in. This should have
periods of continuous enrollment identified - 1 row each.
- enrol - Name of the dataset with month-level enrollment information, such as enrl
- what the final, wide (1 column for each month's age and terr) dataset should be named
- what the final, long (1 row for each calendar year for a continuous enrollment period) dataset 
should be named
**************************************************************************************************/

%MACRO strata(dataset, enrol, output_long);

	*Merge the continuous enrollment period dataset with the dataset with month-level information on
	enrollment to extract the age and region information;
	PROC SQL;
		CREATE TABLE fulldatamerge AS 
		SELECT b.enrolid, a.start, a.end, a.period, b.dtstart, b.dtend, b.year, b.age, b.region, b.egeoloc, b.terr
		FROM &dataset as a left join &enrol as b
		ON a.enrolid = b.enrolid and a.start <= b.dtstart <= a.end and a.start ne .;
		*AND statement removes month-level enrollment periods that are not within the 
			continuous enrollment period on that row;
		QUIT;
	*Sort the data by enrollee id, year of enrollment for that month-level variable and the
	start date of the month-level enrollment information;
	PROC SORT DATA = fulldatamerge;
		BY enrolid year start;
	RUN;
	
	*Create long enrollment file where there is one row for each month within a continuous
	enrollment period;
	DATA /*out.*/&output_long; 
	SET fulldatamerge;
		month = month(dtstart);
		month_yr = PUT(dtstart,mmyyD.);
	RUN;

	*Delete the unnecessary datasets;
	PROC DELETE DATA = fulldatamerge; RUN;

%MEND strata;


