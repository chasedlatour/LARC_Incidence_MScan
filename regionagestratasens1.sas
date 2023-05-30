
*Create macro for forming the dataset for a region;
%MACRO regionagestratasens1(dataset, region_char, region_num);

	*Create dataset with just the information from the region of interest;
	DATA region;
	SET &dataset;
		WHERE region = &region_char;
	RUN;

	*Call stratifying code for each year;
	%agewnregionsens1(region, 2010);
	%agewnregionsens1(region, 2011);
	%agewnregionsens1(region, 2012);
	%agewnregionsens1(region, 2013);
	%agewnregionsens1(region, 2014);
	%agewnregionsens1(region, 2015);
	%agewnregionsens1(region, 2016);
	%agewnregionsens1(region, 2017);
	%agewnregionsens1(region, 2018);


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

	DATA region&region_num;
	SET region&region_num;
		region = &region_num;
	RUN;

	*Delete unnecessary datasets;
	PROC DELETE DATA = region; RUN;

%MEND regionagestratasens1;
