libname b 'D:\重要備份\Wang\data';
/*對應t1 t0，取正確的key_tooth來用*/
data summ;set b.summ;run;
data summ;set summ;keep key_tooth No_ t1 t0;run;
proc transpose data=summ out=k;
by key_tooth;
var t1 t0;
run;

data k1;set k;
gp=substr(_name_,2,1);
tooth=col1;
no=substr(key_tooth,1,4);
drop col1 _name_;
run;

/*確認key_tooth對應沒問題*/
proc freq data=k1;tables gp;run;
proc sort data=k1 out=k2 nodupkey;by key_tooth;run;

/*data try (drop=i);
  set k1;
  do i=1 to 4;
    output;
  end;
run;*/
/*把資料堆成四倍(加上時間)*/
data try (drop=i);
  set k1;
  do i=1 to 4;
 	 do i=1 to 4;
		time=i;
    output;
	end;
  end;
run;

data k2;set try;key=compress(no||tooth||time);/*key=compress(key_tooth||time);*/run;/*之後和bac data merge用*/

/*bac_data*/
PROC IMPORT OUT= WORK.bac 
            	DATAFILE= "D:\重要備份\Wang\data\bac_data.xlsx" 
            	DBMS=EXCEL REPLACE;/*if %sysfunc(exist(00&no.)) %then %do;*/
     	RANGE="raw data$"; 
RUN;

/*檢查baseline有沒有過低的要排除*/
data bac2;set bac;if substr(Sample_Name,12,1)='f';run;
proc univariate data=bac2;var TB Pg Pn Tf;run;
/*proc boxplot data=bac2;plot TB*no;run;*/

/*TB baseline小於1000者排除*/
data exclude;set bac2;
if substr(Sample_Name,12,1)='f' & tb<1000;
no_exclude = substr(Sample_Name,1,1)||substr(Sample_Name,5,3);
run;
/*R047,R048應排除，而R045,R048本就是要排除的，所以最後再一起排除*/

data bac1;set bac;
if tb=. or tb <18.2 then tb=0.001;else if tb>(1.82*(10**5)) then tb=1.82*(10**5);
if pg=. or pg <18.2 then pg=0.001;else if pg>(1.82*(10**5)) then pg=1.82*(10**5);
if pn=. or pn <18.6 then pn=0.001;else if pn>(1.86*(10**5)) then pn=1.86*(10**5);
if tf=. or tf <1.97 then tf=0.001;else if tf>(1.97*(10**4)) then tf=1.97*(10**4);
no=substr(Sample_Name,1,1)||substr(Sample_Name,5,3);
tooth=substr(Sample_Name,10,2);
time=substr(Sample_Name,12,1);
run;

data bac2;set bac1;
if time ='f' then time ='1';
else if time ='g' then time ='2';
else if time ='h' then time ='3';
else if time ='i' then time ='4';
else time='.';
drop Sample_Name;
run;

data bac2;set bac2(rename=(no=no1 time=time1 tooth=tooth1));
	no = put(no1, $8.);
	time = input(time1, 12.);
	tooth = put(tooth1, $2.);
	drop no1 time1 tooth1;
key=compress(no||tooth||time);
run;

/*確定沒有遺漏值(皆已補值)*/
proc means data=bac2 nmiss;
var tb pg pn tf;
run;
proc sort data=bac2;by key;run;
proc sort data=k2;by key;run;

data bac_final;
merge k2(in=a) bac2(in=b);
by key;
if a=1 & b=1;
run;/*n=580=>交集*/

data c;set bac_final;
if no='R045' or no='R047' or no='R048' then delete;
run;/*n=574*/

/*存永久檔*/
data b.bac_final; set c;run;


/*聯集*/
data m;
merge k2 bac2;
by key;
run;/*n=706*/
/*只有臨床資料*/
data m1;set m;
if tb=. & pg=. & pn=. & tf=.; /*if tb^=. or pg^=. or pn^=. or tf^=.;*/
run;/*n=92*/
/*bac only*/
data m2;set m;
if gp='' & key_tooth='';
run;/*n=34*/
/*580+92+34=706*/


/********************************************************************************************/
/*讀永久檔*/
data bac_final; set b.bac_final;run;

/*long to wide*/
/*proc freq data=bac_final;
tables gp;
run;*/
data bac_long;set bac_final;
drop key;
key2=key_tooth||time;
run;
/*n=574*/

/*長轉寬*/
proc sort data=bac_long;by key2;run;
%macro bac(par);
	proc transpose data=bac_long out=wide_&par. prefix=&par.;
   		by key2;
   		id gp;
   		var &par.;
	run;
	data &par.;set wide_&par.;
	key2=compress(key2);
		keep key2 &par.1 &par.0;
	run;
	/*合併檔案前sort*/
	proc sort data=&par.; by key2;run;
%mend;
%bac(TB);
%bac(PG);
%bac(PN);
%bac(TF);

/*合併檔案merge*/
data sum_bac;
	merge TB PG PN TF;
	by key2;
	key_t = substr(key2,1,6);/*沒有time資訊的鍵值*/
	time=substr(key2,7,1);
run;/*n=287*/

/*確認無遺漏值*/
proc means data=sum_bac nmiss;
var tb1 tb0 pg1 pg0 pn1 pn0 tf1 tf0;
run;

proc sort data=sum_bac;by key_t;run;

/*長轉寬(time)*/
%macro time(par);
	proc transpose data=sum_bac out=time_&par. prefix=&par._t;
   		by key_t;
   		id time;
   		var &par.;
	run;
	data t_&par.;set time_&par.; drop _name_;run;
	/*合併檔案前sort*/
	proc sort data=time_&par.; by key_t;run;
%mend;
%time(TB1);%time(TB0);
%time(PG1);%time(PG0);
%time(PN1);%time(PN0);
%time(TF1);%time(TF0);
/*轉完出現遺漏值是因為沒有該時間點的測量值*/

/*合併檔案merge*/
data t_sum_bac;
	merge t_TB1 t_TB0 t_PG1 t_PG0 t_PN1 t_PN0 t_TF1 t_TF0;
	by key_t;
run;/*n=83*/

/*存、讀永久檔*/
data b.t_sum_bac; set t_sum_bac;run;
data t_sum_bac; set b.t_sum_bac;run;

/*對應t0 t1*/
/*k2中沒有時間資訊的鍵值是key_tooth*/
data k3;set k2;
key_t=compress(key_tooth);
k=key_tooth||gp;
run;

proc sort data=k3 nodupkey;by k;run; /*n=168*/
data k3;set k3;
drop key_tooth time key k;
run;
/*長轉寬*/
proc transpose data=k3 out=gp prefix=t;
   	by key_t;
   	id gp;
   	var tooth;
run;
data gp;set gp;
drop _name_;
run;

/*key_t變項長度調整為一致*/
proc sql;
alter table gp
  modify key_t char(6) format=$6.;
quit;
proc sql;
alter table t_sum_bac
  modify key_t char(6) format=$6.;
quit;

proc sort data=gp;by key_t;run; /*n=84*/
proc sort data=t_sum_bac;by key_t;run; /*n=83*/

data bac_sum;
	merge gp(in=A) t_sum_bac(in=B);
	by key_t;
	if A & B;
run;
/*n=83*/

data bac_summary;set bac_sum;
no=substr(key_t,1,4);
run;
/*n=83*/
/*存永久檔*/
data b.bac_summary; set bac_summary;run;
/*************************************************************************/
data bac_summary; set b.bac_summary;run;

/*取log*/
%macro log10(var);
	data bs_&var.;set bac_summary;
		%do t=1 %to 4;
			&var._t&t. = log10(&var._t&t.);
		%end;
		keep key_t no t0 t1 &var._t1 &var._t2 &var._t3 &var._t4;
	run;
	proc sort data=bs_&var.;by key_t;run;
%mend;
%log10(TB1);%log10(TB0);
%log10(PG1);%log10(PG0);
%log10(PN1);%log10(PN0);
%log10(TF1);%log10(TF0);

data bs;
merge bs_tb0 bs_tb1 bs_pg0 bs_pg1 bs_pn0 bs_pn1 bs_tf0 bs_tf1;
by key_t;
run;

/*檢查missing，因為missing代表該時間點無測量值，故先不補值*/
proc means data=bs nmiss;
var _numeric_;
run;

/*算difference*/
%macro diff(var);
data diff_&var.;set bs;
	if &var._t1=. then delete; /*刪掉time=1時missing的*/
	/*or &var._t1<18.2 then &var._t1=0.001;*//*先不補值*/
	d21_&var. = &var._t2 - &var._t1;
	d31_&var. = &var._t3 - &var._t1;
	d41_&var. = &var._t4 - &var._t1;
	keep no key_t t1 t0 d21_&var. d31_&var. d41_&var.;
run;
/*proc means data=diff_&var.;
	var d21_&var. d31_&var. d41_&var.;
run;*/
proc sort data=diff_&var.;by key_t;run;
%mend;
%diff(TB1);%diff(TB0);
%diff(PG1);%diff(PG0);
%diff(PN1);%diff(PN0);
%diff(TF1);%diff(TF0);

data diff_bac;
merge diff_TB1 diff_TB0 diff_PG1 diff_PG0 
	  diff_PN1 diff_PN0 diff_TF1 diff_TF0;
by key_t;
run; /*n=82*/

/*存永久檔*/
data b.diff_bac; set diff_bac;run;
data diff_bac; set b.diff_bac;run;

/*mean change*/
%macro M(var);
%do t=2 %to 4;
	ods output Summary=s_d&t.1_&var.;
	proc means data=diff_bac;
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
%M(TB);
%M(PG);
%M(PN);
%M(TF);

data all1;
set s_d21_TB s_d31_TB s_d41_TB s_d21_PG s_d31_PG s_d41_PG 
s_d21_PN s_d31_PN s_d41_PN s_d21_TF s_d31_TF s_d41_TF;
by group;
run;

/*paired t-test*/
%macro output(var);
%do t=2 %to 4;
	ods output Statistics=&var._d&t.1_stat;
	ods output ConfLimits=&var._d&t.1_CI;
	ods output TTests=&var._d&t.1_ttest;
	proc ttest data=diff_bac;
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

%output(TB);
%output(PG);
%output(PN);
%output(TF);

data all2;
set TB_d21 TB_d31 TB_d41 PG_d21 PG_d31 PG_d41 
PN_d21 PN_d31 PN_d41 TF_d21 TF_d31 TF_d41;
by group;
run;

proc sort data=all1; by var group;run;
proc sort data=all2; by var group;run;
proc sql;
	alter table all2
  	modify var char(3) format=$3.,
		   group char(3) format=$3.;
quit;
data all;
merge all2 all1;
by var group;
run;

proc sort data=all; by group;run;


PROC EXPORT DATA= WORK.All 
            OUTFILE= "D:\重要備份\Wang\data\bac.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

/*check normality assumption*/
data c;set diff_bac;d=d21_tf0 - d21_tf1;run;
proc univariate data = c normal ;
var d;
qqplot;
run;

/*PG,PN違反normality assumption，用Wicoxon signed-rank test*/
data pg;set diff_bac;
d21=d21_pg0 - d21_pg1;
d31=d31_pg0 - d31_pg1;
d41=d41_pg0 - d41_pg1;
run;
proc univariate data=pg;
  var d21 d31 d41;
run;

data pn;set diff_bac;
d21=d21_pn0 - d21_pn1;
d31=d31_pn0 - d31_pn1;
d41=d41_pn0 - d41_pn1;
run;
proc univariate data=pn;
  var d21 d31 d41;
run;

/*IQR for PG PN*/
proc univariate data=diff_bac;
	var d21_pg0 d21_pg1 d31_pg0 d31_pg1 d41_pg0 d41_pg1
		d21_pn0 d21_pn1 d31_pn0 d31_pn1 d41_pn0 d41_pn1;
run;

