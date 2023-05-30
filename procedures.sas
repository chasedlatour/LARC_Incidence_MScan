*Write macro to identify all LARC-related events in the outpatient
		services files.;

%macro procedures (library=, dataset=, OUTPUT=);
data &library..&OUTPUT;
	set &library..&dataset (keep=age enrolid svcdate proc1 proctyp);

	/*Create procedure indicators based upon CPT codes*/
	/*CPT insertion codes*/
	%LET PC1=%STR('58300', '11981', '11975');
	/*CPT removal codes*/
	%LET PC2=%STR('58301', '11982', '11976');
	/*CPT reinsertion codes*/
	%LET PC3=%STR('11983', '11977');
	/*Create procedure indicators based upon HCPCS*/
	/**Implant**/
	%LET PC4=%STR('J7307','J7306','S0180');
	/**Hormonal IUD**/
	%LET PC5=%STR('J7296','J7297','J7298','J7301','J7302','Q0090','S4980','S4981','S4989');
	/**Non-Hormonal IUD**/
	%LET PC6=%STR('J7300');

	%LET PR1=CPTINS;
	%LET LBL1=%STR(CPT Insertion Codes);
	%LET PR2=CPTREM;
	%LET LBL2=%STR(CPT Removal Codes);
	%LET PR3=CPTREINS;
	%LET LBL3=%STR(CPT Re-Insertion Codes);
	%LET PR4=HCPCIMP;
	%LET LBL4=%STR(HCPCS for Implants);
	%LET PR5=HCPCHIUD;
	%LET LBL5=%STR(HCPCS for Hormonal IUD);
	%LET PR6=HCPCNHIUD;
	%LET LBL6=%STR(HCPCS for Non-Hormonal IUD);

	%do DI=1 %to 6;/*Could add other conditions above and do this iteratively*/
		A&DI=0;
		if PROC1 in (&&PC&DI) then A&DI = 1; else A&DI=0;

		if A&DI>0 then &&PR&DI=1;
			else &&PR&DI=0;
			label &&PR&DI = &&LBL&DI;
		DROP A&DI;	
	%end;
		
run;
%mend procedures;
