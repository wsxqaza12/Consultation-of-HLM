%macro output(var);
%do t=2 %to 4;
	ods output Statistics=&var._d&t.1_stat;
	ods output ConfLimits=&var._d&t.1_CI;
	ods output TTests=&var._d&t.1_ttest;
	proc ttest data=diff_con;
		paired d&t.1_&var.0*d&t.1_&var.1;
	run; 
	ODS OUTPUT CLOSE; 

	data &var._d&t.1;
	merge &var._d&t.1_stat (keep = N)
		  &var._d&t.1_CI (keep= Mean LowerCLMean UpperCLMean)
		  &var._d&t.1_ttest (keep = Probt);
	run;

	data &var._d&t.1; set &var._d&t.1;
		all=compress(round(Mean,0.01)||"("||round(LowerCLMean,0.01)||","|| round(UpperCLMean,0.01)||")");
		prob=round(Probt,0.0001);
		var="&var.";
		group="d&t.1";
		drop Mean LowerCLMean UpperCLMean Probt;
		retain N all prob;
	run;
%end;
%mend;

%output(cal);
%output(gr);
%output(pd);

data all1;
set cal_d21 cal_d31 cal_d41 gr_d21 gr_d31 gr_d41 pd_d21 pd_d31 pd_d41;
by group;
run;


/*************************************************************************/

/*mean change*/

%macro M(var);
%do t=2 %to 4;
	ods output Summary=s_d&t.1_&var.;
	proc means data=diff_con;
		var d&t.1_&var.0 d&t.1_&var.1;
	run;
	ods output close;

	data s_d&t.1_&var.;set s_d&t.1_&var.;
		format var $3. group $3.;
		N0=d&t.1_&var.0_N;N1=d&t.1_&var.1_N;
		M0=round(d&t.1_&var.0_Mean,0.01);
		SD0=round(d&t.1_&var.0_StdDev,0.01);
		M1=round(d&t.1_&var.1_Mean,0.01);
		SD1=round(d&t.1_&var.1_StdDev,0.01);
		MSD0=compress(M0||"("||SD0||")");
		MSD1=compress(M1||"("||SD1||")");
		var="&var.";
		group="d&t.1";
		keep N0 MSD0 N1 MSD1 var group;
	run;
%end;
%mend;
%M(cal);
%M(gr);
%M(pd);

data all2;
set s_d21_cal s_d31_cal s_d41_cal s_d21_gr s_d31_gr s_d41_gr s_d21_pd s_d31_pd s_d41_pd;
by group;
run;

proc sort data=all1; by var group;run;
proc sort data=all2; by var group;run;

data all;
merge all2 all1;
by var group;
run;

proc sort data=all; by group;run;


PROC EXPORT DATA= WORK.All 
            OUTFILE= "D:\重要備份\Wang\data\continuous.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;





proc ttest data=diff_con;
	paired d41_cal0*d41_cal1;
run; 
