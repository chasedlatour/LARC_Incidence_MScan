/*This macro will merge whatever dataset we want (e.g., hcpcs) onto whatever substrate (e.g. , first larc insertion)
	There were duplicates in both the hcpc and cptremoval datasets (because there is only ever one first insertion, but potentially multiple hcpcs and removals)
	in this macro, we will only merge the hcpc or insertion with the smallest gap, because that is most relevant to our study question
	The datasets we will be merging have already been restricted to hcpcs within 30 days and removals within 30 days in the main analysis
	If there are two hcpcs or two removals within 30 days, this macro will pick the closest one to the larc insertion date merge

Programmer: Mekhala*/


%macro mergedata(merge,substrate, output, sortvar);

	*Prepare dataset to merge by sorting by enrolid and sort variable;
	proc sort data=&merge;
		by enrolid &sortvar;
	run; 

	*Create a counter variable that will identify duplicates;
	data &merge.2;
	set &merge;
		by enrolid &sortvar; 
		if first.enrolid then counter=1;
		else counter+1;
	run;

	*keep only first row (closest svcdate (i.e. smallest gap) to larc insertion, just closest service date for removals);
	data &merge.3(drop=counter);
	set &merge.2;
		where counter=1;
	run; 

	*sort for merge;
	proc sort data=&merge.3;
		by enrolid firstinsert;
	run; 

	*Join by person id and insertion date;
	proc sql;
		create table &output as
		select a.*,b.*
		from &substrate as a
		left join &merge.3 as b
		on a.enrolid=b.enrolid and a.firstinsert=b.firstinsert ;
		quit; 

%mend mergedata;
