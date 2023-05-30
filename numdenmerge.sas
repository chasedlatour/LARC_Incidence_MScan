*Numerator dataset has 1) a matching hcpc code within 30 days and 2) no removals 30 days before the insertion


*Writing a macro that specifies the numerator, denominator, and output dataset;
*Due to intermediate datasets, the final will be named output4 (i.e., whatever is specified as the root for output);

%macro numdenmerge(num, den, output);

	/*Limit dataset to only necessary variables before merging to denominator*/

	data numerator_merge (drop=firstinsert first_larc_insertion hcpc_proctyp hcpc_type hcpc_cpt_match cptrem_proc1 cptrem_proctyp cptrem_svcdate cptrem_type larc_remove_flag);
	set &num;
		year_insert=year(svcdate); 
		month_insert=month(svcdate);
	run;


	*Left join first larc numerator to enrollment denominator; 
	*Decided to join to long dataset to make tabulations easier;

	PROC SQL;
		CREATE TABLE &output.1 AS 
		SELECT a.*, b.*
		FROM &den as a 
		left join numerator_merge as b
		ON a.enrolid = b.enrolid and a.year=b.year_insert and  a.month = b.month_insert;
		*only join to enrollment period that matches the year;
		*this only works if you are joining to the long dataset, where every year of a continuous enrollment period is a separate row; 
		QUIT;


	*need to be able to sort by larc insertion and copy information from year insert, make a flag to identify larc_insertions; 
	data &output.2;
	set &output.1;
		if proc1 ne "" then larc_insert=1;
		else larc_insert=0;
	run; 


	proc sort data=&output.2;
		*sort descending by larc_insert so that the first row for each person is their larc insertion row;
		by enrolid descending larc_insert ;
	run;


	*Copy the year that the larc was inserted into all rows for someone by enrolid
	this will allow us to flag them as at-risk until they receive their larc, and then not at-risk after;
	data &output.3;
	set &output.2;
		by enrolid ; 
		retain insert_month insert_year;
		if first.enrolid then do;
		*if a value for first insertion is available, create new variable that contains this info;
			if larc_insert=1 then do;
				insert_month=month_insert;
				insert_year=year_insert;
				end;
			else insert_month=.; 
			end;
		else do;
		*copy value for insert year by enrolid
		if this is blank (someone did not have an insertion, this variable will also be blank;
			insert_month=insert_month;
			insert_year=insert_year;
		end; 
	run; 


	data &output.4  ;
	set &output.3;
		*identify years at risk for everyone enrolled;
		*if they are missing insert_year, it means they never received an insertion and therefore are at-risk the entire period;
		if insert_month=. or insert_year=. then atrisk=1;
		*the year variable refers to the year in the enrollment file. Insert_year is larc insertion year.
		*if they received an insertion, they are at risk for an insertion until they receive an insertion, afterwards then they are not at risk;
		else if insert_year>year then atrisk=1;
		else if insert_year<year then atrisk=0;
		else if insert_year = year then do;
			if insert_month >= month then atrisk=1;
			if insert_month < month then atrisk=0;
			end;
/*		else if insert_month>=month and insert_year>=year then atrisk=1;*/
/*		else if insert_month<month then atrisk=0;*/
	run; 

	*arrange by year again; 
	proc sort data=&output.4 out=out.&output.4; /*Saving output dataset to out. library*/
		by enrolid year month;
	run; 

%mend numdenmerge;
