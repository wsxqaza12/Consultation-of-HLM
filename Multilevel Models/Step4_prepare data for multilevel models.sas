libname b "D:\重要備份\Wang\data";

data dat;set b.dat;run;
/*create min_XX & m_XX*/
data _dat(drop=count);
	set dat(rename=(time=time1));
	if test_tooth=1 then trt=0;
	else if test_tooth=2 then trt=1;
	else trt=.;
	time=put(time1,1.);
	drop time1;
run;
data dat1;
	set _dat;
	length k1 $10;
	time_trt=time*trt;
	k1=tooth||"-"||site;
run;
data _dat1;
	set dat1;
	length a b b1 $1;
	if substr(site,1,1)='M' then do;
		a=put(input(substr(tooth,2,1),1.)-1,1.); 
	end;
	else if substr(site,1,1)='D' then do;
		a=put(input(substr(tooth,2,1),1.)+1,1.);
	end;
	else a=put(input(substr(tooth,2,1),1.),1.);


	if length(strip(site))=2 then do;
		if substr(site,1,1)='M' then do;
			b='D'; b1='D';
		end;
		else do; 
			b='M'; b1='M';
		end;
	end;
	else do;
		b='M';
		b1='D';
	end;
	where time='1'; /*baseline*/
run;
/*%if %substr(site,1,1)='M' %then 'D'; %else 'M';*/
/*%macro site;*/
data dat2;
	set _dat1;
	length k2 k3 $10;
	if length(strip(site))=2 then do;
		if substr(tooth,1,1) in ('1','4') then do;
			if substr(tooth,2,1) not in ('1','8') then do;
				k2=substr(tooth,1,1)||a||"-"||b||substr(site,2,1);
				k3=substr(tooth,1,1)||a||"-"||b1||substr(site,2,1);
			end;
			else if substr(tooth,2,1)='1' then do;
				if substr(tooth,1,1)='1' then do;
					k2='21-'||site;
					k3='21-'||site;
				end;
				else if substr(tooth,1,1)='4' then do;
					k2='31-'||site;
					k3='31-'||site;
				end;
			end;
		end;
		else if substr(tooth,1,1) in ('2','3') then do;
			if substr(tooth,2,1) not in ('1','8') then do;
				k2=substr(tooth,1,1)||a||"-"||b||substr(site,2,1);
				k3=substr(tooth,1,1)||a||"-"||b1||substr(site,2,1);
			end;
			else if substr(tooth,2,1)='1' then do;
				if substr(tooth,1,1)='2' then do;
					k2='11-'||site;
					k3='11-'||site;
				end;
				else if substr(tooth,1,1)='3' then do;
					k2='41-'||site;
					k3='41-'||site;
				end;
			end;
		end;
	end;
	else do;
		k2=substr(tooth,1,1)||a||"-"||b||substr(site,1,1);
		k3=substr(tooth,1,1)||a||"-"||b1||substr(site,1,1);
	end;

run;
/*%mend;*/
/**/
/*%site;*/

############################################################  
                           F1
############################################################  
data d1;
	set dat2(drop=k2 k3);
	rename PD=_PD1 CAL=_CAL1 GR=_GR1 BOP=_BOP1 PI=_PI1 k1=k2;
run;
data d2;
	set dat2(drop=k3 k2);
	rename PD=_PD2 CAL=_CAL2 GR=_GR2 BOP=_BOP2 PI=_PI2 k1=k3;
run;

proc sort data=dat2 out=d;
	by trt time No_ k2;
run;
proc sort data=d1 out=d1;
	by trt time No_ k2;
run;
data f1;
	merge d(in=aa) d1(keep=_PD1 _CAL1 _GR1 _BOP1 _PI1 k2 time trt No_);
	by trt time No_ k2;
	if aa;
run;

############################################################  
                           F2
############################################################  

proc sort data=dat2 out=d;
	by trt time No_ k3;
run;
proc sort data=d2 out=d2;
	by trt time No_ k3;
run;
data f2;
	merge d(in=bb) d2(keep=_PD2 _CAL2 _GR2 _BOP2 _PI2 k3 time trt No_);
	by trt time No_ k3;
	if bb;
run;

proc sort data=f1;
	by trt time No_ k1;
run;
proc sort data=f2(keep=k1 time trt _PD2 _CAL2 _GR2 _BOP2 _PI2 No_);
	by trt time No_ k1;
run;
data _f;
	merge f1 f2;
	by trt time No_ k1;
run; 
/*4032*/

proc sql;
	create table _f2 as
	select *, min(_PD1,_PD2) as min_PD, min(_CAL1,_CAL2) as min_CAL, min(_GR1,_GR2) as min_GR, /*min(_BOP1,_BOP2) as min_BOP, min(_PI1,_PI2) as min_PI,*/
			mean(_PD1,_PD2) as m_PD, mean(_CAL1,_CAL2) as m_CAL, mean(_GR1,_GR2) as m_GR/*, mean(_BOP1,_BOP2) as m_BOP, mean(_PI1,_PI2) as m_PI*/
	from _f
	;
quit;

data f;
	set _f2;
	array l1[*] _PD1 _CAL1 _GR1;
	array l2[*} min_PD min_CAL min_GR;
	array l3[*} m_PD m_CAL m_GR; 
	if length(site)=2 then do;
		do i=1 to dim(l1);
			l2[i]=l1[i];
			l3[i]=l1[i];
		end;
		min_BOP=_BOP1; m_BOP=_BOP1;
		min_PI=_PI1; m_PI=_PI1;
	end;
	else do;
		if cmiss(_BOP1,_BOP2)=2 then do;
			min_BOP=''; m_BOP='';
		end;
		else if strip(_BOP1)='1' or strip(_BOP2)='1' then do;
			min_BOP='1'; m_BOP='1';
		end;
		else do;
			min_BOP='0'; m_BOP='0';
		end;

		if cmiss(_PI1,_PI2)=2 then do;
			min_PI=''; m_PI='';
		end;
		else if strip(_PI1)='1' or strip(_PI2)='1' then do;
			min_PI='1'; m_PI='1';
		end;
		else do;
			min_PI='0'; m_PI='0';
		end;
	end;
	drop i;
run;

proc sort data=f out=baseline(keep=_PD1 _CAL1 _GR1 _BOP1 _PI1 _PD2 _CAL2 _GR2 _BOP2 _PI2 
									min_PD min_CAL min_GR min_BOP min_PI m_PD m_CAL m_GR m_BOP m_PI k1 trt No_); /*no time info*/
	by trt No_ k1;
run; 
proc sort data=dat1;
	by trt No_ k1;
run; 

data final;
	merge dat1(in=a) baseline;
	by trt No_ k1;
	if a;
run;
proc sort data=final;
	by No_ k1 trt time;
run;
/*data f;*/
/*	set _f;*/
/*	where cmiss(PD,_PD1,_PD2)=0 & cmiss(CAL,_CAL1,_CAL2)=0 & cmiss(GR,_GR1,_GR2)=0 & cmiss(BOP,_BOP1,_BOP2)=0 & cmiss(PI,_PI1,_PI2)=0;*/
/*run;*/
/*2068*/

data b.fm;
	set final;
run;

data final;
	set b.fm;
run;
proc sort data=final;
	by No_ tooth site trt time;
run;
data final2;
	set final;
	if time='1' then do;
		if ^missing(PD) then base_PD=PD;
		if ^missing(CAL) then base_CAL=CAL;
		if ^missing(GR) then base_GR=GR;
	end;
	retain base_PD base_CAL base_GR;
run;

data b.fm2;
	set final2;
run;
