/*�i�氲�]�˩w*/
libname b 'D:\���n�ƥ�\Wang\data';
data dat;set b.dat;run;

*�׷��ؼСG�����নwide format;
/*********************************************************/
*(A) ����e(time);
data dat1;set dat;
key=No_||tooth||site;/*�S��time��T�����*/
run;
proc sort data=dat1; by key;run;

%macro time(par);
	proc transpose data=dat1 out=t_&par. prefix=&par._t;
   		by key; /*�S��time��T�����*/
   		id time;
   		var &par.; /*���|���ܶ�*/
	run;
	data t_&par.;set t_&par.; drop _name_;run;
	/*�X���ɮ׫esort*/
	proc sort data=t_&par.; by key;run;
%mend;
%time(BOP);%time(PI);
%time(CAL);%time(GR);%time(PD);

/*�X���ɮ�merge*/
data t_wide;
	merge t_bop t_pi t_cal t_gr t_pd;
	by key;
run;/*1008�����=4032/4*/

/*����test_tooth*/
proc sort data=t_wide; by key;run;
proc sort data=dat1(keep=No_ test_tooth tooth site key) out=dat2 nodupkey;by key;run;
data a;
	merge t_wide(in=A) dat2(in=B);
	if A=1;
run; 
/*********************************************************/
*(B) �T�{�v���ճ��i�t����Ӳ�;
data b;set a;
	pos1 = substr(tooth,1,1);
	pos2 = substr(tooth,2,1);
	key = No_||site;
run;

/*���ɮ�*/
%macro group(var);
	data test_&var.;set b;
		if test_tooth=2;/*test*/
		if pos1='2' then pos1='1';
		else if pos1='4' then pos1='3';
		t1=tooth; 
		&var._t1_g1=&var._t1;&var._t2_g1=&var._t2;&var._t3_g1=&var._t3;&var._t4_g1=&var._t4;
		key2=key||pos1||pos2;
		keep No_ site t1 pos1 pos2 &var._t1_g1 &var._t2_g1 &var._t3_g1 &var._t4_g1 key2;
	run;
	proc sort data=test_&var.; by key2;run;

	data control_&var.;set b;
		if test_tooth=1;/*control*/
		if pos1='2' then pos1='1';
		else if pos1='4' then pos1='3';
		t0=tooth; 
		&var._t1_g0=&var._t1;&var._t2_g0=&var._t2;&var._t3_g0=&var._t3;&var._t4_g0=&var._t4;
		key2=key||pos1||pos2;
		keep No_ site t0 pos1 pos2 &var._t1_g0 &var._t2_g0 &var._t3_g0 &var._t4_g0 key2;
	run;
	proc sort data=control_&var.; by key2;run;
%mend;
%group(BOP);%group(PI);
%group(CAL);%group(GR);%group(PD);

data test;merge test_bop test_pi test_cal test_gr test_pd;by key2;run;/*504*/
data control;merge control_bop control_pi control_cal control_gr control_pd;by key2;run;/*504*/

data t;set test;key=No_||site||pos1||pos2;drop key2;run;
proc sort data=t;by key;run;
data c;set control;key=No_||site||pos1||pos2;drop key2;run;
proc sort data=c;by key;run;

/*���t�令�\�������u��504���A��ܦ��ǥ��t�令�\*/
data final;
merge t c;
by key;
run;/*558*/

/*���t�令�\��*/
data f1;
merge t(in=A) c(in=B);
by key;
if A & B;
run;/*450*/

/*�S�t�令�\��*/
data f2;set final;
if t0^=. & t1^=. then delete;
run;/*108*/

data t_f2;set f2;
if t1^=.;
pos2='4';
key=No_||site||pos1||pos2;
keep No_ site t1 pos1 pos2 key BOP_t1_g1 BOP_t2_g1 BOP_t3_g1 BOP_t4_g1 PI_t1_g1 PI_t2_g1 PI_t3_g1 PI_t4_g1 
CAL_t1_g1 CAL_t2_g1 CAL_t3_g1 CAL_t4_g1 GR_t1_g1 GR_t2_g1 GR_t3_g1 GR_t4_g1 PD_t1_g1 PD_t2_g1 PD_t3_g1 PD_t4_g1;
run;
data c_f2;set f2;
if t0^=.;
pos2='4';
key=No_||site||pos1||pos2;
keep No_ site t0 pos1 pos2 key BOP_t1_g0 BOP_t2_g0 BOP_t3_g0 BOP_t4_g0 PI_t1_g0 PI_t2_g0 PI_t3_g0 PI_t4_g0 
CAL_t1_g0 CAL_t2_g0 CAL_t3_g0 CAL_t4_g0 GR_t1_g0 GR_t2_g0 GR_t3_g0 GR_t4_g0 PD_t1_g0 PD_t2_g0 PD_t3_g0 PD_t4_g0;
run;

proc sort data=t_f2;by key;run;
proc sort data=c_f2;by key;run;

data new_f2;
merge t_f2 c_f2;
by key;
run;/*54*/

*(C)�����Ҧ�test vs. control���t��;
data final_v2;
set f1 new_f2;
by key;
drop pos1 pos2 key;
run;/*504*/
/*********************************************/
data final_v2;set final_v2;key_tooth=No_||t1;run; /*tooth-level*/
/*�s�ä[��*/
data b.final_v2; set final_v2;run;
data final_v2; set b.final_v2;run;

*(D)�⥭����;
proc sql;
	create table all_M_c as
	select key_tooth,
	mean(CAL_t1_g0) as M_CAL0_t1,mean(CAL_t2_g0) as M_CAL0_t2,mean(CAL_t3_g0) as M_CAL0_t3,mean(CAL_t4_g0) as M_CAL0_t4,
	mean(CAL_t1_g1) as M_CAL1_t1,mean(CAL_t2_g1) as M_CAL1_t2,mean(CAL_t3_g1) as M_CAL1_t3,mean(CAL_t4_g1) as M_CAL1_t4,
	mean(gr_t1_g0) as M_gr0_t1,mean(gr_t2_g0) as M_gr0_t2,mean(gr_t3_g0) as M_gr0_t3,mean(gr_t4_g0) as M_gr0_t4,
	mean(gr_t1_g1) as M_gr1_t1,mean(gr_t2_g1) as M_gr1_t2,mean(gr_t3_g1) as M_gr1_t3,mean(gr_t4_g1) as M_gr1_t4,
	mean(pd_t1_g0) as M_pd0_t1,mean(pd_t2_g0) as M_pd0_t2,mean(pd_t3_g0) as M_pd0_t3,mean(pd_t4_g0) as M_pd0_t4,
	mean(pd_t1_g1) as M_pd1_t1,mean(pd_t2_g1) as M_pd1_t2,mean(pd_t3_g1) as M_pd1_t3,mean(pd_t4_g1) as M_pd1_t4,
	max(BOP_t1_g1) as  c_BOP1_t1, max(BOP_t2_g1) as  c_BOP1_t2,max(BOP_t3_g1) as  c_BOP1_t3,max(BOP_t4_g1) as  c_BOP1_t4,
	max(BOP_t1_g0) as  c_BOP0_t1, max(BOP_t2_g0) as  c_BOP0_t2,max(BOP_t3_g0) as  c_BOP0_t3,max(BOP_t4_g0) as  c_BOP0_t4,
	max(pi_t1_g1) as  c_pi1_t1, max(pi_t2_g1) as  c_pi1_t2,max(pi_t3_g1) as  c_pi1_t3,max(pi_t4_g1) as  c_pi1_t4,
	max(pi_t1_g0) as  c_pi0_t1, max(pi_t2_g0) as  c_pi0_t2,max(pi_t3_g0) as  c_pi0_t3,max(pi_t4_g0) as  c_pi0_t4
	from final_v2
	group by key_tooth;
quit;

proc sort data=all_M_c;by key_tooth;run;
proc sort data=final_v2(keep=No_ t1 t0 key_tooth) out=ff nodupkey;by key_tooth;run;

data summ;
merge all_M_c(in=A) ff(in=B);
by key_tooth;
if A & B;
run;/*84=504/6*/

data b.summ;set summ;run;
/***********************************************************************************/
*(E)�s���ܶ��G��M�Ĥ@�Ӯɶ��I�ۤ�difference;
%macro diff(par,var);
data diff_&var.;set summ;
	d21_&var. = &par._t2 - &par._t1;
	d31_&var. = &par._t3 - &par._t1;
	d41_&var. = &par._t4 - &par._t1;
	keep no_ t1 t0 d21_&var. d31_&var. d41_&var. key_tooth;
run;
proc sort data=diff_&var.;by key_tooth;run;
%mend;
%diff(M_cal1,cal1);%diff(M_cal0,cal0);
%diff(M_gr1,gr1);%diff(M_gr0,gr0);
%diff(M_pd1,pd1);%diff(M_pd0,pd0);


data diff_con;
merge diff_cal1 diff_cal0 diff_gr1 diff_gr0 diff_pd1 diff_pd0;
by key_tooth;
run;

/*�s�ä[��*/
libname b 'D:\���n�ƥ�\Wang\data';
data b.diff_con; set work.diff_con;run;

*(F)���O�ܶ��G��M�Ĥ@�Ӯɶ��I�ۤ񦳵L�ﵽ;
/*�Y�e�� �� �{�ɯg�p�A�����M��� �S�� �{�ɯg�p�A�P�O���u�ﵽ�v�F
�Y�e�� �� �{�ɯg�p�A�����M��� �� �{�ɯg�p�A�P�O���u�S���ﵽ�v�F
���V�����p�A���k���S���ﵽ*/
proc freq data=summ;
tables c_BOP1_t1 c_BOP1_t2 c_BOP1_t3 c_BOP1_t4;
run;

%macro diff_d(var);
data d_&var.;set summ;
%do t=2 %to 4;
if c_&var._t1=1 & c_&var._t&t.=0 then d&t.1_&var.=1;/*���ﵽ*/
else if c_&var._t1='' or c_&var._t&t.='' then d&t.1_&var.='.';
else d&t.1_&var.=0;
%end;
keep no_ t1 t0 key_tooth d21_&var. d31_&var. d41_&var.;
run;
%mend;
%diff_d(bop1);%diff_d(bop0);
%diff_d(pi1);%diff_d(pi0);

data diff_dis;
merge d_bop1 d_bop0 d_pi1 d_pi0;
by key_tooth;
run;

/*�s�ä[��*/
libname b 'D:\���n�ƥ�\Wang\data';
data b.diff_dis; set work.diff_dis;run;

*(G)���O�ܶ�;
/*�M��BOP��PI�L����paper�u���b�U�Ӯɶ��I���ʤ���A
ex: ���ժ̢Ϧbbaseline�� 60�Ӥ��������ߴ�/�`����120��(���]20����x6�ӭ�)�A
���L��PI�N�O50%�C�M��h�����Ҧ����ժ̱o��@��PI��BOP�����βv*/
data final_v3;set final_v2
(rename=(BOP_t1_g1=BOP_t1_g11 BOP_t2_g1=BOP_t2_g11 BOP_t3_g1=BOP_t3_g11 BOP_t4_g1=BOP_t4_g11
PI_t1_g1=PI_t1_g11 PI_t2_g1=PI_t2_g11 PI_t3_g1=PI_t3_g11 PI_t4_g1=PI_t4_g11
BOP_t1_g0=BOP_t1_g01 BOP_t2_g0=BOP_t2_g01 BOP_t3_g0=BOP_t3_g01 BOP_t4_g0=BOP_t4_g01
PI_t1_g0=PI_t1_g01 PI_t2_g0=PI_t2_g01 PI_t3_g0=PI_t3_g01 PI_t4_g0=PI_t4_g01));

BOP_t1_g1=input(BOP_t1_g11,1.);BOP_t2_g1=input(BOP_t2_g11,1.);BOP_t3_g1=input(BOP_t3_g11,1.);BOP_t4_g1=input(BOP_t4_g11,1.);
PI_t1_g1=input(PI_t1_g11,1.);PI_t2_g1=input(PI_t2_g11,1.);PI_t3_g1=input(PI_t3_g11,1.);PI_t4_g1=input(PI_t4_g11,1.);

BOP_t1_g0=input(BOP_t1_g01,1.);BOP_t2_g0=input(BOP_t2_g01,1.);BOP_t3_g0=input(BOP_t3_g01,1.);BOP_t4_g0=input(BOP_t4_g01,1.);
PI_t1_g0=input(PI_t1_g01,1.);PI_t2_g0=input(PI_t2_g01,1.);PI_t3_g0=input(PI_t3_g01,1.);PI_t4_g0=input(PI_t4_g01,1.);

drop BOP_t1_g11 BOP_t2_g11 BOP_t3_g11 BOP_t4_g11 PI_t1_g11 PI_t2_g11 PI_t3_g11 PI_t4_g11
BOP_t1_g01 BOP_t2_g01 BOP_t3_g01 BOP_t4_g01 PI_t1_g01 PI_t2_g01 PI_t3_g01 PI_t4_g01;
run;

proc sql;
	create table dis_BOP_t1_g1 as
	select No_, count(No_) as denominaotr, sum(BOP_t1_g1) as num_BOP_t1_g1,
	sum(BOP_t1_g0) as num_BOP_t1_g0
	from final_v3
	where BOP_t1_g1^=. /*or BOP_t1_g0^=. */
	group by No_;
quit;

%macro summ(var,time);
proc sql;
	create table dis_&var._t&time. as
	select No_, count(No_) as denominaotr, sum(&var._t&time._g1) as num_&var._t&time._g1,
	sum(&var._t&time._g0) as num_&var._t&time._g0
	from final_v3
	where &var._t&time._g1^=.
	group by No_;
quit;
proc sql;
	create table &var._t&time. as
	select No_, num_&var._t&time._g1/denominaotr as &var._t&time._g1,
	num_&var._t&time._g0/denominaotr as &var._t&time._g0
	from dis_&var._t&time.;
quit;
%mend;
%summ(BOP,1);%summ(BOP,2);%summ(BOP,3);%summ(BOP,4);
%summ(PI,1);%summ(PI,2);%summ(PI,3);%summ(PI,4);


%macro summary(var,t);
	proc sql;
		create table a_&var._t&t. as
		select sum(&var._t&t._g1) as a, sum(&var._t&t._g0) as b, count(No_) as c, 
			   sum(&var._t&t._g1)/count(No_) as g1, 
			   sum(&var._t&t._g0)/count(No_) as g0,
			   &t. as time, "&var." as var format=$5.
		from &var._t&t.;
	quit;
%mend;
%summary(BOP,1);%summary(BOP,2);%summary(BOP,3);%summary(BOP,4);
%summary(PI,1);%summary(PI,2);%summary(PI,3);%summary(PI,4);

data discrete;
	set a_BOP_t1 a_BOP_t2 a_BOP_t3 a_BOP_t4
		a_PI_t1 a_PI_t2 a_PI_t3 a_PI_t4;
	by time;
run;

PROC EXPORT DATA= WORK.Discrete 
            OUTFILE= "D:\���n�ƥ�\Wang\data\discrete.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

/*
proc sql;
	create table a_BOP_t1 as
	select sum(BOP_t1_g1) as a, count(No_) as b, 
		   sum(BOP_t1_g1)/count(No_) as M_BOP_t1_g1,
		   sum(BOP_t1_g0) as c, sum(BOP_t1_g0)/count(No_) as M_BOP_t1_g0,
		   1 as time
	from BOP_t1;
quit;


num_BOP_t1_g1/denominaotr as BOP_t1_g1,
	num_BOP_t1_g0/denominaotr as BOP_t1_g0

proc sql;
	create table dis_BOP_t2_g1 as
	select No_, count(No_) as denominator, sum(BOP_t2_g1) as numerator_BOP_t2
	from final_v3
	where BOP_t2_g1^=.
	group by No_;
quit;

discrete
 

proc sql;
	create table try as
	select No_, count(No_) as denominator, 
sum(BOP_t1_g1) as BOP_t1_g1, sum(BOP_t2_g1) as BOP_t2_g1, 
sum(BOP_t3_g1) as BOP_t3_g1, sum(BOP_t4_g1) as BOP_t4_g1
	from final_v3
	group by No_;
quit;*/
