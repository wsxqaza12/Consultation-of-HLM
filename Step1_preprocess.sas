libname a 'D:\重要備份\Wang';
libname b 'D:\重要備份\Wang\data';
/*匯入資料*/
%macro import;
	%do no=2 %to 6; 
	PROC IMPORT OUT= WORK.no&no. 
            	DATAFILE= "D:\重要備份\Wang\data\statistic-n36-0413.xlsx" 
            	DBMS=EXCEL REPLACE;/*if %sysfunc(exist(00&no.)) %then %do;*/
     	RANGE="00&no.$"; 
	RUN;
	%end;
/*%mend; %import;*/
	%do no=10 %to 55; 
	PROC IMPORT OUT= WORK.no&no. 
            	DATAFILE= "D:\重要備份\Wang\data\statistic-n36-0413.xlsx" 
            	DBMS=EXCEL REPLACE;
     	RANGE="0&no.$"; 
	RUN;
	%end;
%mend; %import;

/*合併檔案*/
%macro combine;
%do i = 2 %to 55;%if %sysfunc(exist(no&i.)) %then %do;/*若某些檔案(e.g.No4)不存在則跳過*/
	/*處理不同資料集變數類型不一致問題*/
	data no&i.;	/*INPUT為文轉數，PUT為數轉文*/
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

/*合併檔案*/
data all;
	set
  	%do i = 2 %to 55;%if %sysfunc(exist(no&i.)) %then %do;
    no&i.
  	%end;%end;
  	;
run;
%mend; %combine;
/*合併完36位患者檔案，一共768*36=27648筆資料*/

/*其他處理*/
data all; set all;
	CAL = PD + GR;/*CAL補值*/
	if No_='R020' & tooth=44 then test_tooth='0'; /*R020病患的44改成不納入分析，45(control)對應34(test)*/
run;

/*匯出合併好的檔案*/
PROC EXPORT DATA= WORK.all
            OUTFILE= "D:\重要備份\Wang\data\all.csv" 
            DBMS=CSV REPLACE;
RUN;

/*存永久檔*/
libname b 'D:\重要備份\Wang\data';
data b.all; set work.all;run;

/*讀永久檔*/
libname b 'D:\重要備份\Wang\data';
data all; set b.all;run;

/*****************************till here************************************/
/*刪掉未納入分析的牙齒，剩4032筆資料*/
data part;set all;
if test_tooth=0 or test_tooth='' then delete;
run;
/*確認time & time1是一樣的東西*/
data c;set part;
if time^=time1 then delete;
run;
data part;set part;drop time1;run;

/*存永久檔*/
data b.part; set work.part;run;

/*************************************************************************/
/*讀永久檔*/
data part; set b.part;run;
PROC EXPORT DATA= WORK.part
            OUTFILE= "D:\重要備份\Wang\data\part.csv" 
            DBMS=CSV REPLACE;
RUN; /*輸出csv檔給R用*/

/*資料【dat】=> 排除不符合inclusion criteria者 (至少兩牙面CAL>=4 & PD>=5)*/
data inclusion; set part;
if time=1; /*4032/4=1008筆資料*/
key_tooth = No_||tooth; 
run;
proc sql;
	create table inclusion2 as
	select *, count(key_tooth) as count
	from inclusion
	where CAL>=4 & PD>=5
	group by key_tooth
	HAVING count>=2     /*HAVING 條件式(新資料集只保留符合條件的資料)*/
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
run;/*3648筆觀測值*/

data b.dat;set dat;run;
data dat;set b.dat;run;
