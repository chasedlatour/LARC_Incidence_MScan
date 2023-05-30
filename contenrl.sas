/*************************************************************************************************
Create a macro that identifies meaningful periods of continuous enrollment. 1 row will be a 
period of continuous enrollment in the output dataset.
INPUT --
- dataset - name of the data file with all the periods of enrollment for each year
- output - name of the output dataset
- gap - the gap that going to allow between periods of continuous enrollment
- continuous - the minimum number of days required in sequence to define a period of cont enrollment
**************************************************************************************************/


*Create MACRO to turn the data into meaningful discrete periods of continuous
enrollment;
%MACRO contenrl (dataset, output, gap, continuous);
	*Sort the input dataset by enrollee id and starting date of 1 month of enrollment;
	proc sort data = &dataset;
		by enrolid dtstart;
	run;
	*identify the periods of continuous enrollment;
	data &output;
		set &dataset (keep = enrolid dtstart dtend);
		by enrolid dtstart;
		retain START END PERIOD;

		if first.enrolid then do;
			start = dtstart;
			end = dtend;
			period = 1;
	     	end;
		*come back and check if both else if statements are needed without the gap coverage.;
		else if dtstart <= end + &gap and dtend > end then end = dtend;
		else if dtstart > end + &gap then do;
			output;
			period + 1;  
			start = dtstart;
			end = dtend;
	     	end;

	    if last.enrolid then output;

	    label	Period = 'Period of Coverage for Enrollee'
	            Start = 'Start Date of Continuous Enrollment Period'
	            End = 'End Date of Continuous Enrollment Period';

	    keep enrolid start end period;
	    format start end date9.;
		run;

	DATA &output;
		SET &output;
		enrollment_days = end-start;
	RUN;

*You know that to make it into your study, people will have to have at least x days
		 of continuous enrollment (-x to 0). Exclude any with a shorter length;
	data /*temp.*/&output; /*Saving as a temporary file for now 	-- VP note - went back to a work datasets*/
		set &output;
		where enrollment_days ge &continuous;
	run;

%MEND contenrl;
