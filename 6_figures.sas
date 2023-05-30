
/****************************************************************************
	Name: Clara Busse, Mekhala Dissanayake, Chase Latour
	Class: EPID 766 / DPOP 766
	Submit Date: 20210223
	Purpose: Create figures to look at our data.
	Files 1 through 5 should have been prior to this. Specifically, you need
	the stratified dataset calcualted in file 5.
	Program path:
		/mnt/files/users/cdlatour/project
	Input paths:	
		/mnt/files/class/random1pct
	Output path:	
		/mnt/files/users/cdlatour/project


*****************************************************************************/

*Code provided by Alan for the class;
options ps=500 ls=220 nodate nocenter nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes mprint;proc template;edit Base.Freq.OneWayList;edit Frequency;format=8.0;end;edit Percent;format = 5.1;end;edit CumPercent;format = 5.1;end;end;run;
 
*Code that tells SAS to pull all the macros that we have in our macros folder;
options source source2 msglevel=I mcompilenote=all mautosource 
     sasautos=(SASAUTOS "/local/projects/marketscanccae/larc_descrip/programs/macros");

*Run the set-up macro that Virginia provided for all projects completed on the
	 N2 server. This facilitates running the analysis on the full MarketScan
	 sample.;
%setup(random1pct, 1_primary_analysis, saveLog=N);

*This will set up all the remote libraries that we need.;

****
****;

*Map local mirrors for all remote libraries using LOCAL SUBMIT (plain ol' running man button, or F3);
libname lraw slibref=raw server=server;
*libname lshare slibref=share server=server;
*libname loutproj slibref=outproj server=server;
libname lwork slibref=work server=server;





/****************************************************************************
PRIMARY ANALYSES
****************************************************************************/



*Plot the age-stratified estimates over time that are region standardized;

*Create the plot;
ODS GRAPHICS / RESET IMAGENAME = 'Age-Stratified Primary' IMAGEFMT =JPEG HEIGHT = 7in WIDTH = 10in;
ODS LISTING GPATH = '/local/projects/marketscanccae/larc_descrip/output/random1pct/graphics' ; 

title "Percent of LARC Insertions Over Time";
proc sgplot data=out.age_strat_region_std;
   series x=month_yr y=age_strat_incidence_10000 / group=agecat;
   xaxis label = 'Year' interval=year display=none;
   yaxis label = 'Proportion of LARC Insertions per 10,000 People' min = 0 max =  50;
run;
title;






/****************************************************************************
OLD CODE
****************************************************************************/


/****************************************************************************
PRIMARY ANALYSES
****************************************************************************/

****Aggregated LARC type over time;

*Make the crudeoverall dataset have only the information that we need;
DATA larctypeprimary;
SET out.overallcrude (KEEP = year propimp prophiud propnhiud);
RUN;
*Transpose the dataset from wide to long to input it into sgplot;
PROC TRANSPOSE DATA = larctypeprimary OUT = larctypeprimary2;
	BY year;
RUN;
*Rename the variables to what would look good in the legend;
DATA ana.larctypeprimary2;
SET larctypeprimary2;
	IF _NAME_ = 'propimp' THEN _NAME_ = 'Implant';
	 	ELSE IF _NAME_ = 'prophiud' THEN _NAME_ = 'H IUD';
		ELSE IF _NAME_ = 'propnhiud' THEN _NAME_ = 'Non-H IUD';
	*Want to remove the label for _NAME_ for the figure;
	LARC = _NAME_;
RUN;

*Create the plot;
ODS GRAPHICS / RESET IMAGENAME = 'LARC aggregate primary' IMAGEFMT =JPEG HEIGHT = 5in WIDTH = 7in;
ODS LISTING GPATH = '/local/projects/marketscanccae/larc_descrip/output/random1pct/graphics' ; 

title "Percent of LARC Insertions by Type Over Time";
proc sgplot data=out.larctypeprimary2;
   series x=year y=col1 / group=LARC;
   xaxis label = 'Year' grid values = (2010 to 2018 by 1);
   yaxis label = 'Percent of Total LARC Insertions' min = 0 max = 100 ;
run;
title;





****LARC incidence proportions over time - stratified by age, different plots
for regions 1-4;

*Region 1;

*Make the dataset how we want to include the necessary data for the figure;
DATA region1fig;
SET out.stratified;
	WHERE region = 1;
	KEEP year agecat incidenceper1000;
RUN;

*Note that keeping the incidence per 1000 individuals in the population;

*Create a nicely-labeled age variable;
DATA ana.region1fig;
	SET region1fig;
	IF agecat = 1 THEN Age = '15-19';
		ELSE IF agecat = 2 THEN Age = '20-24';
		ELSE IF agecat = 3 THEN Age = '25-29';
		ELSE IF agecat = 4 THEN Age = '30-34';
		ELSE IF agecat = 5 THEN Age = '35-39';
		ELSE IF agecat = 6 THEN Age = '40-44';
		ELSE IF agecat = 7 THEN Age = '45-49';

	DROP agecat;
RUN;

*Create the plot;
ODS GRAPHICS / RESET IMAGENAME = 'region 1 primary' IMAGEFMT =JPEG HEIGHT = 5in WIDTH = 7in;
ODS LISTING GPATH = '/local/projects/marketscanccae/larc_descrip/output/random1pct/graphics' ; 

title "Age-Stratified Incidence of Naive LARC Insertions in the Northeastern Region";
proc sgplot data=out.region1fig;
   series x=year y=incidenceper1000 / group=Age;
   xaxis label = 'Year' grid values = (2010 to 2018 by 1);
   yaxis label = 'One-year Incidence Per 1,000 Individuals At-Risk' min=0 max=50;
run;
title;
*************************************************************************************************
*Region 2;

*Make the dataset how we want;
DATA region2fig;
SET out.stratified;
	WHERE region = 2;
	KEEP year agecat incidenceper1000;
RUN;
DATA ana.region2fig;
	SET region2fig;
	IF agecat = 1 THEN Age = '15-19';
		ELSE IF agecat = 2 THEN Age = '20-24';
		ELSE IF agecat = 3 THEN Age = '25-29';
		ELSE IF agecat = 4 THEN Age = '30-34';
		ELSE IF agecat = 5 THEN Age = '35-39';
		ELSE IF agecat = 6 THEN Age = '40-44';
		ELSE IF agecat = 7 THEN Age = '45-49';

	DROP agecat;
RUN;

*Create the plot;
ODS GRAPHICS / RESET IMAGENAME = 'region 2 primary' IMAGEFMT =JPEG HEIGHT = 5in WIDTH = 7in;
ODS LISTING GPATH = '/local/projects/marketscanccae/larc_descrip/output/random1pct/graphics' ; 

title "Age-Stratified Incidence of Naive LARC Insertions in the North Central Region";
proc sgplot data=out.region2fig;
   series x=year y=incidenceper1000 / group=Age;
   xaxis label = 'Year' grid values = (2010 to 2018 by 1);
   yaxis label = 'One-year Incidence Per 1,000 Individuals At-Risk' min=0 max=50;
run;
title;
*************************************************************************************************
*Region 3;

*Make the dataset how we want;
DATA region3fig;
SET out.stratified;
	WHERE region = 3;
	KEEP year agecat incidenceper1000;
RUN;
DATA ana.region3fig;
	SET region3fig;
	IF agecat = 1 THEN Age = '15-19';
		ELSE IF agecat = 2 THEN Age = '20-24';
		ELSE IF agecat = 3 THEN Age = '25-29';
		ELSE IF agecat = 4 THEN Age = '30-34';
		ELSE IF agecat = 5 THEN Age = '35-39';
		ELSE IF agecat = 6 THEN Age = '40-44';
		ELSE IF agecat = 7 THEN Age = '45-49';

	DROP agecat;
RUN;

*Create the plot;
ODS GRAPHICS / RESET IMAGENAME = 'region 3 primary' IMAGEFMT =JPEG HEIGHT = 5in WIDTH = 7in;
ODS LISTING GPATH = '/local/projects/marketscanccae/larc_descrip/output/random1pct/graphics' ; 

title "Age-Stratified Incidence of Naive LARC Insertions in the Southern Region";
proc sgplot data=region3fig;
   series x=year y=incidenceper1000 / group=age;
   xaxis label = 'Year' grid values = (2010 to 2018 by 1);
   yaxis label = 'One-year Incidence Per 1,000 Individuals At-Risk' min=0 max=50;
run;
title;

*************************************************************************************************
*Region 4;

*Make the dataset how we want;
DATA region4fig;
SET out.stratified;
	WHERE region = 4;
	KEEP year agecat incidenceper1000;
RUN;
DATA ana.region4fig;
	SET region4fig;
	IF agecat = 1 THEN Age = '15-19';
		ELSE IF agecat = 2 THEN Age = '20-24';
		ELSE IF agecat = 3 THEN Age = '25-29';
		ELSE IF agecat = 4 THEN Age = '30-34';
		ELSE IF agecat = 5 THEN Age = '35-39';
		ELSE IF agecat = 6 THEN Age = '40-44';
		ELSE IF agecat = 7 THEN Age = '45-49';

	DROP agecat;
RUN;

*Create the plot;
ODS GRAPHICS / RESET IMAGENAME = 'region 4 primary' IMAGEFMT =JPEG HEIGHT = 5in WIDTH = 7in;
ODS LISTING GPATH = '/local/projects/marketscanccae/larc_descrip/output/random1pct/graphics' ; 

title "Age-Stratified Incidence of Naive LARC Insertions in the Western Region";
proc sgplot data=ana.region4fig;
   series x=year y=incidenceper1000 / group=Age;
   xaxis label = 'Year' grid values = (2010 to 2018 by 1);
   yaxis label = 'One-year Incidence Per 1,000 Individuals At-Risk' min=0 max=50;
run;
title;


