
*Create macro to build a dataset for each year of LARC insertions to calculate
proportions. Outputs a dataset for each year and then will later merge;
%MACRO nlarcyear (dataset, year);

	*Create the categorized age variable;
	DATA dataset2;
	SET out.firstlarcenrl4; /*Pulling from prior output data file*/
		WHERE atrisk = 1;
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
	RUN;

	* Categorizations made from above code --
	agecat = 1 -- 15-19
	agecat = 2 -- 20-24
	agecat = 3 -- 25-29
	agecat = 4 -- 30-34
	agecat = 5 -- 35-39
	agecat = 6 -- 40-44
	agecat = 7 -- 45-49
	agecat = 8 -- 50-54
	agecat = 9 -- 55-59
	agecat = 10 -- 60-64
	;

	*Output datasets for each of the years for overall LARC numbers and individual LARC types;
	PROC FREQ DATA = dataset2 NOPRINT;
		WHERE year = &year & atrisk = 1;
		TABLES larc_insert / OUT= prop&year.;
		TABLES hcpcimp / OUT = hcpcimp&year.;
		TABLES hcpchiud / OUT = hcpchiud&year.;
		TABLES hcpcnhiud / OUT = hcpcnhiud&year.;
	RUN;

	*Create a variable that indicates which year the data are drawn from;
	DATA prop&year.; SET prop&year.; year = &year; RUN;
	DATA hcpcimp&year.; SET hcpcimp&year. (RENAME = (count = nhcpcimp)); year = &year; IF hcpcimp ne 1 THEN DELETE; RUN;
	DATA hcpchiud&year.; SET hcpchiud&year. (RENAME = (count = nhcpchiud)); year = &year; IF hcpchiud ne 1 THEN DELETE; RUN;
	DATA hcpcnhiud&year.; SET hcpcnhiud&year. (RENAME = (count = nhcpcnhiud)); year = &year; IF hcpcnhiud ne 1 THEN DELETE; RUN;

	*Join all of the datasets so that there is a column for each LARC type, indicating n for each;
	PROC SQL;
		CREATE TABLE propsum&year AS
		SELECT a.*, b.nhcpcimp, c.nhcpchiud, d.nhcpcnhiud
		FROM prop&year. as a 
		LEFT JOIN hcpcimp&year. as b 
		ON a.year = b.year
		LEFT JOIN hcpchiud&year. as c
		ON a.year = c.year
		LEFT JOIN hcpcnhiud&year. as d
		ON a.year = d.year;
		QUIT;

		*Delete unnecessary intermediate datasets;
	PROC DELETE DATA = prop&year.; RUN;
	PROC DELETE DATA = hcpcimp&year.; RUN;
	PROC DELETE DATA = hcpchiud&year.; RUN;
	PROC DELETE DATA = hcpcnhiud&year.; RUN;

%MEND nlarcyear;
