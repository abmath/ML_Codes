DATA TESTA;
SET TESTA;
SKU=TRANWRD(sku,"_V","_P");
RUN;

options mprint ;


proc freq data=testA;
tables SKU/list out=TESTB;
RUN;

data testb;
set testb;
N=_N_;
RUN;

DATA _NULL_;
SET TestB;
call symput('sku'||LEFT(N), TRIM(SKU));
RUN;

proc sql;
select count(*) INTO:SKUCOUNT
FROM TESTB;
QUIT;

%put &skucount;

/*Give a dummy library where multiple datasets can be created and then manually delete from the folder post program run*/
/*RUN TILL HERE FOR FIRST RUN TO GET COUNT OF SKUs*/

libname dummy "Z:\Dummy";

%macro abc2;

DATA dummy.reg_out&i(DROP=_MODEL_ _TYPE_ _DEPVAR_ _RMSE_ Intercept Volume _ADJRSQ_ _RSQ_ _MSE_ _SSE_ _EDF_ _P_ _IN_ Q1 Q2 Q3 holiday our volume);
SET dummy.reg_out&i;
IF _N_=1;
RUN;

proc transpose data=dummy.reg_out&i out=dummy.trans&i;
run;

data dummy.trans&i;
set dummy.trans&i;
where col1 is not null;
run;


proc sort data=trans&i;
by col1;
run;

data trans&i;
set trans&i;
where col1 is not null;
run;

data trans&i (rename=(_NAME_=VAR) drop=parm pvalue);
set trans&i;
if _n_ > 1;
run;

proc transpose data=trans&i out=dummy.transp&i;
var VAR;
run;

data dummy.transp&i(drop=_name_ _label_);
set dummy.transp&i;
run;

proc sql;
  select name into :varstr2 separated by ','
  from dictionary.columns
  where libname = "DUMMY" and
        memname = "TRANSP&i";
quit;
                                  
data makenew;
  length newvar newvar2 $1000;
  set dummy.transp&i;
  newvar = catt(&varstr2);
  newvar2 = catx(' ',&varstr2);
run;

data _null_;
set makenew;
call symput('model', newvar2);
run;

%put &model;

proc reg data=dummy.&&sku&i noprint outest=dummy.reg_out&i rsquare sse mse adjrsq tableout;
model volume= &model Q1 Q2 Q3 Holiday our/selection=stepwise sle=0.2 sls=0.2 maxstep=1000000;
output out=z.ParameterEstimates&i	 p=pred r=resid;
run;quit;


data dummy.regout&i(drop=_MODEL_ _TYPE_ _DEPVAR_ _RMSE_ Intercept Volume _ADJRSQ_ _RSQ_ _MSE_ _SSE_ _EDF_ _P_ _IN_ Q1 Q2 Q3 holiday our);
set dummy.reg_out&i;
if _n_ = 1;
run;

proc transpose data=dummy.regout&i out=qwe&i;;
run;

data qwe&i(drop=_LABEL_ rename=(_name_=var col1=parm col2=pvalue));
set qwe&i;
run;

proc sort data=qwe&i;
by parm;
run;

data qwe&i;
set qwe&i;
where parm is not null;
run;

%test;

%mend;
/*End of ABC*/

/*Start of test macro*/
%macro test;
proc sql;
select COUNT(*) into : COUNT from qwe&i
WHEre parm < 0
;quit;

%if &count > 0 %then %do;
%abc2;
%end;
/*%else %do;*/
/*DATA A;*/
/*A="DONE";*/
/*RUN;*/
/*proc print data=A;*/
/*RUN;*/
/*%end;*/

%mend;


%macro abc;
%do i=1 %to &skucount;
%put &&SKU&i;

DATA dummy.&&SKU&i(DROP= Year WEEK SKU RENAME=(_&&SKU&i=OUR));
SET TESTA;
WHERE SKU in ("&&SKU&i");
RUN;

proc contents data=dummy.&&SKU&i OUT=dummy.abc&i;
RUN;

data dummy.abc&i(KEEP=NAME);
set dummy.abc&i;
where name not in ("Volume");
RUN;

proc transpose data=dummy.abc&i out=dummy.asd&i;
var name;
run;

data dummy.asd&i(drop= _name_ _label_);
set dummy.asd&i;
run;

proc sql;
  select name into :varstr2 separated by ','
  from dictionary.columns
  where libname = "DUMMY" and
        memname = "ASD&i";
quit;
                                  
data makenew&i;
  length newvar newvar2 $1000;
  set dummy.ASD&i;
  newvar = catt(&varstr2);
  newvar2 = catx(' ',&varstr2);
run;

/*data _null_;*/
/*set makenew;*/
/*call symput('model'||&i, newvar2);*/
/*run;*/


%end;
%mend;

%abc;

%macro qwe;
DATA modelvar;
SET 
%do i=1 %to &skucount;
makenew&i
%end;
;RUN;

DATA modelvar;
SET modelvar;
N=_N_;
RUN;

DATA _NULL_;
SET modelvar;
CALL SYMPUT('model'||LEFT(N), newvar2);
RUN;

%do i=1 %to &SKUCOUNT;
%PUT &&MODEL&i;
%END;

%model;

%output;
%mend;


/*%macro model;*/
%macro model;
%do i=1 %to &skucount;

proc reg data=dummy.&&sku&i noprint outest=dummy.reg_out&i rsquare sse mse adjrsq tableout;
model volume =&&model&i
/selection=stepwise sle=0.2 sls=0.2 maxstep=1000000;
output out=dummy.ParameterEstimates&i	 p=pred r=resid;
run;quit;

DATA dummy.reg_outa&i(DROP=_MODEL_ _TYPE_ _DEPVAR_ _RMSE_ Intercept Volume _ADJRSQ_ _RSQ_ _MSE_ _SSE_ _EDF_ _P_ _IN_ Q1 Q2 Q3 holiday our volume);
SET dummy.reg_out&i;
IF _N_=1;
RUN;

proc transpose data=dummy.reg_outa&i out=dummy.transa&i;
run;

data dummy.transa&i;
set dummy.transa&i;
where col1 is not null;
run;

proc sql;
select count(*) INTO: NEGCOUNT
FROM DUMMY.transa&i
WHERE COL1 < 0
;
QUIT;

%if &negcount >= 0 %then %do;
%abc2;
%end;

/*%output;*/
%end;
%mend;

/*RUN TILL HERE FOR SECOND RUN TO CALCULATE REGRESSION FITS FOR ALL SKUs WITH ASSUMPTION THAT SELF SKU PRICING HAS TO BE NEGATIVE CORRELATION*/
/*AND CORRELATIONS WITH ALL OTHER SKU PRICES HAVE TO BE NEGATIVE*/

%qwe;

/*RUN MARCRO QWE, IF THERE ARE NO ERRORS, RUN THE FOLLOWING MACRO OUTPUT TO GET COMPLETE RESULT WHICH CAN BE EXPORTED*/

%macro output;
%do i=1 %to &SKUCOUNT;

DATA dummy.REG_OUT&i;
SET dummy.REG_OUT&i;
SKU="&&SKU&i";
RUN;
%end;


DATA WORK.OUTPUT;
SET
%do i=1 %to &skucount;
dummy.Reg_out&i
%end;
;
RUN;

PROC PRINT DATA=WORK.OUTPUT;
RUN;

%mend;
