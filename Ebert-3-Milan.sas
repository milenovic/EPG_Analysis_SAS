*********************   CRITICAL INFORMATION   **********************
*********************************************************************
**    Input data must be in this order:                            **
**		Insect Number                                              **
**		Waveform                                                   **
**		Duration of behavior in seconds                            **
**    Adjust the read satatemnt if other variables are present.    **
**    Observation times must be in seconds                         **
*********************************************************************
************  This version is for DC recorded WHITEFLIES ************
*********************************************************************
**************************   Data sets List      ********************
**	one: the raw data set with Insectno, Waveform, and Durations
**  onepd: The raw data with all pd waveforms combined into C
**	two: Ebert variables
**	three: a dataset used to extract information from dataset one
**	OnlyE1: a dataset with insects that all express E1 at least once
**	OnlyE2: a dataset with insects that all express E2 at least once
**	OnlySusE2: only insects having E2 longer than 10 minutes
**	Z: only z waveform
**	NP: only NP waveform
**	C: only C waveform
**	G: only G waveform
**	F: only F waveform
**	E1: only E1 waveform
**	E2: only E2 waveform
**	PD: only PD waveform
**	OnlyPrbs: Data set reduced to probe versus non-probe. #New#
**	
*********************************************************************
*********************************************************************
********************    Variables List     **************************
**	Insectno: The unique identifier for each individual in dataset
**	Waveform: The unique 3 character identifier for behavior
*****		Current options: Z C NP F G E1 E2 D PD II1 II2 E1e

**	Dur: The duration in seconds for each behavior
**	Book keeping variables: ino, w0, w1, marker1, marker2, holder1
**	Line: Variable used to restore chronological order
**	Inverter1: Variable used to reverse chronological order
**	Instance: The number of times a given behavior is recorded
**	Sumstart: time from start of recording to start of behavior
**	SumEnd: time from start of recording to end of behavior

*********************************************************************
*********************************************************************;
options ls=100 ps=72;
%let InPath = C:\Users\milan\Desktop\IITA Work\EPG Data\; *Folder with input file. WITH \ at the end please;
%let InFile = CsvSwpTomCot-CST-CsvSwp-SPT; *Input file name, Without extension please (it is assumed to be .csv);
%let OutPath = C:\Users\milan\Desktop\IITA Work\EPG Data\testout\; *Folder to put the results, WITH \ at the end please;
x "cd ""&OutPath.""";
Data one(keep=insectno waveform dur);
	infile "&InPath.&InFile..csv" dsd missover firstobs=2 delimiter=',' end=last;
	length  insectno$ 20 waveform$ 10 dur 8; *specifies record lengths for reading variables;
	input  insectno$ waveform$ dur; *creates variable names for input. The $ character tells SAS to treat these variables as charaters not numbers;

    waveform=compress(upcase(waveform)); * compress-upcase is done here, it is not neccessary afterwards (speed optimization);
    if waveform='Z' then waveform='NP';
run;

data one; set one;
if waveform='1' then waveform='NP';
if waveform='2' then waveform='C';
if waveform='3' then waveform='E1E';
if waveform='4' then waveform='E1';
if waveform='5' then waveform='E2';
if waveform='6' then waveform='F';
if waveform='7' then waveform='G';
if waveform='8' then waveform='PD';
if waveform='9' then waveform='II2';
if waveform='10' then waveform='II3';
if waveform='11' then waveform="PDL";

data one; set one;
	trt=substr(insectno,1,1);  *recover treatment designations*;
    *insectno=compress(trt||insectno);
	Transform=1; *Transform=0 will disable all transformations*;
    proc sort; by insectno;
*ODS noresults; *suppresses output to "results" and "output" windows.;
ODS HTML file="&OutPath.&InFile.-Output.html";

Data one; set one;
      line=_n_;
*     Calculate time to start and time to end of each behavior.;
      retain in0 SumStart SumEnd dur0;
      if insectno ne in0 then do;
       SumStart=0.0; SumEnd=0.0; dur0=0.0;
       in0=insectno;
      end;
      SumEnd= sum(SumEnd, dur);
      SumStart= sum(SumStart, Dur0);
      dur0=dur;
	proc sort; by insectno waveform line;

data one; set one;
WHERE dur is NOT MISSING; *WHERE is more efficient than IF;

proc sort data=one; by insectno waveform;
data one;set one; by insectno waveform;
	retain instance;
	if first.waveform then instance=0;
	instance=instance+1;
Proc sort data=One; by line;
Data one; set one;
	inverter1=50000-line;
Data one; set one; drop in0 dur0;

Data one; set one;
retain in0 holder1;
if in0 ne insectno then do; in0=insectno; holder1=0; end;
holder1 = sum(holder1, dur);
data one; set one; drop in0;
proc sort data=one; by inverter1;
data one; set one;
retain in0 maxdur;
if in0 ne insectno then do; in0=insectno; maxdur=holder1; end;
data one; set one; drop in0 holder1;
proc sort data=one; by line;
Run;

*********************************************************************
*****We need three data sets associated with pd.                   **
***** 1) All pd are merged into C   (OnlyCNoPD)                    **
***** 2) Only insects with a pd waveform are included (OnlyPd)     **
***** 3) All pd type waveforms are mergec into a generic pd (OnePd)**
*****                                                              **
*****Part 1) Generate dataset OnlyCNoPD                            **
*****        This data set combines all pd waveforms into C        **
*********************************************************************;
Data OnlyCNoPd; set one;
	if waveform='PD' then waveform='C';
	if waveform='PDS' then waveform='C';
	if waveform='PDL' then waveform='C';
	if waveform='II1' then waveform='C';
	if waveform='II2' then waveform='C';
	if waveform='II3' then waveform='C';
*	if waveform='F'   then waveform='C'; *Activating this line merges F and C waveforms*;
Proc sort data=OnlyCNoPD; by line;
Data OnlyCNoPd; Set OnlyCNoPd;
	retain w0 w1 in0 marker1;
	w1=waveform;
	if insectno ne in0 then do;
	  w0='  '; in0=insectno; marker1=0;
	end;
	if w1 ne w0 then do; 
		marker1=marker1+1;
		w0=w1;
	end;
data OnlyCNoPd; set OnlyCNoPd;
proc means noprint; by insectno marker1; var dur; output out=onepdSAS sum=durSum;
Data onepdSAS; set onepdSAS; dur=dursum;

data OnlyCNoPd; set OnlyCNoPd; drop dur line sumstart sumend instance inverter1 w1 w0 in0;
Data OnlyCNoPd; Set OnlyCNoPd;
	retain w0 w1 in0 time1;
	w1=waveform;
	if insectno ne in0 then do;
	  w0='  '; in0=insectno; time1=0;
	end;
	if time1=0 then do; output; time1=1; end;
	else If w1 ne w0 then output;
	w0=w1;
data onepdSAS; set onepdSAS OnlyCNoPd; merge onepdSAS OnlyCNoPd; by insectno marker1;
data oneD; set onepdSAS; Var1=insectno; Var2=waveform; Var3=dur;
data oneD; set oneD; drop insectno marker1 _TYPE_ _Freq_ dursum dur waveform;
Data oneD; set oneD; waveform=Var2; insectno=Var1; dur=Var3;
data oneD; set oneD; drop Var1 var2 var3;
Data OnlyCNoPd; set oneD; line=_n_;
Data OnlyCNoPd; Set OnlyCNoPd; drop in0 w1 w0;
Data OnlyCNoPd; Set OnlyCNoPd;
      retain in0 SumStart SumEnd dur0;
      if insectno ne in0 then do;
       SumStart=0.0; SumEnd=0.0; dur0=0.0;
       in0=insectno;
      end;
      SumEnd=sum(SumEnd, dur);
      SumStart=sum(SumStart, Dur0);
      dur0=dur;
proc sort; by insectno waveform line;
data OnlyCNoPd; set OnlyCNoPd; drop in0 dur0;
data OnlyCNoPd;set OnlyCNoPd; by insectno waveform;
	retain instance;
	if first.waveform then instance=0;
	instance=instance+1;
Proc sort data=OnlyCNoPD; by line;
data OnlyCNoPd; set OnlyCNoPd; inverter1=50000-line;
data OnlyCNoPd; set OnlyCNoPd; drop time1;
proc delete lib=work data= oneD onepdSAS;
run;
*********************************************************************
**************************   Method end   ***************************
*********************************************************************;

*********************************************************************
*******                  Start New Method                         ***
*******            define the dataset OnlyPd                      ***
*********************************************************************;
Proc sort data=one out=three; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=0; 
	end;
    if waveform='PD' then Marker1=1;
Data three; set three;
Proc sort; by insectno Inverter1;
Data three; set three; drop in0;
Data three; Set three;
	retain in0 marker2;
	if insectno ne in0 then do;
	  marker2=0; in0=insectno; 
	end;
	if marker1=1 then marker2=1;
	if marker1=0 and marker2=1 then marker2=1;
Data three; set three;
Where marker2=1;
Proc sort data=three; by insectno line;
data three; set three; drop marker1 marker2 in0;
Data OnlyPd; Set three;
run;
*********************************************************************
*  Finished creating dataset OnlyPd
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXXX;

*********************************************************************
*******                       Start New Method                    ***
*******                   define the dataset onepd                ***
*******	 all pds and pdl have been added to make a single pd event***
*********************************************************************;
Data onepd; set onlypd;  *convert pds and pdl into pd;
if waveform='PDL' or 
	waveform='PDS' or
	waveform='II2' or
	waveform='II3' then waveform='PD';
Proc sort data=onepd out=onepd; by line;
Data onepd; Set onepd;
	retain w0 w1 in0 marker1;
	w1=waveform;
	if insectno ne in0 then do;
	  w0='  '; in0=insectno; marker1=0;
	end;
	if w1 ne w0 then do; 
		marker1=marker1+1;
		w0=w1;
	end;
data onepd; set onepd;
proc means noprint; by insectno marker1; var dur; output out=onepdSAS sum=durSum;

Data onepdSAS; set onepdSAS; dur=dursum;
data onepd; set onepd; drop dur line sumstart sumend instance w1 w0 in0;
data onepd; set onepd;
retain in0 marker2 marker3;
if in0 ne insectno then do; in0=insectno; marker2=0; marker3=0; end;
if marker2 ne marker1 then marker3=1; else marker3=0;
marker2=marker1;
data onepd; set onepd; Where marker3=1;
data onepd; set onepd; drop marker2 marker3 in0;
data onepdSAS; set onepdSAS onepd; merge onepd onepdSAS; by insectno marker1;
data oneD; set onepdSAS; Var1=insectno; Var2=waveform; Var3=dur;
data oneD; set oneD; drop insectno marker1 _TYPE_ _Freq_ dursum dur waveform;
Data oneD; set oneD; insectno=Var1; waveform=Var2; dur=Var3;
data oneD; set oneD; drop Var1 var2 var3;
Data onepd; set oneD;
Data onepd; Set onepd;
line=_n_;
Data onepd; Set onepd;
      retain in0 SumStart SumEnd dur0;
      if insectno ne in0 then do;
       SumStart=0.0; SumEnd=0.0; dur0=0.0;
       in0=insectno;
      end;
      SumEnd=sum(SumEnd, dur);
      SumStart=sum(SumStart, Dur0);
      dur0=dur;
proc sort; by insectno waveform;
data onepd; set onepd; by insectno waveform;
retain instance;
if first.waveform then do;instance=0;end;
instance=instance+1;
proc sort data=onepd out=onepd; by line;
data onepd; set onepd; drop in0 dur0;
data onepd; set onepd; inverter1=50000-line;
proc delete lib=work data= oned onepdSAS;
run;
*********************************************************************
*  Finished creating dataset OnePd
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*;

*********************************************************************
*******                             Start New Method              ***
*******                        define the dataset OnlyG           ***
*********************************************************************;
Proc sort data=one out=three; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=0; 
	end;
    if waveform='G' then Marker1=1;
Data three; set three;
Proc sort; by insectno Inverter1;
Data three; set three; drop in0;
Data three; Set three;
	retain in0 marker2;
	if insectno ne in0 then do;
	  marker2=0; in0=insectno; 
	end;
	if marker1=1 then marker2=1;
	if marker1=0 and marker2=1 then marker2=1;
Data three; set three;
Where marker2=1;
Proc sort data=three; by insectno line;
data three; set three; drop marker1 marker2 in0;
Data OnlyG; Set three;
run;
*********************************************************************
*  Finished creating dataset OnlyG
**********************************     END      *********************;

*********************************************************************
*******                          Start New Method                 ***
*******                     define the dataset OnlyF              ***
*********************************************************************;
Proc sort data=one out=three; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=0; 
	end;
    if waveform='F' then Marker1=1;
Data three; set three;
Proc sort; by insectno Inverter1;
Data three; set three; drop in0;
Data three; Set three;
	retain in0 marker2;
	if insectno ne in0 then do;
	  marker2=0; in0=insectno; 
	end;
	if marker1=1 then marker2=1;
	if marker1=0 and marker2=1 then marker2=1;
Data three; set three;
Where marker2=1;
Proc sort data=three; by insectno line;
data three; set three; drop marker1 marker2 in0;
Data OnlyF; Set three;
run;
*********************************************************************
*  					Finished creating dataset OnlyF					*
*********************************************************************;



*********************************************************************
*******                            Start New Method               ***
*******                        define the dataset OnlyD           ***
*********************************************************************;
*Milan: Commented out. What is the waveform D?;
/*
Proc sort data=one out=three; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=0; 
	end;
    if waveform='D' then Marker1=1;
Data three; set three;
Proc sort; by insectno Inverter1;
Data three; set three; drop in0;
Data three; Set three;
	retain in0 marker2;
	if insectno ne in0 then do;
	  marker2=0; in0=insectno; 
	end;
	if marker1=1 then marker2=1;
	if marker1=0 and marker2=1 then marker2=1;
Data three; set three;
Where marker2=1;
Proc sort data=three; by insectno line;
data three; set three; drop marker1 marker2 in0;
Data OnlyD; Set three;
run;

*********************************************************************
*  Finished creating dataset OnlyD
*******************************  END  ******************************;
*/;

*********************************************************************
*******                             Start New Method              ***
*******                        define the dataset OnlyE1          ***
*********************************************************************;
Proc sort data=one out=three; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=0; 
	end;
    if waveform='E1' then Marker1=1;
Data three; set three;
Proc sort; by insectno Inverter1;
Data three; set three; drop in0;
Data three; Set three;
	retain in0 marker2;
	if insectno ne in0 then do;
	  marker2=0; in0=insectno; 
	end;
	if marker1=1 then marker2=1;
	if marker1=0 and marker2=1 then marker2=1;
Data three; set three;
Where marker2=1;
Proc sort data=three; by insectno line;
data three; set three; drop marker1 marker2 in0;
Data OnlyE1; Set three;
run;
*********************************************************************
*  Finished creating dataset OnlyE1
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*;

*********************************************************************
*******                             Start New Method              ***
*******                        define the dataset OnlyE2          ***
*********************************************************************;
Proc sort data=one out=three; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=0; 
	end;
    if waveform='E2' then Marker1=1;
Data three; set three;
Proc sort; by insectno Inverter1;
Data three; set three; drop in0;
Data three; Set three;
	retain in0 marker2;
	if insectno ne in0 then do;
	  marker2=0; in0=insectno; 
	end;
	if marker1=1 then marker2=1;
	if marker1=0 and marker2=1 then marker2=1;
Data three; set three;
Where marker2=1;
Proc sort data=three; by insectno line;
data three; set three; drop marker1 marker2 in0;
Data OnlyE2; Set three;
run;
*********************************************************************
*  Finished creating dataset OnlyE2
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*;


*********************************************************************
*******                             Start New Method              ***
*******                        define the dataset OnlySusE2       ***
*********************************************************************;
Proc sort data=one out=three; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=0; 
	end;
    if waveform='E2' and dur>600 then Marker1=1;
Data three; set three;
Proc sort; by insectno Inverter1;
Data three; set three; drop in0;
Data three; Set three;
	retain in0 marker2;
	if insectno ne in0 then do;
	  marker2=0; in0=insectno; 
	end;
	if marker1=1 then marker2=1;
	if marker1=0 and marker2=1 then marker2=1;
Data three; set three;
Where marker2=1;
Proc sort data=three; by insectno line;
data three; set three; drop marker1 marker2 in0;
Data OnlySusE2; Set three;
run;
*********************************************************************
*  Finished creating dataset OnlySusE2
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*;

*********************************************************************
***                                 Start New Method              ***
***                            define the dataset OnlySusG        ***
*** Milan: Added this since the variable was mentioned later      ***
*** in the code, but never actually calculated.                   ***
*********************************************************************;
Proc sort data=one out=three; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=0; 
	end;
    if waveform='G' and dur>600 then Marker1=1;
Data three; set three;
Proc sort; by insectno Inverter1;
Data three; set three; drop in0;
Data three; Set three;
	retain in0 marker2;
	if insectno ne in0 then do;
	  marker2=0; in0=insectno; 
	end;
	if marker1=1 then marker2=1;
	if marker1=0 and marker2=1 then marker2=1;
Data three; set three;
Where marker2=1;
Proc sort data=three; by insectno line;
data three; set three; drop marker1 marker2 in0;
Data OnlySusG; Set three;
run;
*********************************************************************
*  Finished creating dataset OnlySusG
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*;


*********************************************************************
*******                             Start New Method              ***
*******                        define the dataset OnlyE1e         ***
*********************************************************************;
Proc sort data=one out=three; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
	 in0=insectno; marker1=0; 
	end;
    if waveform='E1E' then Marker1=1;
Data three; set three;
Proc sort; by insectno Inverter1;
Data three; set three; drop in0;
Data three; Set three;
	retain w0 w1 in0 marker2;
	if insectno ne in0 then do;
	  marker2=0; in0=insectno; 
	end;
	if marker1=1 then marker2=1;
	if marker1=0 and marker2=1 then marker2=1;
Data three; set three;
Where marker2=1;
Proc sort data=three; by insectno line;
data three; set three; drop marker1 marker2 in0;
Data OnlyE1e; Set three;
run;
*********************************************************************
*  Finished creating dataset OnlyE1e
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*;

proc delete lib=work data= three;

*********************************************************************
****               THE END. START Computing Variables      **********
*********************************************************************
*********************************************************************
****             ******    ***********   *****       ****************
****             ******     **********   *****   ***    *************
****   ****************      *********   *****   ******   ***********
****   ****************   *   ********   *****   ********   *********
****   ****************   **   *******   *****   *********   ********
****             ******   ***   ******   *****   **********   *******
****             ******   ****   *****   *****   *********   ********
****   ****************   *****   ****   *****   ********   *********
****   ****************   ******   ***   *****   *******   **********
****   ****************   *******   **   *****   *****   ************
****             ******   ********   *   *****   ***   **************
****             ******   *********      *****       ****************
*********************************************************************
*********************************************************************;

*********************************************************************
*********************************************************************
*********************************************************************
*********************************************************************
*********************************************************************
*********************************************************************
*******                                                      ********
*******                           Variables                  ********
*******                                                      ********
*******               Initial Varibales are similar to       ********
*******                 those in the Sarria workbook         ********
*******                                                      ********
*********************************************************************
*********************************************************************
*********************************************************************
*********************************************************************
*********************************************************************
*********************************************************************
*********************************************************************
*********************************************************************;


*****************************   Start New Method    *****************
Time from beginning of EXPT to first probe (waveform C)
*********************************************************************;

Data Ebert; Set one;
retain in0 trt;
if insectno ne in0 then do; in0=insectno; if waveform="NP" then TmFrstPrbFrmStrt=sumend; else TmFrstPrbFrmStrt="."; end;
Data Ebert; Set Ebert;
 drop in0;
 Data Ebert; Set Ebert;
 retain in0 marker1;
 if in0 ne insectno then do; in0=insectno; marker1=0; end; else marker1=1;
 Data Ebert; Set Ebert; Where marker1=0;

data Ebert; set Ebert; drop sumstart sumend line instance waveform dur inverter1 in0 marker1;
run;

*********************************************************************
*  Finished time from start of experiment to first probe.      ******
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*;


*********************************************************************
/*********************************   Start New Method         *******
*  Number of probes to first E1.                              *******
*  Eliminate all insects without an E1 (data set OnlyE1).     *******
*  Drop all extraneous waveforms.                             *******
*  Set marker1 to 1, and it changes to 0 at the first E1.     *******
*  Delete all marker1=0.                                      *******
*********************************************************************;

Data three; set OnlyE1;
Proc sort data=three; by insectno line;
Data three; set three;
	retain in0 marker1 marker2;
	w1=waveform;
	if insectno ne in0 then do;
	 marker1=0; Marker2=0;
	 in0=insectno;
	end;
	If w1='C' then marker1=1;
	If w1='Z' or w1='NP' then marker1=0;
	if w1='E1' then marker2=1;
Data three; set three; Where marker2=0;
data three; set three; drop marker2 in0;
Data three; set three;
	retain in0 marker3 marker4;
	if insectno ne in0 then do;
	marker3=0; marker4=0; in0=insectno;
	end;
	if marker1=1 and marker3=0 then marker4=marker4+1;
	marker3=marker1;
Data three; set three; drop in0 marker1 marker3;
Proc sort data=three; by insectno inverter1;
data three; set three;
	retain marker1 in0;
	if insectno ne in0 then do;
	marker1=0; in0=insectno;
	end;
	else marker1=1;
Data three; set three; Where marker1=0;
Data three; set three; CtoFrstE1=marker4;
Data three; Set three; drop waveform dur line sumstart sumend instance inverter1 w1 in0 marker4 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;
run;
*********************************************************************
*  Finding number of probes to first E1 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
**********                           The number of F    *************
*********************************************************************;
data three; set OnlyF; Where waveform='F';
proc sort; by insectno inverter1;
data three; set three; 
retain in0 marker1;
if in0 eq insectno then do;
	in0=insectno; marker1=0;
end;
else marker1=1;
data three; set three;
proc means noprint; var instance; by insectno; output out=outsas max=NumF;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
data Ebert; set Ebert; if NumF='.' then NumF="0";

*********************************************************************
*  Finding the number of F is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method              ***
*  Duration of First and Second Probe.                            ***
*  Combine all non-NP and non-Z waveforms into a new waveform "P".***
*  Sum the durations for all consecutive P.                       ***
*  Find last element in any sum, and delete everything else.      ***
*  Rework instance based on new waveform list.                    ***
*  eliminate all but instance=1, then all but instance=2.         ***
*  Delete extraneous variables and merge.                         ***
*********************************************************************;
proc delete lib=work data= three outsas;
Data three; set one;
	if waveform='NP' or waveform='Z' then do marker1=1; waveform="Z"; end; else do marker1=0; waveform="P"; end;
Data three; set three;
	retain W1 W0 in0 marker2;
	if in0 ne insectno then do;
		in0=insectno; marker2=0; W1=0;
	end;
	W0=marker1;
	if W1 ne W0 then marker2=marker2+1;
	W1=W0;
Data three; set three;	drop in0 w1 w0;
data three; set three;
	retain W1 W0 in0 Sdur;
	if in0 ne insectno then do;
		in0=insectno; Sdur=0; W1=0;
	end;
	W0=marker2;
	if W0 eq w1 then sdur=sum(sdur, dur); else sdur=dur;
	w1=w0;
data three; set three; drop in0 w1 w0;
data three; set three;
retain in0;
if in0 ne insectno then do;
	in0=insectno;
*	if waveform eq "P" then sdur="."; *Activate this line to delete first probe if recording not start in NP;
	end;
Data three; set three; drop in0; 
proc sort data=three; by inverter1;
data three; set three;
	retain in0 w1 w0 marker4;
	if in0 ne insectno then do;
		in0=insectno; marker4=0; w1='   ';
	end;
	w0=waveform;
	if w1 ne w0 then marker4=0; else marker4=1;
	w1=w0;
data three; set three; Where marker4=0;
proc sort data=three; by line;
data three; set three; drop instance w1 w0 in0;
proc sort data=three; by insectno waveform;
data three;set three; by insectno waveform;
	retain instance;
	if first.waveform then instance=0;
	instance=instance+1;
data three; set three; Where waveform="P";
data four; set three; Where instance=1;
data five; set three; Where instance=2;
data four; set four; DurFrstPrb=sdur; drop sdur waveform dur line sumstart sumend inverter1 marker1 marker2 marker4 instance;
data five; set five; DurScndPrb=sdur; drop sdur waveform dur line sumstart sumend inverter1 marker1 marker2 marker4 instance;
data Ebert; set Ebert four; merge Ebert four; by insectno;
data Ebert; set Ebert five; merge Ebert five; by insectno;
proc delete lib=work data= four five three;

*********************************************************************
*  Finding duration of First and Second probe is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method         ********
*	Duration of shortest C before first E1 in any probe.     ********
*  "Duration of shortest C before E1"                        ********
*********************************************************************;
Proc sort data=OnlyCNoPd out=three; by insectno line;
data three; set three;
	if waveform='NP' or waveform='Z' then waveform='Z'; else if waveform='E1' then waveform='E1'; else waveform='P';
data three; set three;
	retain in0 marker1 w0;
	if in0 ne insectno then do;
	  in0=insectno; marker1=0; w0='  ';
	end;
	if w0='E1' then marker1=1;
	if w0='Z' then marker1=0;
	w0=waveform;
data three; set three; if waveform='Z' then marker1=0;
data three; set three; Where marker1=0;
proc sort data=three; by inverter1;
data three; set three; drop in0 w0 marker1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
	  in0=insectno; marker1=0;
	end;
	if waveform='E1' then marker1=1;
	if waveform='Z' then marker1=0;
Proc sort data=three; by line;
data three; set three; Where marker1=1;


Data three; set three;	drop in0 marker1;
data three; set three;
	retain W1 W0 in0 Sdur;
	if in0 ne insectno then do;
		in0=insectno; Sdur=dur; W1='  ';
	end;
	W0=waveform;
	if W0 eq w1 then sdur=sum(sdur, dur); else sdur=dur;
	w1=w0;

proc sort data=three; by inverter1;
data three; set three; drop in0 w1 w0;
data three; set three;
	retain in0 w1 w0 marker4;
	if in0 ne insectno then do;
		in0=insectno; marker4=0; w1=' ';
	end;
	w0=waveform;
	if w1 ne w0 then marker4=0; else marker4=1;
	w1=w0;
data three; set three; Where marker4=0;
proc sort data=three; by line;
data three; set three; drop instance w1 w0 in0;
proc sort data=three; by insectno waveform;
data three;set three; by insectno waveform;
	retain instance;
	if first.waveform then instance=0;
	instance=instance+1;
data three; set three; Where waveform="P";
proc sort data=three; by insectno;
data three; set three; proc means noprint; by insectno; var Sdur; output out=outsas min=ShrtCbfrE1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
Data Ebert; Set Ebert; drop _TYPE_ _FREQ_;
proc delete lib=work data= three outsas; 

*********************************************************************
*  Finding duration of shortest C event (including pd) before an E1.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method       **********
*  Duration of second non-probe event (z or np).           **********
*  Eliminate all waveforms except z and np.                **********
*  Count line numbers and extract the second behavior.     **********
*  Delete extraneous variables and merge.                  **********
*********************************************************************;
data three; set one;
retain in0 holder4;
if in0 ne insectno then do; in0=insectno; holder4=waveform; end;
data three; set three; drop in0;
data three; set three;
	Where waveform='Z' or waveform='NP';
data three; set three;
	if holder4="NP" or holder4="Z" then instance=instance; else instance=instance+1;
data three; set three; Where instance=2;
Data three; set three;
	DurScndZ=dur;
	drop waveform line dur instance sumstart sumend inverter1 holder4;
Data Ebert; set Ebert three;
	merge Ebert three;
	by insectno;
proc delete lib=work data= three;
*********************************************************************
*  Finding duration of Second non-probe event is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*******                         Start New Method    *****************
*******         Total duration of F                 *****************
*********************************************************************;
Data three; set OnlyF; Where waveform='F';
Data three; set three;
	retain in0 TtlDurF;
	if insectno ne in0 then do;
		in0=insectno; TtlDurF=0;
	end;
	TtlDurF=sum(TtlDurF+dur);
Proc sort data=three; by insectno inverter1;
Data three; set three; drop in0;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=1;
	end;
	else marker1=0;
Data three; set three; Where marker1=1;
Data three; Set three; drop waveform dur line sumstart sumend instance inverter1 in0 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;
*********************************************************************
*  Finding Total duration of F is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
**                              Start New Method         ************
**	Duration of nonprobe period before the first e1      ************
*********************************************************************;
Data three; set One; *Using dataset OnlyE1 will change insects without E1 to missing;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if waveform eq 'E1' then marker1=1;
Data three; set three; Where marker1=0;
data three; set three; drop in0 marker1;
Proc sort data=three; by insectno inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if waveform eq 'Z' or waveform eq 'NP' then marker1=1;
Data three; set three; Where marker1=1;
Data three; set three; Where waveform='Z' or waveform='NP';
Data three; set three; drop in0 marker1;
proc sort data=three; by insectno line;
data three; set three; 
	retain DurNnprbBfrFrstE1 in0;
	if in0 ne insectno then do; in0=insectno; DurNnprbBfrFrstE1=0; end;
	DurNnprbBfrFrstE1=sum(DurNnprbBfrFrstE1, dur);
Data three; set three; drop in0;
proc sort data=three; by insectno inverter1;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=1;
	end;
	else marker1=0;
Data three; set three; Where marker1=1;
Data three; set three; drop waveform dur line sumstart sumend instance inverter1 in0 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;
*********************************************************************
*  Finding Duration of nonprobe period before the first e1 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
****                            Start New Method    *****************
****       Mean duration of pd
*********************************************************************;
Data three; set OnePD;
data three; set three; Where waveform='PD';
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas mean=meanpd;
data three; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc delete lib=work data= oned outsas three;
*********************************************************************
*  Finding Mean duration of pd is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
******                          Start New Method    *****************
******                Mean duration of pdL
*********************************************************************;
Data three; set one; if waveform='PDL' then PDL=dur;
Data three; set three; proc means noprint; by insectno; var PDL; output out=outsas mean=meanPDL;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= outsas three;
*********************************************************************
*  Finding Mean duration of pd is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
******                        Start New Method    *******************
******     Mean duration of pdS
*********************************************************************;
Data three; set one; if waveform='PD' then PDS=dur;
Data three; set three; proc means noprint; by insectno; var PDS; output out=outsas mean=meanPDS;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
data Ebert; set Ebert; if meanPDS='.' and meanpd ne '.' then meanpds=meanpd;
proc delete lib=work data= outsas three;
*********************************************************************
*  Finding Mean duration of pds is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************************************************
*******        Start New Method                       ***************
*******   Average number of pd per probe              ***************
*********************************************************************;
Data three; set onepd; 								*mark each probe.;
	retain in0 marker1;
	w1=waveform;
	if insectno ne in0 then do;
		in0=insectno; marker1=0;
	end;
	if w1='C' then marker1=1;
	if w1='Z' or w1='NP' then marker1=0;
Data three; set three; drop in0;
Data three; set three; 					*counting the number of probes;
	retain in0 holder1 marker2;
	if insectno ne in0 then do;
		in0=insectno; marker2=0; holder1=0;
	end;
	if holder1 ne marker1  and waveform='C' then do;
		marker2=marker2+1;
	end;
	holder1=marker1;
Data three; set three; drop in0 holder1;
Data three; set three;						*counting pd in each probe;
	retain in0 holder1 marker3 marker4;
	if insectno ne in0 then do;
		in0=insectno; marker3=0; holder1=0; marker4=0;
	end;
	if marker1=1 and holder1=0 then marker3=1;
	if marker1=0 and holder1=1 then marker3=0;
	if marker3=1 and waveform='PD' then marker4=marker4+1;
	if marker3=0 then marker4=0;
	holder1=marker1;
Data three; set three; drop in0 holder1 marker3;
Proc sort data=three; by insectno inverter1;  *Isolate last entry in each probe;
Data three; set three;
	retain in0 holder1 marker5;
	if insectno ne in0 then do;
		in0=insectno; holder1=0; marker5=0;
	end;
	if holder1=0 and marker1=1 then marker5=1;
	else marker5=0;
	holder1=marker1;
data three; set three; drop in0 holder1;
data three; set three; Where marker5=1;
proc sort data=three; by insectno line;
data three; set three; proc means noprint; var marker4; by insectno; output out=outsas mean=meanNPdPrb;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= outsas three;
*********************************************************************
*  Finding Average number of pd per probe is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
********                        Start New Method    *****************
********      Mean duration of F
*********************************************************************;
Data three; set OnlyF; Where waveform='F';
Data three; set three;
	retain in0 meanF;
	if insectno ne in0 then do;
		in0=insectno; MeanF=0;
	end;
	MeanF=sum(MeanF, dur);
Proc sort data=three; by insectno inverter1;
Data three; set three; drop in0;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=1;
	end;
	else marker1=0;
Data three; set three; Where marker1=1;
Data three; set three; MeanF=meanF/instance;
Data three; Set three; drop waveform dur line sumstart sumend instance inverter1 in0 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc delete lib=work data= three;
run;
*********************************************************************
*  Finding Mean duration of F is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*******                       Start New Method    *******************
*******       Time from start of EPG to 1st E
*********************************************************************;
Data three; set onlyE1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='E1' then  marker1=1;
data three; set three; Where marker1=0;
proc sort data=three; by insectno inverter1;
data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	else marker1=1;
Data three; set three; Where marker1=0;
data three; set three; TmStrtEPGFrstE=sumend;
data three; set three; drop waveform dur line sumstart sumend instance inverter1 in0 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc delete lib=work data= three;
Run;
*********************************************************************
*  Finding Time from start of EPG to 1st E is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********    END of PART 1 ******************************************
*********************************************************************;


*********************************************************************
**                                   Start New Method    ************
**	Time from first probe to 1st E                       ************
*********************************************************************;
Data three; set onlyE1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='E1' then  marker1=1;
data three; set three; Where marker1=0;
data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='C' then marker1=1;
Data three; set three; Where marker1=1;
Data three; set three; drop in0 marker1;
data three; set three;
	retain in0 TmFrmFrstPrbFrstE;
	if in0 ne insectno then do;
		in0=insectno; TmFrmFrstPrbFrstE=0;
	end;
	TmFrmFrstPrbFrstE = sum(TmFrmFrstPrbFrstE, dur);
data three; set three; drop in0;
proc sort data=three; by insectno inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	else marker1=1;
proc sort data=three; by line;
data three; set three; Where marker1=0;
data three; set three; drop waveform dur line sumstart sumend instance inverter1 in0 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;
*********************************************************************
*  Finding Time from 1st probe to 1st E is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
**                                 Start New Method    **************
**	Time from start of probe with first E to 1st E     **************
*********************************************************************;
Data three; set onlyE1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='E1' then  marker1=1;
data three; set three; Where marker1=0;
data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='C' then marker1=1;
Data three; set three; Where marker1=1;
Data three; set three; drop in0 marker1;
proc sort data=three; by insectno inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='Z' or waveform='NP' then marker1=1;
proc sort data=three; by line;
data three; set three; Where marker1=0;
Data three; set three; drop in0 marker1;
data three; set three;
	retain in0 TmBegPrbFrstE;
	if in0 ne insectno then do;
		in0=insectno; TmBegPrbFrstE=0;
	end;
	TmBegPrbFrstE=sum(TmBegPrbFrstE, dur);
data three; set three; drop in0;
proc sort data=three; by insectno inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	else marker1=1;
data three; set three; Where marker1=0;
data three; set three; drop waveform dur line sumstart sumend instance inverter1 in0 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;

**********************************************************************
*  Finding Time from start of probe with first E to 1st E is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
********************************   Start New Method        **********
**	Finding the number of G waveforms                      **********
**	Finding the time spent in the G waveform               **********
**	Finding the average duration of each G waveform event  **********
*********************************************************************;
data three; set OnlyG;
proc sort; by insectno waveform;
data three; set three; drop line sumstart sumend instance inverter1;
data three; set three;
proc means noprint; by insectno waveform; output out=outsas n=num mean=avg sum=sum1;
data G; set outsas; Where waveform='G';
Data G; set G; NumG=num; DurG=sum1; MeanG=avg; drop _TYPE_ _FREQ_ waveform num avg sum1;
Data Ebert; set Ebert g; merge Ebert g; by insectno;
data Ebert; set Ebert; if NumG='.' then NumG=0;
proc delete lib=work data= G outsas three;
*********************************************************************
*  Finding NumG DurG, and MeanG is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
***   Find Number of sustained G by milan;
*********************************************************************;
Data three; set OnlyG;
if waveform='G' and dur>600 then marker1=1; else marker1=0;
data three; set three; proc means noprint;
	by insectno; var marker1; output out=outsas sum=NumLngG;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
********************************************************************
*  Finding Number of sustained G is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;
*********************************************************************
*********************************   Start New Method    *************
*************     Time to first sustained G from first probe milan   *****
*********************************************************************;
Data three; set OnlySusG; 
retain in0 marker1;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if waveform="G" and dur>600 then marker1=1;
data three; set three; Where marker1=0;
data three; set three;
proc means noprint; var sumend; by insectno; output out=outsas max=TmSusG;
data four; set one;
proc means noprint; var sumend; by insectno; output out=outsas1 max=runtime;
data outsas; set outsas outsas1; merge outsas outsas1; by insectno;
TmFrstSusG=TmSusG;
data outsas; set outsas; drop runtime tmsusg _TYPE_ _FREQ_;
data three; set one; retain marker1;
data three; set three;
retain in0 marker1;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if waveform="C" then marker1=1;
Data three; set three; Where marker1=0;
data three; set three; drop in0 marker1;
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas3 sum=Sumdur;
Data outsas3; set outsas3; drop _TYPE_ _FREQ_;
data outsas; set outsas outsas3; merge outsas outsas3; by insectno;
data outsas; set outsas; TmFrstSusGFrstPrb=TmfrstSusG-Sumdur;
data outsas; set outsas; if TmFrstSusGFrstPrb<=0 then TmFrstSusGFrstPrb=".";
data outsas; set outsas; drop TmfrstSusG Sumdur;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas outsas1 outsas3 three;
*********************************************************************
*  Finding first sustained G from first probe is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
**	Number of Probes after first E1
*********************************************************************;
Data three; set OnlyE1;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='E1' then marker1=1;
data three; set three; Where marker1=1;
data three; set three; drop in0 marker1;

data three; set three;
	retain in0 marker2 delay1;
	if in0 ne insectno then do;
		in0=insectno; marker2=0; delay1=1;
	end;
	if delay1=0 then do;
		if waveform='Z' then marker2=marker2+1;
		if waveform='NP' then marker2=marker2+1;
		 
	end;
	delay1=0;
data three; set three; Where waveform='C';
Data three; set three; proc means noprint;
	by insectno; var marker2; output out=outsas max=NumPrbsAftrFrstE;
data outsas; set outsas; if NumPrbsAftrFrstE='.' then NumPrbsAftrFrstE=0;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
Data Ebert; set Ebert; if NumPrbsAftrFrstE='.' then NumPrbsAftrFrstE=0;
proc delete lib=work data= three outsas;
run;
*********************************************************************
*  Finding Number of probes after first E1 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
********************************   Start New Method    **************
**	Number of Probes<3min after first E1
*********************************************************************;
Data three; set OnlyE1;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='E1' then marker1=1;
data three; set three; Where marker1=1;
data three; set three; drop in0 marker1;

Data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='NP' or waveform="Z" then marker1=1;
data three; set three; Where marker1=1;
data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker2 delay1;
	if in0 ne insectno then do;
		in0=insectno; marker2=1; delay1=1;
	end;
	if delay1=0 then do;
		if waveform='Z' then marker2=marker2+1;
		if waveform='NP' then marker2=marker2+1;
		 
	end;
	delay1=0;
Data three; set three; if waveform ne "Z" and waveform ne "NP" then waveform="PRB";
data three; set three; 
  proc sort; by insectno marker2 waveform;
  proc means noprint; by insectno marker2 waveform; var dur; output out=outsas2 sum=sdur;
data outsas2; set outsas2; Where waveform="PRB" and sdur<180;
data outsas2; set outsas2;
	retain in0 marker1;
	if in0 ne insectno then do;	in0=insectno; marker1=0; end;
	marker1=marker1+1;
Data outsas2; set outsas2;
  proc means noprint; by insectno; var marker1; output out=outsas4 max=NmbrShrtPrbAftrFrstE;

data outsas4; set outsas4; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas4; merge Ebert outsas4; by insectno;
Data Ebert; set Ebert; if NmbrShrtPrbAftrFrstE='.' then NmbrShrtPrbAftrFrstE=0;
proc delete lib=work data= three outsas4 outsas2;
run;
*********************************************************************
*  Finding Number of probes <3min after first E1 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;



*********************************************************************
*********************************   Start New Method    *************
***	Number of E1
*********************************************************************;
Data three; set onlye1;
data three; set three; Where waveform='E1';
Data three; set three;
marker1=1;
data three; set three; proc means noprint;
by insectno; var marker1; output out=outsas sum=NumE1;
data outsas; set outsas; Drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
data Ebert; set Ebert; if NumE1='.' then NumE1=0;
*********************************************************************
*  Finding number of E1 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
*** Number of E1 (longer than 10 min) followed by E2
*********************************************************************;
Data three; set onlye1;
data three; set three;
	retain in0 w1 w0 holder1 marker1;
	w1=waveform;
	if in0 ne insectno then do;
		in0=insectno; w0='   '; holder1=0; marker1=0;
	end;
	if w0='E1' and holder1>600 and w1='E2' then marker1=marker1+1;
	w0=w1;
	holder1=dur;
data three; set three; proc means noprint; 
	by insectno; var marker1; output out=outsas max=NumLngE1BfrE2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
data Ebert; set Ebert; if NumLngE1BfrE2='.' then NumLngE1BfrE2=0;
*********************************************************************
*  Finding Number of E1 (longer than 10 min) followed by E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
***   Number of single E1
*********************************************************************;
data three; set onlyE1;
	retain in0 w1 w0 marker1 marker2 marker3;
	w1=waveform;
	if in0 ne insectno then do;
		in0=insectno; w0='   '; marker1=0; marker2=0; marker3=0;
	end;
	if w1 ne 'E1' and w1 ne 'E2' then marker1=1; else marker1=0;
	if w0='E2' and w1='E1' then marker3=1; else marker3=0;
	if marker1=1 and w0='E1' and marker3=0 then marker2=marker2+1;
	w0=w1;
data three; set three; drop in0 w1 w0 marker1;
data three; set three;
	retain in0 marker1 holder1 holder2;
	if in0 ne insectno then do;
		in0=insectno; marker1=0; holder1=0; holder2=0;
	end;
	if holder1 ne marker2 and holder2=1 then marker1=marker1+1;
	holder1=marker2;
	holder2=marker3;
data three; set three; marker4=marker2-marker1;
data three; set three; proc means noprint; 
	by insectno; var marker4; output out=outsas max=NumSnglE1;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
data Ebert; set Ebert; if NumSnglE1='.' then NumSnglE1=0;
run;
*********************************************************************
*  Find Number of single E1 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
***  Finding number of E2
*********************************************************************;
Data three; set OnlyE2;
if waveform='E2' then marker1=1; else marker1=0;
data three; set three; proc means noprint;
	by insectno; var marker1; output out=outsas sum=NumE2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
*********************************************************************
*  Finding Number of E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
***   Find Number of sustained E2;
*********************************************************************;
Data three; set OnlyE2;
if waveform='E2' and dur>600 then marker1=1; else marker1=0;
data three; set three; proc means noprint;
	by insectno; var marker1; output out=outsas sum=NumLngE2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
********************************************************************
*  Finding Number of sustained E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find Duration of first E (E1 + E2)
*********************************************************************;
Data three; set onlyE1;
	retain marker1 w0 w1 in0;
	if in0 ne insectno then do; w0="    "; in0=insectno; marker1=0; end;
	w1=waveform;
	if w0="E2" then marker1=1;	
	w0=w1;
Data three; set three; Where marker1=0;
Data three; set three; drop w0 w1 in0 marker1;

Data three; set three;
	if waveform='E1' then waveform='E';
	if waveform='E2' then waveform='E';
data three; set three;
	retain sort1 w0 in0;
	if in0 ne insectno then do; sort1=1; in0=insectno; end;
	w1=waveform;
	if w1 ne w0 then sort1=sort1+1; else sort1=sort1;
	w0=w1;
data three; set three;
proc sort; by insectno waveform;
proc means noprint; by insectno waveform sort1; var dur; output out=outthree sum=durs;
data outthree; set outthree;
data three; set outthree; drop _TYPE_ _FREQ_;
data three; set three;
proc sort; by insectno waveform;
data three;set three; by insectno waveform;
	retain instance;
	if first.waveform then instance=0;
	instance=instance+1;
data three; set three; Where waveform='E' and instance=1;
proc delete lib=work data= outthree;
data three; set three;
DurFirstE=durs;
drop instance sort1 waveform durs;
data Ebert; set Ebert three; merge Ebert three; by insectno;
*********************************************************************
*  Finding duration of first E is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
****	Find contribution of E1 to phloem phase
*********************************************************************;
Data three; set onlye1;
	Where waveform='E1' or waveform='E2';
Data three; set three;
	proc sort; by insectno waveform;
	Proc means noprint; by insectno waveform; var dur; output out=outsas sum=outSum;
data four; set outsas; Where waveform='E1';
Data four; set four; outsumE1=outsum; drop outsum waveform _TYPE_ _FREQ_;
data five; set outsas; Where waveform='E2';
Data five; set five; outsumE2=outsum; drop outsum waveform _TYPE_ _FREQ_;
data three; set four five; merge four five; by insectno;
data three; set three;
if outsume1='.' then outsume1=0;
if outsume2='.' then outsume2=0;
data three; set three;
ttlsum=sum(outsumE1, outsumE2);
CntrbE1toE=100*(outsumE1/ttlsum);
data three; set three; drop outsumE1 outsumE2 ttlsum;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc delete lib=work data= three four five outsas;
*********************************************************************
*  Finding contribution of E1 to phloem phase is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
****	Duration of E1 followed by first sustained E2 (Long E2)
*********************************************************************;
data three; set onlysuse2;
	retain in0 marker1;
	if in0 ne insectno then do;	in0=insectno; marker1=0; end;
	if waveform='E2' and dur>600 then marker1=1;
data three; set three; Where marker1=0;
data three; set three; drop in0 marker1;
proc sort data=three; by insectno inverter1;
data three; set three; Where waveform='E1';
Data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;	in0=insectno; marker1=0; end;
	else marker1=1;
data three; set three; Where marker1=0;
data three; set three; 	DurE1FlwdFrstSusE2 =dur;
Data three; set three;	drop waveform line dur sumstart sumend instance inverter1 in0 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc delete lib=work data= three;
*********************************************************************
*  Finding Duration of E1 followed by first E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
****	Duration of E1 followed by sustained E2
*********************************************************************;
data three; set onlye2;
	retain in0 marker1;
	if in0 ne insectno then do;	in0=insectno; marker1=0; end;
	if waveform='E2' then marker1=1;
data three; set three; Where marker1=0;
data three; set three; drop in0 marker1;
proc sort data=three; by insectno inverter1;
data three; set three; Where waveform='E1';
Data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;	in0=insectno; marker1=0; end;
	else marker1=1;
data three; set three; Where marker1=0;
data three; set three; 	DurE1FlldFrstE2 =dur;
Data three; set three;	drop waveform line dur sumstart sumend instance inverter1 in0 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc delete lib=work data= three;
*********************************************************************
*  Finding Duration of E1 followed by sustained E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
**************  END OF PART 2   *************************************
*********************************************************************;


********************************************************************
*********************************   Start New Method    ************
****	Potential E2 Index
********************************************************************;
Data three; set onlyE2;
data three; set three;
	retain in0 w1 w0 marker2;
	w1=waveform;
	if insectno ne in0 then do;
	  w0='  '; marker2=0;
	 in0=insectno; 
	end;
	if waveform='E2' then marker2=1;
data three; set three; Where marker2=1;
data three; set three; proc means noprint; by insectno; var dur; output out=outsas sum=DurE2toEnd;
data three; set three; Where waveform='E2';
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas1 sum=DurAllE2;
data outsas; set outsas outsas1; merge outsas outsas1; by insectno;
data outsas; set outsas; PotE2Indx=100*(DurAllE2/DurE2toEnd);
data outsas; set outsas; drop _TYPE_ _FREQ_ DurAllE2 DurE2toEnd;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= outsas1 three outsas;
*********************************************************************
*  Finding Potential E2 Index is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find total duration of E
*********************************************************************;
Data three; set onlye1;
Where waveform='E1' or waveform='E2';
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas sum=TtlDurE;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
*********************************************************************
*  Finding total duration of E is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find total duration of E1
*********************************************************************;
Data three; set onlye1;
Where waveform='E1';
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas sum=TtlDurE1;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= three outsas;
*********************************************************************
*  Finding total duration of E1 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find Total Duration of E1 followed by a sustained E2
*********************************************************************;
data three; set onlysusE2;
	if waveform='E2' and dur>600 then marker1=1;
	else marker1=0;
proc sort data=three; by insectno inverter1;
data three; set three;
	retain in0 w0 marker2;
	w1=waveform;
	if in0 ne insectno then do;
		in0=insectno; marker2=0; 
	end;
	if w1="E1" and w0=1 then marker2=1; else marker2=0;
	w0=marker1;
Proc sort data=three; by insectno line;
data three; set three; Where marker2=1;
data three; set three; proc means noprint; by insectno; var dur; output out=outsas sum=TtlDurE1FlldSusE2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= three outsas;

*********************************************************************
*  Finding Total Duration of E1 followed by a sustained E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
****	Total duration of E1 followed by E2
*********************************************************************;
Proc sort data=onlye2 out=three; by insectno inverter1;
data three; set three;
	retain marker1 in0 w1 w0;
	w1=waveform;
	if in0 ne insectno then do;
		in0=insectno; marker1=0; w0='   ';
	end;
	if w0='E2' and w1='E1' then marker1=1; else marker1=0;
	w0=w1;
data three; set three; drop in0;
data three; set three; Where marker1=1;
data three; set three; proc means noprint;
	by insectno; var dur; output out=outsas sum=TtlDurE1FlldE2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
*********************************************************************
*  Finding Total duration of E1 followed by E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Total duration of single E1
*********************************************************************;
Data three; set OnlyE1;
Proc sort data=three; by insectno inverter1;
data three; set three;
	retain w0 w1 in0 marker2;
	w1=waveform;
	if insectno ne in0 then do;
	  w0='  '; marker1=0;
	 in0=insectno; 
	end;
	if w1='E1' and w0 ne 'E2' then marker1=1;
	w0=w1;
proc sort data=three; by insectno line;
data three; set three; drop in0 w1 w0;
data three; set three;
	retain in0 w0 w1;
	w1=waveform;
	if insectno ne in0 then do;
		in0=insectno; w0='   ';
	end;
	if w0='E2' and w1='E1' then marker1=0;
	w0=w1;
data three; set three; Where marker1=1;
data three; set three; proc means noprint;
	by insectno; var dur; output out=outsas sum=TtlDurSnglE1;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
*********************************************************************
*  Finding total duration of single e1 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Total duration of E1 followed by E2 plus E2
*********************************************************************;
Proc sort data=onlye2 out=three; by insectno inverter1;
data three; set three;
	retain marker1 in0 w1 w0;
	w1=waveform;
	if in0 ne insectno then do;
		in0=insectno; marker1=0; w0='   ';
	end;
	if w0='E2' and w1='E1' then marker1=1; else marker1=0;
	w0=w1;
data three; set three; drop in0;
data three; set three; Where marker1=1;
data three; set three; proc means noprint;
	by insectno; var dur; output out=outsas sum=TtlDurE1FlldE2;
data outsas; set outsas; drop _TYPE_ _FREQ_;

data three; set onlye2; Where waveform='E2';
Data three; set three; proc means noprint; 
	by insectno; var dur; output out=outsas2 sum=SE2;
data outsas2; set outsas2; drop _TYPE_ _FREQ_;
data three; set outsas outsas2; merge outsas outsas2; by insectno;
data three; set three;
TtlDurE1FllwdE2PlsE2=sum(TtlDurE1FlldE2, SE2);
data three; set three; drop se2 TtlDurE1FlldE2;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc delete lib=work data= outsas outsas2 three;
*********************************************************************
*  Finding Total duration of E1 followed by E2 plus E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Total Duration of E2
*********************************************************************;
data three; set onlye2;
	Where waveform='E2';
Data three; set three; proc means noprint;
	by insectno; var dur; output out=outsas sum=TtlDurE2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
*********************************************************************
*  Finding Total duration of E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Mean Duration of E1
*********************************************************************;
data three; set onlye1;
	Where waveform='E1';
Data three; set three; proc means noprint;
	by insectno; var dur; output out=outsas mean=MnDurE1;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
*********************************************************************
*  Finding Mean duration of E1 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Mean duration of E2
*********************************************************************;
data three; set onlye2;
	Where waveform='E2';
Data three; set three; proc means noprint;
	by insectno; var dur; output out=outsas mean=MnDurE2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
*********************************************************************
*  Finding mean duration of E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Number of probes
*********************************************************************;
data three; set one;
	retain in0 marker1;
	w1=waveform;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if w1='C' then marker1=1;
	if w1='Z' or w1='NP' then marker1=0;
data three; set three; drop in0;
data three; set three;
	retain in0 marker2 holder1;
	if in0 ne insectno then do;
		in0=insectno; marker2=0; holder1=0;
	end;
	if holder1=0 and marker1=1 then marker2=marker2+1;
	holder1=marker1;
data three; set three; proc means noprint;
	by insectno; var marker2; output out=outsas max=NumPrbs;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
*********************************************************************
*  Finding number of probes is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find number of C events
*********************************************************************;
data three; set OnlyCnoPd; Where waveform='C';
Data three; set three; marker1=1;
proc means noprint;
	by insectno; var marker1; output out=outsas sum=NmbrC;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
*********************************************************************
*  Finding number of C is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find number of short C events
*********************************************************************;
data three; set OnlyCNoPD;
Data three; set three; 
retain in0 marker1;
if in0 ne insectno then do;
in0=insectno; marker1=0;
end;
if waveform="C" then marker1=1;
if waveform="NP" or waveform="Z" then marker1=0;
data three; set three; drop in0;
data three; set three; 
retain in0 marker2 holder1;
if in0 ne insectno then do;
in0=insectno; marker2=0;
end;
if holder1=0 and marker1=1 then marker2=marker2+1;
holder1=marker1;
data three; set three; Where waveform ne "NP" and waveform ne "Z";
data three; set three; proc means noprint; var dur; by insectno marker2; output out=outsas sum=dur2;
data three; set outsas; Where dur2<180; drop _TYPE_ _FREQ_;
data three; set three;
retain in0 marker3;
if in0 ne insectno then do;
in0=insectno; marker3=0;
end;
marker3=marker3+1;
data three; set three; proc means noprint; by insectno; var marker3; output out=outsas max=NmbrShrtC;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
*********************************************************************
*  Finding number of short C is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find the Number of NP
*********************************************************************;
Data three; set one;
data three; set three; if waveform="NP" or waveform="Z" then marker1=1; else marker1=0;
data three; set three; proc means noprint; by insectno; var marker1; output out=outsas sum=NumNP;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= outsas three;
run;
*********************************************************************
*  Finding ........... is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
****** END Part 3  **************************************************
*********************************************************************;



*********************************************************************
*********************************   Start New Method    *************
****	Find the Number of pd
*********************************************************************;
Data three; set onepd;
data three; set three; if waveform="PD" then marker1=1; else marker1=0;
data three; set three; proc means noprint; by insectno; var marker1; output out=outsas sum=NmbrPD;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
run;
*********************************************************************
*  Finding Number of pd is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find the Number of pdL
*********************************************************************;
Data three; set one;
data three; set three; if waveform="PDL" then marker1=1; else marker1=0;
data three; set three; proc means noprint; by insectno; var marker1; output out=outsas sum=NmbrPDL;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
run;
*********************************************************************
*  Finding Number of pdL is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find the Number of pdS
*********************************************************************;
Data three; set one;
data three; set three; if waveform="PDS" then marker1=1; else marker1=0;
data three; set three; if marker1=0 and waveform="PD" then marker1=1;
data three; set three; proc means noprint; by insectno; var marker1; output out=outsas sum=NmbrPDS;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
run;
*********************************************************************
*  Finding Number of pdS is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find the Number of E1e
*********************************************************************;
Data three; set one;
data three; set three; if waveform="E1E" then marker1=1; else marker1=0;
data three; set three; proc means noprint; by insectno; var marker1; output out=outsas sum=NmbrE1e;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
run;
*********************************************************************
*  Finding Number of E1e is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find the Total duration of C
*********************************************************************;
Data three; set OnlyCNoPD;
data three; set three; Where waveform="C";
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas sum=TtlDurC;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
run;
*********************************************************************
*  Finding the Total duration of C is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find the Total duration of E1e
*********************************************************************;
Data three; set one;
data three; set three; Where waveform="E1E";
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas sum=TtlDurE1e;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
run;
*********************************************************************
*  Finding the Total duration of E1e is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXX*XXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find the Total duration of non-phloematic phase
*********************************************************************;
Data three; set OnlyE1;
data three; set three; Where waveform ne "E1" and waveform ne "E2";
data three; set three; proc means noprint; by insectno; var dur; output out=outsas sum=TotDurNnPhlPhs;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
run;
*********************************************************************
*  Finding the Total duration of non-phloematic phase is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
****	Find the Total duration of NP phase
*********************************************************************;
Data three; set one; 
Where waveform eq "NP" or waveform eq "Z";
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas sum=TtlDurNP;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
*********************************************************************
*  Finding the Total duration of NP phase is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
****	Find the Total duration of PD phase
*********************************************************************;
Data three; set OnePD;
Where waveform eq "PD";
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas sum=TtlDurPD;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;

*********************************************************************
*  Finding the Total duration of PD phase is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
****	Find the Total duration of PDL phase
*********************************************************************;
Data three; set one; 
Where waveform eq "PDL";
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas sum=TtlDurPD;
data four; set outsas;
Data three; set one; 
Where waveform eq "II2";
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas sum=TtlDurPD2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data four; set four outsas; merge four outsas; by insectno;
Data three; set one; 
Where waveform eq "PDII3";
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas sum=TtlDurPD3;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data four; set four outsas; merge four outsas; by insectno;
data four; set four; if ttldurpd2="." then ttldurpd2=0;
                     if ttldurpd3="." then ttldurpd3=0;
data four; set four; TtlDurPDL=sum(TtlDurPD, TtlDurPD2, TtlDurPD3);
data four; set four; drop _Type_ _FREQ_ TtlDurPD TtlDurPD2 TtlDurPD3;
data Ebert; set Ebert four; merge Ebert four; by insectno;
proc delete lib=work data= four outsas three;
*********************************************************************
*  Finding the Total duration of PDL phase is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find the Total duration of PDS phase
*********************************************************************;
Data three; set One; 
Where waveform eq "PD";
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas sum=TtlDurPDS;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
Data Ebert; Set Ebert;
if TtlDurPDS="." and TtlDurPD ne "." then TtlDurPDS=TtlDurPD;
*********************************************************************
*  Finding the Total duration of PDS phase is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find the Total probing time
*********************************************************************;
Data three; set one; 
retain in0 marker1;
w0=waveform;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
If w0="C" then marker1=1;
if w0="NP" or w0="Z" then marker1=0;
data three; set three; Where marker1=1;
proc means noprint; var dur; by insectno; output out=outsas sum=TtlPrbTm;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
*********************************************************************
*  Finding the Total probing time is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find the mean duration of NP
*********************************************************************;
Data three; set one; 
Where waveform="NP" or waveform eq "Z";
Data three; set three;
proc means noprint; var instance dur; by insectno; output out=outsas sum=Ins1 dur1 max=InsM durM;
data outsas; set outsas; MnDurNP=dur1/InsM;
data outsas; set outsas; drop ins1 dur1 insm durm _FREQ_ _TYPE_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
*********************************************************************
*  Finding the mean duration of NP is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;



*********************************************************************
*********************************   Start New Method    *************
****	Find the mean duration of C
*********************************************************************;
Data three; set OnlyCNoPD; 
Where waveform="C";
Data three; set three;
proc means noprint; var instance dur; by insectno; output out=outsas sum=Ins1 dur1 max=InsM durM;
data outsas; set outsas; MnDurC=dur1/InsM;
data outsas; set outsas; drop ins1 dur1 insm durm _FREQ_ _TYPE_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
*********************************************************************
*  Finding the mean duration of C is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find time to first sustained E2
*********************************************************************;
Data three; set OnlySusE2; 
retain in0 marker1;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if waveform="E2" and dur>600 then marker1=1;
data three; set three; Where marker1=0;
data three; set three;
proc means noprint; var sumend; by insectno; output out=outsas max=TmSusE2;
data four; set one;
proc means noprint; var sumend; by insectno; output out=outsas1 max=runtime;
data outsas; set outsas outsas1; merge outsas outsas1; by insectno;
* if tmsuse2="." then TmFrstSusE2=runtime; *else TmFrstSusE2=TmSusE2; * This line makes output match Sarria, and it has been changed;
TmFrstSusE2=TmSusE2;
data outsas; set outsas; drop runtime TmSusE2 _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= outsas outsas1 four;
run;
*********************************************************************
*  Finding the time to the first sustained E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*****  END PART 4  **************************************************
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
*************     Time to first sustained E2 from first probe   *****
*********************************************************************;
Data three; set OnlySusE2; 
retain in0 marker1;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if waveform="E2" and dur>600 then marker1=1;
data three; set three; Where marker1=0;
data three; set three;
proc means noprint; var sumend; by insectno; output out=outsas max=TmSusE2;
data four; set one;
proc means noprint; var sumend; by insectno; output out=outsas1 max=runtime;
data outsas; set outsas outsas1; merge outsas outsas1; by insectno;
TmFrstSusE2=TmSusE2;
data outsas; set outsas; drop runtime tmsuse2 _TYPE_ _FREQ_;
data three; set one; retain marker1;
data three; set three;
retain in0 marker1;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if waveform="C" then marker1=1;
Data three; set three; Where marker1=0;
data three; set three; drop in0 marker1;
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas3 sum=Sumdur;
Data outsas3; set outsas3; drop _TYPE_ _FREQ_;
data outsas; set outsas outsas3; merge outsas outsas3; by insectno;
data outsas; set outsas; TmFrstSusE2FrstPrb=TmfrstSusE2-Sumdur;
data outsas; set outsas; if TmFrstSusE2FrstPrb<=0 then TmFrstSusE2FrstPrb=".";
data outsas; set outsas; drop TmfrstSusE2 Sumdur;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas outsas1 outsas3 three;
*********************************************************************
*  Finding first sustained E2 from first probe is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************************************************
*********************************   Start New Method    *************
*************     Time to first sustained E2 from start of probe   **
*********************************************************************;
data three; set OnlySusE2;
retain marker1;
if waveform="C" then marker1=1;
if waveform="NP" or waveform="Z" then marker1=0;
Data three; set three;
retain marker2;
if waveform="E2" and dur>600 then marker2=1;
if waveform="NP" or waveform="Z" then marker2=0;
data four; set three;
proc sort; by inverter1;
data four; set four;
retain marker3 in0;
if in0 ne insectno then do; in0=insectno; marker3=0; end;
if marker2=1 then marker3=1;
if waveform="NP" or waveform="Z" then marker3=0;
data four; set four;
proc sort; by line;
data four; set four;
Where marker3=1;
data four; set four;
drop marker1 marker2 marker3 in0;
data four; set four;
retain marker1 in0;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if waveform="E2" and dur>600 then marker1=1;
data four; set four;
Where marker1=0;
data four; set four;
proc means noprint; var dur; by insectno; output out=outsas sum=TmFrstSusE2StrtPrb;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= three four outsas;
*********************************************************************
*  Finding Time to first sustaines E2 from start of probe is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
**************       Time to first E2 from start of EPG
*********************************************************************;
data three; set OnlyE2;
retain marker1 in0;
if in0 ne insectno then do; marker1=0; in0=insectno; end;
if waveform="E2" then marker1=1;
data three; set three;
Where marker1=0;
proc means noprint; var sumend; by insectno; output out=outsas max=TmFrstE2StrtEPG;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= three outsas;
*********************************************************************
*  Finding time to first E2 from start of EPG is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
**************       Time to first E2 from first probe
*********************************************************************;
data three; set OnlyE2;
retain marker1 in0;
if in0 ne insectno then do; marker1=0; in0=insectno; end;
if waveform="E2" then marker1=1;
data three; set three;
Where marker1=0;
proc means noprint; var sumend; by insectno; output out=outsas max=result1;

data three; set three; drop in0 marker1;
data three; set one; retain marker1;
data three; set three;
retain in0 marker1;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if waveform="C" then marker1=1;
Data three; set three; Where marker1=0;
data three; set three; drop in0 marker1;
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas3 sum=Sumdur;
Data outsas3; set outsas3; drop _TYPE_ _FREQ_;
data outsas; set outsas outsas3; merge outsas outsas3; by insectno;


data outsas; set outsas; TmFrstE2FrmFrstPrb=result1-Sumdur; drop result1 Sumdur _TYPE_ _FREQ_;
data outsas; set outsas; if TmFrstE2FrmFrstPrb<=0 then TmFrstE2FrmFrstPrb=".";
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= three four outsas3 outsas;
*********************************************************************
*  Finding time to first E2 from first probe is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
*************     Time to first E2 from start of probe   ************
*********************************************************************;
data three; set OnlyE2;
retain marker1;
if waveform="C" then marker1=1;
if waveform="NP" or waveform="Z" then marker1=0;
Data three; set three;
retain marker2;
if waveform="E2" then marker2=1;
if waveform="NP" or waveform="Z" then marker2=0;
data four; set three;
proc sort; by inverter1;
data four; set four;
retain marker3 in0;
if in0 ne insectno then do; in0=insectno; marker3=0; end;
if marker2=1 then marker3=1;
if waveform="NP" or waveform="Z" then marker3=0;
data four; set four;
proc sort; by line;
data four; set four;
Where marker3=1;
data four; set four;
drop marker1 marker2 marker3 in0;
data four; set four;
retain marker1 in0;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if waveform="E2" then marker1=1;
data four; set four;
Where marker1=0;
data four; set four;
proc means noprint; var dur; by insectno; output out=outsas sum=TmFrstE2FrmPrbStrt;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= three four outsas;
*********************************************************************
*  Finding Time to first E2 from start of probe is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
***********      Duration of NP by hour
*********************************************************************;
Data three; set one;
Where waveform="NP";
Data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend<=3600 then do; ttldur=sum(ttldur, dur); marker4=1; end;
if sumstart<=3600 and sumend>3600 and marker4=0 then ttldur=ttldur+(3600-sumstart);
if sumstart=0 and sumend>3600 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp1;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend-3600>0 and sumstart<=3600 then do; ttldur= sumend-3600; marker4=1; end;
if sumstart>3600 and sumend<=7200 and marker4=0 then do; ttldur=sum(ttldur, dur); marker4=1; end;
if sumstart<=7200 and sumend>7200 and marker4=0 then ttldur=ttldur+(7200-sumstart);
if sumstart<3600 and sumend>7200 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend-7200>0 and sumstart<=7200 then do; ttldur= sumend-7200; marker4=1; end;
if sumstart>7200 and sumend<=10800 and marker4=0 then do; ttldur=sum(ttldur, dur); marker4=1; end;
if sumstart<=10800 and sumend>10800 and marker4=0 then ttldur=ttldur+(10800-sumstart);
if sumstart<7200 and sumend>10800 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp3;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend-10800>0 and sumstart<=10800 then do; ttldur= sumend-10800; marker4=1; end;
if sumstart>10800 and sumend<=14400 and marker4=0 then do; ttldur=sum(ttldur, dur); marker4=1; end;
if sumstart<=14400 and sumend>14400 and marker4=0 then ttldur=ttldur+(14400-sumstart);
if sumstart<10800 and sumend>14400 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp4;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend-14400>0 and sumstart<=14400 then do; ttldur= sumend-14400; marker4=1; end;
if sumstart>14400 and sumend<=18000 and marker4=0 then do; ttldur=sum(ttldur, dur); marker4=1; end;
if sumstart<=18000 and sumend>18000 and marker4=0 then ttldur=ttldur+(18000-sumstart);
if sumstart<14400 and sumend>18000 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp5;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend-18000>0 and sumstart<=18000 then do; ttldur= sumend-18000; marker4=1; end;
if sumstart>18000 and sumend<=21600 and marker4=0 then do; ttldur=sum(ttldur, dur); marker4=1; end;
if sumstart<=21600 and sumend>21600 and marker4=0 then ttldur=ttldur+(21600-sumstart);
if sumstart<18000 and sumend>21600 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp6;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;
/*milan - add up to 12h below*/;

data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend-21600>0 and sumstart<=21600 then do; ttldur= sumend-21600; marker4=1; end;
if sumstart>21600 and sumend<=25200 and marker4=0 then do; ttldur=sum(ttldur, dur); marker4=1; end;
if sumstart<=25200 and sumend>25200 and marker4=0 then ttldur=ttldur+(25200-sumstart);
if sumstart<21600 and sumend>25200 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp7;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend-25200>0 and sumstart<=25200 then do; ttldur= sumend-25200; marker4=1; end;
if sumstart>25200 and sumend<=28800 and marker4=0 then do; ttldur=sum(ttldur, dur); marker4=1; end;
if sumstart<=28800 and sumend>28800 and marker4=0 then ttldur=ttldur+(28800-sumstart);
if sumstart<25200 and sumend>28800 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp8;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend-28800>0 and sumstart<=28800 then do; ttldur= sumend-28800; marker4=1; end;
if sumstart>28800 and sumend<=32400 and marker4=0 then do; ttldur=sum(ttldur, dur); marker4=1; end;
if sumstart<=32400 and sumend>32400 and marker4=0 then ttldur=ttldur+(32400-sumstart);
if sumstart<28800 and sumend>32400 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp9;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend-32400>0 and sumstart<=32400 then do; ttldur= sumend-32400; marker4=1; end;
if sumstart>32400 and sumend<=36000 and marker4=0 then do; ttldur=sum(ttldur, dur); marker4=1; end;
if sumstart<=36000 and sumend>36000 and marker4=0 then ttldur=ttldur+(36000-sumstart);
if sumstart<32400 and sumend>36000 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp10;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend-36000>0 and sumstart<=36000 then do; ttldur= sumend-36000; marker4=1; end;
if sumstart>36000 and sumend<=39600 and marker4=0 then do; ttldur=sum(ttldur, dur); marker4=1; end;
if sumstart<=39600 and sumend>39600 and marker4=0 then ttldur=ttldur+(39600-sumstart);
if sumstart<36000 and sumend>39600 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp11;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend-39600>0 and sumstart<=39600 then do; ttldur= sumend-39600; marker4=1; end;
if sumstart>39600 and sumend<=43200 and marker4=0 then do; ttldur=sum(ttldur, dur); marker4=1; end;
if sumstart<=43200 and sumend>43200 and marker4=0 then ttldur=ttldur+(43200-sumstart);
if sumstart<39600 and sumend>43200 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp12;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

Data ebert; set ebert;
if TtlDurNP1="." then TtlDurNP1=0;
if TtlDurNP2="." then TtlDurNP2=0;
if TtlDurNP3="." then TtlDurNP3=0;
if TtlDurNP4="." then TtlDurNP4=0;
if TtlDurNP5="." then TtlDurNP5=0;
if TtlDurNP6="." then TtlDurNP6=0;
if TtlDurNP7="." then TtlDurNP7=0;
if TtlDurNP8="." then TtlDurNP8=0;
if TtlDurNP9="." then TtlDurNP9=0;
if TtlDurNP10="." then TtlDurNP10=0;
if TtlDurNP11="." then TtlDurNP11=0;
if TtlDurNP12="." then TtlDurNP12=0;

Run;
*********************************************************************
*  Finding duration of NP by hour is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
***********      Number of PDS by hour
*********************************************************************;
Data three; set one;
Where waveform="PDS" or waveform="PD";
Data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend<=3600 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=3600 and sumend>3600 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPDS1;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-3600>0 and sumstart<=3600 then do; ttl1= ttl1+1; marker4=1; end;
if sumstart>3600 and sumend<=7200 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=7200 and sumend>7200 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPDS2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-7200>0 and sumstart<=7200 then do; ttl1= ttl1+1; marker4=1; end;
if sumstart>7200 and sumend<=10800 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=10800 and sumend>10800 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPDS3;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-10800>0 and sumstart<=10800 then do; ttl1= ttl1+1; marker4=1; end;
if sumstart>10800 and sumend<=14400 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=14400 and sumend>14400 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPDS4;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-14400>0 and sumstart<=14400 then do; ttl1= ttl1+1; marker4=1; end;
if sumstart>14400 and sumend<=18000 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=18000 and sumend>18000 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPDS5;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-18000>0 and sumstart<=18000 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart>18000 and sumend<=21600 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=21600 and sumend>21600 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPDS6;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-21600>0 and sumstart<=21600 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart>21600 and sumend<=25200 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=25200 and sumend>25200 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPDS7;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-25200>0 and sumstart<=25200 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart>25200 and sumend<=28800 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=28800 and sumend>28800 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPDS8;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-28800>0 and sumstart<=28800 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart>28800 and sumend<=32400 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=32400 and sumend>32400 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPDS9;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-32400>0 and sumstart<=32400 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart>32400 and sumend<=36000 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=36000 and sumend>36000 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPDS10;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-36000>0 and sumstart<=36000 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart>36000 and sumend<=39600 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=39600 and sumend>39600 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPDS11;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-39600>0 and sumstart<=39600 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart>39600 and sumend<=43200 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=43200 and sumend>43200 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPDS12;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;


Data ebert; set ebert;
if NumPDS1="." then NumPDS1=0;
if NumPDS2="." then NumPDS2=0;
if NumPDS3="." then NumPDS3=0;
if NumPDS4="." then NumPDS4=0;
if NumPDS5="." then NumPDS5=0;
if NumPDS6="." then NumPDS6=0;
if NumPDS7="." then NumPDS7=0;
if NumPDS8="." then NumPDS8=0;
if NumPDS9="." then NumPDS9=0;
if NumPDS10="." then NumPDS10=0;
if NumPDS11="." then NumPDS11=0;
if NumPDS12="." then NumPDS12=0;

run;
*********************************************************************
*  Finding number of pds by hour is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
***** END PART 5   **************************************************
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
***********      Average Duration of PDS by hour
*********************************************************************;
Data three; set one;
Where waveform="PDS" or waveform="PD";
Data four; set three;
retain ttldur in0 ttl1;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; end;
if sumend<=3600 then do; ttldur=sum(ttldur, dur); ttl1=ttl1+1; marker4=1; end;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS1 Attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS1="."; else MnDurPdS1=MnDurPdS1/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttldur in0 ttl1 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; marker4=0; end;
if sumstart<7200 and sumstart>=3600 then do; ttldur=sum(ttldur, dur); ttl1=ttl1+1; marker4=1; end;
marker4=0;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS2 attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS2="."; else MnDurPdS2=MnDurPdS2/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttldur in0 ttl1 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; marker4=0; end;
if sumstart<10800 and sumstart>=7200 then do; ttldur=sum(ttldur, dur); ttl1=ttl1+1; marker4=1; end;
marker4=0;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS3 attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS3="."; else MnDurPdS3=MnDurPdS3/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttldur in0 ttl1 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; marker4=0; end;
if sumstart<14400 and sumstart>=10800 then do; ttldur=sum(ttldur, dur); ttl1=ttl1+1; marker4=1; end;
marker4=0;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS4 attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS4="."; else MnDurPdS4=MnDurPdS4/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttldur in0 ttl1 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; marker4=0; end;
if sumstart<18000 and sumstart>=14400 then do; ttldur=sum(ttldur, dur); ttl1=ttl1+1; marker4=1; end;
marker4=0;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS5 attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS5="."; else MnDurPdS5=MnDurPdS5/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttldur in0 ttl1 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; marker4=0; end;
if sumstart<21600 and sumstart>=18000 then do; ttldur=sum(ttldur, dur); ttl1=ttl1+1; marker4=1; end;
marker4=0;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS6 attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS6="."; else MnDurPdS6=MnDurPdS6/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttldur in0 ttl1 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; marker4=0; end;
if sumstart<25200 and sumstart>=21600 then do; ttldur=sum(ttldur, dur); ttl1=ttl1+1; marker4=1; end;
marker4=0;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS7 attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS7="."; else MnDurPdS7=MnDurPdS7/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttldur in0 ttl1 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; marker4=0; end;
if sumstart<28800 and sumstart>=25200 then do; ttldur=sum(ttldur, dur); ttl1=ttl1+1; marker4=1; end;
marker4=0;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS8 attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS8="."; else MnDurPdS8=MnDurPdS8/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttldur in0 ttl1 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; marker4=0; end;
if sumstart<32400 and sumstart>=28800 then do; ttldur=sum(ttldur, dur); ttl1=ttl1+1; marker4=1; end;
marker4=0;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS9 attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS9="."; else MnDurPdS9=MnDurPdS9/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttldur in0 ttl1 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; marker4=0; end;
if sumstart<36000 and sumstart>=32400 then do; ttldur=sum(ttldur, dur); ttl1=ttl1+1; marker4=1; end;
marker4=0;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS10 attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS10="."; else MnDurPdS10=MnDurPdS10/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttldur in0 ttl1 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; marker4=0; end;
if sumstart<39600 and sumstart>=36000 then do; ttldur=sum(ttldur, dur); ttl1=ttl1+1; marker4=1; end;
marker4=0;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS11 attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS11="."; else MnDurPdS11=MnDurPdS11/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttldur in0 ttl1 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; marker4=0; end;
if sumstart<43200 and sumstart>=39600 then do; ttldur=sum(ttldur, dur); ttl1=ttl1+1; marker4=1; end;
marker4=0;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS12 attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS12="."; else MnDurPdS12=MnDurPdS12/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

/*Data ebert; set ebert;
if MnDurPDS1="." then MnDurPDS1=0;
if MnDurPDS2="." then MnDurPDS2=0;
if MnDurPDS3="." then MnDurPDS3=0;
if MnDurPDS4="." then MnDurPDS4=0;
if MnDurPDS5="." then MnDurPDS5=0;
if MnDurPDS6="." then MnDurPDS6=0;
if MnDurPDS7="." then MnDurPDS7=0;
if MnDurPDS8="." then MnDurPDS8=0;
if MnDurPDS9="." then MnDurPDS9=0;
if MnDurPDS10="." then MnDurPDS10=0;
if MnDurPDS11="." then MnDurPDS11=0;
if MnDurPDS12="." then MnDurPDS12=0;
run*/;

*********************************************************************
*  Finding duration of PDS by hour is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
***********      Number of F by hour
*********************************************************************;
Data three; set one;
Where waveform="F";
Data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend<=3600 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=3600 and sumend>3600 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumF1;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-3600>0 and sumstart<=3600 then do; ttl1= ttl1+1; marker4=1; end;
if sumstart>3600 and sumend<=7200 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=7200 and sumend>7200 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumF2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-7200>0 and sumstart<=7200 then do; ttl1= ttl1+1; marker4=1; end;
if sumstart>7200 and sumend<=10800 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=10800 and sumend>10800 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumF3;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-10800>0 and sumstart<=10800 then do; ttl1= ttl1+1; marker4=1; end;
if sumstart>10800 and sumend<=14400 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=14400 and sumend>14400 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumF4;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-14400>0 and sumstart<=14400 then do; ttl1= ttl1+1; marker4=1; end;
if sumstart>14400 and sumend<=18000 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=18000 and sumend>18000 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumF5;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-18000>0 and sumstart<=18000 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart>18000 and sumend<=21600 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=21600 and sumend>21600 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumF6;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-25200>0 and sumstart<=25200 then do; ttl1= ttl1+1; marker4=1; end;
if sumstart>25200 and sumend<=21600 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=21600 and sumend>21600 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumF7;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-28800>0 and sumstart<=28800 then do; ttl1= ttl1+1; marker4=1; end;
if sumstart>28800 and sumend<=25200 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=25200 and sumend>25200 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumF8;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-32400>0 and sumstart<=32400 then do; ttl1= ttl1+1; marker4=1; end;
if sumstart>32400 and sumend<=28800 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=28800 and sumend>28800 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumF9;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-36000>0 and sumstart<=36000 then do; ttl1= ttl1+1; marker4=1; end;
if sumstart>36000 and sumend<=32400 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=32400 and sumend>32400 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumF10;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-39600>0 and sumstart<=39600 then do; ttl1= ttl1+1; marker4=1; end;
if sumstart>39600 and sumend<=36000 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=36000 and sumend>36000 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumF11;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend-43200>0 and sumstart<=43200 then do; ttl1= ttl1+1; marker4=1; end;
if sumstart>43200 and sumend<=39600 and marker4=0 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=39600 and sumend>39600 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumF12;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;


Data ebert; set ebert;
if NumF1="." then NumF1=0;
if NumF2="." then NumF2=0;
if NumF3="." then NumF3=0;
if NumF4="." then NumF4=0;
if NumF5="." then NumF5=0;
if NumF6="." then NumF6=0;
if NumF7="." then NumF7=0;
if NumF8="." then NumF8=0;
if NumF9="." then NumF9=0;
if NumF10="." then NumF10=0;
if NumF11="." then NumF11=0;
if NumF12="." then NumF12=0;

run;
*********************************************************************
*  Finding number of pds by hour is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*******   END Part 6   **********************************************
*********************************************************************;



*********************************************************************
*********************************   Start New Method    *************
***********      Duration of F by hour
*********************************************************************;
Data three; set one;
Where waveform="F";
Data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend<=3600 then do; ttldur=sum(ttldur, dur); mark4=1; end;
if sumstart<=3600 and sumend>3600 and mark4=0 then ttldur=ttldur+(3600-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF1;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend-3600>0 and sumstart<=3600 then do; ttldur= sumend-3600; mark4=1; end;
if sumstart>3600 and sumend<=7200 and mark4=0 then do; ttldur=sum(ttldur, dur); mark4=1; end;
if sumstart<=7200 and sumend>7200 and mark4=0 then ttldur=ttldur+(7200-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend-7200>0 and sumstart<=7200 then do; ttldur= sumend-7200; mark4=1; end;
if sumstart>7200 and sumend<=10800 and mark4=0 then do; ttldur=sum(ttldur, dur); mark4=1; end;
if sumstart<=10800 and sumend>10800 and mark4=0 then ttldur=ttldur+(10800-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF3;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend-10800>0 and sumstart<=10800 then do; ttldur= sumend-10800; mark4=1; end;
if sumstart>10800 and sumend<=14400 and mark4=0 then do; ttldur=sum(ttldur, dur); mark4=1; end;
if sumstart<=14400 and sumend>14400 and mark4=0 then ttldur=ttldur+(14400-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF4;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend-14400>0 and sumstart<=14400 then do; ttldur= sumend-14400; mark4=1; end;
if sumstart>14400 and sumend<=18000 and mark4=0 then do; ttldur=sum(ttldur, dur); mark4=1; end;
if sumstart<=18000 and sumend>18000 and mark4=0 then ttldur=ttldur+(18000-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF5;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend-18000>0 and sumstart<=18000 then do; ttldur= sumend-18000; mark4=1; end;
if sumstart>18000 and sumend<=21600 and mark4=0 then do; ttldur=sum(ttldur, dur); mark4=1; end;
if sumstart<=21600 and sumend>21600 and mark4=0 then ttldur=ttldur+(21600-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF6;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend-21600>0 and sumstart<=21600 then do; ttldur= sumend-21600; mark4=1; end;
if sumstart>21600 and sumend<=25200 and mark4=0 then do; ttldur=sum(ttldur, dur); mark4=1; end;
if sumstart<=25200 and sumend>25200 and mark4=0 then ttldur=ttldur+(25200-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF7;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend-25200>0 and sumstart<=25200 then do; ttldur= sumend-25200; mark4=1; end;
if sumstart>25200 and sumend<=28800 and mark4=0 then do; ttldur=sum(ttldur, dur); mark4=1; end;
if sumstart<=28800 and sumend>28800 and mark4=0 then ttldur=ttldur+(28800-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF8;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend-28800>0 and sumstart<=28800 then do; ttldur= sumend-28800; mark4=1; end;
if sumstart>28800 and sumend<=32400 and mark4=0 then do; ttldur=sum(ttldur, dur); mark4=1; end;
if sumstart<=32400 and sumend>32400 and mark4=0 then ttldur=ttldur+(32400-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF9;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend-32400>0 and sumstart<=32400 then do; ttldur= sumend-32400; mark4=1; end;
if sumstart>32400 and sumend<=36000 and mark4=0 then do; ttldur=sum(ttldur, dur); mark4=1; end;
if sumstart<=36000 and sumend>36000 and mark4=0 then ttldur=ttldur+(36000-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF10;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend-36000>0 and sumstart<=36000 then do; ttldur= sumend-36000; mark4=1; end;
if sumstart>36000 and sumend<=39600 and mark4=0 then do; ttldur=sum(ttldur, dur); mark4=1; end;
if sumstart<=39600 and sumend>39600 and mark4=0 then ttldur=ttldur+(39600-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF11;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend-39600>0 and sumstart<=39600 then do; ttldur= sumend-39600; mark4=1; end;
if sumstart>39600 and sumend<=43200 and mark4=0 then do; ttldur=sum(ttldur, dur); mark4=1; end;
if sumstart<=43200 and sumend>43200 and mark4=0 then ttldur=ttldur+(43200-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF12;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four;

Data ebert; set ebert;
if TtlDurF1="." then TtlDurF1=0;
if TtlDurF2="." then TtlDurF2=0;
if TtlDurF3="." then TtlDurF3=0;
if TtlDurF4="." then TtlDurF4=0;
if TtlDurF5="." then TtlDurF5=0;
if TtlDurF6="." then TtlDurF6=0;
if TtlDurF7="." then TtlDurF7=0;
if TtlDurF8="." then TtlDurF8=0;
if TtlDurF9="." then TtlDurF9=0;
if TtlDurF10="." then TtlDurF10=0;
if TtlDurF11="." then TtlDurF11=0;
if TtlDurF12="." then TtlDurF12=0;

run;
*********************************************************************
*  Finding duration of F by hour is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
***********      Number of probes by hour
*********************************************************************;
Data three; set one;
retain marker1 marker2 in0;
w1=waveform;
if in0 ne insectno then do; in0=insectno; marker1=0; marker2=0; end;
if w1="C" then marker1=1;
if w1="NP" or w1="Z" then marker2=1; else marker2=0;
if marker1=1 and marker2=1 then marker1=0;
Data three; set three; drop marker2 in0;
data three; set three;
retain marker2 marker3 in0;
if in0 ne insectno then do; in0=insectno; marker2=0; marker3=0; end;
if marker2 ne marker1 then do; marker2=marker1; marker3=marker3+1; end;
data three; set three;
proc means noprint; var dur; by insectno marker3; output out=outsas sum=durProbe;
data outsas; set outsas; if mod(marker3,2) = 1 then waveform="X "; else waveform="NP";
data outsas; set outsas;
retain sumstart sumend in0 holder1;
if in0 ne insectno then do; in0=insectno; sumstart=0; sumend=0; end;
if sumend ne 0 then sumstart=sum(sumstart, holder1);
sumend=sumend+durprobe;
holder1=durprobe;

data three; set outsas;
drop _TYPE_ _FREQ_ in0 holder1;
data three; set three;
Where waveform="X ";
data four; set three;
retain ttl1 in0 mark4;
if in0 ne insectno then do; in0=insectno; ttl1=0; mark4=0; end;
if sumend<=3600 then do; ttl1=ttl1+1; mark4=1; end;
if sumstart<3600 and sumend>3600 and mark4=0 then ttl1=ttl1+1;
mark4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPrb1;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 mark4;
if in0 ne insectno then do; in0=insectno; ttl1=0; mark4=0; end;
if sumend-3600>0 and sumstart<=3600 then do; ttl1= ttl1+1; mark4=1; end;
if sumstart>3600 and sumend<=7200 and mark4=0 then do; ttl1=ttl1+1; mark4=1; end;
if sumstart<7200 and sumend>7200 and mark4=0 then ttl1=ttl1+1;
mark4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPrb2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 mark4;
if in0 ne insectno then do; in0=insectno; ttl1=0; mark4=0; end;
if sumend-7200>0 and sumstart<=7200 then do; ttl1= ttl1+1; mark4=1; end;
if sumstart>7200 and sumend<=10800 and mark4=0 then do; ttl1=ttl1+1; mark4=1; end;
if sumstart<10800 and sumend>10800 and mark4=0 then ttl1=ttl1+1;
mark4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPrb3;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 mark4;
if in0 ne insectno then do; in0=insectno; ttl1=0; mark4=0; end;
if sumend-10800>0 and sumstart<=10800 then do; ttl1= ttl1+1; mark4=1; end;
if sumstart>10800 and sumend<=14400 and mark4=0 then do; ttl1=ttl1+1; mark4=1; end;
if sumstart<14400 and sumend>14400 and mark4=0 then ttl1=ttl1+1;
mark4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPrb4;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 mark4;
if in0 ne insectno then do; in0=insectno; ttl1=0; mark4=0; end;
if sumend-14400>0 and sumstart<=14400 then do; ttl1= ttl1+1; mark4=1; end;
if sumstart>14400 and sumend<=18000 and mark4=0 then do; ttl1=ttl1+1; mark4=1; end;
if sumstart<18000 and sumend>18000 and mark4=0 then ttl1=ttl1+1;
mark4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPrb5;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 mark4;
if in0 ne insectno then do; in0=insectno; ttl1=0; mark4=0; end;
if sumend-18000>0 and sumstart<=18000 then do; ttl1=ttl1+1; mark4=1; end;
if sumstart>18000 and sumend<=21600 and mark4=0 then do; ttl1=ttl1+1; mark4=1; end;
if sumstart<21600 and sumend>21600 and mark4=0 then ttl1=ttl1+1;
mark4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPrb6;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 mark4;
if in0 ne insectno then do; in0=insectno; ttl1=0; mark4=0; end;
if sumend-25200>0 and sumstart<=25200 then do; ttl1= ttl1+1; mark4=1; end;
if sumstart>25200 and sumend<=21600 and mark4=0 then do; ttl1=ttl1+1; mark4=1; end;
if sumstart<=21600 and sumend>21600 and mark4=0 then ttl1=ttl1+1;
mark4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPrb7;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 mark4;
if in0 ne insectno then do; in0=insectno; ttl1=0; mark4=0; end;
if sumend-28800>0 and sumstart<=28800 then do; ttl1= ttl1+1; mark4=1; end;
if sumstart>28800 and sumend<=25200 and mark4=0 then do; ttl1=ttl1+1; mark4=1; end;
if sumstart<=25200 and sumend>25200 and mark4=0 then ttl1=ttl1+1;
mark4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPrb8;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 mark4;
if in0 ne insectno then do; in0=insectno; ttl1=0; mark4=0; end;
if sumend-32400>0 and sumstart<=32400 then do; ttl1= ttl1+1; mark4=1; end;
if sumstart>32400 and sumend<=28800 and mark4=0 then do; ttl1=ttl1+1; mark4=1; end;
if sumstart<=28800 and sumend>28800 and mark4=0 then ttl1=ttl1+1;
mark4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPrb9;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 mark4;
if in0 ne insectno then do; in0=insectno; ttl1=0; mark4=0; end;
if sumend-36000>0 and sumstart<=36000 then do; ttl1= ttl1+1; mark4=1; end;
if sumstart>36000 and sumend<=32400 and mark4=0 then do; ttl1=ttl1+1; mark4=1; end;
if sumstart<=32400 and sumend>32400 and mark4=0 then ttl1=ttl1+1;
mark4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPrb10;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 mark4;
if in0 ne insectno then do; in0=insectno; ttl1=0; mark4=0; end;
if sumend-39600>0 and sumstart<=39600 then do; ttl1= ttl1+1; mark4=1; end;
if sumstart>39600 and sumend<=36000 and mark4=0 then do; ttl1=ttl1+1; mark4=1; end;
if sumstart<=36000 and sumend>36000 and mark4=0 then ttl1=ttl1+1;
mark4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPrb11;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

data four; set three;
retain ttl1 in0 mark4;
if in0 ne insectno then do; in0=insectno; ttl1=0; mark4=0; end;
if sumend-43200>0 and sumstart<=43200 then do; ttl1= ttl1+1; mark4=1; end;
if sumstart>43200 and sumend<=39600 and mark4=0 then do; ttl1=ttl1+1; mark4=1; end;
if sumstart<=39600 and sumend>39600 and mark4=0 then ttl1=ttl1+1;
mark4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPrb12;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= four outsas;

Data ebert; set ebert;
if NumPrb1="." then NumPrb1=0;
if NumPrb2="." then NumPrb2=0;
if NumPrb3="." then NumPrb3=0;
if NumPrb4="." then NumPrb4=0;
if NumPrb5="." then NumPrb5=0;
if NumPrb6="." then NumPrb6=0;
if NumPrb7="." then NumPrb7=0;
if NumPrb8="." then NumPrb8=0;
if NumPrb9="." then NumPrb9=0;
if NumPrb10="." then NumPrb10=0;
if NumPrb11="." then NumPrb11=0;
if NumPrb12="." then NumPrb12=0;

run;
*********************************************************************
*  Finding number of pds by hour is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*******    END Part 7   *********************************************
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
*****************         Time to first pd from beginning of first probe
*********************************************************************;
data three; set onepd;
retain in0 marker1 marker2;
if in0 ne insectno then do; in0=insectno; marker1=0; marker2=0; end;
if waveform= 'C' and marker2=0 then do; marker1=1; marker2=1; end;
If waveform= 'PD' then marker1=0;
data three; set three;
Where marker1=1;
data three; set three;
proc means noprint; var dur; by insectno; output out=outsas sum=TmFrstCFrstPD;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
*********************************************************************
*  Finding Time to first pd from beginning of first probe is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
******   Time from end of last pd in probe to end of first probe   **
*********************************************************************;
data three; set onepd;
data three; set three;
retain in0 marker2;
if in0 ne insectno then do in0=insectno; marker2=0; end;
if waveform="PD"  then marker2=marker2+1;
Data three; set three; Where marker2>0;
Data three; set three; drop in0 marker2;
data three; set three;
retain in0 marker1;
if in0 ne insectno then do;
	in0=insectno; marker1=0;
	end;
if waveform = "NP" then marker1=1;
data three; set three; Where marker1=0;
data three; set three; drop in0 marker1;
Proc sort data=three; by inverter1;
data three; set three;
retain in0 marker2;
if in0 ne insectno then do in0=insectno; marker2=0; end;
if waveform="PD"  then marker2=marker2+1;
proc sort data=three out=three(drop=in0); by line;
data three; set three; 
retain in0 holder1;
if in0 ne insectno then do; in0=insectno; holder1=0; end;
if marker2=0 then holder1=sum(holder1, dur);
data three; set three;
proc means noprint; by insectno; var holder1; output out=outsas42 max=TmEndLstPDEndPrb;
Data outsas42; set outsas42; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas42; merge Ebert outsas42; by insectno;
proc delete lib=work data= three outsas42;
*********************************************************************
*  Finding Time from end of last pd to end of probe is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
**********     Duration of PD subphases, if present   ***************
*********************************************************************;
data three; set one;
retain in0 marker1;
if in0 ne insectno then do; marker1=0; in0=insectno; end;
if waveform= 'II2' then marker1=1;
data three; set three; drop in0;
proc sort data=three; by inverter1;
data three; set three;
retain marker2 in0;
if in0 ne insectno then do; in0=insectno; marker2=0; end;
if marker1=1 then marker2=1;
data three; set three; Where marker2=1;
proc sort data=three; by line;
data three; set three;
Where waveform='PD' or waveform='II2' or waveform='II3';
Data Four; set three;
Where waveform='PD';
proc means noprint;
var dur; by insectno; output out=outsas sum=SumPDII1;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;

data Four; set three;
Where waveform='II2';
proc means noprint;
var dur; by insectno; output out=outsas sum=SumPDII2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;

data Four; set three;
Where waveform='II3';
proc means noprint;
var dur; by insectno; output out=outsas sum=SumPDII3;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= Four outsas three;
*********************************************************************
*  Finding duration of PD subphases is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
* Time from the end of the last pd to the beginning of the E1 followed by sustained E2
*      In this code the last sustained E2 is used. 
*      It doesn't consider the possibility of multiple sustained E2
*********************************************************************;
Data three; set onlysusE2;
proc sort; by inverter1;
data three; set three;  *remove all events after the last sustained E2 ;
retain in0 marker1;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if waveform="E2" and dur>600 then marker1=1;
Data three; set three; Where marker1=1;
data three; set three; drop in0 marker1;

Data three; set three; *remove all events before the last pd;
if waveform='PD' or waveform='II2' or waveform='PDS'
   or waveform='II3' or waveform='PDL' then waveform='PD';
data three; set three;
retain in0 marker1;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if waveform="PD" then marker1=1;
Data three; set three; Where marker1=0;
data three; set three; drop in0 marker1;

data three; set three; *remove the E1 before sustained E2 and remove the sustained E2;
retain in0 marker1;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if waveform="E1" then marker1=1;
Data three; set three; Where marker1=1;
data three; set three; drop in0 marker1;
data three; set three;
retain in0 marker1;
if in0 ne insectno then do; in0=insectno; marker1=0; end; else marker1=1;
data three; set three; Where marker1=1;
proc sort data=three; by line;
data three; set three; proc means noprint; by insectno; var dur; output out=outsas sum=TmEndPDBegE1FllwdSusE2;
Data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= three outsas;
run;
*********************************************************************
*  Finding Tm End of last pd to beginning of E1 followed sustained E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
* Time from the end of the last pd to the end of EPG
*********************************************************************;
Data three; set onepd;
marker1=0;
	if waveform='PD' then marker1=1;
	if waveform='PDL' then marker1=1;
	if waveform='II2' then marker1=1;
	if waveform='II3' then marker1=1;
data three; set three;
proc sort; by inverter1;
data three; set three;
	retain marker2 in0;
	if in0 ne insectno then do; in0=insectno; marker2=0; end;
	if marker1=1 then marker2=1;
data three; set three;
	Where marker2=0;
proc sort; by line;
proc sort data=three; by line;
proc means noprint; var dur; by insectno; output out=outsas sum=TmLstPdEndRcrd;
data outsas; set outsas; Drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= three outsas;
*********************************************************************
*  Finding Time from the end of the last pd to the end of EPG is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
****     From start of last E1 to end of EPG recording
****Milan: added since the variable was mention but never calculated*
*********************************************************************;
data three; set onlyE1;
proc sort data=three; by inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end; else marker1=1;
data three; set three; Where marker1=0 and waveform="E1";
proc sort data=three; by line;
data three; set three; TmLstE1EndRcrd=dur;
data three; set three; drop waveform dur line sumstart sumend instance inverter1 in0 marker1;
proc sort; by insectno;
data Ebert; set Ebert three; merge Ebert three; by insectno;
*********************************************************************
*  Finding from first E1 to end of EPG record is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
***** Time from Last E2 to end of EPG record 
*********************************************************************;
data three; set onlyE2;
proc sort data=three; by inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end; else marker1=1;
data three; set three; Where marker1=0 and waveform="E2";
proc sort data=three; by line;
data three; set three; TmLstE2EndRcrd=dur;
data three; set three; drop waveform dur line sumstart sumend instance inverter1 in0 marker1;
proc sort; by insectno;
data Ebert; set Ebert three; merge Ebert three; by insectno;
*********************************************************************
*  Finding time from the beginning of E2 to the end of the EPG record is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
***** Duration of longest E2
*********************************************************************;
Data three; set OnlyE2;
	Where waveform='E2';
data three; set three; proc means noprint;
	var dur; by insectno; output out=outsas max=maxE2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= three outsas;
*********************************************************************
*  Finding Duration of longest E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****** Find duration of NP following first sustained E2  ************
*********************************************************************;
Data three; set onlysuse2;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if waveform='E2' and dur>600 then marker1=1;
data three; set three; Where marker1=1;
data three; set three; drop in0 marker1;
Data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if waveform='NP' or waveform="Z" then marker1=1;
Data three; set three; Where marker1=1;
Data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if waveform ne'NP' and waveform ne 'Z' then marker1=1;
data three; set three; Where marker1=0;
data three; set three; DurNpFllwFrstSusE2=dur;
data three; set three; drop dur waveform line sumstart sumend instance inverter1 in0 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc delete lib=work data= three;
*********************************************************************
*  Finding Find duration of NP following first sustained E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method         ********
***** Duration of NP just after sus E2 given NP last event   ********
*********************************************************************;
Data three; set onlysuse2;
proc sort; by inverter1;
data three; set three; *delete all insects that do not have an ending NP waveform;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if waveform = "NP" or waveform = "Z" then marker1=1;
proc sort data=three; by insectno line;
data three; set three; drop in0;
data three; set three;
	retain in0 marker2;
	if in0 ne insectno then do; in0=insectno; marker2=0; if marker1=1 then marker2=1; end;
data three; set three; Where marker2=1;
data three; set three; drop in0 marker1 marker2;
proc sort data=three; by insectno inverter1;

Data three; set three;
	retain in0 RecDur;
	if in0 ne insectno then do; in0=insectno; RecDur=sumend; end;
data three; set three;
proc sort; by line;
data three; set three; drop in0;
Data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if waveform='E2' and dur>600 then marker1=1;
data three; set three; Where marker1=1;
data three; set three; drop in0 marker1;
Data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if waveform='NP' or waveform="Z" then marker1=1;
Data three; set three; Where marker1=1;
Data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if waveform ne'NP' and waveform ne 'Z' then marker1=1;
data three; set three; Where marker1=0;
/*data three; set three; 
	if sumend=RecDur then DurTrmNpFllwFrstSusE2=.; else DurTrmNpFllwFrstSusE2='.'; *NOTE: This variable is set to missing in all cases;
*milan: commented out. Why is it missing in all cases?;
*/;
data three; set three; drop dur line sumstart RecDur sumend instance inverter1 in0 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc delete lib=work data= three;
*********************************************************************
*  Finding Duration of NP just after sus E2 given NP artificially terminated event is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****  Percent probing spent in C
*********************************************************************;
Data three; set onlycnopd;
	Where waveform ne 'NP' and waveform ne 'Z';
data three; set three;
proc means noprint; var dur; by insectno; output out=outsas1 sum=SumPrb;
data three; set three;
	Where waveform='C' or waveform ='PD';
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas2 sum=sumC;
data outsas1; set outsas1 outsas2; merge outsas1 outsas2; by insectno;
data outsas1; set outsas1;
	PrcntPrbC=100*sumC/sumprb;
data outsas1; set outsas1; drop _TYPE_ _FREQ_ SumC SumPrb;
data Ebert; set Ebert outsas1; merge Ebert outsas1; by insectno;
data Ebert; set Ebert; if PrcntPrbC='.' then PrcntPrbC=0;
proc delete lib=work data= outsas1 outsas2 three;
*********************************************************************
*  Finding Percent probing spent in C is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


***********************************************************************
*********************************   Start New Method    ***************
****  Percent probing spent in E1
*********************************************************************;
Data three; set OnlyE1;
	Where waveform ne 'NP' and waveform ne 'Z';
data three; set three;
proc means noprint; var dur; by insectno; output out=outsas1 sum=SumPrb;
data three; set three;
	Where waveform='E1';
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas2 sum=sumC;
data outsas1; set outsas1 outsas2; merge outsas1 outsas2; by insectno;
data outsas1; set outsas1;
	PrcntPrbE1=100*sumC/sumprb;
data outsas1; set outsas1; drop _TYPE_ _FREQ_ SumC SumPrb;
data Ebert; set Ebert outsas1; merge Ebert outsas1; by insectno;
data Ebert; set Ebert; if PrcntPrbE1='.' then PrcntPrbE1=0;
proc delete lib=work data= outsas1 outsas2 three;
*********************************************************************
*  Finding Percent probing spent in E1 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****  Percent probing spent in E2
*********************************************************************;
Data three; set one;
	Where waveform ne 'NP' and waveform ne 'Z';
data three; set three;
proc means noprint; var dur; by insectno; output out=outsas1 sum=SumPrb;
data three; set three;
	Where waveform='E2';
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas2 sum=sumC;
data outsas1; set outsas1 outsas2; merge outsas1 outsas2; by insectno;
data outsas1; set outsas1;
	PrcntPrbE2=100*sumC/sumprb;
data outsas1; set outsas1; drop _TYPE_ _FREQ_ SumC SumPrb;
data Ebert; set Ebert outsas1; merge Ebert outsas1; by insectno;
proc delete lib=work data= outsas1 outsas2 three;
data Ebert; set Ebert; if PrcntPrbE2='.' then PrcntPrbE2=0;
*********************************************************************
*  Finding Percent probing spent in E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
****     Start New Method                                 ***********
****  Percent probing spent in F                          ***********
*********************************************************************;
Data three; set one;
	Where waveform ne 'NP' and waveform ne 'Z';
data three; set three;
proc means noprint; var dur; by insectno; output out=outsas1 sum=SumPrb;
data three; set three;
	Where waveform='F';
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas2 sum=sumC;
data outsas1; set outsas1 outsas2; merge outsas1 outsas2; by insectno;
data outsas1; set outsas1;
	PrcntPrbF=100*sumC/sumprb;
data outsas1; set outsas1; drop _TYPE_ _FREQ_ SumC SumPrb;
data Ebert; set Ebert outsas1; merge Ebert outsas1; by insectno;
proc delete lib=work data= outsas1 outsas2 three;
data Ebert; set Ebert; if PrcntPrbF='.' then PrcntPrbF=0;
*********************************************************************
*  Finding Percent probing spent in F is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
****     Start New Method                                 ***********
****  Percent probing spent in G                          ***********
*********************************************************************;
Data three; set one;
	Where waveform ne 'NP' and waveform ne 'Z';
data three; set three;
proc means noprint; var dur; by insectno; output out=outsas1 sum=SumPrb;
data three; set three;
	Where waveform='G';
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas2 sum=sumC;
data outsas1; set outsas1 outsas2; merge outsas1 outsas2; by insectno;
data outsas1; set outsas1;
	PrcntPrbG=100*sumC/sumprb;
data outsas1; set outsas1; drop _TYPE_ _FREQ_ SumC SumPrb;
data Ebert; set Ebert outsas1; merge Ebert outsas1; by insectno;
proc delete lib=work data= outsas1 outsas2 three;
data Ebert; set Ebert; if PrcntPrbG='.' then PrcntPrbG=0;
*******************************************************************
*  Finding Percent probing spent in G is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXXXXXX*
*******************************************************************


*******************************************************************
****               Start New Method                     ***********
****       Percent E2 spent in Sustained E2             ***********
*******************************************************************;
Data three; set OnlyE2;
	if waveform = 'E2' then marker1=1; else marker1=0;
data three; set three;
proc means noprint; var marker1; by insectno; output out=outsas1 sum=SumPrb;
data three; set three;
	Where waveform='E2' and dur>600;
Data three; set three;
proc means noprint; var marker1; by insectno; output out=outsas2 sum=sumC;
data outsas1; set outsas1 outsas2; merge outsas1 outsas2; by insectno;
data outsas1; set outsas1;
	PrcntE2SusE2=100*sumC/sumprb;
data outsas1; set outsas1; drop _TYPE_ _FREQ_ SumC SumPrb;
data outsas1; set outsas1; if PrcntE2SusE2='.' then PrcntE2SusE2=0;
data Ebert; set Ebert outsas1; merge Ebert outsas1; by insectno;
proc delete lib=work data= outsas1 outsas2 three;
Run;
*********************************************************************
*  Finding Percent E2 spent in Sustained E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


**********************************************************************
*****               THE END. START STATISTICAL ANALYSES     **********
**********************************************************************
**********************************************************************
*****             ******    ***********   *****       ****************
*****             ******     **********   *****   ***    *************
*****   ****************      *********   *****   ******   ***********
*****   ****************   *   ********   *****   ********   *********
*****   ****************   **   *******   *****   *********   ********
*****             ******   ***   ******   *****   **********  ********
*****             ******   ****   *****   *****   *********   ********
*****   ****************   *****   ****   *****   ********   *********
*****   ****************   ******   ***   *****   *******   **********
*****   ****************   *******   **   *****   *****   ************
*****             ******   ********   *   *****   ***   **************
*****             ******   *********      *****       ****************
**********************************************************************
**********************************************************************;

**********************************************************************
**********************************************************************
**********************************************************************
**********************************************************************
**********************************************************************
**********************************************************************
*******                                                      *********
*******                      Clean-up                        *********
*******                                                      *********
*******                     Treatments                       *********
*******                                                      *********
*******               Zeros and Missing data                 *********
*******                                                      *********
*******                                                      *********
**********************************************************************
**********************************************************************
**********************************************************************
**********************************************************************
**********************************************************************
**********************************************************************;

Data Ebert; Set Ebert; Drop waveform;
/*
Milan: Moved up.
Data Ebert; Set Ebert; trt=substr(insectno,1,1);  *recover treatment designations*;
*/;
Data Ebert; Set Ebert;
If NmbrShrtC="." then NmbrShrtC="0";
if MnDurPDS1="." then MnDurPDS1=0;
if TtlDurF1="." then TtlDurF1=0;
If NumPrb1="." then NumPrb1=0;
If NumF1="." then NumF1=0;
if TtlDurNp1="." then TtlDurNp1=0;
If NumPDS1="." then NumPDS1=0;

If maxdur<3600 then do; *if maxdur<3600 then the recording duration was less than 1 hour;
		If MnDurPDS2=0 then MnDurPDS2=".";
		If TtlDurF2=0 then TtlDurF2=".";
		If NumPrb2=0 then NumPrb2=".";
		If NumF2=0 then NumF2=".";
		if TtlDurNp2=0 then TtlDurNp2=".";
		If NumPDS2=0 then NumPDS2=".";
End;

If maxdur<7200 then do;
		If MnDurPDS3=0 then MnDurPDS3=".";
		If TtlDurF3=0 then TtlDurF3=".";
		If NumPrb3=0 then NumPrb3=".";
		If NumF3=0 then NumF3=".";
		if TtlDurNp3=0 then TtlDurNp3=".";
		If NumPDS3=0 then NumPDS3=".";
End;

If maxdur<10800 then do;
		If MnDurPDS4=0 then MnDurPDS4=".";
		If TtlDurF4=0 then TtlDurF4=".";
		If NumPrb4=0 then NumPrb4=".";
		If NumF4=0 then NumF4=".";
		if TtlDurNp4=0 then TtlDurNp4=".";
		If NumPDS4=0 then NumPDS4=".";

End;

If maxdur<14400 then do;
		If MnDurPDS5=0 then MnDurPDS5=".";
		If TtlDurF5=0 then TtlDurF5=".";
		If NumPrb5=0 then NumPrb5=".";
		If NumF5=0 then NumF5=".";
		if TtlDurNp5=0 then TtlDurNp5=".";
		If NumPDS5=0 then NumPDS5=".";

End;

If maxdur<18000 then do;
		If MnDurPDS6=0 then MnDurPDS6=".";
		If TtlDurF6=0 then TtlDurF6=".";
		If NumPrb6=0 then NumPrb6=".";
		If NumF6=0 then NumF6=".";
		if TtlDurNp6=0 then TtlDurNp6=".";
		If NumPDS6=0 then NumPDS6=".";

End;

If maxdur<21600 then do;
		If MnDurPDS7=0 then MnDurPDS7=".";
		If TtlDurF7=0 then TtlDurF7=".";
		If NumPrb7=0 then NumPrb7=".";
		If NumF7=0 then NumF7=".";
		if TtlDurNp7=0 then TtlDurNp7=".";
		If NumPDS7=0 then NumPDS7=".";

End;

If maxdur<25200 then do;
		If MnDurPDS8=0 then MnDurPDS8=".";
		If TtlDurF8=0 then TtlDurF8=".";
		If NumPrb8=0 then NumPrb8=".";
		If NumF8=0 then NumF8=".";
		if TtlDurNp8=0 then TtlDurNp8=".";
		If NumPDS8=0 then NumPDS8=".";

End;

If maxdur<28800 then do;
		If MnDurPDS9=0 then MnDurPDS9=".";
		If TtlDurF9=0 then TtlDurF9=".";
		If NumPrb9=0 then NumPrb9=".";
		If NumF9=0 then NumF9=".";
		if TtlDurNp9=0 then TtlDurNp9=".";
		If NumPDS9=0 then NumPDS9=".";

End;

If maxdur<32400 then do;
		If MnDurPDS10=0 then MnDurPDS10=".";
		If TtlDurF10=0 then TtlDurF10=".";
		If NumPrb10=0 then NumPrb10=".";
		If NumF10=0 then NumF10=".";
		if TtlDurNp10=0 then TtlDurNp10=".";
		If NumPDS10=0 then NumPDS10=".";

End;

If maxdur<36000 then do;
		If MnDurPDS11=0 then MnDurPDS11=".";
		If TtlDurF11=0 then TtlDurF11=".";
		If NumPrb11=0 then NumPrb11=".";
		If NumF11=0 then NumF11=".";
		if TtlDurNp11=0 then TtlDurNp11=".";
		If NumPDS11=0 then NumPDS11=".";

End;

If maxdur<39600 then do;
		If MnDurPDS12=0 then MnDurPDS12=".";
		If TtlDurF12=0 then TtlDurF12=".";
		If NumPrb12=0 then NumPrb12=".";
		If NumF12=0 then NumF12=".";
		if TtlDurNp12=0 then TtlDurNp12=".";
		If NumPDS12=0 then NumPDS12=".";

End;

If maxdur<39600 and NumF12=0 then NumF12=".";

* If TmStrtEPGFrstE="." then TmStrtEPGFrstE=maxdur;
* If TmFrmFrstPrbFrstE="." then TmFrmFrstPrbFrstE=maxdur;
if NumE2="." then NumE2=0;
if NumLngE2="." then NumLngE2=0;
if NumLngG="." then NumLngG=0;
* if TmFrstSusE2="." then TmFrstSusE2=maxdur;
* if TmFrstSusE2FrstPrb="." then TmFrstSusE2FrstPrb=maxdur;
* if TmFrstSusGFrstPrb="." then TmFrstSusGFrstPrb=maxdur;
* if TmFrstE2StrtEPG="." then TmFrstE2StrtEPG=maxdur;
* if TmFrstE2FrmFrstPrb="." then TmFrstE2FrmFrstPrb=maxdur;
if TtlDurF=0 then TtlDurF=".";

*********************************************************************
*********************************************************************
***        THIS SECTION CONTAINS A FEW NEW VARIABLES              ***
***          THAT WERE NOT PART OF THE SARRIA WORKBOOK            ***
*********************************************************************
*********************************************************************;

*****************************************************************************
*****************************************************************************
*****************************************************************************
*****************************   NEW VARIABLES   *****************************
*****************************   Not in Sarria   *****************************
*****************************************************************************
*****************************************************************************
*****************************************************************************;
proc delete lib=work data= three;
*********************************************************************;
*********************************************************************
****   New Data set, OnlyPrbs. This converts all recordings into  ***
****      probe versus non-probe.                                 ***
*********************************************************************;
Data OnlyPrbs; set one;
	if waveform='NP' then waveform='NP';
		else waveform='C';
Proc sort data=OnlyPrbs; by line;
Data OnlyPrbs; Set OnlyPrbs;
	retain w0 w1 in0 marker1;
	w1=waveform;
	if insectno ne in0 then do;
	  w0='  '; in0=insectno; marker1=0;
	end;
	if w1 ne w0 then do; 
		marker1=marker1+1;
		w0=w1;
	end;
data OnlyPrbs; set OnlyPrbs;
proc means noprint; by insectno marker1; var dur; output out=onePrbSAS sum=durSum;
Data onePrbSAS; set onePrbSAS; dur=dursum;

data OnlyPrbs; set OnlyPrbs; drop dur line sumstart sumend instance inverter1 w1 w0 in0;
Data OnlyPrbs; Set OnlyPrbs;
	retain w0 w1 in0 time1;
	w1=waveform;
	if insectno ne in0 then do;
	  w0='  '; in0=insectno; time1=0;
	end;
	if time1=0 then do; output; time1=1; end;
	else If w1 ne w0 then output;
	w0=w1;
data onePrbSAS; set onePrbSAS OnlyPrbs; merge onePrbSAS OnlyPrbs; by insectno marker1;
data oneZZ; set onePrbSAS; Var1=insectno; Var2=waveform; Var3=dur;
data oneZZ; set oneZZ; drop insectno marker1 _TYPE_ _Freq_ dursum dur waveform;
Data oneZZ; set oneZZ; waveform=Var2; insectno=Var1; dur=Var3;
data oneZZ; set oneZZ; drop Var1 var2 var3;
Data OnlyPrbs; set oneZZ; line=_n_;
Data OnlyPrbs; Set OnlyPrbs; drop in0 w1 w0;
Data OnlyPrbs; Set OnlyPrbs;
      retain in0 SumStart SumEnd dur0;
      if insectno ne in0 then do;
       SumStart=0.0; SumEnd=0.0; dur0=0.0;
       in0=insectno;
      end;
      SumEnd=sum(SumEnd, dur);
      SumStart=sum(SumStart, Dur0);
      dur0=dur;
proc sort; by insectno waveform line;
data OnlyPrbs; set OnlyPrbs; drop in0 dur0;
data OnlyPrbs;set OnlyPrbs; by insectno waveform;
	retain instance;
	if first.waveform then instance=0;
	instance=instance+1;
Proc sort data=OnlyPrbs; by line;
data OnlyPrbs; set OnlyPrbs; inverter1=50000-line;
data OnlyPrbs; set OnlyPrbs; drop time1;
proc delete lib=work data= oneZZ onePrbSAS;
run;
*********************************************************************
**************************   Method end   ***************************
*********************************************************************;

******************************************************************
/******************   Start New Method    ************************
*  Number of probes to first G.
*****************************************************************/;

Data three; set OnlyG;
Proc sort data=three; by insectno line;
Data three; set three;
	retain in0 marker1 marker2;
	w1=waveform;
	if insectno ne in0 then do;
	 marker1=0; Marker2=0;
	 in0=insectno;
	end;
	If w1='C' then marker1=1;
	If w1='Z' or w1='NP' then marker1=0;
	if w1='G' then marker2=1;
	run;
Data three; set three; Where marker2=0;
data three; set three; drop marker2 in0;
Data three; set three;
	retain in0 marker3 marker4;
	if insectno ne in0 then do;
	marker3=0; marker4=0; in0=insectno;
	end;
	if marker1=1 and marker3=0 then marker4=marker4+1;
	marker3=marker1;
Data three; set three; drop in0 marker1 marker3;
Proc sort data=three; by insectno inverter1;
data three; set three;
	retain marker1 in0;
	if insectno ne in0 then do;
	marker1=0; in0=insectno;
	end;
	else marker1=1;
Data three; set three; Where marker1=0;
Data three; set three; CtoFrstG=marker4;
*milan: check;
Data three; Set three; drop waveform dur line sumstart sumend instance inverter1 w1 in0 marker4 marker1 dur0;
data Ebert; set Ebert three; merge Ebert three; by insectno;
run;
******************************************************************
*  Finding number of probes to first G is finished.
* XXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXXXXXXXX*
******************************************************************;


******************************************************************
*****************   Start New Method    **************************
**	Duration of nonprobe period before the first G
******************************************************************;
Data three; set OnlyG; 
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if waveform eq 'G' then marker1=1;
Data three; set three; Where marker1=0;
data three; set three; drop in0 marker1;
Proc sort data=three; by insectno inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if waveform eq 'Z' or waveform eq 'NP' then marker1=1;
Data three; set three; Where marker1=1;
Data three; set three; Where waveform eq 'Z' or waveform eq 'NP';
Data three; set three; drop in0 marker1;
proc sort data=three; by insectno line;
data three; set three; 
	retain DurNnprbBfrFrstG in0;
	if in0 ne insectno then do; in0=insectno; DurNnprbBfrFrstG=0; end;
	DurNnprbBfrFrstG=sum(DurNnprbBfrFrstG, dur);
Data three; set three; drop in0;
proc sort data=three; by insectno inverter1;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=1;
	end;
	else marker1=0;
Data three; set three; Where marker1=1;
*Milan:check;
Data three; set three; drop waveform dur line sumstart sumend instance inverter1 in0 marker1 dur0;
data Ebert; set Ebert three; merge Ebert three; by insectno;
******************************************************************
*  Finding Duration of nonprobe period before the first G is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX*
******************************************************************


******************************************************************
******************************************************************
/*********************************   Start New Method    ******************************
**	Average number of G per probe
******************************************************************;
Data three; set OnlyG; 								*mark each probe.;
	retain in0 marker1;
	w1=waveform;
	if insectno ne in0 then do;
		in0=insectno; marker1=0;
	end;
	if w1='C' then marker1=1;
	if w1='Z' or w1='NP' then marker1=0;
Data three; set three; drop in0;
Data three; set three; 									*counting the number of probes;
	retain in0 holder1 marker2;
	if insectno ne in0 then do;
		in0=insectno; marker2=0; holder1=0;
	end;
	if holder1 ne marker1  and waveform='C' then do;
		marker2=marker2+1;
	end;
	holder1=marker1;
Data three; set three; drop in0 holder1;
Data three; set three;								*counting G in each probe;
	retain in0 holder1 marker3 marker4;
	if insectno ne in0 then do;
		in0=insectno; marker3=0; holder1=0; marker4=0;
	end;
	if marker1=1 and holder1=0 then marker3=1;
	if marker1=0 and holder1=1 then marker3=0;
	if marker3=1 and waveform='G' then marker4=marker4+1;
	if marker3=0 then marker4=0;
	holder1=marker1;
Data three; set three; drop in0 holder1 marker3;
Proc sort data=three; by insectno inverter1;  *Isolate the last entry in each probe;
Data three; set three;
	retain in0 holder1 marker5;
	if insectno ne in0 then do;
		in0=insectno; holder1=0; marker5=0;
	end;
	if holder1=0 and marker1=1 then marker5=1;
	else marker5=0;
	holder1=marker1;
data three; set three; drop in0 holder1;
data three; set three; Where marker5=1;
proc sort data=three; by insectno line;
data three; set three; proc means noprint; var marker4; by insectno; output out=outsas mean=meanNGPrb;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc delete lib=work data= outsas three;
******************************************************************
*  Finding Average number of G per probe is finished.
* XXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXXXXXXX*
******************************************************************
******************************************************************
/***************   Start New Method    ***************************
**	Time from first probe to 1st G
******************************************************************;
Data three; set onlyG;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='G' then  marker1=1;
data three; set three; Where marker1=0;
data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='C' then marker1=1;
Data three; set three; Where marker1=1;
Data three; set three; drop in0 marker1;
data three; set three;
	retain in0 TmFrmFrstPrbFrstG;
	if in0 ne insectno then do;
		in0=insectno; TmFrmFrstPrbFrstG=0;
	end;
	TmFrmFrstPrbFrstG = sum(TmFrmFrstPrbFrstG, dur);
data three; set three; drop in0;
proc sort data=three; by insectno inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	else marker1=1;
proc sort data=three; by line;
data three; set three; Where marker1=0;
data three; set three; drop waveform dur line sumstart sumend instance inverter1 in0 marker1 dur0;
data Ebert; set Ebert three; merge Ebert three; by insectno;
******************************************************************
*  Finding Time from 1st probe to 1st G is finished.
* XXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXXXXXXXX*
******************************************************************

******************************************************************
/*************   Start New Method    *****************************
**	Time from start of probe with first G to 1st G
******************************************************************;
Data three; set onlyG;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='G' then  marker1=1;
data three; set three; Where marker1=0;
data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='C' then marker1=1;
Data three; set three; Where marker1=1;
Data three; set three; drop in0 marker1;
proc sort data=three; by insectno inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='Z' or waveform='NP' then marker1=1;
proc sort data=three; by line;
data three; set three; Where marker1=0;
Data three; set three; drop in0 marker1;
data three; set three;
	retain in0 TmBegPrbFrstG;
	if in0 ne insectno then do;
		in0=insectno; TmBegPrbFrstG=0;
	end;
	TmBegPrbFrstG=sum(TmBegPrbFrstG,dur);
data three; set three; drop in0;
proc sort data=three; by insectno inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	else marker1=1;
data three; set three; Where marker1=0;
data three; set three; drop waveform dur line sumstart sumend instance inverter1 in0 marker1 dur0;
data Ebert; set Ebert three; merge Ebert three; by insectno;

******************************************************************
*  Finding Time from start of probe with first G to 1st G is finished.
* XXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX*
******************************************************************

******************************************************************
/***************   Start New Method    ***************************
**	Number of Probes after first G
******************************************************************;
Data three; set OnlyG;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='G' then marker1=1;
data three; set three; Where marker1=1;
data three; set three; drop in0 marker1;

data three; set three;
	retain in0 marker2 delay1;
	if in0 ne insectno then do;
		in0=insectno; marker2=0; delay1=1;
	end;
	if delay1=0 then do;
		if waveform='Z' then marker2=marker2+1;
		if waveform='NP' then marker2=marker2+1;
		 
	end;
	delay1=0;
data three; set three; Where waveform='C';
Data three; set three; proc means noprint;
	by insectno; var marker2; output out=outsas max=NumPrbsAftrFrstG;
data outsas; set outsas; if NumPrbsAftrFrstG='.' then NumPrbsAftrFrstG=0;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
Data Ebert; set Ebert; if NumPrbsAftrFrstG='.' then NumPrbsAftrFrstG=0;
proc delete lib=work data= three outsas;
run;
******************************************************************
*  Finding Number of probes after first G is finished.
* XXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXXXXXXX*
******************************************************************

******************************************************************
/******************   Start New Method    ************************
**	Number of Probes<3min after first G
******************************************************************;
Data three; set OnlyG;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='G' then marker1=1;
data three; set three; Where marker1=1;
data three; set three; drop in0 marker1;

Data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if waveform='NP' or waveform="Z" then marker1=1;
data three; set three; Where marker1=1;
data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker2 delay1;
	if in0 ne insectno then do;
		in0=insectno; marker2=1; delay1=1;
	end;
	if delay1=0 then do;
		if waveform='Z' then marker2=marker2+1;
		if waveform='NP' then marker2=marker2+1;
		 
	end;
	delay1=0;
Data three; set three; if waveform ne "Z" and waveform ne "NP" then waveform="PRB";
data three; set three; 
  proc sort; by insectno marker2 waveform;
  proc means noprint; by insectno marker2 waveform; var dur; output out=outsas2 sum=sdur;
data outsas2; set outsas2; Where waveform="PRB" and sdur<180;
data outsas2; set outsas2;
	retain in0 marker1;
	if in0 ne insectno then do;	in0=insectno; marker1=0; end;
	marker1=marker1+1;
Data outsas2; set outsas2;
  proc means noprint; by insectno; var marker1; output out=outsas4 max=NmbrShrtPrbAftrFrstG;

data outsas4; set outsas4; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas4; merge Ebert outsas4; by insectno;
Data Ebert; set Ebert; if NmbrShrtPrbAftrFrstG='.' then NmbrShrtPrbAftrFrstG=0;
proc delete lib=work data= three outsas4 outsas2;
run;
******************************************************************
*  Finding Number of probes <3min after first G is finished.
* XXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXXXXXXXXX*
******************************************************************


*******************************************************************
*******************************************************************
*******************************************************************
****                                                           ****
**** It is possible that treatments could change the variance  ****
****     while having little or no influence on the means.     ****
**** ALSO note that the assumption for many models is          **** 
****     equality of variances: Homoscedasticity versus        ****
****     Heteroscedasticity. If the following variables have   ****
****     significant treatment effects then the data are       ****
****     heteroscedastic.                                      ****
****                                                           ****
**** Note: a non-significant outcome is not sufficient to      ****
****     demonstrate homoscedasticity.                         ****
****                                                           ****
**** I have added five variables to look at variance.          ****
****   sdC = standard deviation of the mean duration of C      ****
****             for each insect.                              ****
****   sdD = standard deviation of the mean duration of D      ****
****             for each insect.                              ****
****   sdG = standard deviation of the mean duration of G      ****
****             for each insect.                              ****
****   sdE1 = standard deviation of the mean duration of E1    ****
****             for each insect.                              ****
****   sdE2 = standard deviation of the mean duration of E2    ****
****             for each insect.                              ****
*******************************************************************
*******************************************************************
*******************************************************************

*********************************************************************
****                            Start New Method    *****************
****       Mean Deviation of C
*********************************************************************;
Data three; set One;
data three; set three; Where waveform='C';
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas stddev=sdC;
data three; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc delete lib=work data= oned outsas three;
*********************************************************************
*  Finding Mean deviation of C is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
****                            Start New Method    *****************
****       Mean Deviation of F
*********************************************************************;
Data three; set OnlyF;
data three; set three; Where waveform='F';
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas stddev=sdF;
data three; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc delete lib=work data= oned outsas three;
*********************************************************************
*  Finding Mean deviation of D is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
****                            Start New Method    *****************
****       Mean Deviation of G
*********************************************************************;
Data three; set OnlyG;
data three; set three; Where waveform='G';
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas stddev=sdG;
data three; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc delete lib=work data= oned outsas three;
*********************************************************************
*  Finding Mean deviation of G is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
****                            Start New Method    *****************
****       Mean Deviation of E1
*********************************************************************;
Data three; set OnlyE1;
data three; set three; Where waveform='E1';
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas stddev=sdE1;
data three; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc delete lib=work data= oned outsas three;
*********************************************************************
*  Finding Mean deviation of E1 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
****                            Start New Method    *****************
****       Mean Deviation of E2
*********************************************************************;
Data three; set OnlyE2;
data three; set three; Where waveform='E2';
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas stddev=sdE2;
data three; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc delete lib=work data= oned outsas three;
*********************************************************************
*  Finding Mean deviation of E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
****                            Start New Method    *****************
****       Mean Deviation of NP
*********************************************************************;
Data three; set One;
data three; set three; Where waveform='NP';
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas stddev=sdNP;
data three; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc delete lib=work data= oned outsas three;
*********************************************************************
*  Finding Mean deviation of NP is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
****                            Start New Method    *****************
****       Mean Deviation of Probes
*********************************************************************;
Data OnlyPrbsC; set OnlyPrbs;
Where waveform="C";
proc sort; by  insectno waveform;
proc means noprint; by  insectno; var dur; output out=Prbsout mean=MnPrbs stddev=sdPrbs median=MdnPrbs;

data three; set Prbsout; drop _TYPE_ _FREQ_;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc delete lib=work data= three OnlyPrbsC Prbsout;
*********************************************************************
*  Finding Mean deviation of Probes is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************************************************
*******                                                         *****
*******    Consider this section if treatments are fatal        *****
*******                                                         *****
*********************************************************************
*********************************************************************;
/*
data Ebert; set Ebert; 
	if NumF='.' then NumF="0";
	if NumE1=0 and NumPrbsAftrFrstE=0 then NumPrbsAftrFrstE=".";
	if NumE1=0 and NmbrShrtPrbAftrFrstE=0 then NmbrShrtPrbAftrFrstE=".";
	if numE2="." then NumE2="0";
	if NumE2=0 and NumLngE1bfrE2=0 then NumLngE1bfrE2=".";
	if numlngE2="." then numlngE2="0";
	If NmbrC="." then NmbrC="0";
	If NmbrShrtC="." then NmbrShrtC="0";

	if TtlDurF= "." then TtlDurF="0";
	If MeanPD= "." then MeanPD="0";
	if MeanPDL= "." then MeanPDL="0";
	if MeanPDS= "." then MeanPDS="0";
	if meanNPdPrb= "." then meanNPdPrb="0";
	if MeanF= "." then MeanF="0";
	If DurG="." then DurG="0";
	if MeanG="." then MeanG="0";
	if TtlDurE="." then TtlDurE="0";
	if TtlDurE1="." then TtlDurE1="0";
	if TtlDurSnglE1="." then TtlDurSnglE1="0";
	If TtlDurE2 ="." then TtlDurE2="0";
	If MnDurE1 ="." then MnDurE1="0";
	If MnDurE2 ="." then MnDurE2="0";
	If TtlDurC="." then TtlDurC="0";
	If TtlDurE1e="." then TtlDurE1e="0";
	If TtlDurNP="." then TtlDurNP="0";
	If TtlDurPd ="." then TtlDurPd="0";
	If TtlDurPDL ="." then TtlDurPDL="0";
	If TtlDurPDS ="." then TtlDurPDS="0";
	If MnDurC="." then MnDurC="0";
	If MnDurNP="." then MnDurNP="0";
	If TtlDurNP1="." then TtlDurNP1="0";
	If TtlDurNP2="." then TtlDurNP2="0";
	If TtlDurNP3="." then TtlDurNP3="0";
	If TtlDurNP4="." then TtlDurNP4="0";
	If TtlDurNP5="." then TtlDurNP5="0";
	If TtlDurNP6="." then TtlDurNP6="0";
	If MnDurPdS1="." then MnDurPdS1="0";
	If MnDurPdS2="." then MnDurPdS2="0";
	If MnDurPdS3="." then MnDurPdS3="0";
	If MnDurPdS4="." then MnDurPdS4="0";
	If MnDurPdS5="." then MnDurPdS5="0";
	If MnDurPdS6="." then MnDurPdS6="0";
	If TtlDurF1="." then TtlDurF1="0";
	If TtlDurF2="." then TtlDurF2="0";
	If TtlDurF3="." then TtlDurF3="0";
	If TtlDurF4="." then TtlDurF4="0";
	If TtlDurF5="." then TtlDurF5="0";
	If TtlDurF6="." then TtlDurF6="0";

*/;

Data Ebert; Set Ebert; *make labels for the Ebert table;
LABEL
TmFrstPrbFrmStrt = "Time from beginning of EPG to first probe"
CtoFrstE1 = "Number of probes to first E1"
NumF = "Number of F waveforms"
DurFrstPrb = "Duration of First Probe"
DurScndPrb = "Duration of Second Probe"
ShrtCbfrE1 = "Duration of shortest C before first E1 in any probe"
DurScndZ = "Duration of second non-probe event (z or np)"
TtlDurF = "Total duration of F"
DurNnprbBfrFrstE1 = "Duration of nonprobe period before first E1"
meanpd = "Mean duration of pd"
meanPDL = "Mean duration of pdL"
meanPDS = "Mean duration of pdS"
meanNPdPrb = "Mean number of pd per probe"
meanF = "Mean duration of F"
TmStrtEPGFrstE = "Time from start of EPG to 1st E"
TmFrmFrstPrbFrstE = "Time from first probe to 1st E"
TmBegPrbFrstE = "Time from start of probe with first E to 1st E"
NumG = "Number of G"
DurG = "Total Time spent in G waveform"
MeanG = "Mean duration of G"
NumLngG = "Number of sustained G "
TmFrstSusGFrstPrb = "Time to first sustained G from start of first probe"
NumPrbsAftrFrstE = "Number of Probes after first E1"
NmbrShrtPrbAftrFrstE = "Number of Probes<3min after first E1"
NumE1 = "Number of E1"
NumLngE1BfrE2 = "Number of E1 (longer than 10 min) followed by E2"
NumSnglE1 = "Number of single E1"
NumE2 = "Number of E2"
NumLngE2 = "Number of sustained E2"
DurFirstE = "Duration of first E (E1 + E2)"
CntrbE1toE = "Contribution of E1 to phloem phase"
DurE1FlwdFrstSusE2 = "Duration of E1 followed by first sustained E2 (Long E2)"
DurE1FlldFrstE2 = "Duration of E1 followed by first sustained E2"
PotE2Indx = "Potential E2 Index (E2/(time from start of first E2 to end of recording))"
TtlDurE = "Total duration of E"
TtlDurE1 = "Total duration of E1"
TtlDurE1FlldSusE2 = "Total Duration of E1 followed by a sustained E2"
TtlDurE1FlldE2 = "Total duration of E1 followed by E2"
TtlDurSnglE1 = "Total duration of single E1"
TtlDurE1FllwdE2PlsE2 = "Total duration of E1 followed by E2 plus E2"
TtlDurE2 = "Total Duration of E2"
MnDurE1 = "Mean Duration of E1"
MnDurE2 = "Mean duration of E2"
NumPrbs = "Number of probes"
NmbrC = "Number of C"
NmbrShrtC = "Number of short C events"
NumNP = "Number of NP"
NmbrPD = "Number of pd"
NmbrPDL = "Number of pdL"
NmbrPDS = "Number of pdS"
NmbrE1e = "Number of E1e"
TtlDurC = "Total duration of C"
TtlDurE1e = "Total duration of E1e"
TotDurNnPhlPhs = "Total duration of non-phloematic phase (recording duration minus total duration E1 and E2)"
TtlDurNP = "Total duration of NP"
TtlDurPD = "Total duration of PD"
TtlDurPDL = "Total duration of PDL"
TtlDurPDS = "Total duration of PDS"
TtlPrbTm = "Total probing time"
MnDurNP = "Mean duration of NP"
MnDurC = "Mean duration of C"
TmFrstSusE2 = "Time to first sustained E2 from start of recording"
TmFrstSusE2FrstPrb = "Time to first sustained E2 from start of first probe"
TmFrstSusE2StrtPrb = "Time to first sustained E2 from start of that probe"
TmFrstE2StrtEPG = "Time to first E2 from start of EPG"
TmFrstE2FrmFrstPrb = "Time to first E2 from start of first probe"
TmFrstE2FrmPrbStrt = "Time to first E2 from start of that probe"
TtlDurNp1 = "Duration of NP in hour 1"
TtlDurNp2 = "Duration of NP in hour 2"
TtlDurNp3 = "Duration of NP in hour 3"
TtlDurNp4 = "Duration of NP in hour 4"
TtlDurNp5 = "Duration of NP in hour 5"
TtlDurNp6 = "Duration of NP in hour 6"
TtlDurNp7 = "Duration of NP in hour 7"
TtlDurNp8 = "Duration of NP in hour 8"
TtlDurNp9 = "Duration of NP in hour 9"
TtlDurNp10 = "Duration of NP in hour 10"
TtlDurNp11 = "Duration of NP in hour 11"
TtlDurNp12 = "Duration of NP in hour 12"
NumPDS1 = "Number of PDS in hour 1"
NumPDS2 = "Number of PDS in hour 2"
NumPDS3 = "Number of PDS in hour 3"
NumPDS4 = "Number of PDS in hour 4"
NumPDS5 = "Number of PDS in hour 5"
NumPDS6 = "Number of PDS in hour 6"
NumPDS7 = "Number of PDS in hour 7"
NumPDS8 = "Number of PDS in hour 8"
NumPDS9 = "Number of PDS in hour 9"
NumPDS10 = "Number of PDS in hour 10"
NumPDS11 = "Number of PDS in hour 11"
NumPDS12 = "Number of PDS in hour 12"
MnDurPdS1 = "Mean Duration of PDS in hour 1"
MnDurPdS2 = "Mean Duration of PDS in hour 2"
MnDurPdS3 = "Mean Duration of PDS in hour 3"
MnDurPdS4 = "Mean Duration of PDS in hour 4"
MnDurPdS5 = "Mean Duration of PDS in hour 5"
MnDurPdS6 = "Mean Duration of PDS in hour 6"
MnDurPdS7 = "Mean Duration of PDS in hour 7"
MnDurPdS8 = "Mean Duration of PDS in hour 8"
MnDurPdS9 = "Mean Duration of PDS in hour 9"
MnDurPdS10 = "Mean Duration of PDS in hour 10"
MnDurPdS11 = "Mean Duration of PDS in hour 11"
MnDurPdS12 = "Mean Duration of PDS in hour 12"
NumF1 = "Number of F in hour 1"
NumF2 = "Number of F in hour 2"
NumF3 = "Number of F in hour 3"
NumF4 = "Number of F in hour 4"
NumF5 = "Number of F in hour 5"
NumF6 = "Number of F in hour 6"
NumF7 = "Number of F in hour 7"
NumF8 = "Number of F in hour 8"
NumF9 = "Number of F in hour 9"
NumF10 = "Number of F in hour 10"
NumF11 = "Number of F in hour 11"
NumF12 = "Number of F in hour 12"
TtlDurF1 = "Duration of F in hour 1"
TtlDurF2 = "Duration of F in hour 2"
TtlDurF3 = "Duration of F in hour 3"
TtlDurF4 = "Duration of F in hour 4"
TtlDurF5 = "Duration of F in hour 5"
TtlDurF6 = "Duration of F in hour 6"
TtlDurF7 = "Duration of F in hour 7"
TtlDurF8 = "Duration of F in hour 8"
TtlDurF9 = "Duration of F in hour 9"
TtlDurF10 = "Duration of F in hour 10"
TtlDurF11 = "Duration of F in hour 11"
TtlDurF12 = "Duration of F in hour 12"
NumPrb1 = "Number of probes in hour 1"
NumPrb2 = "Number of probes in hour 2"
NumPrb3 = "Number of probes in hour 3"
NumPrb4 = "Number of probes in hour 4"
NumPrb5 = "Number of probes in hour 5"
NumPrb6 = "Number of probes in hour 6"
NumPrb7 = "Number of probes in hour 7"
NumPrb8 = "Number of probes in hour 8"
NumPrb9 = "Number of probes in hour 9"
NumPrb10 = "Number of probes in hour 10"
NumPrb11 = "Number of probes in hour 11"
NumPrb12 = "Number of probes in hour 12"
TmFrstCFrstPD = "Time to first pd from beginning of first probe"
TmEndLstPDEndPrb = "Time from end of last pd in probe to end of first probe"
SumPDII1 = "Duration of PD subphase I"
SumPDII2 = "Duration of PD subphase II"
SumPDII3 = "Duration of PD subphase III"
TmEndPDBegE1FllwdSusE2 = "Time from end of last pd to beginning of E1 followed by sustained E2"
TmLstPdEndRcrd = "Time from end of last pd to end of EPG record"
TmLstE1EndRcrd = "Time from Last E1 to end of EPG record"
TmLstE2EndRcrd = "Time from Last E2 to end of EPG record"
maxE2 = "Duration of longest E2"
DurNpFllwFrstSusE2 = "Duration of NP following first sustained E2"
PrcntPrbC = "Percent probing spent in C"
PrcntPrbE1 = "Percent probing spent in E1"
PrcntPrbE2 = "Percent probing spent in E2"
PrcntPrbF = "Percent probing spent in F"
PrcntPrbG = "Percent probing spent in G"
PrcntE2SusE2 = "Percent E2 spent in Sustained E2"
CtoFrstG = "Number of probes to first G"
DurNnprbBfrFrstG = "Duration of nonprobe period before first G"
meanNGPrb = "Mean number of G per probe"
TmFrmFrstPrbFrstG = "Time from first probe to 1st G"
TmBegPrbFrstG = "Time from start of probe with first G to 1st G"
NumPrbsAftrFrstG = "Number of Probes after first G"
NmbrShrtPrbAftrFrstG = "Number of Probes<3min after first G"
sdC = "Standard Deviation of duration of C"
sdF = "Standard Deviation of duration of F"
sdG = "Standard Deviation of duration of G"
sdE1 = "Standard Deviation of duration of E1"
sdE2 = "Standard Deviation of duration of E2"
sdNP = "Standard Deviation of duration of NP"
MnPrbs = "Mean duration of probes"
sdPrbs = "Standard Deviation of duration of Probes"
MdnPrbs = "Median duration of probes";
Run;

********************************************************
********************************************************
********************************************************
********************************************************
********************************************************
********************************************************
********                                    ************
********                                    ************
********                                    ************
********            DATA ANALYSES           ************
********                                    ************
********                                    ************
********************************************************
********************************************************
********************************************************
********************************************************
********************************************************;
************************************************************************************************
**       NOTE THIS PROGRAM IS REORGANIZED LIST BASED ON EBERT 1.0.SAS.                        **
**              It is based on the SAS mimic of the Sarria workbook, but                      **
**              the order of the variables has been changed. A few additional                 **
**              variables were added at the probe level. Also added were variables            **
**              using standard deviations and medians as used by Freddy Tjallingii's group.   **
**                                                                                            **
************************************************************************************************;
/*
*Milan: TODO: Check if all calculated variables are listed here:;
Data Ebert; Set Ebert; 
    Proc means data=ebert; 
     by trt;
     var  NumPrbs MnPrbs sdPrbs MdnPrbs DurFrstPrb DurScndPrb TtlPrbTm NumPrb1 NumPrb2 NumPrb3 NumPrb4 NumPrb5 NumPrb6 NumPrb7 NumPrb8 NumPrb9 NumPrb10 NumPrb11 NumPrb12;
     title "Untransformed Means for Probe variables";
	     Proc means data=ebert; 
     by trt;
     var NumNP TtlDurNP MnDurNP sdNP TmFrstPrbFrmStrt DurScndZ DurNnprbBfrFrstE1 DurNpFllwFrstSusE2 TtlDurNp1 TtlDurNp2 TtlDurNp3 TtlDurNp4 TtlDurNp5 TtlDurNp6 TtlDurNp7 TtlDurNp8 TtlDurNp9 TtlDurNp10 TtlDurNp11 TtlDurNp12;
     title "Untransformed Means for NP variables";
    Proc means data=ebert; 
     by trt;
     var NmbrC TtlDurC MnDurC sdC NmbrShrtC ShrtCbfrE1 PrcntPrbC;
     title "Untransformed Means for C variables";
    Proc means data=ebert; 
     by trt;
     var NumG NumLngG DurG MeanG sdG TmFrstSusGFrstPrb CtoFrstG DurNnprbBfrFrstG meanNGPrb TmFrmFrstPrbFrstG TmBegPrbFrstG NumPrbsAftrFrstG
 NmbrShrtPrbAftrFrstG PrcntPrbG;
     title "Untransformed Means for G variables";
    Proc means data=ebert; 
     by trt;
     var NumF TtlDurF meanF TtlDurF1 TtlDurF2 TtlDurF3 TtlDurF4 TtlDurF5 TtlDurF6 TtlDurF7 TtlDurF8 TtlDurF9 TtlDurF10 TtlDurF11 TtlDurF12 NumF1 NumF2 NumF3 NumF4 NumF5 NumF6 NumF7 NumF8 NumF9 NumF10 NumF11 NumF12 PrcntPrbF;
     title "Untransformed Means for F variables";
    Proc means data=ebert; 
     by trt;
     var meanpd meanPDS meanNPdPrb NmbrPD NmbrPDS TtlDurPD TtlDurPDS NumPDS1 NumPDS2
 NumPDS3 NumPDS4 NumPDS5 NumPDS6 NumPDS7 NumPDS8 NumPDS9 NumPDS10 NumPDS11 NumPDS12 MnDurPdS1 MnDurPdS2 MnDurPdS3 MnDurPdS4 MnDurPdS5 MnDurPdS6 MnDurPdS7 MnDurPdS8 MnDurPdS9 MnDurPdS10 MnDurPdS11 MnDurPdS12 TmFrstCFrstPD 
 TmEndLstPDEndPrb;
 * Milan removed: meanPDL NmbrPDL TtlDurPDL;
     title "Untransformed Means for pd variables";
    Proc means data=ebert; 
     by trt;
     var NumE1 TtlDurE1 MnDurE1 sdE1 CtoFrstE1 TmStrtEPGFrstE TmFrmFrstPrbFrstE TmBegPrbFrstE NumPrbsAftrFrstE
           NmbrShrtPrbAftrFrstE NumLngE1BfrE2 NumSnglE1 DurFirstE CntrbE1toE DurE1FlwdFrstSusE2 DurE1FlldFrstE2 
           TtlDurE1FlldSusE2 TtlDurE1FlldE2 TtlDurSnglE1 PrcntPrbE1;
     title "Untransformed Means for E1 variables";
    Proc means data=ebert; 
     by trt;
     var NumE2 NumLngE2 TtlDurE2 MnDurE2 sdE2 TmFrstSusE2FrstPrb TmFrstSusE2StrtPrb TmFrstE2StrtEPG TmFrstE2FrmFrstPrb
            TmFrstE2FrmPrbStrt TmLstE1EndRcrd TmLstE2EndRcrd maxE2 PrcntPrbE2 PrcntE2SusE2;
     title 'Untransformed Means for E2 variables';
    Proc means data=ebert; 
     by trt;
     var PotE2Indx TtlDurE TtlDurE1FllwdE2PlsE2 TotDurNnPhlPhs TmFrstSusE2;
     title "Untransformed Means for E1+E2 variables";
run;
*/;

*Procedure for removing missing and all 0 variables;
*This is very hepful for transformation and PROC GLIMMIX later on.;
*Adapted from: https://support.sas.com/kb/24/622.html;

/* Create two macro variables, NUM_QTY and CHAR_QTY, to hold */
/* the number of numeric and character variables, respectively. */
/* These will be used to define the number of elements in the arrays */
/* in the next DATA step. */
options symbolgen; *useful for debugging macros, it prints how macro variables resolve.;
data _null_;
   set Ebert (obs=1);
   array num_vars[*] _NUMERIC_;
   array char_vars[*] _CHARACTER_;
   call symputx('num_qty', dim(num_vars));
   call symputx('char_qty', dim(char_vars));
run;

data _null_;
   set Ebert end=finished;

   /* Use the reserved word _NUMERIC_ to load all numeric variables  */
   /* into the NUM_VARS array.  Use the reserved word _CHARACTER_ to */ 
   /* to load all character variables into the CHAR_VARS array.      */
   array num_vars[*] _NUMERIC_;
   array char_vars[*] _CHARACTER_;

   /* Create 'flag' arrays for the variables in NUM_VARS and CHAR_VARS. */
   /* Initialize their values to 'missing'.  Values initialized in an   */
   /* ARRAY statement are retained.                                     */
   array num_miss [&num_qty] $ (&num_qty * 'missing');
   array char_miss [&char_qty] $ (&char_qty * 'missing'); 
  
   /* LIST will contain the list of variables to be dropped. */
   /* Ensure that its length is sufficient. */
   length list $ 250; 
  
   /* Check for non-missing and 0 values.  Reassign the corresponding 'flag' */
   /* value accordingly.                                               */
   do i=1 to dim(num_vars);
      if num_vars(i) ne . and num_vars(i) ne 0 then num_miss(i)='non-miss';
   end;
   do i=1 to dim(char_vars);
      if char_vars(i) ne '' and char_vars(i) ne '0' then char_miss(i)='non-miss';
   end;

   /* On the last observation of the data set, if a 'flag' value is still */
   /* 'missing', the variable needs to be dropped.  Concatenate the       */
   /* variable's name onto LIST to build the values of a DROP statement   */
   /* to be executed in another step.                                     */
   if finished then do;
      do i= 1 to dim(num_vars);
         if num_miss(i) = 'missing' then list=trim(list)||' '||trim(vname(num_vars(i)));
      end;
      do i= 1 to dim(char_vars);
         if char_miss(i) = 'missing' then list=trim(list)||' '||trim(vname(char_vars(i)));
      end;
      call symput('mlist',list);
   end;
run;

*Use the macro variable MLIST in the DROP statement to drop missing and all 0 variables.;
data Ebert;
   set Ebert;
   drop &mlist;
run;
*removing missing and all 0 variables finished!;

*Transpose Ebert to Long format and sort so PROC TRANSREG BY statement can be used;
Proc sort data=work.Ebert out=EbertLong (drop= maxdur); by insectno;
run;
proc transpose data=EbertLong out=EbertLong NAME = Parameter LABEL = ParameterLabel ;
  by insectno trt transform;
run;
proc sort data=EbertLong out=EbertLong(rename=(COL1=observations)); label Parameter='Parameter'; by Parameter;
run;

*Calculate min max mean median;
ods exclude all;
ods graphics on;
ods output summary=ParamMeans; *NOTE: is there better way to get median in a table like we normally get means? ods out= did not work;
Proc means data=ebertlong mean median min max; by Parameter;
Run;
Data ParamMeans (keep=Parameter observations_Median observations_Mean observations_Max observations_Min rename=( observations_Median=median observations_Mean=mean observations_Max=max observations_Min=min));
set ParamMeans; 
run;

*********************;
*Merge Proc Means and EbertLong;
proc sort data=EbertLong; by Parameter;
proc sort data=ParamMeans; by Parameter;
Data EbertLong;
 MERGE EbertLong(IN=In1) ParamMeans;
 BY Parameter;
 IF In1=1 then output EbertLong;
 drop _LABEL_ N STD;
run;
proc delete lib=work data= ParamMeans;

*********************;
*invert if median>mean;
Data EbertLong; set EbertLong;
 if Observations = "." then Observations = observations;
 else if median>mean then Observations = MAX-observations;
 else Observations = observations;
run;
 
*THIS SORT IS CRITICAL, especially by observations!;
proc sort data=ebertlong; by parameter observations; run;
*Following two lines control BoxCox transformation output;
ods exclude none;
ods graphics on;
*Transform all variables using BoxCox transformation;
ods output Details=Details;
proc transreg detail nozeroconstant data=EbertLong nomiss; by Parameter; id insectno trt;
model boxcox(observations/ LAMBDA= -3 TO 3 BY 0.20 PARAMETER=1)=identity(transform); output out=BoxCoxTransLong;
Proc delete lib=work data=EbertLong Details;

*Extract Lambda used for transformation;
Data Lambda(keep=Parameter FormattedValue rename=(FormattedValue=Lambda)); 
   Set Details; 
   Where Description = 'Lambda Used';
   Run;

*********************************************************************
*** Custom transformation for selected variables can be set here  ***
*** Useful if data requires transofrmation that is not a power    ***
*** transformation (e.g. Arsin, LOGIT, etc.). If no custom        ***
*** transformations are desired, this data step is commented out  ***
*********************************************************************;
Data BoxCoxTransLong; Set BoxCoxTransLong;
 if parameter = "PrcntPrbE1" then TObservations = arsin(observations); *example of Arsin;
 run;


*Sort as required for PROC GLIMMIX BY statement, cleanup along the way;
proc sort data=BoxCoxTransLong out=BoxCoxTransLong(where=(Untransformed is NOT MISSING) keep=Parameter trt insectno observations tobservations rename=(observations=untransformed tobservations=transformed)); label Parameter='Parameter'; by Parameter;
run;

*ANOVA with Tukey test procedure!;
ods exclude none;
ods graphics on / byline=title;  *byline ensures that Residual plot has a subtitle with variable name;

*Supress "unwanted" tables from the output;
ods exclude ModelInfo (PERSIST) ClassLevels (PERSIST) Dimensions (PERSIST) OptInfo (PERSIST) IterHistory (PERSIST) ConvergenceStatus (PERSIST) Tests3 (PERSIST);
ods output DIFFS=ANOVA; *save Diffs(Anova results); 
ods output LSMLines=Groups; *Save LSMLines (Tukey test groups);
Proc glimmix data=BoxCoxTransLong plots=residualpanel; by Parameter; class trt; model transformed=trt; random _residual_/group=trt; lsmeans trt/pdiff lines adjust=tukey alpha=0.05; title "ANOVA and Tukey test"; run;
ods output close;

*Cleanup;
proc delete lib=work data= BoxCoxTransLong; run;

*Save tukey grouping in a table and clean it up;
Data Groups; set Groups;
 Where Estimate ne ._;
 drop Effect Method Estimate;
 Letter=cats(of Line:);
 drop of Line:;
 drop of EqLS:;
 run;
/*
Data Ebert; Set Ebert; TtlPrbTm = maxdur - TtlPrbTm; run; *revert to normal so the means are correct!;
*/;
*Calculate Means for all variables. This will be combined with Groups later;
Proc means data=ebert; 
     by trt;
     title "Untransformed means for all variables";
	 output out=trtMeans;
	 Run;

*Transpose calculated means for combining with Tukey Grouping;
proc sql;
 create table trtMeansLong (drop= _TYPE_ _FREQ_ Transform maxdur) as select *,  _STAT_ as column from trtMeans;
quit;
*Delete trtMeans, not needed anymore;
proc delete lib=work data= trtMeans;
proc transpose data=trtMeansLong out=trtMeansLong(RENAME=(_NAME_=Parameter)); by trt; id column; idlabel column;
run;


*Finally merge the two datasets into a pretty table;
Proc sort data=work.trtMeansLong; by Parameter trt;
Proc sort data=work.Groups; by Parameter trt;
Data Final; Set trtMeansLong Groups; 
merge trtMeansLong Groups; by Parameter trt;
run;

*And merge used lambda;
Data Final;
 MERGE Final(IN=In1) Lambda;
 BY Parameter;
 IF In1=1 then output Final; 
run;

*delete unncecessary datasets ("unncecessary" may vary for different use cases);
proc delete lib=work data= trtMeansLong Groups lambda;

*export the Final table that combines untransformed means and Tukey grouping in one CSV file;
*Name is given autmatically;
proc export data=Final outfile="&OutPath.&InFile.-Output-MeansTukey.csv" dbms=csv replace;
 ods results;
 ods html close;
run;
********************************************************************************************
*** ATTENTION: The table Groups and therefore Final will not contain information if      ***
*** Tukey grouping was not able to generate letter code for all significant differences. ***
*** This can happen if there is larger number of treatments being compared beacause      ***
*** LSMLines can ony show letters continuously which is not allways possible. In this    ***
*** case the message "The LINES display does not reflect all significant comparisons.    ***
*** The following additional pairs are significantly different: <list of pairs>" is      ***
*** printed in HTML output, so make sure you check for those cases in HTML output!       ***
********************************************************************************************


***************************************************************************************
*** Following  ANOVA table is interesting if someone wants the exact p-value for    ***
*** any of trt pairwise comparisons and does not want to scroll through HTML output ***
***************************************************************************************;

*Make parameters easy to read in the ANOVA table;
Data ANOVA;
 Retain _LABEL_;
 MERGE ANOVA(IN=In1) Final(keep= Parameter _LABEL_);
 BY Parameter;
 IF In1=1 then output ANOVA; 
run;

*Uncomment the following to export the ANOVA table to .csv file;
/*
proc export data=ANOVA outfile="&OutPath.&InFile.-Output-ANOVA.csv" dbms=csv replace;
 ods results;
 ods html close;
run;
*/;
quit;