/****************************************************************************
Calculate the stratified incidence proportions over each region and then
over the age groups within each region.
****************************************************************************/

*Need to calculate the stratified dataset so that we can merge it with the
cross-classified (agexregion) probabilities in 2010 so that we can 
standardize the incidence estimates.;

*Create macro that calculates the year-specific age-stratified estimates of
incidence;
%MACRO agewnregionsens1(dataset, year);
	*Subset the dataset to that of interest;
	DATA restrict;
	SET &dataset;
		WHERE atrisk = 1 & year = &year;
	RUN;

	*Create all the cross-classified tables to get the nlarc insertions for total year;
	PROC FREQ DATA = restrict NOPRINT;
		TABLES agecat * larc_insert / OUT = agelarc;
	RUN;

	*Re-format the datasets so that they contain the information that we can join together for each year;
	DATA agelarc; SET agelarc; year = &year; RUN;

	*Separate the larc insertion rows from the non-larc rows;
	DATA alllarc1;
	SET agelarc;
		WHERE larc_insert = 1;
		RENAME count = nlarc; 
		DROP percent; *Do not think that this is necessary and confusing which percent references;
	RUN;
	DATA alllarc0;
	SET agelarc;
		WHERE larc_insert = 0;
		RENAME count = nnolarc;
	RUN;

	*Merge them back together with the desired information;
	PROC SQL;
		CREATE TABLE alllarc2 AS 
		SELECT a.year, a.agecat, a.nlarc, b.nnolarc 
		FROM alllarc1 as a LEFT JOIN alllarc0 as b
		ON a.year = b.year AND a.agecat = b.agecat;
		QUIT;

	DATA region&year;
	SET alllarc2;
		total = nlarc + nnolarc;
		incidenceperc = 100 * nlarc / total;
		incidencepercround = round(incidenceperc, 0.01);
		DROP nnolarc;
	RUN;

	PROC DELETE DATA = agelarc;
	PROC DELETE DATA = alllarc1;
	PROC DELETE DATA = alllarc0;
	PROC DELETE DATA = alllarc2;
	PROC DELETE DATA = restrict;
	RUN;
%MEND agewnregionsens1;
