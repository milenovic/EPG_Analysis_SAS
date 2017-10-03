
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
* Input statement for basic testing and program development. It is replaced when program is used for Data analyses.;
Data one(keep=insectno waveform dur);
	infile 'C:\Users\yourfilename.csv' dsd missover firstobs=2 delimiter=',' end=last;
	length  insectno$ 20 waveform$ 10 dur 8; *specifies record lengths for reading variables;
	input  insectno$ waveform$ dur; *creates variable names for input. The $ character tells SAS to treat these variables as charaters not numbers;

    waveform=compress(upcase(waveform));
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
    *insectno=compress(trt||insectno);
	Transform=1; *Transform=0 will disable all transformations*;
    proc sort; by insectno;

*ODS noresults; *suppresses output to "results" and "output" windows.;
* Output statement for basic testing and program development. It is replaced when program is used for Data analyses.;
ODS HTML file='C:\Users\tebert\OneDrive - University of Florida\Work\Deepak\Whitefly3 out'; *Directs all output to this file.;

Data one; set one;
      line=_n_;
*     Calculate time to start and time to end of each behavior.;
      retain in0 SumStart SumEnd dur0;
      if insectno ne in0 then do;
       SumStart=0.0; SumEnd=0.0; dur0=0.0;
       in0=insectno;
      end;
      SumEnd=SumEnd+dur;
      SumStart=SumStart+Dur0;
      dur0=dur;
	proc sort;by insectno waveform line;
data one; set one;
if dur ne "." then output;

data one; set one; proc sort; by insectno waveform;
data one;set one; by insectno waveform;
	retain instance;
	if first.waveform then instance=0;
	instance=instance+1;
Data one; set one; proc sort; by line;
Data one; set one;
	inverter1=50000-line;
Data one; set one; drop in0 dur0;

Data one; set one;
retain in0 holder1;
if in0 ne insectno then do; in0=insectno; holder1=0; end;
holder1 = holder1+dur;
data one; set one; drop in0;
data one; set one; proc sort; by inverter1;
data one; set one;
retain in0 maxdur;
if in0 ne insectno then do; in0=insectno; maxdur=holder1; end;
data one; set one; drop in0 holder1;
data one; set one; proc sort; by line;
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
	if compress(upcase(waveform))='PD' then waveform='C';
	if compress(upcase(waveform))='PDS' then waveform='C';
	if compress(upcase(waveform))='PDL' then waveform='C';
	if compress(upcase(waveform))='II1' then waveform='C';
	if compress(upcase(waveform))='II2' then waveform='C';
	if compress(upcase(waveform))='II3' then waveform='C';
*	if compress(upcase(waveform))='F'   then waveform='C'; *Activating this line merges F and C waveforms*;
Data OnlyCNoPd; Set OnlyCNoPd; proc sort; by line;
Data OnlyCNoPd; Set OnlyCNoPd;
	retain w0 w1 in0 marker1;
	w1=Compress(upcase(waveform));
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
	w1=Compress(upcase(waveform));
	if insectno ne in0 then do;
	  w0='  '; in0=insectno; time1=0;
	end;
	if time1=0 then do; output; time1=1; end;
	else If w1 ne w0 then output;
	w0=w1;
data onepdSAS; set onepdSAS OnlyCNoPd; merge onepdSAS OnlyCNoPd; by insectno marker1;
data oneD; set onepdSAS;  Var1=insectno; Var2=waveform; Var3=dur;
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
      SumEnd=SumEnd+dur;
      SumStart=SumStart+Dur0;
      dur0=dur;
proc sort; by insectno waveform line;
data OnlyCNoPd; set OnlyCNoPd; drop in0 dur0;
data OnlyCNoPd;set OnlyCNoPd; by insectno waveform;
	retain instance;
	if first.waveform then instance=0;
	instance=instance+1;
data OnlyCNoPd; set OnlyCNoPd; proc sort; by line;
data OnlyCNoPd; set OnlyCNoPd; inverter1=50000-line;
data OnlyCNoPd; set OnlyCNoPd; drop time1;
proc datasets nodetails nolist; delete oneD onepdSAS;
run;
*********************************************************************
**************************   Method end   ***************************
*********************************************************************;

*********************************************************************
*******                  Start New Method                         ***
*******            define the dataset OnlyPd                      ***
*********************************************************************;
Data three; set one; Proc sort; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=0; 
	end;
    if compress(upcase(waveform))='PD' then Marker1=1;
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
if marker2=1 then output;
Data three; set three; Proc sort; by insectno line;
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
Data onepd; set onlypd;                  *convert pds and pdl into pd;
if compress(upcase(waveform))='PDL' or 
	compress(upcase(waveform))='PDS' or
	compress(upcase(waveform))='II2' or
	compress(upcase(waveform))='II3' then waveform='PD';
Data onepd; Set onepd; proc sort; by line;
Data onepd; Set onepd;
	retain w0 w1 in0 marker1;
	w1=Compress(upcase(waveform));
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
data onepd; set onepd; if marker3=1 then output;
data onepd; set onepd; drop marker2 marker3 in0;
data onepdSAS; set onepdSAS onepd; merge onepd onepdSAS; by insectno marker1;
data oneD; set onepdSAS;  Var1=insectno; Var2=waveform; Var3=dur;
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
      SumEnd=SumEnd+dur;
      SumStart=SumStart+Dur0;
      dur0=dur;
proc sort; by insectno waveform;
data onepd; set onepd;by insectno waveform;
retain instance;
if first.waveform then do;instance=0;end;
instance=instance+1;
data onepd; set onepd; proc sort; by line;
data onepd; set onepd; drop in0 dur0;
data onepd; set onepd; inverter1=50000-line;
proc datasets nodetails nolist; delete oned onepdSAS;
run;
*********************************************************************
*  Finished creating dataset OnePd
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*;

*********************************************************************
*******                             Start New Method              ***
*******                        define the dataset OnlyG           ***
*********************************************************************;
Data three; set one; Proc sort; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=0; 
	end;
    if compress(upcase(waveform))='G' then Marker1=1;
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
if marker2=1 then output;
Data three; set three; Proc sort; by insectno line;
data three; set three; drop marker1 marker2 in0;
Data OnlyG; Set three;
run;
*********************************************************************
*  Finished creating dataset OnlyG
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*;

*********************************************************************
*******                          Start New Method                 ***
*******                     define the dataset OnlyF              ***
*********************************************************************;
Data three; set one; Proc sort; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=0; 
	end;
    if compress(upcase(waveform))='F' then Marker1=1;
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
if marker2=1 then output;
Data three; set three; Proc sort; by insectno line;
data three; set three; drop marker1 marker2 in0;
Data OnlyF; Set three;
run;
*********************************************************************
*  Finished creating dataset OnlyF
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*;



*********************************************************************
*******                            Start New Method               ***
*******                        define the dataset OnlyD           ***
*********************************************************************;
Data three; set one; Proc sort; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=0; 
	end;
    if compress(upcase(waveform))='D' then Marker1=1;
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
if marker2=1 then output;
Data three; set three; Proc sort; by insectno line;
data three; set three; drop marker1 marker2 in0;
Data OnlyD; Set three;
run;
*********************************************************************
*  Finished creating dataset OnlyD
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*;

*********************************************************************
*******                             Start New Method              ***
*******                        define the dataset OnlyE1          ***
*********************************************************************;
Data three; set one; Proc sort; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=0; 
	end;
    if compress(upcase(waveform))='E1' then Marker1=1;
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
if marker2=1 then output;
Data three; set three; Proc sort; by insectno line;
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
Data three; set one; Proc sort; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=0; 
	end;
    if compress(upcase(waveform))='E2' then Marker1=1;
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
if marker2=1 then output;
Data three; set three; Proc sort; by insectno line;
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
Data three; set one; Proc sort; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=0; 
	end;
    if compress(upcase(waveform))='E2' and dur>600 then Marker1=1;
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
if marker2=1 then output;
Data three; set three; Proc sort; by insectno line;
data three; set three; drop marker1 marker2 in0;
Data OnlySusE2; Set three;
run;
*********************************************************************
*  Finished creating dataset OnlySusE2
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*;


*********************************************************************
*******                             Start New Method              ***
*******                        define the dataset OnlyE1e         ***
*********************************************************************;
Data three; set one; Proc sort; by insectno line;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
	 in0=insectno; marker1=0; 
	end;
    if compress(upcase(waveform))='E1E' then Marker1=1;
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
if marker2=1 then output;
Data three; set three; Proc sort; by insectno line;
data three; set three; drop marker1 marker2 in0;
Data OnlyE1e; Set three;
run;
*********************************************************************
*  Finished creating dataset OnlyE1e
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*;

proc datasets nodetails nolist; delete three;

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
retain in0;
if insectno ne in0 then do; in0=insectno; if waveform="NP" then TmFrstPrbFrmStrt=sumend; else TmFrstPrbFrmStrt="."; end;
Data Ebert; Set Ebert;
 drop in0;
 Data Ebert; Set Ebert;
 retain in0 marker1;
 if in0 ne insectno then do; in0=insectno; marker1=0; end; else marker1=1;
 Data Ebert; Set Ebert; if marker1=0 then output;

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
Data three; set three; Proc sort; by insectno line;
Data three; set three;
	retain in0 marker1 marker2;
	w1=Compress(upcase(waveform));
	if insectno ne in0 then do;
	 marker1=0; Marker2=0;
	 in0=insectno;
	end;
	If w1='C' then marker1=1;
	If w1='Z' or w1='NP' then marker1=0;
	if w1='E1' then marker2=1;
Data three; set three; if marker2=0 then output;
data three; set three; drop marker2 in0;
Data three; set three;
	retain in0 marker3 marker4;
	if insectno ne in0 then do;
	marker3=0; marker4=0; in0=insectno;
	end;
	if marker1=1 and marker3=0 then marker4=marker4+1;
	marker3=marker1;
Data three; set three; drop in0 marker1 marker3;
Data three; set three; proc sort; by insectno inverter1;
data three; set three;
	retain marker1 in0;
	if insectno ne in0 then do;
	marker1=0; in0=insectno;
	end;
	else marker1=1;
Data three; set three; if marker1=0 then output;
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
data three; set OnlyF; if compress(upcase(waveform))='F' then output;
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
Proc datasets nolist nodetails; delete three outsas;
Data three; set one;
	if compress(upcase(waveform))='NP' or compress(upcase(waveform))='Z' then do marker1=1; waveform="Z"; end; else do marker1=0; waveform="P"; end;
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
	if W0 eq w1 then sdur=sdur+dur; else sdur=dur;
	w1=w0;
data three; set three; drop in0 w1 w0;
data three; set three;
retain in0;
if in0 ne insectno then do;
	in0=insectno;
*	if waveform eq "P" then sdur="."; *Activate this line to delete first probe if recording not start in NP;
	end;
Data three; set three; drop in0; 
data three; set three; proc sort; by inverter1;
data three; set three;
	retain in0 w1 w0 marker4;
	if in0 ne insectno then do;
		in0=insectno; marker4=0; w1='   ';
	end;
	w0=waveform;
	if w1 ne w0 then marker4=0; else marker4=1;
	w1=w0;
data three; set three; if marker4=0 then output;
data three; set three; proc sort; by line;
data three; set three; drop instance w1 w0 in0;
data three; set three; proc sort; by insectno waveform;
data three;set three; by insectno waveform;
	retain instance;
	if first.waveform then instance=0;
	instance=instance+1;
data three; set three; if waveform="P" then output;
data four; set three; if instance=1 then output;
data five; set three; if instance=2 then output;
data four; set four; DurFrstPrb=sdur; drop sdur waveform dur line sumstart sumend inverter1 marker1 marker2 marker4 instance;
data five; set five; DurScndPrb=sdur; drop sdur waveform dur line sumstart sumend inverter1 marker1 marker2 marker4 instance;
data Ebert; set Ebert four; merge Ebert four; by insectno;
data Ebert; set Ebert five; merge Ebert five; by insectno;
proc datasets nolist nodetails; delete four five three;

*********************************************************************
*  Finding duration of First and Second probe is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method         ********
*	Duration of shortest C before first E1 in any probe.     ********
*  "Duration of shortest C before E1"                        ********
*********************************************************************;
Data three; set OnlyCNoPd; Proc sort; by insectno line;
data three; set three;
	if compress(upcase(waveform))='NP' or compress(upcase(waveform))='Z' then waveform='Z'; else if compress(upcase(waveform))='E1' then waveform='E1'; else waveform='P';
data three; set three;
	retain in0 marker1 w0;
	if in0 ne insectno then do;
	  in0=insectno; marker1=0; w0='  ';
	end;
	if w0='E1' then marker1=1;
	if w0='Z' then marker1=0;
	w0=waveform;
data three; set three; if waveform='Z' then marker1=0;
data three; set three; if marker1=0 then output;
data three; set three; proc sort; by inverter1;
data three; set three; drop in0 w0 marker1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
	  in0=insectno; marker1=0;
	end;
	if waveform='E1' then marker1=1;
	if waveform='Z' then marker1=0;
Data three; set three; proc sort; by line;
data three; set three; if marker1=1 then output;


Data three; set three;	drop in0 marker1;
data three; set three;
	retain W1 W0 in0 Sdur;
	if in0 ne insectno then do;
		in0=insectno; Sdur=dur; W1='  ';
	end;
	W0=compress(upcase(waveform));
	if W0 eq w1 then sdur=sdur+dur; else sdur=dur;
	w1=w0;

data three; set three; proc sort; by inverter1;
data three; set three; drop in0 w1 w0;
data three; set three;
	retain in0 w1 w0 marker4;
	if in0 ne insectno then do;
		in0=insectno; marker4=0; w1=' ';
	end;
	w0=waveform;
	if w1 ne w0 then marker4=0; else marker4=1;
	w1=w0;
data three; set three; if marker4=0 then output;
data three; set three; proc sort; by line;
data three; set three; drop instance w1 w0 in0;
data three; set three; proc sort; by insectno waveform;
data three;set three; by insectno waveform;
	retain instance;
	if first.waveform then instance=0;
	instance=instance+1;
data three; set three; if waveform="P" then output;
data three; set three; proc sort; by insectno;
data three; set three; proc means noprint; by insectno; var Sdur; output out=outsas min=ShrtCbfrE1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
Data Ebert; Set Ebert; drop _TYPE_ _FREQ_;
proc datasets nolist nodetails; delete three outsas; 

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
	if  compress(upcase(waveform))='Z' or compress(upcase(waveform))='NP' then output;
data three; set three;
	if holder4="NP" or holder4="Z" then instance=instance; else instance=instance+1;
data three; set three; if instance=2 then output;
Data three; set three;
	DurScndZ=dur;
	drop waveform line dur instance sumstart sumend inverter1 holder4;
Data Ebert; set Ebert three;
	merge Ebert three;
	by insectno;
proc datasets nolist nodetails; delete three;
*********************************************************************
*  Finding duration of Second non-probe event is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*******                         Start New Method    *****************
*******         Total duration of F                 *****************
*********************************************************************;
Data three; set OnlyF; if compress(upcase(waveform))='F' then output;
Data three; set three;
	retain in0 TtlDurF;
	if insectno ne in0 then do;
		in0=insectno; TtlDurF=0;
	end;
	TtlDurF=TtlDurF+dur;
Data three; set three; proc sort; by insectno inverter1;
Data three; set three; drop in0;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=1;
	end;
	else marker1=0;
Data three; set three; if marker1=1 then output;
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
	if compress(upcase(waveform)) eq 'E1' then marker1=1;
Data three; set three; if marker1=0 then output;
data three; set three; drop in0 marker1;
Data three; set three; proc sort; by insectno inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if compress(upcase(waveform)) eq 'Z' or compress(upcase(waveform)) eq 'NP' then marker1=1;
Data three; set three; if marker1=1 then output;
Data three; set three; if compress(upcase(waveform)) eq 'Z' or compress(upcase(waveform)) eq 'NP' then output;
Data three; set three; drop in0 marker1;
data three; set three; proc sort; by insectno line;
data three; set three; 
	retain DurNnprbBfrFrstE1 in0;
	if in0 ne insectno then do; in0=insectno; DurNnprbBfrFrstE1=0; end;
	DurNnprbBfrFrstE1=DurNnprbBfrFrstE1+dur;
Data three; set three; drop in0;
data three; set three; proc sort; by insectno inverter1;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=1;
	end;
	else marker1=0;
Data three; set three; if marker1=1 then output;
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
data three; set three; if compress(upcase(waveform))='PD' then output;
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas mean=meanpd;
data three; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert three; merge Ebert three; by insectno;
Proc datasets nolist nodetails; delete oned outsas three;
*********************************************************************
*  Finding Mean duration of pd is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
******                          Start New Method    *****************
******                Mean duration of pdL
*********************************************************************;
Data three; set one; if compress(upcase(waveform))='PDL' then PDL=dur;
Data three; set three; proc means noprint; by insectno; var PDL; output out=outsas mean=meanPDL;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nolist nodetails; delete outsas three;
*********************************************************************
*  Finding Mean duration of pd is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
******                        Start New Method    *******************
******     Mean duration of pdS
*********************************************************************;
Data three; set one; if compress(upcase(waveform))='PD' then PDS=dur;
Data three; set three; proc means noprint; by insectno; var PDS; output out=outsas mean=meanPDS;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
data Ebert; set Ebert; if meanPDS='.' and meanpd ne '.' then meanpds=meanpd;
proc datasets nolist nodetails; delete outsas three;
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
	w1=compress(upcase(waveform));
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
	if holder1 ne marker1  and compress(upcase(waveform))='C' then do;
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
	if marker3=1 and compress(upcase(waveform))='PD' then marker4=marker4+1;
	if marker3=0 then marker4=0;
	holder1=marker1;
Data three; set three; drop in0 holder1 marker3;
Data three; set three; proc sort; by insectno inverter1;*Isolate last entry in each probe;
Data three; set three;
	retain in0 holder1 marker5;
	if insectno ne in0 then do;
		in0=insectno; holder1=0; marker5=0;
	end;
	if holder1=0 and marker1=1 then marker5=1;
	else marker5=0;
	holder1=marker1;
data three; set three; drop in0 holder1;
data three; set three; if marker5=1 then output;
data three; set three; proc sort; by insectno line;
data three; set three; proc means noprint; var marker4; by insectno; output out=outsas mean=meanNPdPrb;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete outsas three;
*********************************************************************
*  Finding Average number of pd per probe is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
********                        Start New Method    *****************
********      Mean duration of F
*********************************************************************;
Data three; set OnlyF; if compress(upcase(waveform))='F' then output;
Data three; set three;
	retain in0 meanF;
	if insectno ne in0 then do;
		in0=insectno; MeanF=0;
	end;
	MeanF=MeanF+dur;
Data three; set three; proc sort; by insectno inverter1;
Data three; set three; drop in0;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=1;
	end;
	else marker1=0;
Data three; set three; if marker1=1 then output;
Data three; set three; MeanF=meanF/instance;
Data three; Set three; drop waveform dur line sumstart sumend instance inverter1 in0 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc datasets nodetails nolist; delete three;
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
	if compress(upcase(waveform))='E1' then  marker1=1;
data three; set three; if marker1=0 then output;
data three; set three; proc sort; by insectno inverter1;
data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	else marker1=1;
Data three; set three; if marker1=0 then output;
data three; set three; TmStrtEPGFrstE=sumend;
data three; set three; drop waveform dur line sumstart sumend instance inverter1 in0 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc datasets nolist nodetails; delete three;
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
	if compress(upcase(waveform))='E1' then  marker1=1;
data three; set three; if marker1=0 then output;
data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if compress(upcase(waveform))='C' then marker1=1;
Data three; set three; if marker1=1 then output;
Data three; set three; drop in0 marker1;
data three; set three;
	retain in0 TmFrmFrstPrbFrstE;
	if in0 ne insectno then do;
		in0=insectno; TmFrmFrstPrbFrstE=0;
	end;
	TmFrmFrstPrbFrstE = TmFrmFrstPrbFrstE + dur;
data three; set three; drop in0;
data three; set three; proc sort; by insectno inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	else marker1=1;
data three; set three; proc sort; by line;
data three; set three; if marker1=0 then output;
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
	if compress(upcase(waveform))='E1' then  marker1=1;
data three; set three; if marker1=0 then output;
data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if compress(upcase(waveform))='C' then marker1=1;
Data three; set three; if marker1=1 then output;
Data three; set three; drop in0 marker1;
data three; set three; proc sort; by insectno inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if compress(upcase(waveform))='Z' or compress(upcase(waveform))='NP' then marker1=1;
data three; set three; proc sort; by line;
data three; set three; if marker1=0 then output;
Data three; set three; drop in0 marker1;
data three; set three;
	retain in0 TmBegPrbFrstE;
	if in0 ne insectno then do;
		in0=insectno; TmBegPrbFrstE=0;
	end;
	TmBegPrbFrstE=TmBegPrbFrstE+dur;
data three; set three; drop in0;
data three; set three; proc sort; by insectno inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	else marker1=1;
data three; set three; if marker1=0 then output;
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
proc means noprint; by insectno waveform;  output out=outsas n=num mean=avg sum=sum1;
data G; set outsas; if compress(upcase(waveform))='G' then output;
Data G; set G; NumG=num; DurG=sum1; MeanG=avg; drop _TYPE_ _FREQ_ waveform num avg sum1;
Data Ebert; set Ebert g; merge Ebert g; by insectno;
data Ebert; set Ebert; if NumG='.' then NumG=0;
proc datasets nolist nodetails; delete G outsas three;
*********************************************************************
*  Finding NumG DurG, and MeanG is finished.
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
	if compress(upcase(waveform))='E1' then marker1=1;
data three; set three; if marker1=1 then output;
data three; set three; drop in0 marker1;

data three; set three;
	retain in0 marker2 delay1;
	if in0 ne insectno then do;
		in0=insectno; marker2=0; delay1=1;
	end;
	if delay1=0 then do;
		if compress(upcase(waveform))='Z' then marker2=marker2+1;
		if compress(upcase(waveform))='NP' then marker2=marker2+1;
		 
	end;
	delay1=0;
data three; set three; if compress(upcase(waveform))='C' then output;
data three; set three; proc means noprint;
	by insectno; var marker2; output out=outsas max=NumPrbsAftrFrstE;
data outsas; set outsas; if NumPrbsAftrFrstE='.' then NumPrbsAftrFrstE=0;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
Data Ebert; set Ebert; if NumPrbsAftrFrstE='.' then NumPrbsAftrFrstE=0;
proc datasets nodetails nolist; delete three outsas;
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
	if compress(upcase(waveform))='E1' then marker1=1;
data three; set three; if marker1=1 then output;
data three; set three; drop in0 marker1;

Data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if compress(upcase(waveform))='NP' or compress(upcase(waveform))="Z" then marker1=1;
data three; set three; if marker1=1 then output;
data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker2 delay1;
	if in0 ne insectno then do;
		in0=insectno; marker2=1; delay1=1;
	end;
	if delay1=0 then do;
		if compress(upcase(waveform))='Z' then marker2=marker2+1;
		if compress(upcase(waveform))='NP' then marker2=marker2+1;
		 
	end;
	delay1=0;
Data three; set three; if compress(upcase(waveform)) ne "Z" and compress(upcase(waveform)) ne "NP" then waveform="PRB";
data three; set three; 
  proc sort; by insectno marker2 waveform;
  proc means noprint; by insectno marker2 waveform; var dur; output out=outsas2 sum=sdur;
data outsas2; set outsas2; if waveform="PRB" and sdur<180 then output;
data outsas2; set outsas2;
	retain in0 marker1;
	if in0 ne insectno then do;	in0=insectno; marker1=0; end;
	marker1=marker1+1;
Data outsas2; set outsas2;
  proc means noprint; by insectno; var marker1; output out=outsas4 max=NmbrShrtPrbAftrFrstE;

data outsas4; set outsas4; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas4; merge Ebert outsas4; by insectno;
Data Ebert; set Ebert; if NmbrShrtPrbAftrFrstE='.' then NmbrShrtPrbAftrFrstE=0;
proc datasets nolist nodetails; delete three outsas4 outsas2;
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
data three; set three; if compress(upcase(waveform))='E1' then output;
data three; set three;
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
	w1=compress(upcase(waveform));
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
	w1=compress(upcase(waveform));
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
if compress(upcase(waveform))='E2' then marker1=1; else marker1=0;
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
if compress(upcase(waveform))='E2' and dur>600 then marker1=1; else marker1=0;
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
	w1=compress(upcase(waveform));
	if w0="E2" then marker1=1;	
	w0=w1;
Data three; set three; if marker1=0 then output;
Data three; set three; drop w0 w1 in0 marker1;

Data three; set three;
	if compress(upcase(waveform))='E1' then waveform='E';
	if compress(upcase(waveform))='E2' then waveform='E';
data three; set three;
	retain sort1 w0 in0;
	if in0 ne insectno then do; sort1=1; in0=insectno; end;
	w1=compress(upcase(waveform));
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
data three; set three; if waveform='E' and instance=1 then output;
proc datasets nolist nodetails; delete outthree;
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
	if compress(upcase(waveform))='E1' or compress(upcase(waveform))='E2' then output;
Data three; set three;
	proc sort; by insectno waveform;
	Proc means noprint; by insectno waveform; var dur; output out=outsas sum=outSum;
data four; set outsas; if compress(upcase(waveform))='E1' then output;
data four; set four; outsumE1=outsum; drop outsum waveform _TYPE_ _FREQ_;
data five; set outsas; if compress(upcase(waveform))='E2' then output;
data five; set five; outsumE2=outsum; drop outsum waveform _TYPE_ _FREQ_;
data three; set four five; merge four five; by insectno;
data three; set three;
if outsume1='.' then outsume1=0;
if outsume2='.' then outsume2=0;
data three; set three;
ttlsum=outsumE1+outsumE2;
CntrbE1toE=100*(outsumE1/ttlsum);
data three; set three; drop outsumE1 outsumE2 ttlsum;
data Ebert; set Ebert three; merge Ebert three; by insectno;
Proc datasets nolist nodetails; delete three four five outsas;
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
	if compress(upcase(waveform))='E2' and dur>600 then marker1=1;
data three; set three; if marker1=0 then output;
data three; set three; drop in0 marker1;
data three; set three; proc sort; by insectno inverter1;
data three; set three; if compress(upcase(waveform))='E1' then output;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;	in0=insectno; marker1=0; end;
	else marker1=1;
data three; set three; if marker1=0 then output;
data three; set three; 	DurE1FlwdFrstSusE2 =dur;
Data three; set three;	drop waveform line dur sumstart sumend instance inverter1 in0 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;
Proc datasets nolist nodetails; delete three;
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
	if compress(upcase(waveform))='E2' then marker1=1;
data three; set three; if marker1=0 then output;
data three; set three; drop in0 marker1;
data three; set three; proc sort; by insectno inverter1;
data three; set three; if compress(upcase(waveform))='E1' then output;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;	in0=insectno; marker1=0; end;
	else marker1=1;
data three; set three; if marker1=0 then output;
data three; set three; 	DurE1FlldFrstE2 =dur;
Data three; set three;	drop waveform line dur sumstart sumend instance inverter1 in0 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;
Proc datasets nolist nodetails; delete three;
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
	w1=Compress(upcase(waveform));
	if insectno ne in0 then do;
	  w0='  '; marker2=0;
	 in0=insectno; 
	end;
	if compress(upcase(waveform))='E2' then marker2=1;
data three; set three; if marker2=1 then output;
data three; set three; proc means noprint; by insectno; var dur; output out=outsas sum=DurE2toEnd;
data three; set three; if compress(upcase(waveform))='E2' then output;
data three; set three; proc means noprint; by insectno; var dur; output out=outsas1 sum=DurAllE2;
data outsas; set outsas outsas1; merge outsas outsas1; by insectno;
data outsas; set outsas; PotE2Indx=100*(DurAllE2/DurE2toEnd);
data outsas; set outsas; drop _TYPE_ _FREQ_ DurAllE2 DurE2toEnd;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nolist nodetails; delete outsas1 three outsas;
*********************************************************************
*  Finding Potential E2 Index is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find total duration of E
*********************************************************************;
Data three; set onlye1;
if compress(upcase(waveform))='E1' or compress(upcase(waveform))='E2' then output;
data three; set three; proc means noprint; by insectno; var dur; output out=outsas sum=TtlDurE;
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
if compress(upcase(waveform))='E1' then output;
data three; set three; proc means noprint; by insectno; var dur; output out=outsas sum=TtlDurE1;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
Proc datasets nolist nodetails; delete three outsas;
*********************************************************************
*  Finding total duration of E1 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find Total Duration of E1 followed by a sustained E2
*********************************************************************;
data three; set onlysusE2;
	if compress(upcase(waveform))='E2' and dur>600 then marker1=1;
	else marker1=0;
data three; set three; proc sort; by insectno inverter1;
data three; set three;
	retain in0 w0 marker2;
	w1=compress(upcase(waveform));
	if in0 ne insectno then do;
		in0=insectno; marker2=0; 
	end;
	if w1="E1" and w0=1 then marker2=1; else marker2=0;
	w0=marker1;
Data three; set three; proc sort; by insectno line;
data three; set three; if marker2=1 then output;
data three; set three; proc means noprint; by insectno; var dur; output out=outsas sum=TtlDurE1FlldSusE2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
Proc datasets nolist nodetails; delete three outsas;

*********************************************************************
*  Finding Total Duration of E1 followed by a sustained E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
****	Total duration of E1 followed by E2
*********************************************************************;
Data three; set onlye2; proc sort; by insectno inverter1;
data three; set three;
	retain marker1 in0 w1 w0;
	w1=compress(upcase(waveform));
	if in0 ne insectno then do;
		in0=insectno; marker1=0; w0='   ';
	end;
	if w0='E2' and w1='E1' then marker1=1; else marker1=0;
	w0=w1;
data three; set three; drop in0;
data three; set three; if marker1=1 then output;
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
Data three; Set three; proc sort; by insectno inverter1;
data three; set three;
	retain w0 w1 in0 marker2;
	w1=Compress(upcase(waveform));
	if insectno ne in0 then do;
	  w0='  '; marker1=0;
	 in0=insectno; 
	end;
	if w1='E1' and w0 ne 'E2' then marker1=1;
	w0=w1;
data three; set three; proc sort; by insectno line;
data three; set three; drop in0 w1 w0;
data three; set three;
	retain in0 w0 w1;
	w1=compress(upcase(waveform));
	if insectno ne in0 then do;
		in0=insectno; w0='   ';
	end;
	if w0='E2' and w1='E1' then marker1=0;
	w0=w1;
data three; set three; if marker1=1 then output;
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
Data three; set onlye2; proc sort; by insectno inverter1;
data three; set three;
	retain marker1 in0 w1 w0;
	w1=compress(upcase(waveform));
	if in0 ne insectno then do;
		in0=insectno; marker1=0; w0='   ';
	end;
	if w0='E2' and w1='E1' then marker1=1; else marker1=0;
	w0=w1;
data three; set three; drop in0;
data three; set three; if marker1=1 then output;
data three; set three; proc means noprint;
	by insectno; var dur; output out=outsas sum=TtlDurE1FlldE2;
data outsas; set outsas; drop _TYPE_ _FREQ_;

data three; set onlye2; if compress(upcase(waveform))='E2' then output;
data three; set three; proc means noprint; 
	by insectno; var dur; output out=outsas2 sum=SE2;
data outsas2; set outsas2; drop _TYPE_ _FREQ_;
data three; set outsas outsas2; merge outsas outsas2; by insectno;
data three; set three;
TtlDurE1FllwdE2PlsE2=TtlDurE1FlldE2+SE2;
data three; set three; drop se2 TtlDurE1FlldE2;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc datasets nolist nodetails; delete outsas outsas2 three;
*********************************************************************
*  Finding Total duration of E1 followed by E2 plus E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Total Duration of E2
*********************************************************************;
data three; set onlye2;
	if compress(upcase(waveform))='E2' then output;
data three; set three; proc means noprint;
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
	if compress(upcase(waveform))='E1' then output;
data three; set three; proc means noprint;
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
	if compress(upcase(waveform))='E2' then output;
data three; set three; proc means noprint;
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
	w1=compress(upcase(waveform));
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
data three; set OnlyCnoPd; if compress(upcase(waveform))='C' then output;
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
if compress(upcase(waveform))="C" then marker1=1;
if compress(upcase(waveform))="NP" or compress(upcase(waveform))="Z" then marker1=0;
data three; set three; drop in0;
data three; set three; 
retain in0 marker2 holder1;
if in0 ne insectno then do;
in0=insectno; marker2=0;
end;
if holder1=0 and marker1=1 then marker2=marker2+1;
holder1=marker1;
data three; set three; if compress(upcase(waveform)) ne "NP" and compress(upcase(waveform)) ne "Z" then output;
data three; set three; proc means noprint; var dur; by insectno marker2; output out=outsas sum=dur2;
data three; set outsas; if dur2<180 then output; drop _TYPE_ _FREQ_;
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
data three; set three; if compress(upcase(waveform))="NP" or compress(upcase(waveform))="Z" then marker1=1; else marker1=0;
data three; set three; proc means noprint; by insectno; var marker1; output out=outsas sum=NumNP;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nolist nodetails; delete outsas three;
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
data three; set three; if compress(upcase(waveform))="PD" then marker1=1; else marker1=0;
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
data three; set three; if compress(upcase(waveform))="PDL" then marker1=1; else marker1=0;
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
data three; set three; if compress(upcase(waveform))="PDS" then marker1=1; else marker1=0;
data three; set three; if marker1=0 and compress(upcase(waveform))="PD" then marker1=1;
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
data three; set three; if compress(upcase(waveform))="E1E" then marker1=1; else marker1=0;
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
data three; set three; if compress(upcase(waveform))="C" then output;
data three; set three; proc means noprint; by insectno; var dur; output out=outsas sum=TtlDurC;
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
data three; set three; if compress(upcase(waveform))="E1E" then output;
data three; set three; proc means noprint; by insectno; var dur; output out=outsas sum=TtlDurE1e;
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
data three; set three; if compress(upcase(waveform))ne "E1" and compress(upcase(waveform)) ne "E2" then output;
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
if compress(upcase(waveform))eq "NP" or compress(upcase(waveform)) eq "Z" then output;
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
if compress(upcase(waveform))eq "PD" then output;
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
if compress(upcase(waveform))eq "PDL" then output;
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas sum=TtlDurPD;
data four; set outsas;
Data three; set one; 
if compress(upcase(waveform))eq "II2" then output;
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas sum=TtlDurPD2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data four; set four outsas; merge four outsas; by insectno;
Data three; set one; 
if compress(upcase(waveform))eq "PDII3" then output;
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas sum=TtlDurPD3;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data four; set four outsas; merge four outsas; by insectno;
data four; set four; if ttldurpd2="." then ttldurpd2=0;
                     if ttldurpd3="." then ttldurpd3=0;
data four; set four; TtlDurPDL=TtlDurPD+TtlDurPD2+TtlDurPD3;
data four; set four; drop _Type_ _FREQ_ TtlDurPD TtlDurPD2 TtlDurPD3;
data Ebert; set Ebert four; merge Ebert four; by insectno;
proc datasets nodetails nolist; 
delete four outsas three;
*********************************************************************
*  Finding the Total duration of PDL phase is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****	Find the Total duration of PDS phase
*********************************************************************;
Data three; set One; 
if compress(upcase(waveform))eq "PD" then output;
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
w0=compress(upcase(waveform));
if in0 ne insectno then do; in0=insectno; marker1=0; end;
If w0="C" then marker1=1;
if w0="NP" or w0="Z" then marker1=0;
data three; set three; if marker1=1 then output;
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
if compress(upcase(waveform))="NP" or compress(upcase(waveform)) eq "Z" then output;
data three; set three;
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
if compress(upcase(waveform))="C" then output;
data three; set three;
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
if compress(upcase(waveform))="E2" and dur>600 then marker1=1;
data three; set three; if marker1=0 then output;
data three; set three;
proc means noprint; var sumend; by insectno; output out=outsas max=TmSusE2;
data four; set one;
proc means noprint; var sumend; by insectno; output out=outsas1 max=runtime;
data outsas; set outsas outsas1; merge outsas outsas1; by insectno;
* if tmsuse2="." then TmFrstSusE2=runtime; *else TmFrstSusE2=TmSusE2; * This line makes output match Sarria, and it has been changed;
TmFrstSusE2=TmSusE2;
data outsas; set outsas; drop runtime TmSusE2 _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete outsas outsas1 four;
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
if compress(upcase(waveform))="E2" and dur>600 then marker1=1;
data three; set three; if marker1=0 then output;
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
if compress(upcase(waveform))="C" then marker1=1;
Data three; set three; If marker1=0 then output;
data three; set three; drop in0 marker1;
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas3 sum=Sumdur;
Data outsas3; set outsas3; drop _TYPE_ _FREQ_;
data outsas; set outsas outsas3; merge outsas outsas3; by insectno;
data outsas; set outsas; TmFrstSusE2FrstPrb=TmfrstSusE2-Sumdur;
data outsas; set outsas; if TmFrstSusE2FrstPrb<=0 then TmFrstSusE2FrstPrb=".";
data outsas; set outsas; drop TmfrstSusE2 Sumdur;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four outsas outsas1 outsas3 three;
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
if compress(upcase(waveform))="C" then marker1=1;
if compress(upcase(waveform))="NP" or compress(upcase(waveform))="Z" then marker1=0;
Data three; set three;
retain marker2;
if compress(upcase(waveform))="E2" and dur>600 then marker2=1;
if compress(upcase(waveform))="NP" or compress(upcase(waveform))="Z" then marker2=0;
data four; set three;
proc sort; by inverter1;
data four; set four;
retain marker3 in0;
if in0 ne insectno then do; in0=insectno; marker3=0; end;
if marker2=1 then marker3=1;
if compress(upcase(waveform))="NP" or compress(upcase(waveform))="Z" then marker3=0;
data four; set four;
proc sort; by line;
data four; set four;
if marker3=1 then output;
data four; set four;
drop marker1 marker2 marker3 in0;
data four; set four;
retain marker1 in0;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if compress(upcase(waveform))="E2" and dur>600 then marker1=1;
data four; set four;
if marker1=0 then output;
data four; set four;
proc means noprint; var dur; by insectno; output out=outsas sum=TmFrstSusE2StrtPrb;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete three four outsas;
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
if compress(upcase(waveform))="E2" then marker1=1;
data three; set three;
if marker1=0 then output;
proc means noprint; var sumend; by insectno; output out=outsas max=TmFrstE2StrtEPG;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
Proc datasets nodetails nolist; delete three outsas;
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
if compress(upcase(waveform))="E2" then marker1=1;
data three; set three;
if marker1=0 then output;
proc means noprint; var sumend; by insectno; output out=outsas max=result1;

data three; set three; drop in0 marker1;
data three; set one; retain marker1;
data three; set three;
retain in0 marker1;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if compress(upcase(waveform))="C" then marker1=1;
Data three; set three; If marker1=0 then output;
data three; set three; drop in0 marker1;
Data three; set three;
proc means noprint; var dur; by insectno; output out=outsas3 sum=Sumdur;
Data outsas3; set outsas3; drop _TYPE_ _FREQ_;
data outsas; set outsas outsas3; merge outsas outsas3; by insectno;


data outsas; set outsas; TmFrstE2FrmFrstPrb=result1-Sumdur; drop result1 Sumdur _TYPE_ _FREQ_;
data outsas; set outsas; if TmFrstE2FrmFrstPrb<=0 then TmFrstE2FrmFrstPrb=".";
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
Proc datasets nodetails nolist; delete three four outsas3 outsas;
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
if compress(upcase(waveform))="C" then marker1=1;
if compress(upcase(waveform))="NP" or compress(upcase(waveform))="Z" then marker1=0;
Data three; set three;
retain marker2;
if compress(upcase(waveform))="E2" then marker2=1;
if compress(upcase(waveform))="NP" or compress(upcase(waveform))="Z" then marker2=0;
data four; set three;
proc sort; by inverter1;
data four; set four;
retain marker3 in0;
if in0 ne insectno then do; in0=insectno; marker3=0; end;
if marker2=1 then marker3=1;
if compress(upcase(waveform))="NP" or compress(upcase(waveform))="Z" then marker3=0;
data four; set four;
proc sort; by line;
data four; set four;
if marker3=1 then output;
data four; set four;
drop marker1 marker2 marker3 in0;
data four; set four;
retain marker1 in0;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if compress(upcase(waveform))="E2" then marker1=1;
data four; set four;
if marker1=0 then output;
data four; set four;
proc means noprint; var dur; by insectno; output out=outsas sum=TmFrstE2FrmPrbStrt;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete three four outsas;
*********************************************************************
*  Finding Time to first E2 from start of probe is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
***********      Duration of NP by hour
*********************************************************************;
Data three; set one;
if compress(upcase(waveform))="NP" then output;
data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend<=3600 then do; ttldur=ttldur+dur; marker4=1; end;
if sumstart<=3600 and sumend>3600 and marker4=0 then ttldur=ttldur+(3600-sumstart);
if sumstart=0 and sumend>3600 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp1;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four;

data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend-3600>0 and sumstart<=3600 then do; ttldur= sumend-3600; marker4=1; end;
if sumstart>3600 and sumend<=7200 and marker4=0 then do; ttldur=ttldur+dur; marker4=1; end;
if sumstart<=7200 and sumend>7200 and marker4=0 then ttldur=ttldur+(7200-sumstart);
if sumstart<3600 and sumend>7200 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four;

data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend-7200>0 and sumstart<=7200 then do; ttldur= sumend-7200; marker4=1; end;
if sumstart>7200 and sumend<=10800 and marker4=0 then do; ttldur=ttldur+dur; marker4=1; end;
if sumstart<=10800 and sumend>10800 and marker4=0 then ttldur=ttldur+(10800-sumstart);
if sumstart<7200 and sumend>10800 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp3;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four;

data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend-10800>0 and sumstart<=10800 then do; ttldur= sumend-10800; marker4=1; end;
if sumstart>10800 and sumend<=14400 and marker4=0 then do; ttldur=ttldur+dur; marker4=1; end;
if sumstart<=14400 and sumend>14400 and marker4=0 then ttldur=ttldur+(14400-sumstart);
if sumstart<10800 and sumend>14400 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp4;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four;

data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend-14400>0 and sumstart<=14400 then do; ttldur= sumend-14400; marker4=1; end;
if sumstart>14400 and sumend<=18000 and marker4=0 then do; ttldur=ttldur+dur; marker4=1; end;
if sumstart<=18000 and sumend>18000 and marker4=0 then ttldur=ttldur+(18000-sumstart);
if sumstart<14400 and sumend>18000 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp5;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four;

data four; set three;
retain ttldur in0 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; marker4=0; end;
if sumend-18000>0 and sumstart<=18000 then do; ttldur= sumend-18000; marker4=1; end;
if sumstart>18000 and sumend<=21600 and marker4=0 then do; ttldur=ttldur+dur; marker4=1; end;
if sumstart<=21600 and sumend>21600 and marker4=0 then ttldur=ttldur+(21600-sumstart);
if sumstart<18000 and sumend>21600 then ttldur=3600;
marker4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurNp6;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four;

Data ebert; set ebert;
if TtlDurNP1="." then TtlDurNP1=0;
if TtlDurNP2="." then TtlDurNP2=0;
if TtlDurNP3="." then TtlDurNP3=0;
if TtlDurNP4="." then TtlDurNP4=0;
if TtlDurNP5="." then TtlDurNP5=0;
if TtlDurNP6="." then TtlDurNP6=0;

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
if compress(upcase(waveform))="PDS" or compress(upcase(waveform))="PD" then output;
data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend<=3600 then do; ttl1=ttl1+1; marker4=1; end;
if sumstart<=3600 and sumend>3600 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumPDS1;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four;

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
proc datasets nodetails nolist; delete four;

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
proc datasets nodetails nolist; delete four;

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
proc datasets nodetails nolist; delete four;

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
proc datasets nodetails nolist; delete four;

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
proc datasets nodetails nolist; delete three four;

Data ebert; set ebert;
if NumPDS1="." then NumPDS1=0;
if NumPDS2="." then NumPDS2=0;
if NumPDS3="." then NumPDS3=0;
if NumPDS4="." then NumPDS4=0;
if NumPDS5="." then NumPDS5=0;
if NumPDS6="." then NumPDS6=0;

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
if compress(upcase(waveform))="PDS" or compress(upcase(waveform))="PD" then output;
data four; set three;
retain ttldur in0 ttl1;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; end;
if sumend<=3600 then do; ttldur=ttldur+dur; ttl1=ttl1+1; marker4=1; end;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS1 Attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS1="."; else MnDurPdS1=MnDurPdS1/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four outsas;

data four; set three;
retain ttldur in0 ttl1 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; marker4=0; end;
if sumstart<7200 and sumstart>=3600 then do; ttldur= ttldur+dur; ttl1=ttl1+1; marker4=1; end;
marker4=0;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS2 attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS2="."; else MnDurPdS2=MnDurPdS2/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four outsas;

data four; set three;
retain ttldur in0 ttl1 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; marker4=0; end;
if sumstart<10800 and sumstart>=7200 then do; ttldur=ttldur+dur; ttl1=ttl1+1; marker4=1; end;
marker4=0;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS3 attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS3="."; else MnDurPdS3=MnDurPdS3/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four outsas;

data four; set three;
retain ttldur in0 ttl1 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; marker4=0; end;
if sumstart<14400 and sumstart>=10800 then do; ttldur=ttldur+dur; ttl1=ttl1+1; marker4=1; end;
marker4=0;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS4 attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS4="."; else MnDurPdS4=MnDurPdS4/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four outsas;

data four; set three;
retain ttldur in0 ttl1 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; marker4=0; end;
if sumstart<18000 and sumstart>=14400 then do; ttldur= ttldur+dur; ttl1=ttl1+1; marker4=1; end;
marker4=0;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS5 attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS5="."; else MnDurPdS5=MnDurPdS5/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four outsas;

data four; set three;
retain ttldur in0 ttl1 marker4;
if in0 ne insectno then do; in0=insectno; ttldur=0; ttl1=0; marker4=0; end;
if sumstart<21600 and sumstart>=18000 then do; ttldur= ttldur+dur; ttl1=ttl1+1; marker4=1; end;
marker4=0;
data four; set four;
proc means noprint; var ttldur ttl1; by insectno; output out=outsas max=MnDurPdS6 attl1;
data outsas; set outsas; if attl1=0 then MnDurPdS6="."; else MnDurPdS6=MnDurPdS6/attl1;
data outsas; set outsas; drop _TYPE_ _FREQ_ attl1;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four outsas;

Data ebert; set ebert;
if MnDurPDS1="." then MnDurPDS1=0;
if MnDurPDS2="." then MnDurPDS2=0;
if MnDurPDS3="." then MnDurPDS3=0;
if MnDurPDS4="." then MnDurPDS4=0;
if MnDurPDS5="." then MnDurPDS5=0;
if MnDurPDS6="." then MnDurPDS6=0;

run;

*********************************************************************
*  Finding duration of PDS by hour is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
***********      Number of F by hour
*********************************************************************;
Data three; set one;
if compress(upcase(waveform))="F" then output;
data four; set three;
retain ttl1 in0 marker4;
if in0 ne insectno then do; in0=insectno; ttl1=0; marker4=0; end;
if sumend<=3600 then do; ttl1=ttl1+1;  marker4=1; end;
if sumstart<=3600 and sumend>3600 and marker4=0 then ttl1=ttl1+1;
marker4=0;
data four; set four;
proc means noprint; var ttl1; by insectno; output out=outsas max=NumF1;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four outsas;

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
proc datasets nodetails nolist; delete four outsas;

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
proc datasets nodetails nolist; delete four outsas;

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
proc datasets nodetails nolist; delete four outsas;

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
proc datasets nodetails nolist; delete four outsas;

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
proc datasets nodetails nolist; delete four outsas;

Data ebert; set ebert;
if NumF1="." then NumF1=0;
if NumF2="." then NumF2=0;
if NumF3="." then NumF3=0;
if NumF4="." then NumF4=0;
if NumF5="." then NumF5=0;
if NumF6="." then NumF6=0;

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
if compress(upcase(waveform))="F" then output;
data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend<=3600 then do; ttldur=ttldur+dur; mark4=1; end;
if sumstart<=3600 and sumend>3600 and mark4=0 then ttldur=ttldur+(3600-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF1;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four;

data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend-3600>0 and sumstart<=3600 then do; ttldur= sumend-3600; mark4=1; end;
if sumstart>3600 and sumend<=7200 and mark4=0 then do; ttldur=ttldur+dur; mark4=1; end;
if sumstart<=7200 and sumend>7200 and mark4=0 then ttldur=ttldur+(7200-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four;

data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend-7200>0 and sumstart<=7200 then do; ttldur= sumend-7200; mark4=1; end;
if sumstart>7200 and sumend<=10800 and mark4=0 then do; ttldur=ttldur+dur; mark4=1; end;
if sumstart<=10800 and sumend>10800 and mark4=0 then ttldur=ttldur+(10800-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF3;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four;

data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend-10800>0 and sumstart<=10800 then do; ttldur= sumend-10800; mark4=1; end;
if sumstart>10800 and sumend<=14400 and mark4=0 then do; ttldur=ttldur+dur; mark4=1; end;
if sumstart<=14400 and sumend>14400 and mark4=0 then ttldur=ttldur+(14400-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF4;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four;

data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend-14400>0 and sumstart<=14400 then do; ttldur= sumend-14400; mark4=1; end;
if sumstart>14400 and sumend<=18000 and mark4=0 then do; ttldur=ttldur+dur; mark4=1; end;
if sumstart<=18000 and sumend>18000 and mark4=0 then ttldur=ttldur+(18000-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF5;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four;

data four; set three;
retain ttldur in0 mark4;
if in0 ne insectno then do; in0=insectno; ttldur=0; mark4=0; end;
if sumend-18000>0 and sumstart<=18000 then do; ttldur= sumend-18000; mark4=1; end;
if sumstart>18000 and sumend<=21600 and mark4=0 then do; ttldur=ttldur+dur; mark4=1; end;
if sumstart<=21600 and sumend>21600 and mark4=0 then ttldur=ttldur+(21600-sumstart);
mark4=0;
data four; set four;
proc means noprint; var ttldur; by insectno; output out=outsas max=TtlDurF6;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete four;

Data ebert; set ebert;
if TtlDurF1="." then TtlDurF1=0;
if TtlDurF2="." then TtlDurF2=0;
if TtlDurF3="." then TtlDurF3=0;
if TtlDurF4="." then TtlDurF4=0;
if TtlDurF5="." then TtlDurF5=0;
if TtlDurF6="." then TtlDurF6=0;

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
w1=compress(upcase(waveform));
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
if sumend ne 0 then sumstart=sumstart+holder1;
sumend=sumend+durprobe;
holder1=durprobe;

data three; set outsas;
drop _TYPE_ _FREQ_ in0 holder1;
data three; set three;
if waveform="X " then output;
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
proc datasets nodetails nolist; delete four outsas;

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
proc datasets nodetails nolist; delete four outsas;

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
proc datasets nodetails nolist; delete four outsas;

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
proc datasets nodetails nolist; delete four outsas;

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
proc datasets nodetails nolist; delete four outsas;

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
proc datasets nodetails nolist; delete four outsas;

Data ebert; set ebert;
if NumPrb1="." then NumPrb1=0;
if NumPrb2="." then NumPrb2=0;
if NumPrb3="." then NumPrb3=0;
if NumPrb4="." then NumPrb4=0;
if NumPrb5="." then NumPrb5=0;
if NumPrb6="." then NumPrb6=0;

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
if compress(upcase(waveform))= 'C' and marker2=0 then do; marker1=1; marker2=1; end;
If compress(upcase(waveform))= 'PD' then marker1=0;
data three; set three;
if marker1=1 then output;
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
if compress(upcase(waveform))="PD"  then marker2=marker2+1;
Data three; set three; if marker2>0 then output;
Data three; set three; drop in0 marker2;
data three; set three;
retain in0 marker1;
if in0 ne insectno then do;
	in0=insectno; marker1=0;
	end;
if compress(upcase(waveform)) = "NP" then marker1=1;
data three; set three; if marker1=0 then output;
data three; set three; drop in0 marker1;
Data three; set three; proc sort; by inverter1;
data three; set three;
retain in0 marker2;
if in0 ne insectno then do in0=insectno; marker2=0; end;
if compress(upcase(waveform))="PD"  then marker2=marker2+1;
data three; set three; proc sort; by line;

data three; set three; drop in0; proc sort; by line;
data three; set three;
retain in0 holder1;
if in0 ne insectno then do; in0=insectno; holder1=0; end;
if marker2=0 then holder1=holder1+dur;
data three; set three;
proc means noprint; by insectno; var holder1; output out=outsas42 max=TmEndLstPDEndPrb;
Data outsas42; set outsas42; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas42; merge Ebert outsas42; by insectno;
proc datasets nodetails nolist; delete three outsas42;
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
if compress(upcase(waveform))= 'II2' then marker1=1;
data three; set three; drop in0;
data three; set three; proc sort; by inverter1;
data three; set three;
retain marker2 in0;
if in0 ne insectno then do; in0=insectno; marker2=0; end;
if marker1=1 then marker2=1;
data three; set three; if marker2=1 then output;
data three; set three; proc sort; by line;
data three; set three;
if compress(upcase(waveform))='PD' or compress(upcase(waveform))='II2' or compress(upcase(waveform))='II3' then output;
data Four; set three;
if compress(upcase(waveform))='PD' then output;
proc means noprint;
var dur; by insectno; output out=outsas sum=SumPDII1;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;

data Four; set three;
if compress(upcase(waveform))='II2' then output;
proc means noprint;
var dur; by insectno; output out=outsas sum=SumPDII2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;

data Four; set three;
if compress(upcase(waveform))='II3' then output;
proc means noprint;
var dur; by insectno; output out=outsas sum=SumPDII3;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nolist nodetails; delete Four outsas three;
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
data three; set three;*remove all events after the last sustained E2 ;
retain in0 marker1;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if compress(upcase(waveform))="E2" and dur>600 then marker1=1;
Data three; set three; if marker1=1 then output;
data three; set three; drop in0 marker1;

Data three; set three; *remove all events before the last pd;
if compress(upcase(waveform))='PD' or compress(upcase(waveform))='II2' or compress(upcase(waveform))='PDS'
   or compress(upcase(waveform))='II3' or compress(upcase(waveform))='PDL' then waveform='PD';
data three; set three;
retain in0 marker1;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if compress(upcase(waveform))="PD" then marker1=1;
Data three; set three; if marker1=0 then output;
data three; set three; drop in0 marker1;

data three; set three; *remove the E1 before sustained E2 and remove the sustained E2;
retain in0 marker1;
if in0 ne insectno then do; in0=insectno; marker1=0; end;
if compress(upcase(waveform))="E1" then marker1=1;
Data three; set three; if marker1=1 then output;
data three; set three; drop in0 marker1;
data three; set three;
retain in0 marker1;
if in0 ne insectno then do; in0=insectno; marker1=0; end; else marker1=1;
data three; set three; if marker1=1 then output;
data three; set three; proc sort; by line;
data three; set three; proc means noprint; by insectno; var dur; output out=outsas sum=TmEndPDBegE1FllwdSusE2;
Data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nolist nodetails; delete three outsas;
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
	if compress(upcase(waveform))='PD' then marker1=1;
	if compress(upcase(waveform))='PDL' then marker1=1;
	if compress(upcase(waveform))='II2' then marker1=1;
	if compress(upcase(waveform))='II3' then marker1=1;
data three; set three;
proc sort; by inverter1;
data three; set three;
	retain marker2 in0;
	if in0 ne insectno then do; in0=insectno; marker2=0; end;
	if marker1=1 then marker2=1;
data three; set three;
	if marker2=0 then output;
proc sort; by line;
data three; set three; proc sort; by line;
proc means noprint; var dur; by insectno; output out=outsas sum=TmLstPdEndRcrd;
data outsas; set outsas; Drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nolist nodetails; delete three outsas;
*********************************************************************
*  Finding Time from the end of the last pd to the end of EPG is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
****     From start of last E1 to end of EPG record
*********************************************************************;
data Ebert; set Ebert; TmLstE1EndRcrd=".";
*********************************************************************
*  Finding from first E1 to end of EPG record is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


*********************************************************************
*********************************   Start New Method    *************
***** Time from Last E2 to end of EPG record 
*********************************************************************;
data three; set onlyE2;
data three; set three; proc sort; by inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end; else marker1=1;
data three; set three; if marker1=0 and waveform="E2" then output;
data three; set three; proc sort; by line;
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
	if compress(upcase(waveform))='E2' then output;
data three; set three; proc means noprint;
	var dur; by insectno; output out=outsas max=maxE2;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nolist nodetails; delete three outsas;
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
	if compress(upcase(waveform))='E2' and dur>600 then marker1=1;
data three; set three; if marker1=1 then output;
data three; set three; drop in0 marker1;
Data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if compress(upcase(waveform))='NP' or compress(upcase(waveform))="Z" then marker1=1;
Data three; set three; if marker1=1 then output;
Data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if compress(upcase(waveform))ne'NP' and compress(upcase(waveform)) ne 'Z' then marker1=1;
data three; set three; if marker1=0 then output;
data three; set three; DurNpFllwFrstSusE2=dur;
data three; set three; drop dur waveform line sumstart sumend instance inverter1 in0 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;
proc datasets nolist nodetails; delete three;
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
data three; set three; proc sort; by insectno line;
data three; set three; drop in0;
data three; set three;
	retain in0 marker2;
	if in0 ne insectno then do; in0=insectno; marker2=0; if marker1=1 then marker2=1; end;
data three; set three; if marker2=1 then output;
data three; set three; drop in0 marker1 marker2;
data three; set three; proc sort; by insectno inverter1;

Data three; set three;
	retain in0 RecDur;
	if in0 ne insectno then do; in0=insectno; RecDur=sumend; end;
data three; set three;
proc sort; by line;
data three; set three; drop in0;
Data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if compress(upcase(waveform))='E2' and dur>600 then marker1=1;
data three; set three; if marker1=1 then output;
data three; set three; drop in0 marker1;
Data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if compress(upcase(waveform))='NP' or compress(upcase(waveform))="Z" then marker1=1;
Data three; set three; if marker1=1 then output;
Data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if compress(upcase(waveform))ne'NP' and compress(upcase(waveform)) ne 'Z' then marker1=1;
data three; set three; if marker1=0 then output;
data three; set three; 
	if sumend=RecDur then DurTrmNpFllwFrstSusE2=.; else DurTrmNpFllwFrstSusE2='.'; *NOTE: This variable is set to missing in all cases;
data three; set three; drop dur line sumstart RecDur sumend instance inverter1 in0 marker1;
data Ebert; set Ebert three; merge Ebert three; by insectno;
Proc datasets nolist nodetails; delete three;
*********************************************************************
*  Finding Duration of NP just after sus E2 given NP artificially terminated event is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****  Percent probing spent in C
*********************************************************************;
Data three; set onlycnopd;
	if compress(upcase(waveform)) ne 'NP' and compress(upcase(waveform)) ne 'Z' then output;
data three; set three;
proc means noprint; var dur; by insectno; output out=outsas1 sum=SumPrb;
data three; set three;
	if compress(upcase(waveform))='C' or compress(upcase(waveform)) ='PD' then output;
data three; set three;
proc means noprint; var dur; by insectno; output out=outsas2 sum=sumC;
data outsas1; set outsas1 outsas2; merge outsas1 outsas2; by insectno;
data outsas1; set outsas1;
	PrcntPrbC=100*sumC/sumprb;
data outsas1; set outsas1; drop _TYPE_ _FREQ_ SumC SumPrb;
data Ebert; set Ebert outsas1; merge Ebert outsas1; by insectno;
data Ebert; set Ebert; if PrcntPrbC='.' then PrcntPrbC=0;
proc datasets nolist nodetails; delete outsas1 outsas2 three;
*********************************************************************
*  Finding Percent probing spent in C is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;


***********************************************************************
*********************************   Start New Method    ***************
****  Percent probing spent in E1
*********************************************************************;
Data three; set OnlyE1;
	if compress(upcase(waveform)) ne 'NP' and compress(upcase(waveform)) ne 'Z' then output;
data three; set three;
proc means noprint; var dur; by insectno; output out=outsas1 sum=SumPrb;
data three; set three;
	if compress(upcase(waveform))='E1' then output;
data three; set three;
proc means noprint; var dur; by insectno; output out=outsas2 sum=sumC;
data outsas1; set outsas1 outsas2; merge outsas1 outsas2; by insectno;
data outsas1; set outsas1;
	PrcntPrbE1=100*sumC/sumprb;
data outsas1; set outsas1; drop _TYPE_ _FREQ_ SumC SumPrb;
data Ebert; set Ebert outsas1; merge Ebert outsas1; by insectno;
data Ebert; set Ebert; if PrcntPrbE1='.' then PrcntPrbE1=0;
proc datasets nolist nodetails; delete outsas1 outsas2 three;
*********************************************************************
*  Finding Percent probing spent in E1 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
*********************************   Start New Method    *************
****  Percent probing spent in E2
*********************************************************************;
Data three; set one;
	if compress(upcase(waveform)) ne 'NP' and compress(upcase(waveform)) ne 'Z' then output;
data three; set three;
proc means noprint; var dur; by insectno; output out=outsas1 sum=SumPrb;
data three; set three;
	if compress(upcase(waveform))='E2' then output;
data three; set three;
proc means noprint; var dur; by insectno; output out=outsas2 sum=sumC;
data outsas1; set outsas1 outsas2; merge outsas1 outsas2; by insectno;
data outsas1; set outsas1;
	PrcntPrbE2=100*sumC/sumprb;
data outsas1; set outsas1; drop _TYPE_ _FREQ_ SumC SumPrb;
data Ebert; set Ebert outsas1; merge Ebert outsas1; by insectno;
proc datasets nolist nodetails; delete outsas1 outsas2 three;
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
	if compress(upcase(waveform)) ne 'NP' and compress(upcase(waveform)) ne 'Z' then output;
data three; set three;
proc means noprint; var dur; by insectno; output out=outsas1 sum=SumPrb;
data three; set three;
	if compress(upcase(waveform))='F' then output;
data three; set three;
proc means noprint; var dur; by insectno; output out=outsas2 sum=sumC;
data outsas1; set outsas1 outsas2; merge outsas1 outsas2; by insectno;
data outsas1; set outsas1;
	PrcntPrbF=100*sumC/sumprb;
data outsas1; set outsas1; drop _TYPE_ _FREQ_ SumC SumPrb;
data Ebert; set Ebert outsas1; merge Ebert outsas1; by insectno;
proc datasets nolist nodetails; delete outsas1 outsas2 three;
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
	if compress(upcase(waveform)) ne 'NP' and compress(upcase(waveform)) ne 'Z' then output;
data three; set three;
proc means noprint; var dur; by insectno; output out=outsas1 sum=SumPrb;
data three; set three;
	if compress(upcase(waveform))='G' then output;
data three; set three;
proc means noprint; var dur; by insectno; output out=outsas2 sum=sumC;
data outsas1; set outsas1 outsas2; merge outsas1 outsas2; by insectno;
data outsas1; set outsas1;
	PrcntPrbG=100*sumC/sumprb;
data outsas1; set outsas1; drop _TYPE_ _FREQ_ SumC SumPrb;
data Ebert; set Ebert outsas1; merge Ebert outsas1; by insectno;
proc datasets nolist nodetails; delete outsas1 outsas2 three;
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
	if compress(upcase(waveform)) = 'E2' then marker1=1; else marker1=0;
data three; set three;
proc means noprint; var marker1; by insectno; output out=outsas1 sum=SumPrb;
data three; set three;
	if compress(upcase(waveform))='E2' and dur>600 then output;
data three; set three;
proc means noprint; var marker1; by insectno; output out=outsas2 sum=sumC;
data outsas1; set outsas1 outsas2; merge outsas1 outsas2; by insectno;
data outsas1; set outsas1;
	PrcntE2SusE2=100*sumC/sumprb;
data outsas1; set outsas1; drop _TYPE_ _FREQ_ SumC SumPrb;
data outsas1; set outsas1; if PrcntE2SusE2='.' then PrcntE2SusE2=0;
data Ebert; set Ebert outsas1; merge Ebert outsas1; by insectno;
proc datasets nolist nodetails; delete outsas1 outsas2 three;
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
Data Ebert; Set Ebert; trt=substr(insectno,1,1);*recover treatment designations*;
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

If maxdur<18000 and NumF6=0 then NumF6=".";

If TmStrtEPGFrstE="." then TmStrtEPGFrstE=maxdur;
If TmFrmFrstPrbFrstE="." then TmFrmFrstPrbFrstE=maxdur;
if NumE2="." then NumE2=0;
if NumLngE2="." then NumLngE2=0;
if TmFrstSusE2="." then TmFrstSusE2=maxdur;
if TmFrstSusE2FrstPrb="." then TmFrstSusE2FrstPrb=maxdur;
if TmFrstE2StrtEPG="." then TmFrstE2StrtEPG=maxdur;
if TmFrstE2FrmFrstPrb="." then TmFrstE2FrmFrstPrb=maxdur;
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
proc datasets nodetails nolist; delete three;
*********************************************************************;
*********************************************************************
****   New Data set, OnlyPrbs. This converts all recordings into  ***
****      probe versus non-probe.                                 ***
*********************************************************************;
Data OnlyPrbs; set one;
	if compress(upcase(waveform))='NP' then waveform='NP';
		else waveform='C';
Data OnlyPrbs; Set OnlyPrbs; proc sort; by line;
Data OnlyPrbs; Set OnlyPrbs;
	retain w0 w1 in0 marker1;
	w1=Compress(upcase(waveform));
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
	w1=Compress(upcase(waveform));
	if insectno ne in0 then do;
	  w0='  '; in0=insectno; time1=0;
	end;
	if time1=0 then do; output; time1=1; end;
	else If w1 ne w0 then output;
	w0=w1;
data onePrbSAS; set onePrbSAS OnlyPrbs; merge onePrbSAS OnlyPrbs; by insectno marker1;
data oneZZ; set onePrbSAS;  Var1=insectno; Var2=waveform; Var3=dur;
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
      SumEnd=SumEnd+dur;
      SumStart=SumStart+Dur0;
      dur0=dur;
proc sort; by insectno waveform line;
data OnlyPrbs; set OnlyPrbs; drop in0 dur0;
data OnlyPrbs;set OnlyPrbs; by insectno waveform;
	retain instance;
	if first.waveform then instance=0;
	instance=instance+1;
data OnlyPrbs; set OnlyPrbs; proc sort; by line;
data OnlyPrbs; set OnlyPrbs; inverter1=50000-line;
data OnlyPrbs; set OnlyPrbs; drop time1;
proc datasets nodetails nolist; delete oneZZ onePrbSAS;
run;
*********************************************************************
**************************   Method end   ***************************
*********************************************************************;

******************************************************************
/******************   Start New Method    ************************
*  Number of probes to first G.
*****************************************************************/;

Data three; set OnlyG;
Data three; set three; Proc sort; by insectno line;
Data three; set three;
	retain in0 marker1 marker2;
	w1=Compress(upcase(waveform));
	if insectno ne in0 then do;
	 marker1=0; Marker2=0;
	 in0=insectno;
	end;
	If w1='C' then marker1=1;
	If w1='Z' or w1='NP' then marker1=0;
	if w1='G' then marker2=1;
	run;
Data three; set three; if marker2=0 then output;
data three; set three; drop marker2 in0;
Data three; set three;
	retain in0 marker3 marker4;
	if insectno ne in0 then do;
	marker3=0; marker4=0; in0=insectno;
	end;
	if marker1=1 and marker3=0 then marker4=marker4+1;
	marker3=marker1;
Data three; set three; drop in0 marker1 marker3;
Data three; set three; proc sort; by insectno inverter1;
data three; set three;
	retain marker1 in0;
	if insectno ne in0 then do;
	marker1=0; in0=insectno;
	end;
	else marker1=1;
Data three; set three; if marker1=0 then output;
Data three; set three; CtoFrstG=marker4;
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
	if compress(upcase(waveform)) eq 'G' then marker1=1;
Data three; set three; if marker1=0 then output;
data three; set three; drop in0 marker1;
Data three; set three; proc sort; by insectno inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do; in0=insectno; marker1=0; end;
	if compress(upcase(waveform)) eq 'Z' or compress(upcase(waveform)) eq 'NP' then marker1=1;
Data three; set three; if marker1=1 then output;
Data three; set three; if compress(upcase(waveform)) eq 'Z' or compress(upcase(waveform)) eq 'NP' then output;
Data three; set three; drop in0 marker1;
data three; set three; proc sort; by insectno line;
data three; set three; 
	retain DurNnprbBfrFrstG in0;
	if in0 ne insectno then do; in0=insectno; DurNnprbBfrFrstG=0; end;
	DurNnprbBfrFrstG=DurNnprbBfrFrstG+dur;
Data three; set three; drop in0;
data three; set three; proc sort; by insectno inverter1;
Data three; set three;
	retain in0 marker1;
	if insectno ne in0 then do;
		in0=insectno; marker1=1;
	end;
	else marker1=0;
Data three; set three; if marker1=1 then output;
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
	w1=compress(upcase(waveform));
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
	if holder1 ne marker1  and compress(upcase(waveform))='C' then do;
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
	if marker3=1 and compress(upcase(waveform))='G' then marker4=marker4+1;
	if marker3=0 then marker4=0;
	holder1=marker1;
Data three; set three; drop in0 holder1 marker3;
Data three; set three; proc sort; by insectno inverter1;  *Isolate the last entry in each probe;
Data three; set three;
	retain in0 holder1 marker5;
	if insectno ne in0 then do;
		in0=insectno; holder1=0; marker5=0;
	end;
	if holder1=0 and marker1=1 then marker5=1;
	else marker5=0;
	holder1=marker1;
data three; set three; drop in0 holder1;
data three; set three; if marker5=1 then output;
data three; set three; proc sort; by insectno line;
data three; set three; proc means noprint; var marker4; by insectno; output out=outsas mean=meanNGPrb;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
proc datasets nodetails nolist; delete outsas three;
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
	if compress(upcase(waveform))='G' then  marker1=1;
data three; set three; if marker1=0 then output;
data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if compress(upcase(waveform))='C' then marker1=1;
Data three; set three; if marker1=1 then output;
Data three; set three; drop in0 marker1;
data three; set three;
	retain in0 TmFrmFrstPrbFrstG;
	if in0 ne insectno then do;
		in0=insectno; TmFrmFrstPrbFrstG=0;
	end;
	TmFrmFrstPrbFrstG = TmFrmFrstPrbFrstG + dur;
data three; set three; drop in0;
data three; set three; proc sort; by insectno inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	else marker1=1;
data three; set three; proc sort; by line;
data three; set three; if marker1=0 then output;
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
	if compress(upcase(waveform))='G' then  marker1=1;
data three; set three; if marker1=0 then output;
data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if compress(upcase(waveform))='C' then marker1=1;
Data three; set three; if marker1=1 then output;
Data three; set three; drop in0 marker1;
data three; set three; proc sort; by insectno inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if compress(upcase(waveform))='Z' or compress(upcase(waveform))='NP' then marker1=1;
data three; set three; proc sort; by line;
data three; set three; if marker1=0 then output;
Data three; set three; drop in0 marker1;
data three; set three;
	retain in0 TmBegPrbFrstG;
	if in0 ne insectno then do;
		in0=insectno; TmBegPrbFrstG=0;
	end;
	TmBegPrbFrstG=TmBegPrbFrstG+dur;
data three; set three; drop in0;
data three; set three; proc sort; by insectno inverter1;
data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	else marker1=1;
data three; set three; if marker1=0 then output;
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
	if compress(upcase(waveform))='G' then marker1=1;
data three; set three; if marker1=1 then output;
data three; set three; drop in0 marker1;

data three; set three;
	retain in0 marker2 delay1;
	if in0 ne insectno then do;
		in0=insectno; marker2=0; delay1=1;
	end;
	if delay1=0 then do;
		if compress(upcase(waveform))='Z' then marker2=marker2+1;
		if compress(upcase(waveform))='NP' then marker2=marker2+1;
		 
	end;
	delay1=0;
data three; set three; if compress(upcase(waveform))='C' then output;
data three; set three; proc means noprint;
	by insectno; var marker2; output out=outsas max=NumPrbsAftrFrstG;
data outsas; set outsas; if NumPrbsAftrFrstG='.' then NumPrbsAftrFrstG=0;
data outsas; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas; merge Ebert outsas; by insectno;
Data Ebert; set Ebert; if NumPrbsAftrFrstG='.' then NumPrbsAftrFrstG=0;
proc datasets nodetails nolist; delete three outsas;
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
	if compress(upcase(waveform))='G' then marker1=1;
data three; set three; if marker1=1 then output;
data three; set three; drop in0 marker1;

Data three; set three;
	retain in0 marker1;
	if in0 ne insectno then do;
		in0=insectno; marker1=0;
	end;
	if compress(upcase(waveform))='NP' or compress(upcase(waveform))="Z" then marker1=1;
data three; set three; if marker1=1 then output;
data three; set three; drop in0 marker1;
data three; set three;
	retain in0 marker2 delay1;
	if in0 ne insectno then do;
		in0=insectno; marker2=1; delay1=1;
	end;
	if delay1=0 then do;
		if compress(upcase(waveform))='Z' then marker2=marker2+1;
		if compress(upcase(waveform))='NP' then marker2=marker2+1;
		 
	end;
	delay1=0;
Data three; set three; if compress(upcase(waveform)) ne "Z" and compress(upcase(waveform)) ne "NP" then waveform="PRB";
data three; set three; 
  proc sort; by insectno marker2 waveform;
  proc means noprint; by insectno marker2 waveform; var dur; output out=outsas2 sum=sdur;
data outsas2; set outsas2; if waveform="PRB" and sdur<180 then output;
data outsas2; set outsas2;
	retain in0 marker1;
	if in0 ne insectno then do;	in0=insectno; marker1=0; end;
	marker1=marker1+1;
Data outsas2; set outsas2;
  proc means noprint; by insectno; var marker1; output out=outsas4 max=NmbrShrtPrbAftrFrstG;

data outsas4; set outsas4; drop _TYPE_ _FREQ_;
data Ebert; set Ebert outsas4; merge Ebert outsas4; by insectno;
Data Ebert; set Ebert; if NmbrShrtPrbAftrFrstG='.' then NmbrShrtPrbAftrFrstG=0;
proc datasets nolist nodetails; delete three outsas4 outsas2;
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
data three; set three; if compress(upcase(waveform))='C' then output;
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas stddev=sdC;
data three; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert three; merge Ebert three; by insectno;
Proc datasets nolist nodetails; delete oned outsas three;
*********************************************************************
*  Finding Mean deviation of C is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
****                            Start New Method    *****************
****       Mean Deviation of F
*********************************************************************;
Data three; set OnlyF;
data three; set three; if compress(upcase(waveform))='F' then output;
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas stddev=sdF;
data three; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert three; merge Ebert three; by insectno;
Proc datasets nolist nodetails; delete oned outsas three;
*********************************************************************
*  Finding Mean deviation of D is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
****                            Start New Method    *****************
****       Mean Deviation of G
*********************************************************************;
Data three; set OnlyG;
data three; set three; if compress(upcase(waveform))='G' then output;
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas stddev=sdG;
data three; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert three; merge Ebert three; by insectno;
Proc datasets nolist nodetails; delete oned outsas three;
*********************************************************************
*  Finding Mean deviation of G is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
****                            Start New Method    *****************
****       Mean Deviation of E1
*********************************************************************;
Data three; set OnlyE1;
data three; set three; if compress(upcase(waveform))='E1' then output;
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas stddev=sdE1;
data three; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert three; merge Ebert three; by insectno;
Proc datasets nolist nodetails; delete oned outsas three;
*********************************************************************
*  Finding Mean deviation of E1 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
****                            Start New Method    *****************
****       Mean Deviation of E2
*********************************************************************;
Data three; set OnlyE2;
data three; set three; if compress(upcase(waveform))='E2' then output;
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas stddev=sdE2;
data three; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert three; merge Ebert three; by insectno;
Proc datasets nolist nodetails; delete oned outsas three;
*********************************************************************
*  Finding Mean deviation of E2 is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
****                            Start New Method    *****************
****       Mean Deviation of NP
*********************************************************************;
Data three; set One;
data three; set three; if compress(upcase(waveform))='NP' then output;
Data three; set three; proc means noprint; by insectno; var dur; output out=outsas stddev=sdNP;
data three; set outsas; drop _TYPE_ _FREQ_;
data Ebert; set Ebert three; merge Ebert three; by insectno;
Proc datasets nolist nodetails; delete oned outsas three;
*********************************************************************
*  Finding Mean deviation of NP is finished.
* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     END      XXXXXXXXXXXXXXXXXXXX*
*********************************************************************;

*********************************************************************
****                            Start New Method    *****************
****       Mean Deviation of Probes
*********************************************************************;
Data OnlyPrbsC; set OnlyPrbs;
if waveform="C" then output;
proc sort; by  insectno waveform;
proc means noprint; by  insectno; var dur; output out=Prbsout mean=MnPrbs stddev=sdPrbs median=MdnPrbs;

data three; set Prbsout; drop _TYPE_ _FREQ_;
data Ebert; set Ebert three; merge Ebert three; by insectno;
Proc datasets nolist nodetails; delete three OnlyPrbsC Prbsout;
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
***********************************************************************
***********************************************************************
***********************************************************************
***********************************************************************
*******                                                      **********
*******                                                      **********
*******                                                      **********
*******                   TRANSFORMATIONS                    **********
*******                                                      **********
*******                                                      **********
***********************************************************************
***********************************************************************
***********************************************************************
***********************************************************************;


***********************************************************************
***********************************************************************
**** Here is a good generic set of transformations                 ****
**** Counts are sqrt transformed, durations are log transformed    ****
***********************************************************************
***********************************************************************;
/*
Data Ebert; Set Ebert;
if transform=1 then do;
PrcntPrbC = arsin(sqrt(PrcntPrbC/100));
PrcntPrbE1 = arsin(sqrt(PrcntPrbE1/100));
PrcntPrbE2 = arsin(sqrt(PrcntPrbE2/100));
PrcntPrbF = arsin(sqrt(PrcntPrbF/100));
PrcntPrbG = arsin(sqrt(PrcntPrbG/100));
PrcntE2SusE2= arsin(sqrt(PrcntE2SusE2/100));
*/;
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
**              variables were added at te probe level. Also added were variables             **
**              using standard deviations and medians as used by Freddy Tjallingii's group.   **
**                                                                                            **
************************************************************************************************;
Data Ebert; Set Ebert; 
    Proc means data=ebert; 
     by trt;
     var  NumPrbs MnPrbs sdPrbs MdnPrbs DurFrstPrb DurScndPrb TtlPrbTm;
     title "Untransformed Means for Probe variables";
	     Proc means data=ebert; 
     by trt;
     var NumNP TtlDurNP MnDurNP sdNP TmFrstPrbFrmStrt DurScndZ DurNnprbBfrFrstE1 DurNpFllwFrstSusE2;
     title "Untransformed Means for NP variables";
    Proc means data=ebert; 
     by trt;
     var NmbrC TtlDurC MnDurC sdC NmbrShrtC ShrtCbfrE1 PrcntPrbC;
     title "Untransformed Means for C variables";
    Proc means data=ebert; 
     by trt;
     var NumG DurG MeanG sdG CtoFrstG DurNnprbBfrFrstG meanNGPrb TmFrmFrstPrbFrstG TmBegPrbFrstG NumPrbsAftrFrstG
 NmbrShrtPrbAftrFrstG PrcntPrbG;
     title "Untransformed Means for G variables";
    Proc means data=ebert; 
     by trt;
     var NumF TtlDurF meanF TtlDurF1 TtlDurF2 TtlDurF3 TtlDurF4 TtlDurF5 TtlDurF6 NumF1 NumF2 NumF3 NumF4 NumF5 NumF6 PrcntPrbF;
     title "Untransformed Means for F variables";
    Proc means data=ebert; 
     by trt;
     var meanpd meanPDL meanPDS meanNPdPrb NmbrPD NmbrPDL NmbrPDS TtlDurPD TtlDurPDL TtlDurPDS NumPDS1 NumPDS2
 NumPDS3 NumPDS4 NumPDS5 NumPDS6 MnDurPdS1 MnDurPdS2 MnDurPdS3 MnDurPdS4 MnDurPdS5 MnDurPdS6 TmFrstCFrstPD 
 TmEndLstPDEndPrb;
     title "Untransformed Means for pd variables";
    Proc means data=ebert; 
     by trt;
     var NumE1 TtlDurE1 MnDurE1 sdE1 CtoFrstE1 TmStrtEPGFrstE TmFrmFrstPrbFrstE TmBegPrbFrstE NumPrbsAftrFrstE
           NmbrShrtPrbAftrFrstE NumLngE1BfrE2 NumSnglE1 DurFirstE CntrbE1toE DurE1FlwdFrstSusE2 DurE1FlldFrstE2 
           TtlDurE1FlldSusE2 TtlDurE1FlldE2 TtlDurSnglE1;
     title "Untransformed Means for E1 variables";
    Proc means data=ebert; 
     by trt;
     var NumE2 NumLngE2 TtlDurE2 MnDurE2 sdE2 TmFrstSusE2FrstPrb TmFrstSusE2StrtPrb TmFrstE2StrtEPG TmFrstE2FrmFrstPrb
            TmFrstE2FrmPrbStrt TmLstE2EndRcrd maxE2 PrcntPrbE2 PrcntE2SusE2;
     title 'Untransformed Means for E2 variables';
    Proc means data=ebert; 
     by trt;
     var PotE2Indx TtlDurE TtlDurE1FllwdE2PlsE2 TotDurNnPhlPhs TmFrstSusE2;
     title "Untransformed Means for E1+E2 variables";


ods graphics on;
*******************************************************************;
********      Probe Level Variables       *************************;
*******************************************************************;
Data Ebert; Set Ebert; cnstnt=1;
********************************************************************
***********************    cnstnt      *****************************
******  There are two ways to look at the constant that is *********
******    added to prevent log(0).                         *********
******   1) Use 1 because log(1)=0                         *********
******   2) There is some value below which we cannot      *********
******          measure. Thus we add a small value that    *********
******          we hope adjusts zeros to this non-zero but *********
******          non-observable value.                      *********
******    In this case 1 (second) may serve both options.  *********
********************************************************************
*******************************************************************;
Data Ebert; Set Ebert;
if transform=1 then do; numprbs=sqrt(numprbs); 				Mnprbs=log(mnprbs+cnstnt); 
						sdprbs=log(sdprbs+cnstnt); 			mdnprbs=log(mdnprbs+cnstnt);
                        DurFrstPrb=log(durfrstprb+cnstnt); 	durscndprb=log(durscndprb+cnstnt); 
						ttlprbtm=log(ttlprbtm+cnstnt); 
					end;
Proc glimmix plots=residualpanel; class trt; model  NumPrbs=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumPrbs';
Proc glimmix plots=residualpanel; class trt; model  MnPrbs=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of MnPrbs';
Proc glimmix plots=residualpanel; class trt; model  sdPrbs=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of sdPrbs';
Proc glimmix plots=residualpanel; class trt; model  MdnPrbs=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of MdnPrbs';
Proc glimmix plots=residualpanel; class trt; model  DurFrstPrb=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of DurFrstPrb';
Proc glimmix plots=residualpanel; class trt; model  DurScndPrb=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of DurScndPrb';
Proc glimmix plots=residualpanel; class trt; model  TtlPrbTm=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlPrbTm';*duration of recording less duration of NP or Z;

*******************************************************************;
********      Variables for NP            *************************;
*******************************************************************;
if transform=1 then do;
					   	NumNP=sqrt(NumNP);									TtlDurNP=log(ttldurnp+cnstnt);
  					 	MnDurNP=log(MnDurNP+cnstnt);						sdnp=log(sdnp+cnstnt);
						TmFrstPrbFrmStrt=log(TmFrstPrbFrmStrt+cnstnt);		DurScndZ=log(DurScndZ+cnstnt);
						DurNnprbBfrFrstE1=log(DurNnprbBfrFrstE1+cnstnt);	DurNpFllwFrstSusE2=log(DurNpFllwFrstSusE2+cnstnt);
					end;
Proc glimmix plots=residualpanel; class trt; model  NumNP=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumNP';
Proc glimmix plots=residualpanel; class trt; model  TtlDurNP=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurNP';
Proc glimmix plots=residualpanel; class trt; model  MnDurNP=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of MnDurNP';
Proc glimmix plots=residualpanel; class trt; model  sdNP=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of sdNP';
Proc glimmix plots=residualpanel; class trt; model  TmFrstPrbFrmStrt=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TmFrstPrbFrmStrt'; *Duration of first NP;
Proc glimmix plots=residualpanel; class trt; model  DurScndZ=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of DurScndZ';                 *Duration of second NP;
Proc glimmix plots=residualpanel; class trt; model  DurNnprbBfrFrstE1=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of DurNnprbBfrFrstE1';
Proc glimmix plots=residualpanel; class trt; model  DurNpFllwFrstSusE2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of DurNpFllwFrstSusE2';
* NumNP TtlDurNP MnDurNP sdNP TmFrstPrbFrmStrt DurScndZ DurNnprbBfrFrstE1 DurNpFllwFrstSusE2;

*******************************************************************;
********      Variables for C or Pathway (=C+A+B+PD)  *************;
*******************************************************************;
if transform=1 then do;
					   	NmbrC=sqrt(NmbrC);									TtlDurC=log(TtlDurC+cnstnt);
  					 	MnDurC=log(MnDurC+cnstnt);							sdC=log(sdC+cnstnt);
						NmbrShrtC=sqrt(NmbrShrtC);							ShrtCbfrE1=log(ShrtCbfrE1+cnstnt);
						*PrcntPrbC = arsin(sqrt(PrcntPrbC/100));			PrcntPrbC=log((PrcntPrbC/100)/(1-(PrcntPrbC/100)));
					end;
run;
Data Ebert; set ebert;
Proc glimmix plots=residualpanel; class trt; model  NmbrC=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NmbrC';
Proc glimmix plots=residualpanel; class trt; model  TtlDurC=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurC';
Proc glimmix plots=residualpanel; class trt; model  MnDurC=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of MnDurC';
Proc glimmix plots=residualpanel; class trt; model  sdC=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of sdC';
Proc glimmix plots=residualpanel; class trt; model  NmbrShrtC=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NmbrShrtC';
Proc glimmix plots=residualpanel; class trt; model  ShrtCbfrE1=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of ShrtCbfrE1';
Proc glimmix plots=residualpanel; class trt; model  PrcntPrbC=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of PrcntPrbC';
* NmbrC TtlDurC MnDurC sdC NmbrShrtC ShrtCbfrE1 PrcntPrbC;
*******************************************************************;
********      Variables for pd                        *************;
*******************************************************************;
if transform=1 then do;
						meanPD=log(meanPD+cnstnt);
						meanPDL=log(meanpdl+cnstnt);						MeanPDS=log(meanPDS+cnstnt);
						meanNPdPrb=sqrt(meanNPdPrb);						NmbrPD=sqrt(NmbrPD);
						NmbrPDL=sqrt(nmbrPDL);								NmbrPDS=sqrt(NmbrPDS);
						TtlDurPD=log(TtlDurPD+cnstnt);						TtlDurPDL=log(TtlDurPDL+cnstnt);
						TtlDurPDS=log(TtlDurPDS+cnstnt);					NumPDS1=sqrt(NumPDS1);
						NumPDS2=sqrt(NumPDS2);								NumPDS3=sqrt(NumPDS3);
						NumPDS4=sqrt(NumPDS4);								NumPDS5=sqrt(NumPDS5);
						NumPDS6=sqrt(NumPDS6);								MnDurPdS1=log(MnDurPdS1+cnstnt);
						MnDurPdS2=log(MnDurPdS2+cnstnt);					MnDurPdS3=log(MnDurPdS3+cnstnt);
						MnDurPdS4=log(MnDurPdS4+cnstnt);					MnDurPdS5=log(MnDurPdS5+cnstnt);
						MnDurPdS6=log(MnDurPdS6+cnstnt);					TmFrstCFrstPD=log(TmFrstCFrstPD+cnstnt);
						TmEndLstPDEndPrb=log(TmEndLstPDEndPrb+cnstnt);
Proc glimmix; class trt; model  meanpd=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of meanpd';
Proc glimmix; class trt; model  meanPDL=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of meanPDL';
Proc glimmix; class trt; model  meanPDS=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of meanPDS';
Proc glimmix; class trt; model  meanNPdPrb=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of meanNPdPrb';
Proc glimmix; class trt; model  NmbrPD=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NmbrPD';
Proc glimmix; class trt; model  NmbrPDL=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NmbrPDL';
Proc glimmix; class trt; model  NmbrPDS=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NmbrPDS';
Proc glimmix; class trt; model  TtlDurPD=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurPD';
Proc glimmix; class trt; model  TtlDurPDL=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurPDL';
Proc glimmix; class trt; model  TtlDurPDS=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurPDS';
Proc glimmix; class trt; model  NumPDS1=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumPDS1';
Proc glimmix; class trt; model  NumPDS2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumPDS2';
Proc glimmix; class trt; model  NumPDS3=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumPDS3';
Proc glimmix; class trt; model  NumPDS4=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumPDS4';
Proc glimmix; class trt; model  NumPDS5=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumPDS5';
Proc glimmix; class trt; model  NumPDS6=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumPDS6';
Proc glimmix; class trt; model  MnDurPdS1=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of MnDurPdS1';
Proc glimmix; class trt; model  MnDurPdS2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of MnDurPdS2';
Proc glimmix; class trt; model  MnDurPdS3=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of MnDurPdS3';
Proc glimmix; class trt; model  MnDurPdS4=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of MnDurPdS4';
Proc glimmix; class trt; model  MnDurPdS5=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of MnDurPdS5';
Proc glimmix; class trt; model  MnDurPdS6=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of MnDurPdS6';
Proc glimmix; class trt; model  TmFrstCFrstPD=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TmFrstCFrstPD';
Proc glimmix; class trt; model  TmEndLstPDEndPrb=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TmEndLstPDEndPrb';
* meanpd meanPDL meanPDS meanNPdPrb NmbrPD NmbrPDL NmbrPDS TtlDurPD TtlDurPDL TtlDurPDS NumPDS1 NumPDS2
 NumPDS3 NumPDS4 NumPDS5 NumPDS6 MnDurPdS1 MnDurPdS2 MnDurPdS3 MnDurPdS4 MnDurPdS5 MnDurPdS6 TmFrstCFrstPD 
 TmEndLstPDEndPrb;
*******************************************************************;
********      Variables for F                         *************;
*******************************************************************;
if transform=1 then do;
						numf=sqrt(numf);									ttlduff=log(ttldurf+cnstnt);
						meanf=log(meanf+cnstnt);							ttldurf1=log(ttldurf1+cnstnt);
						ttldurf2=log(ttldurf2+cnstnt);						ttldurf3=log(ttldurf3+cnstnt);
						ttldurf4=log(ttldurf4+cnstnt);						ttldurf5=log(ttldurf5+cnstnt);
						ttldurf6=log(ttldurf6+cnstnt);						numf1=sqrt(numf1);
						numf2=sqrt(numf2);									numf3=sqrt(numf3);
						numf4=sqrt(numf4);									numf5=sqrt(numf5);
						numf6=sqrt(numf6);
						*PrcntPrbF = arsin(sqrt(PrcntPrbF/100));			PrcntPrbF=log((PrcntPrbF/100)/(1-(PrcntPrbF/100)));
					end;
Proc glimmix plots=residualpanel; class trt; model  NumF=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumF';
Proc glimmix plots=residualpanel; class trt; model  TtlDurF=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurF';
Proc glimmix plots=residualpanel; class trt; model  meanF=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of meanF';
Proc glimmix plots=residualpanel; class trt; model  TtlDurF1=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurF1';
Proc glimmix plots=residualpanel; class trt; model  TtlDurF2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurF2';
Proc glimmix plots=residualpanel; class trt; model  TtlDurF3=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurF3';
Proc glimmix plots=residualpanel; class trt; model  TtlDurF4=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurF4';
Proc glimmix plots=residualpanel; class trt; model  TtlDurF5=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurF5';
Proc glimmix plots=residualpanel; class trt; model  TtlDurF6=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurF6';
Proc glimmix plots=residualpanel; class trt; model  NumF1=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumF1';
Proc glimmix plots=residualpanel; class trt; model  NumF2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumF2';
Proc glimmix plots=residualpanel; class trt; model  NumF3=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumF3';
Proc glimmix plots=residualpanel; class trt; model  NumF4=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumF4';
Proc glimmix plots=residualpanel; class trt; model  NumF5=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumF5';
Proc glimmix plots=residualpanel; class trt; model  NumF6=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumF6';
Proc glimmix plots=residualpanel; class trt; model  PrcntPrbF=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of PrcntPrbF';
* NumF TtlDurF meanF TtlDurF1 TtlDurF2 TtlDurF3 TtlDurF4 TtlDurF5 TtlDurF6 NumF1 NumF2 NumF3 NumF4 NumF5 NumF6 PrcntPrbF;

*******************************************************************;
********      Variables for G             *************************;
*******************************************************************;
if transform=1 then do;
						NumG=sqrt(NumG);									DurG=log(DurG+cnstnt);
						MeanG=log(MeanG+cnstnt);							sdG=log(sdG);
						CtoFrstG=log(CtoFrstG+cnstnt);						DurNnprbBfrFrstG=log(DurNnprbBfrFrstG+cnstnt);
						meanNGPrb=sqrt(meanNGPrb);							TmFrmFrstPrbFrstG=log(TmFrmFrstPrbFrstG+cnstnt);
						TmBegPrbFrstG=log(TmBegPrbFrstG+cnstnt);			NumPrbsAftrFrstG=sqrt(NumPrbsAftrFrstG);
						NmbrShrtPrbAftrFrstG=sqrt(NmbrShrtPrbAftrFrstG);	NumLngG=sqrt(NumLngG);
						TmFrstSusGFrstPrb=log(TmFrstSusGFrstPrb+cnstnt);
						*PrcntPrbG = arsin(sqrt(PrcntPrbG/100));			PrcntPrbG=log((PrcntPrbG/100)/(1-(PrcntPrbF/100)));
					end;
Proc glimmix plots=residualpanel; class trt; model  NumG=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumG';
Proc glimmix plots=residualpanel; class trt; model  DurG=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of DurG';
Proc glimmix plots=residualpanel; class trt; model  MeanG=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of MeanG';
Proc glimmix plots=residualpanel; class trt; model  sdG=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of sdG';
Proc glimmix plots=residualpanel; class trt; model  CtoFrstG=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of CtoFrstG';
Proc glimmix plots=residualpanel; class trt; model  DurNnprbBfrFrstG=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of DurNnprbBfrFrstG';
Proc glimmix plots=residualpanel; class trt; model  meanNGPrb=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of meanNGPrb';
Proc glimmix plots=residualpanel; class trt; model  TmFrmFrstPrbFrstG=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TmFrmFrstPrbFrstG';
Proc glimmix plots=residualpanel; class trt; model  TmBegPrbFrstG=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TmBegPrbFrstG';
Proc glimmix plots=residualpanel; class trt; model  NumPrbsAftrFrstG=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumPrbsAftrFrstG';
Proc glimmix plots=residualpanel; class trt; model  NmbrShrtPrbAftrFrstG=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NmbrShrtPrbAftrFrstG';
Proc glimmix plots=residualpanel; class trt; model  NumLngG=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumLngG';
Proc glimmix plots=residualpanel; class trt; model  TmFrstSusGFrstPrb=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TmFrstSusGFrstPrb';
Proc glimmix plots=residualpanel; class trt; model  PrcntPrbG=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of PrcntPrbG';
* NumG DurG MeanG sdG CtoFrstG DurNnprbBfrFrstG meanNGPrb TmFrmFrstPrbFrstG TmBegPrbFrstG NumPrbsAftrFrstG
 NmbrShrtPrbAftrFrstG NumLngG TmFrstSusGFrstPrb PrcntPrbG;

*******************************************************************;
********      Variables for E or E1       *************************;
*******************************************************************;
if transform=1 then do;
						NumE1=sqrt(NumE1);										TtlDurE1=log(TtlDurE1+cnstnt);
						MnDurE1=log(MnDurE1+cnstnt);							sdE1=log(sdE1);
						CtoFrstE1=log(CtoFrstE1+cnstnt);						TmFrmFrstPrbFrstE=log(TmFrmFrstPrbFrstE+cnstnt);
						TmBegPrbFrstE=log(TmBegPrbFrstE+cnstnt);				NumPrbsAftrFrstE=log(NumPrbsAftrFrstE+cnstnt);
						NmbrShrtPrbAftrFrstE=log(NmbrShrtPrbAftrFrstE+cnstnt);	NumLngE1BfrE2=sqrt(NumLngE1BfrE2);
						NumSnglE1=sqrt(NumSnglE1);								DurFirstE=log(DurFirstE+cnstnt);
						*CntrbE1toE=log((CntrbE1toE/100)/(1-(CntrbE1toE/100)));	CntrbE1toE = arsin(sqrt(CntrbE1toE/100));
						DurE1FlwdFrstSusE2=log(DurE1FlwdFrstSusE2+cnstnt);
						DurE1FlldFrstE2=log(DurE1FlldFrstE2+cnstnt);			TtlDurE1FlldSusE2=log(TtlDurE1FlldSusE2+cnstnt);
						TtlDurE1FlldE2=log(TtlDurE1FlldE2+cnstnt);				TtlDurSnglE1=log(TtlDurSnglE1+cnstnt);
						*PrcntPrbE1 = arsin(sqrt(PrcntPrbE1/100));				PrcntPrbE1=log((PrcntPrbE1/100)/(1-(PrcntPrbE1/100)));
					end;

Proc glimmix plots=residualpanel; class trt; model  NumE1=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumE1';
Proc glimmix plots=residualpanel; class trt; model  TtlDurE1=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurE1';
Proc glimmix plots=residualpanel; class trt; model  MnDurE1=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of MnDurE1';
Proc glimmix plots=residualpanel; class trt; model  sdE1=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of sdE1';
Proc glimmix plots=residualpanel; class trt; model  CtoFrstE1=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of CtoFrstE1';
Proc glimmix plots=residualpanel; class trt; model  TmFrmFrstPrbFrstE=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TmFrmFrstPrbFrstE';
Proc glimmix plots=residualpanel; class trt; model  TmBegPrbFrstE=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TmBegPrbFrstE';
Proc glimmix plots=residualpanel; class trt; model  NumPrbsAftrFrstE=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumPrbsAftrFrstE';
Proc glimmix plots=residualpanel; class trt; model  NmbrShrtPrbAftrFrstE=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NmbrShrtPrbAftrFrstE';
Proc glimmix plots=residualpanel; class trt; model  NumLngE1BfrE2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumLngE1BfrE2';
Proc glimmix plots=residualpanel; class trt; model  NumSnglE1=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumSnglE1';
Proc glimmix plots=residualpanel; class trt; model  DurFirstE=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of DurFirstE';
Proc glimmix plots=residualpanel; class trt; model  CntrbE1toE=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of CntrbE1toE';
Proc glimmix plots=residualpanel; class trt; model  DurE1FlwdFrstSusE2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of DurE1FlwdFrstSusE2';
Proc glimmix plots=residualpanel; class trt; model  DurE1FlldFrstE2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of DurE1FlldFrstE2';
Proc glimmix plots=residualpanel; class trt; model  TtlDurE1FlldSusE2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurE1FlldSusE2';
Proc glimmix plots=residualpanel; class trt; model  TtlDurE1FlldE2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurE1FlldE2';
Proc glimmix plots=residualpanel; class trt; model  TtlDurSnglE1=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurSnglE1';
Proc glimmix plots=residualpanel; class trt; model  PrcntPrbE1=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of PrcntPrbE1';


*******************************************************************;
********      Variables for E2            *************************;
*******************************************************************;
if transform=1 then do;
						NumE2=sqrt(NumE2);										NumLngE2=sqrt(NumLngE2);
						TtlDurE2=log(TtlDurE2+cnstnt);							MnDurE2=log(MnDurE2+cnstnt);
						sdE2=log(sdE2);											TmFrstSusE2FrstPrb=log(TmFrstSusE2FrstPrb+cnstnt);
						TmFrstSusE2StrtPrb=log(TmFrstSusE2StrtPrb+cnstnt);		TmFrstE2FrmFrstPrb=log(TmFrstE2FrmFrstPrb+cnstnt);
						TmFrstE2FrmPrbStrt=log(TmFrstE2FrmPrbStrt+cnstnt);		MaxE2=log(maxE2);
						*PrcntPrbE2 = arsin(sqrt(PrcntPrbe2/100));				PrcntPrbE1=log((PrcntPrbG/100)/(1-(PrcntPrbF/100)));
						PrcntE2SusE2=arsin(sqrt(PrcntE2SusE2/100));
					end;

Proc glimmix plots=residualpanel; class trt; model  NumE2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumE2';
Proc glimmix plots=residualpanel; class trt; model  NumLngE2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of NumLngE2';
Proc glimmix plots=residualpanel; class trt; model  TtlDurE2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurE2';
Proc glimmix plots=residualpanel; class trt; model  MnDurE2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of MnDurE2';
Proc glimmix plots=residualpanel; class trt; model  sdE2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of sdE2';
Proc glimmix plots=residualpanel; class trt; model  TmFrstSusE2FrstPrb=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TmFrstSusE2FrstPrb';
Proc glimmix plots=residualpanel; class trt; model  TmFrstSusE2StrtPrb=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TmFrstSusE2StrtPrb';
*Proc glimmix; *class trt; *model  TmFrstE2StrtEPG=trt; *lsmeans trt/pdiff lines adjust=tukey; *title 'ANOVA & LSD of TmFrstE2StrtEPG';
Proc glimmix plots=residualpanel; class trt; model  TmFrstE2FrmFrstPrb=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TmFrstE2FrmFrstPrb';
Proc glimmix plots=residualpanel; class trt; model  TmFrstE2FrmPrbStrt=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TmFrstE2FrmPrbStrt';
Proc glimmix plots=residualpanel; class trt; model  TmLstE2EndRcrd=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TmLstE2EndRcrd';
Proc glimmix plots=residualpanel; class trt; model  maxE2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of maxE2';
Proc glimmix plots=residualpanel; class trt; model  PrcntPrbE2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of PrcntPrbE2';
Proc glimmix plots=residualpanel; class trt; model  PrcntE2SusE2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of PrcntE2SusE2';

*******************************************************************;
********      Variables for E1+E2         *************************;
*******************************************************************;
if transform=1 then do;
						PotE2Indx = arsin(sqrt(PotE2Indx/100));					TtlDurE=log(ttldure+cnstnt);
						TtlDurE1FllwdE2PlsE2=log(TtlDurE1FllwdE2PlsE2+cnstnt);	TotDurNnPhlPhs=log(TotDurNnPhlPhs+cnstnt);
						TmFrstSusE2=log(TmFrstSusE2+cnstnt);
					end;
Proc glimmix plots=residualpanel; class trt; model  PotE2Indx=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of PotE2Indx';
Proc glimmix plots=residualpanel; class trt; model  TtlDurE=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurE';
Proc glimmix plots=residualpanel; class trt; model  TtlDurE1FllwdE2PlsE2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TtlDurE1FllwdE2PlsE2';
Proc glimmix plots=residualpanel; class trt; model  TotDurNnPhlPhs=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TotDurNnPhlPhs';*Duration of recording less E1 and E2;
Proc glimmix plots=residualpanel; class trt; model  TmFrstSusE2=trt; lsmeans trt/pdiff lines adjust=tukey; title 'ANOVA & LSD of TmFrstSusE2';

/*
Data Ebert; Set Ebert;
proc discrim crosslisterr crossvalidate distance method=normal;
class trt;
var CtoFrstE1 TtlPrbTm  ;
*NumPrbs MnPrbs  DurFrstPrb DurScndPrb  NumNP  MnDurNP  
 DurScndZ NmbrC  MnDurC  NmbrShrtC 
 meanpd  meanNPdPrb NmbrPD    TmFrstCFrstPD 
 NumE1  MnDurE1  TmFrmFrstPrbFrstE TmBegPrbFrstE NumPrbsAftrFrstE NmbrShrtPrbAftrFrstE NumLngE1BfrE2 
NumSnglE1 DurFirstE CntrbE1toE NumE2 NumLngE2 PrcntPrbE2 TtlDurE TotDurNnPhlPhs ;


Data Ebert; Set Ebert;
proc stepdisc method=stepwise sle=.1 sls=.06 ;
class trt;
var CtoFrstE1 
NumPrbs MnPrbs DurFrstPrb DurScndPrb TtlPrbTm NumNP  MnDurNP NmbrC  MnDurC  NmbrShrtC 
 meanpd  meanNPdPrb NmbrPD    TmFrstCFrstPD 
  PrcntPrbF  
NumE1  MnDurE1  TmFrmFrstPrbFrstE TmBegPrbFrstE NumPrbsAftrFrstE NmbrShrtPrbAftrFrstE NumLngE1BfrE2 
NumSnglE1 DurFirstE CntrbE1toE NumE2 NumLngE2 PrcntPrbE2 TtlDurE TotDurNnPhlPhs ;
*/;

*The following line can be used to export the equivalent of the Ebert worksheet output into a text file. 
*Read text file using Excel, as delimited file with commas.;
*proc export data=Ebert outfile='C:\Users\tebert\Desktop\EBERT 1 0 1\Ebert1.txt' dbms=csv replace;

run;
 ods results;
 ods html close;
run;
quit;
