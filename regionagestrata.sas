
*Create macro for forming the dataset for a region;
%MACRO regionagestrata(dataset, region_char, region_num);

	*Create dataset with just the information from the region of interest;
	DATA region;
	SET &dataset;
		WHERE region = &region_char;
	RUN;

	*Call stratifying code for each year;
	%agewnregion(region, 2010);
	%agewnregion(region, 2011);
	%agewnregion(region, 2012);
	%agewnregion(region, 2013);
	%agewnregion(region, 2014);
	%agewnregion(region, 2015);
	%agewnregion(region, 2016);
	%agewnregion(region, 2017);
	%agewnregion(region, 2018);


	*Stack the datasets output for each year;
	PROC SQL;
		CREATE TABLE region&region_num AS
		SELECT * FROM region2010
		UNION CORR
		SELECT * FROM region2011
		UNION CORR
		SELECT * FROM region2012
		UNION CORR
		SELECT * FROM region2013
		UNION CORR
		SELECT * FROM region2014
		UNION CORR
		SELECT * FROM region2015
		UNION CORR
		SELECT * FROM region2016
		UNION CORR
		SELECT * FROM region2017
		UNION CORR
		SELECT * FROM region2018
		;
		QUIT;

	*Want to create a region variable that is numeric.;
	DATA region&region_num;
	SET region&region_num;
		region = &region_num;
	RUN;

	*Delete unnecessary datasets;
	PROC DELETE DATA = region; RUN;

%MEND regionagestrata;
