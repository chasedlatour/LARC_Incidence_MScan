
/***************************************************************************
Calculate the incidence proportion of first LARC insertions over the 
enrollment period.

This code is just slightly modified from the code used to create the output
for the primary analyses. The main difference is that there is no 
differentiation by LARC type.
****************************************************************************/


*Create macro to build a dataset for each year of LARC insertions to calculate
proportions. Outputs a dataset for each year and then will later merge;
%MACRO nlarcyearsens1 (dataset, year);

	*Create the categorized age variable;
	DATA &dataset;
	SET &dataset;
		IF 15 <= age < 20 THEN agecat = 1;
			ELSE IF 20 <= age < 25 THEN agecat = 2;
			ELSE IF 25 <= age < 30 THEN agecat = 3;
			ELSE IF 30 <= age < 35 THEN agecat = 4;
			ELSE IF 35 <= age < 40 THEN agecat = 5;
			ELSE IF 40 <= age < 45 THEN agecat = 6;
			ELSE IF 45 <= age <= 49 THEN agecat = 7;
	RUN;

	* Categorizations made from above code --
	agecat = 1 -- 15-19
	agecat = 2 -- 20-24
	agecat = 3 -- 25-29
	agecat = 4 -- 30-34
	agecat = 5 -- 35-39
	agecat = 6 -- 40-44
	agecat = 7 -- 45-49
	;

	*Output datasets for each of the years for overall LARC numbers and individual LARC types;
	PROC FREQ DATA = &dataset NOPRINT;
		WHERE year = &year & atrisk = 1;
		TABLES larc_insert / OUT= prop&year.;
	RUN;

	*Create a variable that indicates which year the data are drawn from;
	DATA prop&year.; SET prop&year.; year = &year; RUN;

%MEND nlarcyearsens1;
