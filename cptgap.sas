/***********************************************************
*Identify removals within 30 days of insertion;

Programmer: Mekhala
*******************************************************/

/*Confirmed that if the gap is negative, the removal happened before the insertion*/

*The gap in this macro should be a negative number (unlike hcpc gap, which uses the absolute value of the gap between service date
and larc insertion date);
%macro cptgap (dataset, output, gap);

	DATA larc_removals;
	SET &dataset;
		*gaps>0 means that gaps that the removal happened after the first insertion and we do not care about that; 
		*a missing gap means there is no first insertion for this enrolid; 
		WHERE cptrem=1 & cpt_gap<=0 & cpt_gap ne . ;
	run; 

	/*proc contents data=larc_removals;
	run;*/

	data larc_removals2;
	set larc_removals; 
		*set a flag that identifies gaps that occurred within 30 days of first larc insertion;
		removal_flag =  cpt_gap >= &gap;
		*set to zero if there is no gap; 
		if cpt_gap=. then removal_flag=.; 
	run; 

	*keep only removals within a 30 day window, prepare for merge with larc insertion substrate
	*rename variables so I retain the information that is relevant to do the removals  (larc insertion will also have these same variables);
	data &output (keep=enrolid cptrem_type firstinsert cptrem_proc1 cptrem_proctyp cptrem_svcdate larc_remove_flag);
	set larc_removals2;
		where removal_flag=1; 
		rename removal_flag=larc_remove_flag;
		rename proc1=cptrem_proc1;
		rename proctyp=cptrem_proctyp;
		rename svcdate=cptrem_svcdate;
		rename type=cptrem_type;
	run;

%mend cptgap;
