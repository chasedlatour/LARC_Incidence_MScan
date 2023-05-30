
/****************************************************************************
	Name: Clara Busse, Mekhala Dissanayake, Chase Latour
	Class: EPID 766 / DPOP 766
	Submit Date: 20210223
	Purpose: Project
	Program path:
		/mnt/files/users/cdlatour/project
	Input paths:	
		/mnt/files/class/random1pct
	Output path:	
		/mnt/files/users/cdlatour/project

FILE IS NO LONGER NECESSARY AND NOT REFERENCED IN THE PRIMARY ANALYSIS FILE


In order to use this file, you should have already run cbmdcl_identify_larc_outpatient and have the dataset
first_larc_hcpc_cptrem_formerge

And cbmdcl_identify_enrollment and have the dataset
enrlprimarystrata

*****************************************************************************/

/*Comment out so that can run from the overall project file -- 


*Map local mirrors for all remote libraries using LOCAL SUBMIT (plain ol' running man button, or F3);
libname ldata slibref=data server=server;
libname lshare slibref=share server=server;
libname loutproj slibref=outproj server=server;
libname lwork slibref=work server=server;

*/


/*Run */

options mprint;
*main analysis: numerator is first larcs, with a hpcc within 30 days, no removal within 30 days;
%numdenmerge(first_larc_hcpc_cptrem_formerge, enrlstratalong, firstlarcenrl);

*final output dataset= firstlarcnenrl4;
*end;

