
/****************************************************************************
	Name: Clara Busse, Mekhala Dissanayake, Chase Latour
	Class: EPID 766 / DPOP 766
	Submit Date: 20210223
	Purpose: Main project analysis file. This file runs all the code necessary
	to generate the data for the primary analyses. All the library statements 
	have been commented out in the included code, so those just need to be run
	once here.
	This file should be run before all other files.
	Program path:
		/mnt/files/users/cdlatour/project
	Input paths:	
		/mnt/files/class/random1pct
	Output path:	
		/mnt/files/users/cdlatour/project



	This code will be run together to derive the primary study cohort.


*****************************************************************************/



********
Options settings that should be run at the beginning of the file PRIOR TO 
ANYTHING ELSE
********;

*Code provided by Alan for the class;
options ps=500 ls=220 nodate nocenter nofmterr pageno=1 fullstimer stimer stimefmt=z compress=yes mprint;proc template;edit Base.Freq.OneWayList;edit Frequency;format=8.0;end;edit Percent;format = 5.1;end;edit CumPercent;format = 5.1;end;end;run;
 
*Code that tells SAS to pull all the macros that we have in our macros folder;
options source source2 msglevel=I mcompilenote=all mautosource 
     sasautos=(SASAUTOS "/local/projects/marketscanccae/larc_descrip/programs/macros");

*Run the set-up macro that Virginia provided for all projects completed on the
	 N2 server. This facilitates running the analysis on the full MarketScan
	 sample.;
%setup(full, 1_sensitivity_analysis, saveLog=Y);

*This will set up all the remote libraries that we need.;

****
****;

*Map local mirrors for all remote libraries using LOCAL SUBMIT (plain ol' running man button, or F3);
/*libname lraw slibref=raw server=server;*/
*libname lshare slibref=share server=server;
*libname loutproj slibref=outproj server=server;
/*libname lwork slibref=work server=server;*/
/*libname lout slibref=out server=server;*/


**********************************************************************
Implement periods of continuous enrollment.

This file was written to derive the enrollment datasets that are
necessary for identifying the denominator. Run this with the remote
submit.
**********************************************************************;

%include '/local/projects/marketscanccae/larc_descrip/programs/2_continuous_enrollment.sas';

*Old:;
*%include '/mnt/files/class/projects/cbmdcl/Busse_Dissanayake_Latour_PP5_file2.sas';


**********************************************************************
Now identify LARCS using just CPT codes.

This has already been done, so we just read in the file.
**********************************************************************;

data numerator_sens_analysis;
set out.numerator_sens_analysis;
run;


**********************************************************************
Now merge the numerator and denominator files.

This code merges the LARC insertion information with the enrollment 
information and removes the risk periods that are no-longer at risk
if a person experience an earlier LARC inesrtion in the data. Run
this with a remote submit.
**********************************************************************;

*Once mapped over the macro, this file contained nothing but the 
macro running, so I have included that here.;
options mprint;
%numdenmerge(numerator_sens_analysis, enrlstratalong, month_sens_analysis_cohort);

