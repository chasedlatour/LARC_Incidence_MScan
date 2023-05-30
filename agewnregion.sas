
*Create macro that calculates the year-specific age-stratified estimates of
incidence;
%MACRO agewnregion(dataset, year);
	*Subset the dataset to that of interest;
	DATA restrict;
	SET &dataset;
		WHERE atrisk = 1 & year = &year;
	RUN;

	*Create all the cross-classified tables to get the nlarc insertions for total year;
	PROC FREQ DATA = restrict NOPRINT;
		TABLES agecat * larc_insert / OUT = agelarc;
		TABLES agecat * hcpcimp / OUT = ageimp;
		TABLES agecat * hcpchiud / OUT = agehiud;
		TABLES agecat * hcpcnhiud / OUT = agenhiud;
	RUN;

	*Re-format the datasets so that they contain the information that we can join together for each year;
	DATA agelarc; SET agelarc; year = &year; RUN;
	DATA ageimp; SET ageimp (RENAME = (count = nhcpcimp)); IF hcpcimp ne 1 THEN DELETE; RUN;
	DATA agehiud; SET agehiud (RENAME = (count = nhcpchiud)); IF hcpchiud ne 1 THEN DELETE; RUN;
	DATA agenhiud; SET agenhiud (RENAME = (count = nhcpcnhiud)); IF hcpcnhiud ne 1 THEN DELETE; RUN;

	*Join the datasets so that all the information is merged onto a LARC insertion row.;
	PROC SQL;
		CREATE TABLE alllarc AS
		SELECT a.*, b.nhcpcimp, c.nhcpchiud, d.nhcpcnhiud 
		FROM agelarc as a
		LEFT JOIN ageimp as b
		ON a.agecat = b.agecat
		LEFT JOIN agehiud as c
		ON a.agecat = c.agecat
		LEFT JOIN agenhiud as d
		ON a.agecat = d.agecat ;
		QUIT;

	*Separate the larc insertion rows from the non-larc rows;
	DATA alllarc1;
	SET alllarc;
		WHERE larc_insert = 1;
		RENAME count = nlarc; 
		DROP percent; *Do not think that this is necessary and confusing which percent references;
	RUN;
	DATA alllarc0;
	SET alllarc;
		WHERE larc_insert = 0;
		RENAME count = nnolarc;
	RUN;

	*Merge them back together with the desired information;
	PROC SQL;
		CREATE TABLE alllarc2 AS 
		SELECT a.year, a.agecat, a.nlarc, a.nhcpcimp, a.nhcpchiud, a.nhcpcnhiud, b.nnolarc 
		FROM alllarc1 as a LEFT JOIN alllarc0 as b
		ON a.year = b.year AND a.agecat = b.agecat;
		QUIT;

	DATA region&year;
	SET alllarc2;
		total = nlarc + nnolarc;
		*incidencepropround = round(100 * incidenceprop, 0.01);
		propimp = 100 * nhcpcimp / nlarc;
		*propimpround = round(propimp, 0.01);
		prophiud = 100 * nhcpchiud / nlarc;
		*prophiudround = round(prophiud, 0.01);
		propnhiud = 100 * nhcpcnhiud / nlarc;
		*propnhiudround = round(propnhiud, 0.01);
		DROP nnolarc;
	RUN;

	PROC DELETE DATA = agelarc;
	PROC DELETE DATA = ageimp;
	PROC DELETE DATA = agehiud;
	PROC DELETE DATA = agenhiud;
	PROC DELETE DATA = alllarc;
	PROC DELETE DATA = alllarc1;
	PROC DELETE DATA = alllarc0;
	PROC DELETE DATA = alllarc2;
	PROC DELETE DATA = restrict;
	RUN;
%MEND agewnregion;
