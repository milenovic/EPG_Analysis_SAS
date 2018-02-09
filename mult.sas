/*********************************************************************************************/
/*                                                                                           */
/*  This macro finds a letters display for all pairwise comparisons                          */
/*  using the insert-and-absorb algorithm with sweeping                                      */
/*  It uses output generated from the MIXED, GLIMMIX or GENMOD procedures                    */
/*                                                                                           */
/*  The method is based on                                                                   */
/*                                                                                           */
/*  Piepho, H.P. (2004): An algorithm for a letter-based representation of all-pairwise      */
/*  comparisons. Journal of Computational and Graphical Statistics 13, 456-466.              */
/*                                                                                           */
/* Usage of the macro is described in detail in:                                             */
/*                                                                                           */
/* Piepho, H.P. (2012): A SAS macro for generating letter displays of pairwise mean          */
/* comparisons. Communications in Biometry and Crop Science 7, 4-13.                         */
/*                                                                                           */
/* The paper also compares the macro to the LINES option and SLCICE statement of GLIMMIX     */
/*                                                                                           */ 
/* Requirements:                                                                             */
/*                                                                                           */
/*  SAS/IML, SAS/STAT                                                                        */
/*                                                                                           */
/*  Dataset diffs with the following variables:                                              */
/*     p = adjusted p-value                                                                  */
/*  Comparisons sorted by i=1 to t-1 and j=i+1 to t, where t is the number of treatments     */
/*  The ODS diffs table automatically produces this variable in the required order           */
/*  If adjusted p-values of the MIXED ODS diffs are to be used, relabeling is necessary,     */
/*  since PROBT is the p-value for an ordinary t-test                                        */
/*                                                                                           */
/* Dataset lsmeans with the following variables:                                             */
/*      - a treatment label                                                                  */
/*      - estimate (mean or other statistic to be compared)                                  */
/*                                                                                           */
/* To generate these two files from GLIMMIX, MIXED or GENMOD, simple use this statement:     */
/* ODS output lsmeans=lsmeans diffs=diffs;                                                   */
/*                                                                                           */
/* The LSMEANS statement should be used with only one model term at a time. Do not use       */
/* multiple terms or multiple LSMEANS statements. %MULT can process only one term at a time. */
/* If you need mean comparisons for multiple terms, you need to run MIXED or GLIMMIX several */
/* times, or you need to subset the diffs and lsmeans datasets accordingly                   */
/*                                                                                           */
/* trt= specifies the treatment factor for which means are to be compared.                   */
/*      (Only a single treatment factor is allowed)                                          */
/*                                                                                           */
/* For factorial experiments, you can slice the comparision of means. For example if you     */
/* have A*B means, and you want to compare levels of A separately for each level of B,       */
/* you can slice them by levels of B using trt=A and the by=B obtion                         */
/*                                                                                           */
/* Up to three by variables are allowed, so you can analyse up to 4-factorial experiments    */
/*                                                                                           */
/* by = specifies first  by-variable.                                                        */
/* by2= specifies second by-variable.                                                        */
/* by3= specifies third  by-variable.                                                        */
/*                                                                                           */
/* alpha= specifies the type I error rate (default alpha=0.05)                               */
/*                                                                                           */
/* p= specifies the variable containing the p-values; default: p = probt, the p-value of     */
/*    pairwise t-tests as generated by the LSMEANS statement                                 */
/*                                                                                           */
/* descending=0 smallest mean will get the letter a, etc.                                    */
/*           =1 largest mean will get the letter a, etc. (default)                           */
/*                                                                                           */
/* Please note that in a factorial experiment you cannot use trt=A*B, because only           */
/* a single factor is allowed in the trt= option. The rationale for this restriction         */
/* is that in a factorial experiment, it is not usually helpful to perform all pairwise      */
/* comparisons among A*B means, but you want to slice comparisons by levels of A and/or B.   */
/* This can be implemented in the macro using trt=A, by=B and trt=B, by=A                    */
/*                                                                                           */
/* The maximum number of letter is restricted to 26, the ordinary alphabet                   */
/* In my experience it hardly ever makes sense to use the letter display when many           */
/* letters are needed, because the display becomes messy. This is why I have not made an     */
/* effort to extend the letter set beyond the size of 26.                                    */
/*                                                                                           */
/* The letter display is also saved in to a SAS dataset "letters"                            */
/*                                                                                           */
/*                                                                                           */
/* First version 3 March 2002                                                                */
/* 7 February 2003: added by and level options                                               */
/* 26 March 2003 modified by options                                                         */
/* Sorting of letters and check for columns of all zeros after sweeping added 26 Jan 2009    */
/* inserted 16 FEB 2011: Compute min, max and mean s.e.d. and l.s.d.                         */
/* 6 February 2012 added descending option                                                   */
/* 8 February 2012 added more convenient mode of slicing                                     */
/* 1 December 2012 LSD computed at &alpha                                                    */
/* 10 January 2013 Write letter display into SAS dataset "letters"                           */
/*                                                                                           */
/* Written by: Hans-Peter Piepho (piepho@uni-hohenheim.de)                                   */
/*********************************************************************************************/

%macro mult(trt=, par=., by=., by2=., by3=., alpha=0.05, p=Adjp, descending=1);

data letters;
run;

%if &by=. %then %do;
  run;
  %mult_inner(trt=&trt, alpha=&alpha, p=&p, descending=&descending);
%end;

%else %do; 
  %if &by2=. %then %do; /*by2=.*/
    proc sort data=lsmeans out=lsmeans;
	  by &by;
	run;
    proc means data=lsmeans noprint;
      var estimate;
      by &by;
      output out=bymeans mean=;
    run;

    /*get size of dataset*/
    data q;
      i=1;
      set bymeans point=i nobs=n;
      call symput('n',trim(left(n)));
	  stop;
    run;

    %do i=1 %to &n;

      data q;
	    ii=&i;
        set bymeans point=ii;
	    level=&by;
        call symput('bylevel',trim(left(level)));
	    stop;
      run;

	  %mult_inner(trt=&trt, by=&by, level="&bylevel", alpha=&alpha, p=&p, descending=&descending);

    %end;
  %end;
  %else %do; /*by2 ne .*/
    %if &by3=. %then %do;
      proc sort data=lsmeans out=lsmeans;
	    by &by &by2;
	  run;
      proc means data=lsmeans noprint;
        var estimate;
        by &by &by2;
        output out=bymeans mean=;
      run;

      /*get size of dataset*/
      data q;
        i=1;
        set bymeans point=i nobs=n;
        call symput('n',trim(left(n)));
	    stop;
      run;

      %do i=1 %to &n;

        data q;
	      ii=&i;
          set bymeans point=ii;
	      level=&by;
	      level2=&by2;
          call symput('bylevel',trim(left(level)));
          call symput('bylevel2',trim(left(level2)));
	      stop;
        run;

	    %mult_inner(trt=&trt, by=&by, by2=&by2, level="&bylevel", level2="&bylevel2", alpha=&alpha, p=&p, descending=&descending);

      %end;
    %end;
    %else %do;
      proc sort data=lsmeans out=lsmeans;
	    by &by &by2 &by3;
	  run;
      proc means data=lsmeans noprint;
        var estimate;
        by &by &by2 &by3;
        output out=bymeans mean=;
      run;

      /*get size of dataset*/
      data q;
        i=1;
        set bymeans point=i nobs=n;
        call symput('n',trim(left(n)));
	    stop;
      run;

      %do i=1 %to &n;

        data q;
	      ii=&i;
          set bymeans point=ii;
	      level=&by;
	      level2=&by2;
	      level3=&by3;
          call symput('bylevel',trim(left(level)));
          call symput('bylevel2',trim(left(level2)));
          call symput('bylevel3',trim(left(level3)));
	      stop;
        run;

	    %mult_inner(trt=&trt, by=&by, by2=&by2, by3=&by3, level="&bylevel", level2="&bylevel2", level3="&bylevel3", alpha=&alpha, p=&p, descending=&descending);

      %end;
    %end; 
  %end;
%end;

data letters;
set letters;
if _N_=1 then delete;
run;

%mend;

%macro mult_inner(trt=, by=., by2=., by3=., level=., level2=., level3=., alpha=0.05, p=Adjp, descending=1);


data diffs0;
set diffs;
%if (&by ne .) %then %do;
  if &by=&level;
  if _&by=&level;
%end;
%if (&by2 ne .) %then %do;
  if &by2=&level2;
  if _&by2=&level2;
%end;
%if (&by3 ne .) %then %do;
  if &by3=&level3;
  if _&by3=&level3;
%end;


data lsmeans0;
set lsmeans;
%if (&by ne .) %then %do;
  if &by=&level;
%end;
%if (&by2 ne .) %then %do;
  if &by2=&level2;
%end;
%if (&by3 ne .) %then %do;
  if &by3=&level3;
%end;

proc sort data=diffs0 out=diffs0;
by &trt _&trt;

proc sort data=lsmeans0 out=lsmeans0;
by &trt;
/**************end of added Feb 7, 2003*****/

title 'Letter display';
proc iml;
use diffs0;
read all var {&p} into p;

use lsmeans0;
read all var {&trt} into label;
read all var {parameter} into param;
read all var {estimate} into est;

t=nrow(label);
count=0;
c=j(1,t,0);
do i=1 to t-1;
  do j= i+1 to t;
    count=count+1;
    if p[count]<&alpha then do;
	  done='no';
	  k=1;
	  do while(done='no');
	    n=nrow(c);
		found='no';
        if c[k,i]=0 then do;
   	      if c[k,j]=0 then do;
		    c1=c[k,];
		    c1[i]=1;
		    c2=c[k,];
		    c2[j]=1;
			c[k,i]=1;
			found='yes';
		  end;
        end;
		if found='yes' then do;
		  /*check if either c1 or c2 is redundant*/
		  m=nrow(c);
		  contain1=0;
		  contain2=0;
		  do w=1 to m;
		    check1=c1-c[w,];
		    min1=min(check1);
			if w=k then min1=-1;
			if min1>-1 then contain1=1; /*c1 is contained*/
		    check2=c2-c[w,];
		    min2=min(check2);
			if min2>-1 then contain2=1; /*c2 is contained*/  
		  end;
		  if contain1=1 then do;
		    free c_neu;
			do w=1 to m;
			  if abs(w-k)>0 then c_neu=c_neu//c[w,];
			end;
			c=c_neu;
		  end;
		  if contain2=0 then c=c//c2;
		  k=0;
		end;
		k=k+1;
		if k>n then done='yes';  
	  end;
	end;
/********************/

  end;
end;

/*clear superfluous letters*/

n=nrow(c);
c=c`;     

if n>26 then do;
  print 'W A R N I N G !';
  print 'The letter display would require more than 26 letters.';
  print '%MULT can only produce letter displays with up to 26 letters, ';
  print 'so no display will be produces here.';
end;
else do;  /*need <=26 letters*/

L='a'//'b'//'c'//'d'//'e'//'f'//'g'//'h'//'i'//'j'//'k'//'l'//'m'//'n'//'o'//'p'//'q'//'r'//'s'//'t'//'u'//'v'//'w'//'x'//'y'//'z';

g=j(t,n,'.');
do j=1 to n;
  do i=1 to t;
    if c[i,j]=0 then g[i,j]=L[j];
  end;
end;

do j=1 to n;
  started=1;
  do i=1 to t;
    if c[i,j]=0 then do;
	  covered=1;
	  if started=1 then do;
	    if sum(c[,j])=(t-1) then covered=0; 
	  end;
	  do ii=1 to t;
	    if abs(ii-i)>0 then do;
	      if c[ii,j]=0 then do;  /*i and ii not diff in col j*/
		    cov_ii=0;
		    do jj=1 to n;        /*do we find the same statement in any of the other columns?*/
			  if abs(j-jj)>0 then do;  /*jj is a different column*/
		        check=c[i,jj]+c[ii,jj]; if abs(check)<1e-10 then cov_ii=1; /*yes we do!*/
        	  end;
		    end;
            if cov_ii=0 then covered=0;
		  end;
		end;
	  end;
      if covered=1 then do; c[i,j]=1; end;
      started=0;
    end;
  end;
end;

/*26 JAN 2009: check if after sweeping a column has ones only. Delete this column*/

col=ncol(c);
row=nrow(c);
do i=1 to col;
  if sum(c[,i])<row then cc=cc||c[,i];
end;
c=cc;
n=ncol(c);

/*end inserted 26 JAN 2009*/


L='a'//'b'//'c'//'d'//'e'//'f'//'g'//'h'//'i'//'j'//'k'//'l'//'m'//'n'//'o'//'p'//'q'//'r'//'s'//'t'//'u'//'v'//'w'//'x'//'y'//'z';

g=j(t,n,' ');

/*14 MAR 2005: check which letter has smallest mean of lsmeans etc. Assign "a" to smallest mean etc.*/


order=j(n,1,0);
mean_o=order;
do j=1 to n;
  size=0;
  do i=1 to t;
    mean_o[j]=mean_o[j]+(c[i,j]-1)*est[i];
	size=size+(c[i,j]-1);
  end;
  mean_o[j]=mean_o[j]/size;
end;

r_mean_o=rank(mean_o);

/*end of check*/

do j=1 to n;
  do i=1 to t;
    if &descending=0 then do; if c[i,j]=0 then g[i,j]=L[r_mean_o[j]]; end;
    if &descending=1 then do; if c[i,j]=0 then g[i,j]=L[n-r_mean_o[j]+1]; end;
  end;
end;

/*permute letters 26 JAN 09*/

do i=1 to n;
  do j=1 to n;
    if &descending=0 then do; if r_mean_o[j]=i     then gg=gg||g[,j]; end;
    if &descending=1 then do; if r_mean_o[j]=n-i+1 then gg=gg||g[,j]; end;
  end;
end;
letters=j(nrow(gg),1,' ')||gg;

/*end permute letters*/

lsmean=est;
parameter=param;

by =symget('by');
level=symget('level');
by2 =symget('by2');
level2=symget('level2');
by3 =symget('by3');
level3=symget('level3');

trt=symget('trt');
check=j(1,3,1);
if by3='.' then check[3]=0;
if by2='.' then check[2]=0;
if by ='.' then check[1]=0;

/*added 10 JAN 2013: Export letters to SAS file*/
if check={0 0 0} then do; 
  print parameter trt label lsmean letters;
  create letters1 var {"parameter" "trt" "label" "lsmean"};
  append;
  create letters2 from letters;
  append from letters;
end;
if check={1 0 0} then do;
  print trt by level label lsmean letters;
  *print trt label lsmean letters;
  create letters1 var {"trt" "by" "level" "label" "lsmean"};
  append;
  create letters2 from letters;
  append from letters;
end;
if check={1 1 0} then do; 
  print trt by level by2 level2 Label lsmean letters;
  *print trt label lsmean letters;
  create letters1 var {"trt" "by" "level" "by2" "level2" "label" "lsmean"};
  append;
  create letters2 from letters;
  append from letters;
end;
if check={1 1 1} then do; 
  print trt by level by2 level2 by3 level3 Label lsmean letters;
  *print trt label lsmean letters;
  create letters1 var {"trt" "by" "level" "by2" "level2" "by3" "level3" "label" "lsmean"};
  append;
  create letters2 from letters;
  append from letters;
end;

end;  /*need <=26 letters*/

run;

data letters0;
merge letters1 letters2;
run;

data letters;
set letters letters0;
run;

data GroupsM;
set GroupsM letters;
run;

/*inserted 16 FEB 2011: Compute min, max and mean s.e.d. and l.s.d.*/
/*
data lsd;
set diffs0;
if DF=. then DF=1e3;  *assume that DF=infty;
t=tinv(1-&alpha/2, DF);
SED=stderr;
LSD=sed*t;
alpha=&alpha;

title "Standard errors of a difference (SED) and Least significant differences (LSD) at alpha=&alpha ";
proc means data=lsd min mean max;
var sed lsd;
run;

title '.';
*/
quit;

%mend mult_inner;
