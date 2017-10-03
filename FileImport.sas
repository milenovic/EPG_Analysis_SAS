Data one;
%let path = C:\Users\milan\Desktop\IITA Work\EPG Data\Cassava-Tomato\Annotations\Tomato\; *Path to the working folder with annotation files, no quotes!;
%let prefix = f; *Single letter treatment name a-z;
%let OutputFile = Tomato-CsvTom-CST; *Output file name, no quotes and extensions please!;

*********************************************************************
************   No user input required below this point   ************
*********************************************************************;

filename indata pipe "dir ""&path.*.ANA"" /b"; *look only for files with .ANA extension;
data file_list;
 length InFileName $30;
 infile indata truncover; /* infile statement for file names */
 input InFileName $30.; /* read the file names from the directory */
 call symput ('num_files',_n_); /* store the record number in a macro variable */
run; 
%macro fileread;

	%do j=1 %to &num_files;
		data _null_;
			set file_list;
			if _n_=&j;
			call symput ('filein',InFileName);
		run;
		data temp;
			infile "&path.&filein." dsd dlm='09'x truncover;
			input @;
			_infile_=compress(translate(_infile_,'.',','),'"');
			input waveform duration volts;
		run;

		%if &j=1 %then
			%do;
				data temp; set temp;
				insectno="&prefix.0&j.";

				retain holder1 in0;
				if in0 ne insectno then do; holder1=0; in0=insectno; dur=duration; end; 
				else dur=duration-holder1; holder1=duration;
				duration=dur; 
				drop holder1 in0 dur volts;
				run;

				data data_all; set temp; run;
			%end;
		%else
			%do;
				data temp; set temp;
					%if &j<10 %then
						%do;
							insectno="&prefix.0&j.";
						%end;
					%else
						%do;
							insectno="&prefix.&j.";
						%end;
			
				retain holder1 in0;
				if in0 ne insectno then do; holder1=0; in0=insectno; dur=duration; end; 
				else dur=duration-holder1; holder1=duration;
				duration=dur;
				drop holder1 in0 dur volts;
				run;

				data data_all; set data_all temp; run;
			%end;
	%end; /* end of do-loop with index j */
%mend fileread;
%fileread;

data data_all; set data_all;
if waveform=1 then SW="NP";
if waveform=2 then SW="C";
if waveform=3 then SW="E1e";
if waveform=4 then SW="E1";
if waveform=5 then SW="E2";
if waveform=6 then SW="F";
if waveform=7 then SW="G";
if waveform=8 then SW="PD";
if waveform=9 then SW="II2";
if waveform=10 then SW="II3";
if waveform=11 then SW="PDL";

Data data_all; set data_all; ins=insectno; wave=sw; dur=duration;
drop insectno waveform duration sw;
data data_all; set data_all; dur=round(dur,0.001);
run;
data fixedDur;
merge data_all data_all (firstobs=2 rename=(dur=new_dur)); drop ins wave dur;
run;
data data_all; set data_all; merge fixedDur;
if wave="" then delete;
drop dur;
rename new_dur=dur;
proc datasets lib=work nolist; delete one temp fixedDur;
proc export data=data_all outfile="&path.&OutputFile..csv" dbms=csv replace;
Data file_list; Set file_list; Code=cats("&prefix",_n_);
proc export data=file_list outfile="&path.FileList-&OutputFile..csv" dbms=csv replace;
run;
quit;
