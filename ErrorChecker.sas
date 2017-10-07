options ls=100 ps=72;		*SAS output will be 100 characters per page with 72 lines per page;
data one;
	infile 'C:\Users\milan\Desktop\IITA Work\EPG Data\Cassava-Tomato\Annotations\CsvTom-CST.csv' dsd missover firstobs=2 delimiter=',' end=last;
	*no user input reqired below this line!;
	length insectno$ 20 waveform$ 10 dur 8;
	input insectno$ waveform$ dur;
run;

PROC FORMAT; *Color codes for transitions;
VALUE $color
 "NP to NP" = 'Salmon'
 "NP to C" = 'LILG'
 "NP to F" = 'Gold'
 "NP to G" = 'Salmon'
 "NP to E1" = 'Salmon'
 "NP to E2" = 'Salmon'
 "NP to PD" = 'Salmon'
 "C to NP" = 'LILG'
 "C to C" = 'Salmon'
 "C to F" = 'LILG'
 "C to G" = 'LILG'
 "C to E1" = 'LILG'
 "C to E2" = 'Salmon'
 "C to PD" = 'LILG'
 "F to NP" = 'LILG'
 "F to C" = 'LILG'
 "F to F" = 'Salmon'
 "F to G" = 'LILG'
 "F to E1" = 'Salmon'
 "F to E2" = 'Salmon'
 "F to PD" = 'Gold'
 "G to NP" = 'LILG'
 "G to C" = 'LILG'
 "G to F" = 'LILG'
 "G to G" = 'Salmon'
 "G to E1" = 'Salmon'
 "G to E2" = 'Salmon'
 "G to PD" = 'Salmon'
 "E1 to NP" = 'LILG'
 "E1 to C" = 'LILG'
 "E1 to F" = 'Gold'
 "E1 to G" = 'Salmon'
 "E1 to E1" = 'Salmon'
 "E1 to E2" = 'LILG'
 "E1 to PD" = 'Salmon'
 "E2 to NP" = 'LILG'
 "E2 to C" = 'LILG'
 "E2 to F" = 'Gold'
 "E2 to G" = 'Salmon'
 "E2 to E1" = 'LILG'
 "E2 to E2" = 'Salmon'
 "E2 to PD" = 'Salmon'
 "PD to NP" = 'Gold'
 "PD to C" = 'LILG'
 "PD to F" = 'Gold'
 "PD to G" = 'Salmon'
 "PD to E1" = 'Gold'
 "PD to E2" = 'Salmon'
 "PD to PD" = 'Salmon';
RUN;

%macro PrintErrors; *tests to see if the print macro should be invoked;
	%let id=%sysfunc(open(two)); *opens dataset "two" that was created in the Proc Means statement;
	%let NObs=%sysfunc(attrn(&id,NOBS)); *The number of observations in the SAS data set. It might be none, or many;
	%syscall set(id); *This is linking macro and open code variables;
	%do i=1 %to &NObs; *this works through all observations;
		%let rc=%sysfunc(fetchobs(&id,&i)); *this fetches specific observations from the data set;
		%if  &p = 1 %then; *If the variable p in dataset work.two equals 1 then print errors;
			proc print data=one;
			where marker1 = 1;
			Title "Attention: " color=red "Errors found!!!" ;
			run;
	%end;
	%let rc=%sysfunc(close(&id));
%mend;

%macro Frequencies; *tests to see if the PFreq macro should be invoked; 
	%let id=%sysfunc(open(two)); *opens dataset "two" that was created in the Proc Means statement;
	%let NObs=%sysfunc(attrn(&id,NOBS)); *The number of observations in the SAS data set. It might be none, or many;
	%syscall set(id); *This is linking macro and open code variables;
	%do i=1 %to &NObs; *this works through all observations;
		%let rc=%sysfunc(fetchobs(&id,&i)); *this fetches specific observations from the data set;
		%if  &p = 0 %then 
			%do;
			 proc tabulate data=five5 ; class waveform; table waveform, (N PCTN='Percent');
			 title 'Frequency Table of Waveform Events';
			 Footnote "Check these numbers please!";
			 run;
			 proc tabulate data=one; class Transition; classlev Transition / s={background=$color.}; table Transition, (N PCTN='Percent');
        	 title 'Frequency Table of Waveform Transitions';
			 footnote "Transitions are color-coded: common transitions - GREEN, uncommon but perhaps plausible - YELLOW, impossible transitions - RED";
        	 run;
			 footnote blank=yes;
			%end;
	%end;
	%let rc=%sysfunc(close(&id));
%mend;

* We need to find if there are any repete behaviors. This only works on waveform designations
	with three or fewer characters. A novel waveform Z1E will be a duplicate of Z1E2. If there
	are waveforms with more characters, adjust the program accordingly.;

Data one; Set one;
waveform=upcase(waveform);

Data one; set one; *if substr(insectno,1,1)="e" then output;

waveform=compress(upcase(waveform));

Data one; set one;
	retain w0 w1 in0;
	w1=substr(waveform,1,3);
	if insectno ne in0 then do;
	  w0='   '; marker1=0;
	 in0=insectno; * in0 is the previous value of insectno. If this changes you have a new insect.;
	               *if you start a new insect then reinitialize all variables.;
	end;
*Now test if any two consecutive behaviors are the same within one insect;
*Also test if any durations are negative.;
	if w1 ne w0 and dur>0 then do;
	   w0=w1; marker1=0;
	end;
    else do;
		marker1=1;
	end;
run;

************************************************
Make sure that every recording starts with NP;
Data one; Set one; Drop w0 w1 in0;
Data one; set one;
	retain w0 w1 in0 marker2;
	w1=substr(waveform,1,3);
	if insectno ne in0 then do;
	  w0='   '; marker2=0;
	 in0=insectno; * in0 is the previous value of insectno. If this changes you have a new insect.;
	               *if you start a new insect then reinitialize all variables.;
	end;
	else marker2=1;
run;
Data one; set one;
if marker2=0 and waveform ne "NP" then marker1=1;
Run;
*Data one; *Set one; *Drop W0 W1 in0;
/************************************************************************************
	Note: In this version dataset "two" will be empty if there were no problems, and
	   SAS will not generate any output if the data set is empty.
	   If there were problems, each instance will be printed.

*************************************************************************************/;

*creates a data set two that will have variable p that will be 1 if at least one marker1 =1;
proc means data=one max noprint;
var marker1;
output out=two max=p;
run;
*creates macro to call proc print;

%PrintErrors;
*******************************************************************************
* We now look at transitions as a final error check.
* This is for error checking, not data analysis.
* First count the number of instances of each waveform. Is this list correct?
 ******************************************************************************;
/*********************************************************************************
*Now check the transitions;
*To make this work we need to first drop several variables from the data set and then
    reinitialize them.
*ZZZ is a marker for the starting behavior for each insect. It should equal the
    number of insects in the data file.
*NOTE: there should never be a behavior with the designation ZZZ.
***********************************************************************************/
Data Five5; Set one;
Data one; Set one; Drop w0 w1 in0;
Data one; Set one;
	retain w0 w1 in0;
	w1=substr(waveform,1,3);
	if insectno ne in0 then do;
	  w0='XYY';
	 in0=insectno;
	end;

   if w1 ne w0 then do; 
      if w0 ne 'XYY' then Transition=catx(' to ', of w0 w1);
	  else Transition='ZZZ';
	end;
	w0=w1;
run;
data three; set one;
data one; set one; if Transition ne "ZZZ" then output;
%Frequencies;
run;


Data Four; set three;
title 'Duration of waveforms for every insect';
proc sort; by waveform insectno;
Proc means n min max mean median; var dur; class insectno; by waveform;
run;


*/;
/*
Data one; set three; drop w0 in0 w1 marker1 Transition;
line=_N_;
InvLine=50000-_N_;
Data EveC; set one; if waveform='C' then output;
Data EveC; Set EveC; proc sort; by insectno InvLine;
Data EveC; Set EveC;
	retain w0 w1 in0;
	w1=dur;
	if insectno ne in0 then do;
	  w0=dur;
	 in0=insectno;
	end;

	Mult1=w0/w1;
	if w0>w1 then mult2=w0/w1; else mult2=-w1/w0;
	w0=w1;
Data Evec; Set EveC; Proc sort; by insectno line;
Data EveC; Set EveC; drop w0 in0 w1 line;
Data EveC; Set EveC;
	retain line in0;
	if insectno ne in0 then do;
	 line=0;
	 in0=insectno;
	end;
	line=line+1;
Data EveC; Set EveC; drop w0 in0 w1;
data eveC; Set EveC;
proc sort; by line;
proc means noprint; by line; var Mult1; output out=EveCA mean=mMult1 std=StdMult1;
data eveC; Set EveC;
mult2=mult2-1;
proc means mean std n min max t prt; by line; var mult2; 
title 'For Waveform C';

Data Evepd; set one; if waveform='PD' then output;
Data Evepd; Set Evepd; proc sort; by insectno InvLine;
Data Evepd; Set Evepd;
	retain w0 w1 in0;
	w1=dur;
	if insectno ne in0 then do;
	  w0=dur;
	 in0=insectno;
	end;

	Mult1=w0/w1;
	if w0>w1 then mult2=(-w0/w1)+1; else mult2=(w1/w0)-1; *W0/W1 converges to 1 as W0 approaches W1, multiply by -1 and subtract 1 to make it converge to zero if W0>W1 *;
	w0=w1;
Data Evepd; Set Evepd; Proc sort; by insectno line;
Data Evepd; Set Evepd; drop w0 in0 w1 line;
Data Evepd; Set Evepd;
	retain line in0;
	if insectno ne in0 then do;
	 line=0;
	 in0=insectno;
	end;
	line=line+1;
Data Evepd; Set Evepd; drop w0 in0 w1;
data Evepd; Set Evepd;
proc sort; by line;
proc means noprint; by line; var Mult1; output out=EvepdA mean=mMult1 std=StdMult1;
data Evepd; Set Evepd;
mult2=mult2-1;
proc means mean std n min max t prt; by line; var mult2; 
Title 'For Waveform pd';



Data EveE1; set one; if waveform='E1' then output;
Data EveE1; Set EveE1; proc sort; by insectno InvLine;
Data EveE1; Set EveE1;
	retain w0 w1 in0;
	w1=dur;
	if insectno ne in0 then do;
	  w0=dur;
	 in0=insectno;
	end;

	Mult1=w0/w1;
	if w0>w1 then mult2=w0/w1; else mult2=-w1/w0;
	w0=w1;
Data EveE1; Set EveE1; Proc sort; by insectno line;
Data EveE1; Set EveE1; drop w0 in0 w1 line;
Data EveE1; Set EveE1;
	retain line in0;
	if insectno ne in0 then do;
	 line=0;
	 in0=insectno;
	end;
	line=line+1;
Data EveE1; Set EveE1; drop w0 in0 w1;
data EveE1; Set EveE1;
proc sort; by line;
proc means noprint; by line; var Mult1; output out=EveE1A mean=mMult1 std=StdMult1;
data EveE1; Set EveE1;
mult2=mult2-1;
proc means mean std n min max t prt; by line; var mult2; 
Title 'For Waveform E1';



Data EveE2; set one; if waveform='E2' then output;
Data EveE2; Set EveE2; proc sort; by insectno InvLine;
Data EveE2; Set EveE2;
	retain w0 w1 in0;
	w1=dur;
	if insectno ne in0 then do;
	  w0=dur;
	 in0=insectno;
	end;

	Mult1=w0/w1;
	if w0>w1 then mult2=w0/w1; else mult2=-w1/w0;
	w0=w1;
Data EveE2; Set EveE2; Proc sort; by insectno line;
Data EveE2; Set EveE2; drop w0 in0 w1 line;
Data EveE2; Set EveE2;
	retain line in0;
	if insectno ne in0 then do;
	 line=0;
	 in0=insectno;
	end;
	line=line+1;
Data EveE2; Set EveE2; drop w0 in0 w1;
data EveE2; Set EveE2;
proc sort; by line;
proc means noprint; by line; var Mult1; output out=EveE2A mean=mMult1 std=StdMult1;
data EveE2; Set EveE2;
mult2=mult2-1;
proc means mean std n min max t prt; by line; var mult2; 
title 'For Waveform E2';


Run;
quit;
