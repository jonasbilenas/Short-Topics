options nocenter mprint symbolgen compress=binary fullstimer
        /*mstored SASMSTORE=macin*/ source2;


%let home=/home/STUFF/TAB_SPACES;


libname stuff "&home.";

%macro BREAK ;  /* MACRO to break out of a sheet */
ods EXCEL options(sheet_interval="output");
ods exclude all;
data _null;
  declare odsout obj();
run;
ods select all;
%mend;

data classes;
  do campaign='2015/3', '2015/4';
    do offer = 'A', 'B';
      output;
    end;
  campaign=' '; offer=' ';
  output;
  end;
run;


proc format;
  value $classes (notsorted)
    '2015/3' = '2015/3'
    ' '  = ' '
    '2015/4' = '2015/4'
  ;
  value blank_it_out
    low-high = '      '
    other    = '      '
  ;
  value accts /* set 0 account total to missing */
        . , 0  = ' '
        other  = [comma10.]
  ;

  /* FORMATS USED IN LATEST FORMAT AND TABULATE TRAINING CLASS SESUG 2017*/
  picture pct (round) low - <0 = '0009.99%' (prefix='-')
                      0 - high = '0009.99%';
  picture BTM (round) low-high = '00,009.00' (prefix='$' mult=1);
  value $offer 'A' = 'A: Really good Offer'
              'B' = 'B: Good Offer';
  value tf .             = 'white'
           0 - < 0.05    = 'red'
           0.05 - <0.08  = 'yellow'
           other         = 'green'
  ;
run;


ods EXCEL file="&home./TAB_ALL3.xlsx"
          style=SASWEB
          OPTIONS (fittopage = 'yes'
                   frozen_headers='no'
                   autofilter='none'
                   embedded_titles = 'YES'
                   embedded_footnotes = 'YES'
                   zoom = '100'
                   orientation='Landscape'
                   Pages_FitHeight = '100'
                   center_horizontal = 'no'
                   center_vertical = 'no'
              );

ods EXCEL options(sheet_interval="none"
            sheet_name="NOROWSPACES"
           );

title Tabulate Run with no Blank Rows and Columns;
proc tabulate data=stuff.simdata noseps formchar='           ' missing
              /*QMETHOD=OS*/;
  class campaign offer;
  var baltran;
  keylabel n=' ' sum=' ' mean=' ' std=' ' pctn=' ' pctsum=' ' ;
  table CAMPAIGN*OFFER
        ,
    baltran='Balance Transfer'*
        (min p1 p5 p25 median p75 p95 p99 max)*f=dollar8.2
        /rts=30 row=float misstext=' ';
run;
title;
%break;


ods EXCEL options(sheet_interval="none"
            sheet_name="ROW_SPACE"
           );

title Tabulate Run with Blank Rows;
proc tabulate data=stuff.simdata noseps formchar='           ' missing
              /*QMETHOD=P2*/ classdata=classes;
  class campaign/preloadfmt order=data;
  class offer;
  format campaign $classes.;
  var baltran;
  keylabel n=' ' sum=' ' mean=' ' std=' ' pctn=' ' pctsum=' ' ;
  table CAMPAIGN*OFFER
        ,
    baltran='Balance Transfer'*
        (min p1 p5 p25 median p75 p95 p99 max)*f=dollar8.2
        /rts=30 row=float misstext=' ';
run;
title;
%break;


ods EXCEL options(sheet_interval="none"
            sheet_name="ROWS_COLS"
           );

title Tabulate Run with Blank Rows and Blank Columns;
proc tabulate data=stuff.simdata noseps formchar='           ' missing
              /*QMETHOD=P2*/ classdata=classes;
  class campaign/preloadfmt order=data;
  class offer;
  format campaign $classes.;
  var baltran;
  keylabel n=' ' sum=' ' mean=' ' std=' ' pctn=' ' pctsum=' ' ;
  table CAMPAIGN*OFFER
        ,
    baltran='Balance Transfer Amounts'*
        (
          (N = 'ACCOUNTS'*f=accts.
           N = '        '*f=blank_it_out.
          )
          (MEAN = 'MEAN'*f=dollar8.2
           STD  = 'STD'*f=dollar8.2
           N ='        '*f=blank_it_out.
          )
          (min p1 p5 p25 median p75 p95 p99 max)*f=dollar8.2
        )
        /rts=30 row=float misstext=' ';
run;
title;
%break;


ods EXCEL options(sheet_interval="none"
            sheet_name="ROWS_COLS_BOX"
           );

title Tabulate Run with Blank Rows and Blank Columns;
proc tabulate data=stuff.simdata noseps formchar='           ' missing
              /*QMETHOD=P2*/ classdata=classes;
  class campaign/preloadfmt order=data;
  class offer;
  format campaign $classes.;
  var baltran;
  keylabel n=' ' sum=' ' mean=' ' std=' ' pctn=' ' pctsum=' ' ;
  table CAMPAIGN*OFFER
        ,
    baltran='Balance Transfer Amounts'*
        (
          (N = 'RESPONDERS'*f=accts.
           N = '        '*f=blank_it_out.
          )
          (MEAN = 'MEAN'*f=dollar8.2
           STD  = 'STD'*f=dollar8.2
           N ='        '*f=blank_it_out.
          )
          (min p1 p5 p25 median p75 p95 p99 max)*f=dollar8.2
        )
        /rts=30 row=float misstext=' ';
run;
title;
title Box Plots Of Balance Transfer Amounts;
proc sgpanel data=stuff.simdata;
  PANELBY  campaign / rows=2 uniscale=all;
  HBOX baltran/category = offer
               /*DATASKIN=GLOSS */ /* available in SAS9.4 M7 */;
run;
%break;


ods Excel options(Sheet_Name="COOL REPORT");

proc tabulate data=stuff.simdata noseps;
  class offer campaign;
  format offer $offer.;
  var respond baltran mailed;
  keylabel n=' ' sum=' ' mean=' ' pctn=' ' pctsum=' ' ;
  table (offer all='TOTAL' )
        *
        (n='Mailed' *f=comma9.
        pctn<offer all>=' % ' *f=pct.
        respond='Responders' *f=comma10.
        respond='Response Rate' *mean*f=percent9.2*[style=[background=tf.]]
        baltran='Balance Transfer per respond' *mean*f=dollar9.0
        baltran='Balance Transfer per mailed' *pctsum<mailed>*f=btm.
        baltran='Total Transfer'*f=dollar13.
        baltran='% Total Transfer'*colpctsum=' '*f=pct.
        )
     ,
        campaign
       /rts=19 row=float misstext=' ' box='SESUG2017' ;
run;
%break;
ods Excel close;

