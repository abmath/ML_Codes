{\rtf1\ansi\deff0{\fonttbl{\f0\fnil\fcharset0 Courier New;}}
{\*\generator Msftedit 5.41.21.2510;}\viewkind4\uc1\pard\lang1033\f0\fs22 LIBNAME TEST '\\\\LOC';\par
\par
/*Giving library reference to where datafiles are saved*/\par
\par
/*ID of MAPE and Order totals,*/\par
/*Save the entire Scenario output for a line from the Forecast table and run the commands below*/\par
PROC SQL;\par
CREATE TABLE DUMMY AS SELECT\par
DIM1, DIM2, DIM3,FORECAST_DATE, SUM(ORDER_QTY) AS ORDER_QTY, SUM(FORECAST_QTY) AS FORECAST_QTY\par
FROM DUMMY\par
GROUP BY DIM1, DIM2, DIM3, FORECAST_DATE\par
;\par
QUIT;\par
\par
PROC SQL;\par
CREATE TABLE ID AS SELECT\par
DIM1, DIM2, DIM3,\par
AVG(ABS(FORECAST_QTY-ORDER_QTY)/ORDER_QTY) AS MAPE,\par
SUM(ORDER_QTY) AS ORDERS\par
FROM DUMMY\par
GROUP BY DIM1, DIM2, DIM3\par
ORDER BY ORDERS DESC\par
;\par
QUIT;\par
\par
\par
\par
************************************ MODEL SELECTION ****************************************************************\par
\par
\par
\par
\par
/*Run from the below options statement to the comment of ' End of model selection'*/\par
options mprint symbolgen;\par
PROC FREQ DATA=TEST.DUMMY;\par
TABLES DIM1*DIM3*DIM2/OUT=ABC LIST;\par
RUN;\par
\par
PROC SQL;\par
SELECT COUNT(*) INTO:COMBOS FROM ABC;\par
QUIT;\par
\par
DATA _NULL_;\par
SET ABC;\par
CALL SYMPUT('DIM1'||COMPRESS(_N_),DIM1);\par
RUN;\par
\par
DATA _NULL_;\par
SET ABC;\par
CALL SYMPUT('DIM2'||COMPRESS(_N_),DIM2);\par
RUN;\par
\par
DATA _NULL_;\par
SET ABC;\par
CALL SYMPUT('DIM3'||COMPRESS(_N_),DIM3);\par
RUN;\par
\par
%PUT &DIM31;\par
\par
%MACRO MAIN;\par
\par
%DO J =1 %TO &COMBOS;\par
PROC SQL;\par
CREATE TABLE DATA&J AS \par
SELECT SUM(ORDER_QTY) AS ORDERS, DIM2, DIM3, FORECAST_DATE, DIM1\par
FROM TEST.DUMMY\par
WHERE DIM1 IN ("&&DIM1&J") AND DIM2 IN ("&&DIM2&J") AND DIM3 IN ("&&DIM3&J") AND FORECAST_DATE < '01DEC2015'D\par
GROUP BY FORECAST_DATE, DIM1,  DIM2, DIM3\par
ORDER BY FORECAST_DATE\par
;\par
QUIT;\par
\par
DATA DATA&J;\par
SET DATA&J;\par
SQRT=SQRT(ORDERS);\par
LN=LOG10(ORDERS);\par
/*WHERE PERIOD < '01DEC2015'D;*/\par
RUN;\par
\par
DATA DATA&J;\par
SET DATA&J;\par
IF LN=. THEN LN=0;\par
RUN;\par
%MODEL;\par
%END;\par
\par
DATA RESULT;\par
SET %DO J=1 %TO &COMBOS;\par
FINAL&J\par
%END;;RUN;\par
%MEND;\par
\par
%MACRO MODEL;\par
\par
DATA  _NULL_;\par
SET TEST.PDQ;\par
CALL SYMPUT('P'||COMPRESS(_N_),P);\par
CALL SYMPUT('D'||COMPRESS(_N_),D);\par
CALL SYMPUT('Q'||COMPRESS(_N_),Q);\par
RUN;\par
\par
PROC SQL;\par
SELECT COUNT(*) INTO:NOS FROM TEST.PDQ ;\par
QUIT;\par
%DO I = 1 %TO &NOS;\par
\par
PROC ARIMA DATA=DATA&J;\par
IDENTIFY VAR=ORDERS(&&D&i);\par
ESTIMATE P=&&P&I Q=&&Q&I;\par
FORECAST OUT=MODEL&I LEAD=5;\par
\par
PROC ARIMA DATA=DATA&J;\par
IDENTIFY VAR=SQRT(&&D&i);\par
ESTIMATE P=&&P&I Q=&&Q&I;\par
FORECAST OUT=MODELSQ&I LEAD=5;\par
\par
PROC ARIMA DATA=DATA&J;\par
IDENTIFY VAR=LN(&&D&i);\par
ESTIMATE P=&&P&I Q=&&Q&I;\par
FORECAST OUT=MODELog&I LEAD=5;\par
\par
PROC SQL;\par
SELECT AVG(ABS(10**LN-10**forecast)/10**LN) INTO: MAPELOG FROM MODELOG&I;QUIT;\par
\par
PROC SQL;\par
SELECT AVG(ABS(FORECAST-ORDERS)/ORDERS) INTO: MAPE FROM MODEL&I;QUIT;\par
\par
PROC SQL;\par
SELECT AVG(ABS(SQRT**2-FORECAST**2)/SQRT**2) INTO: MAPESQ FROM MODELSQ&I;QUIT;\par
\par
DATA OUT&I;\par
PARM='ARIMA';\par
P=&&P&I;\par
D=&&D&I;\par
Q=&&Q&I;\par
MAPE=&MAPE;\par
RUN;\par
\par
DATA OUTSQ&I;\par
PARM='SQRT';\par
P=&&p&i;\par
D=&&d&i;\par
Q=&&q&i;\par
MAPE=&MAPESQ;\par
RUN;\par
\par
DATA OUTLog&I;\par
PARM='log';\par
P=&&p&i;\par
D=&&d&i;\par
Q=&&q&i;\par
MAPE=&MAPElog;\par
RUN;\par
%end;\par
\par
PROC UCM DATA=DATA&J; \par
      id FORECAST_DATE interval = month; \par
      model ORDERS ; \par
      irregular ; \par
      level variance=0 noest ; \par
      slope variance=0 noest ; \par
      cycle plot=smooth ; \par
      estimate back=5 plot=(normal acf); \par
      forecast lead=10 back=0 plot=decomp out=UCM ;\par
   run ; \par
\par
PROC SQL;\par
SELECT AVG(ABS(FORECAST-ORDERS)/ORDERS) INTO: MAPEUCM FROM UCM;QUIT;\par
\par
%put &mapeucm;\par
\par
DATA UCMRES;\par
PARM='UCM';\par
MAPE=&MAPEUCM;\par
RUN;\par
\par
DATA FINALt&J;\par
SET %do i=1 %to &nos;\par
OUT&i OUTSQ&I OUTLOG&i\par
%end;UCMRES;\par
/*FORMAT MAPE PERCENT6.3;*/\par
RUN;\par
\par
%DO I=1 %TO &NOS;\par
PROC DELETE DATA=OUT&I;\par
RUN;\par
\par
PROC DELETE DATA=OUTLOG&I;\par
RUN;\par
\par
PROC DELETE DATA=OUTSQ&I;\par
RUN;\par
\par
PROC DELETE DATA=MODEL&I;\par
RUN;\par
\par
PROC DELETE DATA=MODELOG&I;\par
RUN;\par
\par
PROC DELETE DATA=MODELSQ&I;\par
RUN;\par
%END;\par
PROC  DELETE DATA=UCMRES;\par
RUN;\par
\par
PROC  DELETE DATA=UCM;\par
RUN;\par
\par
PROC SORT DATA=FINALT&J;\par
BY MAPE ;\par
RUN;\par
\par
data final&j;\par
set finalT&J;\par
IF _N_=1;\par
DIM1="&&DIM1&J";\par
DIM2="&&DIM2&J";\par
DIM3="&&DIM3&J";\par
/*FORMAT MAPE PERCENT6.3;*/\par
RUN;\par
\par
%MEND;\par
\par
%MAIN;\par
/*End of model selection*/\par
\par
\par
********************************************* FORECAST GENERATION ***************************************;\par
\par
/*RUN THE BELOW CODES TILL END OF FORECAST GENERATION */\par
\par
DATA _NULL_;\par
set RESULT;\par
CALL SYMPUT('PARM'||COMPRESS(_N_), PARM);\par
CALL SYMPUT('P'||COMPRESS(_N_), P);\par
CALL SYMPUT('D'||COMPRESS(_N_),D);\par
CALL SYMPUT('Q'||COMPRESS(_N_),Q);\par
CALL SYMPUT('DIM1'||COMPRESS(_N_),DIM1);\par
CALL SYMPUT('DIM2'||COMPRESS(_N_),DIM2);\par
CALL SYMPUT('DIM3'||COMPRESS(_N_), DIM3);\par
RUN;\par
\par
PROC SQL;\par
SELECT COUNT(*) INTO:MODELS FROM RESULT;\par
QUIT;\par
\par
%MACRO UCM;\par
PROC UCM DATA=DATA&I; \par
      id FORECAST_DATE interval = month; \par
      model ORDERS ; \par
      irregular ; \par
      level variance=0 noest ; \par
      slope variance=0 noest ; \par
      cycle plot=smooth ; \par
      estimate back=5 plot=(normal acf); \par
      forecast lead=10 back=0 plot=decomp out=MODEL_A&I ;\par
   run ; \par
\par
DATA MODEL_A&I;\par
SET MODEL_A&I;\par
DIM1="&&DIM1&I";\par
DIM2="&&DIM2&I";\par
DIM3="&&DIM3&I";\par
N=_N_;\par
%MEND;\par
\par
%MACRO ARIMA;\par
PROC ARIMA DATA=DATA&I;\par
IDENTIFY VAR=ORDERS(&&D&i);\par
ESTIMATE P=&&P&I Q=&&Q&I;\par
FORECAST OUT=MODEL_A&I LEAD=0;\par
RUN;\par
\par
DATA MODEL_A&I;\par
SET MODEL_A&I;\par
DIM1="&&DIM1&I";\par
DIM2="&&DIM2&I";\par
DIM3="&&DIM3&I";\par
N=_N_;\par
%MEND;\par
\par
\par
%MACRO LOG;\par
PROC ARIMA DATA=DATA&I;\par
IDENTIFY VAR=LN(&&D&i);\par
ESTIMATE P=&&P&I Q=&&Q&I;\par
FORECAST OUT=MODEL_A&I LEAD=0;\par
RUN;\par
\par
DATA MODEL_A&I;\par
SET MODEL_A&I;\par
ORDERS=10**LN;\par
FORECAST=10**FORECAST;\par
DIM1="&&DIM1&I";\par
DIM2="&&DIM2&I";\par
DIM3="&&DIM3&I";\par
n=_N_;\par
RUN;\par
%MEND;\par
%MACRO SQRT;\par
PROC ARIMA DATA=DATA&i;\par
IDENTIFY VAR=sqrt(&&d&i);\par
ESTIMATE P=&&P&i Q=&&Q&i;\par
FORECAST OUT=MODEL_A&i LEAD=0;\par
RUN;\par
\par
DATA MODEL_A&i;\par
SET MODEL_A&i;\par
ORDERS=SQRT**2;\par
FORECAST=FORECAST**2;\par
DIM1="&&DIM1&I";\par
DIM2="&&DIM2&I";\par
DIM3="&&DIM3&I";\par
N=_N_;\par
RUN;\par
%MEND;\par
\par
%MACRO BUILD;\par
%DO I=1 %TO &MODELS;\par
%IF &&PARM&I=ARIMA %THEN %DO;\par
%ARIMA;%END;\par
%IF &&PARM&I=SQRT %THEN %DO;\par
%SQRT;%END;\par
%IF &&PARM&I=log %THEN %DO;\par
%log;%END;\par
%IF &&PARM&I=UCM %THEN %DO;\par
%UCM;\par
%END;\par
%END;\par
\par
data final_models;\par
set %do i=1 %to &models;\par
model_A&i%end;;run;\par
%mend;\par
\par
%BUILD;\par
\par
PROC SQL;\par
CREATE TABLE LOOKUP AS\par
SELECT DISTINCT FORECAST_DATE FROM TEST.DUMMY\par
ORDER BY FORECAST_DATE;\par
QUIT;\par
\par
DATA LOOKUP;\par
SET LOOKUP;\par
NOS=_N_;\par
RUN;\par
\par
PROC SQL;\par
CREATE TABLE OUTPUT AS \par
SELECT * FROM LOOKUP INNER JOIN FINAL_MODELS\par
ON LOOKUP.NOS=FINAL_MODELS.N;\par
QUIT;\par
\par
/*END OF FORECAST GENERATION*/\par
\par
****************************COALITION OF FAW AND OUR FORECASTS********************************;\par
PROC SQL;\par
CREATE TABLE SUMM AS \par
SELECT DIM1, DIM2, DIM3,FORECAST_DATE, SUM(ORDER_QTY) AS ORDERS, SUM(FORECAST_QTY) AS FAW_FC\par
FROM TEST.DUMMY \par
GROUP BY DIM1, DIM2, DIM3,FORECAST_DATE\par
;\par
QUIT;\par
\par
\par
PROC SQL;\par
CREATE TABLE REM AS \par
SELECT SUMM.DIM1, SUMM.DIM2, SUMM.DIM3, SUMM.FORECAST_DATE, SUMM.ORDERS, SUMM.FAW_FC,\par
OUTPUT.FORECAST FROM SUMM\par
full JOIN OUTPUT \par
ON\par
OUTPUT.DIM1=SUMM.DIM1 AND\par
OUTPUT.DIM2=SUMM.DIM2 AND\par
OUTPUT.DIM3=SUMM.DIM3 AND\par
OUTPUT.FORECAST_DATE=SUMM.FORECAST_DATE\par
ORDER BY \par
DIM1, FORECAST_DATE;\par
QUIT;\par
\par
PROC SQL;\par
CREATE TABLE OP_COMP AS\par
SELECT AVG(ABS(FAW_FC-ORDERS)/ORDERS) AS FAW_MAPE,SUM(ORDERS) as orders,\par
AVG(ABS(FORECAST-ORDERS)/ORDERS) AS FC_MAPE,\par
DIM1, DIM2, DIM3 FROM REM\par
GROUP BY DIM1, DIM2, DIM3\par
;\par
QUIT;\par
\par
/*END OF COALITION*/\par
/**/\par
/*(1) YOUR FINAL OUTPUTS ARE IN THE TABLE WORK.OP_COMP*/\par
/*(2) YOUR BEST (LEAST MAPE) PARAMETERS ARE IN WORK.RESULT*/\par
\par
/*Enter the email to which you want to which you want to send either of the files and invoke the macro*/\par
\par
%macro email(email=abhinav.mathur@abc.com);\par
%let dir = %sysfunc(pathname(WORK));\par
\par
filename tempfile "&dir.\\DPA.parameters";\par
\par
ods pdf body=tempfile;\par
\par
PROC PRINT DATA=result NOOBS;\par
TITLE "Model parameters for optimized models";\par
RUN;\par
\par
ods pdf close;\par
\par
filename outbox email "&email" \par
         subject="Your DPA Report"\par
         replyto="abhinav.mathur@abc.com" \par
         attach="&dir.\\parameters.pdf";\par
                                                                            \par
data _null_;                                              \par
  file outbox;                                         \par
  put "Your parameters configuration is included in the attached file.";\par
  put " "\par
  put "Warm Regards";\par
  put "Abhinav Mathur";\par
run;                                                                                                                                        \par
/*data _null_;  */\par
/*  file _webout; */\par
/*  put '<HTML>';*/\par
/*  put '<H1>Your request was completed</H1>';*/\par
/*  put '<H1>An email message will be sent to you.</H1>';*/\par
/*  put '</HTML>';*/\par
/*run;*/\par
%mend;\par
%email;\par
}
�
