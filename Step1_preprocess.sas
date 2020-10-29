libname a 'D:\���n�ƥ�\Wang';
libname b 'D:\���n�ƥ�\Wang\data';
/*�פJ���*/
%macro import;
	%do no=2 %to 6; 
	PROC IMPORT OUT= WORK.no&no. 
            	DATAFILE= "D:\���n�ƥ�\Wang\data\statistic-n36-0413.xlsx" 
            	DBMS=EXCEL REPLACE;/*if %sysfunc(exist(00&no.)) %then %do;*/
     	RANGE="00&no.$"; 
	RUN;
	%end;
/*%mend; %import;*/
	%do no=10 %to 55; 
	PROC IMPORT OUT= WORK.no&no. 
            	DATAFILE= "D:\���n�ƥ�\Wang\data\statistic-n36-0413.xlsx" 
            	DBMS=EXCEL REPLACE;
     	RANGE="0&no.$"; 
	RUN;
	%end;
%mend; %import;

/*�X���ɮ�*/
%macro combine;
%do i = 2 %to 55;%if %sysfunc(exist(no&i.)) %then %do;/*�Y�Y���ɮ�(e.g.No4)���s�b�h���L*/
	/*�B�z���P��ƶ��ܼ��������@�P���D*/
	data no&i.;	/*INPUT������ơAPUT�������*/
		set no&i.(rename=(Test_tooth=Test_tooth1 KM=KM1 BOP=BOP1 PI=PI1 PD=PD1 GR=GR1 tooth=tooth1 CAL=CAL1)); 
			Test_tooth = put(Test_tooth1, $1.);
			KM = input(KM1, 7.);
			BOP = put(BOP1, $1.);
			PI = put(PI1, $1.);
			PD = input(PD1, 7.);
			GR = input(GR1, 7.);
			tooth = put(tooth1, $2.);
			CAL = input(CAL1, 7.);
		drop Test_tooth1 KM1 BOP1 PI1 PD1 GR1 tooth1 CAL1 FI;
	run;
%end;%end;

/*�X���ɮ�*/
data all;
	set
  	%do i = 2 %to 55;%if %sysfunc(exist(no&i.)) %then %do;
    no&i.
  	%end;%end;
  	;
run;
%mend; %combine;
/*�X�֧�36��w���ɮסA�@�@768*36=27648�����*/

/*��L�B�z*/
data all; set all;
	CAL = PD + GR;/*CAL�ɭ�*/
	if No_='R020' & tooth=44 then test_tooth='0'; /*R020�f�w��44�令���ǤJ���R�A45(control)����34(test)*/
run;

/*�ץX�X�֦n���ɮ�*/
PROC EXPORT DATA= WORK.all
            OUTFILE= "D:\���n�ƥ�\Wang\data\all.csv" 
            DBMS=CSV REPLACE;
RUN;

/*�s�ä[��*/
libname b 'D:\���n�ƥ�\Wang\data';
data b.all; set work.all;run;

/*Ū�ä[��*/
libname b 'D:\���n�ƥ�\Wang\data';
data all; set b.all;run;

/*****************************till here************************************/
/*�R�����ǤJ���R�������A��4032�����*/
data part;set all;
if test_tooth=0 or test_tooth='' then delete;
run;
/*�T�{time & time1�O�@�˪��F��*/
data c;set part;
if time^=time1 then delete;
run;
data part;set part;drop time1;run;

/*�s�ä[��*/
data b.part; set work.part;run;

/*************************************************************************/
/*Ū�ä[��*/
data part; set b.part;run;
PROC EXPORT DATA= WORK.part
            OUTFILE= "D:\���n�ƥ�\Wang\data\part.csv" 
            DBMS=CSV REPLACE;
RUN; /*��Xcsv�ɵ�R��*/

/*��ơidat�j=> �ư����ŦXinclusion criteria�� (�ܤ֨����CAL>=4 & PD>=5)*/
data inclusion; set part;
if time=1; /*4032/4=1008�����*/
key_tooth = No_||tooth; 
run;
proc sql;
	create table inclusion2 as
	select *, count(key_tooth) as count
	from inclusion
	where CAL>=4 & PD>=5
	group by key_tooth
	HAVING count>=2     /*HAVING ����(�s��ƶ��u�O�d�ŦX���󪺸��)*/
	;
quit;
/************************************/
proc sort data=inclusion2 out=id nodupkey;by No_;run;
proc sort data=id;by No_;run;
proc sort data=part;by No_;run;
data dat;
merge id(in=A) part(in=B);
by No_;
if A & B;
run;/*3648���[����*/

data b.dat;set dat;run;
data dat;set b.dat;run;
