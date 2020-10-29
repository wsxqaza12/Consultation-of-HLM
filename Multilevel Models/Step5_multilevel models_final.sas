libname b "D:\重要備份\Wang\data";

data final;
	set b.fm2;
run;

%macro output(no);
data _n;
	set N;
	length col1 col2 $200;
	col1='N';
	col2=strip(put(NobsUsed,20.));
	keep col1 col2;
run;
proc sort data=_n nodupkey; by col1; run;

data _cov;
	length subject col1 col2 $200;
	set Cov;
	if index(subject,'site')>0 then subject='Site';
/*	else if index(subject,'No_')>0 then subject='Subject';*/
	if index(CovParm,'UN(1,1)')>0 then CovParm='Intercept';

	if subject^="" then col1=strip(CovParm)||' ('||strip(subject)||')';
	else col1=strip(CovParm);

	if ProbZ<0.05 then col2=strip(put(round(Estimate,0.01),20.2))||'*'||' ('||strip(put(round(StdErr,0.01),20.2))||')';
	else col2=strip(put(round(Estimate,0.01),20.2))||' ('||strip(put(round(StdErr,0.01),20.2))||')';
	keep col1 col2;
run;

data _aic;
	set AIC;
	length col1 col2 $200;
	col1=strip(scan(Descr,1,'('));
	col2=strip(put(round(Value,0.01),best.));
	keep col1 col2;
run;

data _fe;
	set FE;
	length col1 col2 $200;
	
	if time^="" then col1=strip(Effect)||' '||strip(time);
	else col1=strip(Effect);

	if cmiss(Estimate,StdErr, Probt)=0 & Probt<0.05 then col2=strip(put(round(Estimate,0.01),20.2))||'*'||' ('||strip(put(round(StdErr,0.01),20.2))||')';
	else if cmiss(Estimate,StdErr, Probt)=0 then col2=strip(put(round(Estimate,0.01),20.2))||' ('||strip(put(round(StdErr,0.01),20.2))||')';
	else col2='Ref';

	keep col1 col2;
run;

data e0;
	length col1 col2 $200;
	col1='Number of Observations Used';	col2='';
run;
data e1;
	length col1 col2 $200;
	col1='Fixed Effects'; col2='';
run;
data e2;
	length col1 col2 $200;
	col1='Error Variance'; col2='';
run;
data e3;
	length col1 col2 $200;
	col1='Model Fit'; col2='';
run;
data s_&no.;
	set e0 _n e1 _fe e2 _cov e3 _aic;
	id=_n_;
run;
%mend output;

/*%let m=base_PD;*/
/*%let var=%scan(&m,2,'_');*/
/*%put &m &var;*/

%macro out2(m,dat);
%let var=%scan(&m,2,'_');
data c1;
	set final;
	if ^missing(&var.);
run;
data c2;
	set final;
	if ^missing(&var.) & ^missing(&m.);
run;
data c3;
	set final;
	if cmiss(&var.,&m.,min_PD,min_CAL,min_GR)=0;
run;

/*M1:uncondition model*/
ods output  NObs=N(keep=NObsUsed) CovParms=Cov(drop=ZValue) FitStatistics=AIC(Where=(index(Descr,'AIC ')>0 or index(Descr,'BIC ')>0)) SolutionF=FE(drop=df tValue);
proc mixed data = &dat. noclprint method=ml covtest;
	class site; 
	model &var. = /s ;
	random intercept / sub=site type=un;
run;
ods output close;
%output(no=1);

/*M2: add predictors: time trt time*trt */
ods output  NObs=N(keep=NObsUsed) CovParms=Cov(drop=ZValue) FitStatistics=AIC(Where=(index(Descr,'AIC ')>0 or index(Descr,'BIC ')>0)) SolutionF=FE(drop=df tValue);
proc mixed data = &dat. noclprint covtest method=ml;
	class time(ref='1') trt(ref='0') site; 
	model &var. = time trt time*trt /s ;
	random intercept / sub=site type=un;
run;
ods output close;
%output(no=2);

/*M3: add base_XX*/
ods output  NObs=N(keep=NObsUsed) CovParms=Cov(drop=ZValue) FitStatistics=AIC(Where=(index(Descr,'AIC ')>0 or index(Descr,'BIC ')>0)) SolutionF=FE(drop=df tValue);
proc mixed data = &dat. noclprint covtest method=ml;
	class time(ref='1') trt(ref='0') site; 
	model &var. = time trt time*trt &m./s ;
	random intercept / sub=site type=un;
run;
ods output close;
%output(no=3);

/*M4-6: add min_XX*/
%let varlist= min_PD min_CAL min_GR;
%put &varlist;
%macro test;
%do i = 1 %to %sysfunc(countw(&varlist)) ;
  %let par = %scan(&varlist,&i);
	ods output  NObs=N(keep=NObsUsed) CovParms=Cov(drop=ZValue) FitStatistics=AIC(Where=(index(Descr,'AIC ')>0 or index(Descr,'BIC ')>0)) SolutionF=FE(drop=df tValue);
	proc mixed data = &dat. noclprint covtest method=ml;
		class time(ref='1') trt(ref='0') site; 
		model &var. = time trt time*trt &m. &par. /s ;
		random intercept / sub=site type=un;
	run;
	ods output close;
	%output(no=%eval(&i+3));
%end;
%mend test;
%test;

proc sort data=s_1(rename=(col2=M1) drop=id) out=s1; by col1; run;
proc sort data=s_2(rename=(col2=M2) drop=id) out=s2; by col1; run;
proc sort data=s_3(rename=(col2=M3) drop=id) out=s3; by col1; run;
proc sort data=s_4(rename=(col2=M4 id=id1)) out=s4; by col1; run;
proc sort data=s_5(rename=(col2=M5 id=id2)) out=s5; by col1; run;
proc sort data=s_6(rename=(col2=M6 id=id3)) out=s6; by col1; run;

data &var.;
	merge s1 s2 s3 s4 s5 s6;
	by col1;
	if id1=. then id1=20.5;
	if id2=. then id2=20.5;
	if id3=. then id3=20.5;
run;
proc sort data=&var. out=&var.(drop=id1 id2 id3);
	by id1 id2 id3;
run;

PROC EXPORT DATA= WORK.&var.
            OUTFILE= "C:\Users\user\Desktop\multilevel models.xls"
/*            OUTFILE= "\\twtpe-vsfs01\personal\Q1047381\wang\data\multilevel models.xls" */
            DBMS=EXCEL REPLACE;
			SHEET="&var._2_level_&dat.)"; 
RUN;
%mend out2;

%out2(m=base_PD,dat=c2);
%out2(m=base_CAL,dat=c2);

%out2(m=base_PD,dat=c3);
%out2(m=base_CAL,dat=c3);

