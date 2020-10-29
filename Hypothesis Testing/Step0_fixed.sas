%macro fix(no);
	PROC IMPORT OUT= WORK.no&no. 
            	DATAFILE= "D:\重要備份\Wang\data\statistic-n36-0413.xlsx" 
            	DBMS=EXCEL REPLACE;
     	RANGE="0&no.$"; 
		GETNAMES=YES;
     	MIXED=NO;
     	SCANTEXT=YES;
     	USEDATE=YES;
     	SCANTIME=YES;
	RUN;
	data no&no.;	/*INPUT為文轉數，PUT為數轉文*/
		set no&no.(rename=(Test_tooth=Test_tooth1 KM=KM1 BOP=BOP1 PI=PI1 PD=PD1 GR=GR1 tooth=tooth1 CAL=CAL1)); 
			Test_tooth = put(Test_tooth1, $1.);
			KM = input(put(KM1,$7.),7.);
			BOP = put(BOP1, $1.);
			PI = put(PI1, $1.);
			PD = input(put(PD1,$7.),7.);
			GR = input(put(GR1,$7.),7.);
			tooth = put(tooth1, $2.);
			CAL = input(put(CAL1,$7.),7.);
		drop Test_tooth1 KM1 BOP1 PI1 PD1 GR1 tooth1 CAL1 FI;
	run;
%mend;
%fix(02);%fix(03);%fix(06);%fix(10);%fix(12);%fix(14);
%fix(16);%fix(17);%fix(19);%fix(20);%fix(21);%fix(22);
%fix(23);%fix(24);%fix(25);%fix(26);%fix(28);%fix(30);
%fix(31);%fix(34);%fix(35);%fix(36);%fix(37);%fix(38);
%fix(40);%fix(42);%fix(43);%fix(44);%fix(46);%fix(47);
%fix(50);%fix(51);%fix(52);%fix(53);%fix(54);%fix(55);

/*%fix(14);%fix(40);%fix(42);%fix(47);%fix(51);*/
/*
	data no&no.;	
		set no&no.(rename=(Test_tooth=Test_tooth1 KM=KM1 BOP=BOP1 PI=PI1 PD=PD1 GR=GR1 tooth=tooth1 CAL=CAL1)); 
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
if No_ in ("R014","R040","R042","R047","R051");*/

/*合併檔案*/
%macro combine;
data all;
	set
  	%do i = 10 %to 55;%if %sysfunc(exist(no&i.)) %then %do;
    no&i.
  	%end;%end;
  	;
run;
%mend; %combine;
data all;
set all No02 No03 No06;
run;
/*合併完36位患者檔案，一共768*36=27648筆資料*/
