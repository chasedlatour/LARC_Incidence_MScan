*Write a macro for HCPC gaps

Programmer: Mekhala;

%macro hcpcgap (dataset, output, gap);

	PROC SORT DATA = &dataset;
		BY ENROLID hcpc_gap;
	RUN;
	*4/13/21 CB note - changed GAP to hcpc_gap in proc sort above;

	*Create a flag variable that identifies gap between hcpc code and first larc insertion; 

	DATA gapflag;
	SET &dataset;
		WHERE HCPCIMP = 1 OR HCPCHIUD = 1 OR HCPCNHIUD = 1;
		BY enrolid;
		*We want to count the amount of flags that qualify, so we retain the flag itself and the sum; 
		retain gapflag gapsum;

			IF first.enrolid THEN DO;
			*if a gap is less than or equal to the specified gap, flag it; 
				gapflag = hcpc_gap <= &gap;
			*missing is a small number, do not want to flag gaps that are missing;
				if hcpc_gap =. then gapflag=.; 
				gapsum=gapflag;
				
				END;
			ELSE DO;
			*there may be multiple hcpcs, and we do not know which one will match; 
				gapflag = hcpc_gap <= &gap;
				if hcpc_gap =. then gapflag=.; 
				gapsum=sum(gapflag, gapsum);
				END;

			IF last.enrolid THEN DO;
				
				gapflag = hcpc_gap <= &gap;
				if hcpc_gap =. then gapflag=.; 
				*This sum variable will tell us whether someone has any hcpc code that matches a cpt code within 30 days
				if someone has zero, this tells us they never have one and we can drop this hcpc; 
				gapsum = sum(gapsum);
				*Create a flag variable that identifies the last of someones hcpc codes -- this is what we want to tabulate;
				last=1;
				END;
	RUN;


	data gapzero;
	set gapflag;
		where last=1 & gapsum=0;
	run; 

	*make a flag variable for removing the people who never had a hcpc match, keep only what is necessary and merge back to dataset;
	*if someone did not have any hcpc codes that matched a cpt code within 30 days, we want to get rid of that hcpc;
	data gapzero_merge (keep=enrolid gap_remove_obs);
	set gapzero; 
		gap_remove_obs=1;
	run;


	*merge removal flag back to previous gap dataset;
	*it is ok to do this just by enrolid bc if someone had gapflagsum of zero, they did not have a qualifying hcpc match at all; 
	data gapflag2;
		merge gapflag(in=x) gapzero_merge(in=y);
		by enrolid;
	run; 

	*make new flag;
	data gapflag3;
		set gapflag2;
		*in the absence of a removal flag and the presence of a gapflag 1, this code is a match; 
		if gap_remove_obs=. & gapflag=1 then hcpc_cpt_match=1;
		*these are the people (i.e., within an enrolid) with no matches at all; 
			else if gap_remove_obs=1 then hcpc_cpt_match=0;
		*missing if there was no first insertion that pulled a date within an enrolid (e.g., maybe just a removal or reinsertion within the period); 
			else if hcpc_gap=. then hcpc_cpt_match=0; 
		*these are specific hcpcs (if there were multiple per enrolid) that did not have a gap that qualified; 
			else if gapflag=0 then hcpc_cpt_match=0; 
	run; 

	*Make dataset that will be merged onto first larc insertion substrate; 
	*rename variables so I retain the information that is relevant to the hcpcs  (larc insertion will also have these same variables);
	data &output (drop=year cptins cptrem cptreins first_rem first_reins first_larc_insertion cpt_gap gapflag gapsum last gap_remove_obs);
	set gapflag3;
		where hcpc_cpt_match=1; 
		rename proc1=hcpc_proc1;
		rename proctyp=hcpc_proctyp;
		rename type=hcpc_type;
		rename svcdate = hcpc_svcdate;
	run; 

	*Delete intermediary datasets;
	proc delete data=gapflag;
	proc delete data=gapzero;
	proc delete data=gapzero_merge;
	proc delete data=gapflag2;
	*proc delete data=gapflag3;
	run;
%mend hcpcgap;
