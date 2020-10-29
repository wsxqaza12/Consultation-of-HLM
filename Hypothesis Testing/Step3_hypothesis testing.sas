/*讀永久檔*/
libname b 'D:\重要備份\Wang\data';
data diff_con; set b.diff_con;run;

/*paired t-test*/
%macro pt(v1,v0);
%do t=2 %to 4;
proc ttest data=diff_con;
	paired d&t.1_&v1.*d&t.1_&v0.;
run;
%end;
%mend;
%pt(cal0,cal1);
%pt(gr0,gr1);
%pt(pd0,pd1);

/*check normality assumption*/
data c;set diff_con;d=d21_cal0 - d21_cal1;run;
proc univariate data = c normal ;
var d;
qqplot;
run;

/*PD違反normality assumption，用Wicoxon signed-rank test*/
data pd;set diff_con;
d21=d21_pd0 - d21_pd1;
d31=d31_pd0 - d31_pd1;
d41=d41_pd0 - d41_pd1;
run;
proc univariate data=pd;
  var d21 d31 d41;
run;

data gr;set diff_con;
d21=d21_gr0 - d21_gr1;
run;
proc univariate data=gr;
  var d21;
run;

/*mean change*/
%macro pm(v1,v0);
%do t=2 %to 4;
proc means data=diff_con;
	var d&t.1_&v1. d&t.1_&v0.;
run;
%end;
%mend;
%pm(cal0,cal1);
%pm(gr0,gr1);

/*IQR for PD*/
proc univariate data=diff_con;
	var d21_pd0 d21_pd1 d31_pd0 d31_pd1 d41_pd0 d41_pd1;
run;
proc univariate data=diff_con;
	var d21_gr0 d21_gr1;
run;

/*讀永久檔*/
libname b 'D:\重要備份\Wang\data';
data diff_dis; set b.diff_dis;run;

/*McNemar test*/
%macro mc(v1,v0);
%do t=2 %to 4;
proc freq data=diff_dis;
	tables d&t.1_&v1.*d&t.1_&v0./agree;
run;
%end;
%mend;
%mc(bop0,bop1);
%mc(pi0,pi1);
/*d21_bop1*d21_bop0/agree;*/

/*change percentage*/
%macro per(v1,v0);
%do t=2 %to 4;
	proc freq data=diff_dis;
		tables d&t.1_&v1. d&t.1_&v0.;
	run;
%end;
%mend;
%per(bop0,bop1);
%per(pi0,pi1);
