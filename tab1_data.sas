options nocenter mprint symbolgen compress=binary fullstimer
        /*mstored sasmstore=macin*/ source2;


%let home=/home/STUFF/TAB_SPACES;


libname stuff "&home.";

proc format;
  value offer   /* Offer mix rates */
                low   - 0.45 = 'A'
                0.45 <- high = 'B'
  ;
  value $grroff /* Response Rate FORMATS TO use based on OFFER */
                'A' = 'aoff'
                'B' = 'boff'
  ;
  value aoff    /* Response rates for A-OFFER */
                low - 0.10 = '1'
                other      = '0'
  ;
  value boff    /* Response rates for B-OFFER */
                low - 0.05 = '1'
                other      = '0'
  ;
  value $ABT    /* Average Balance Transfer Amounts by Offer */
                'A' = '6500'
                'B' = '5400'
  ;
run;

data stuff.simdata;
  call streaminit(20160804);
  do campaign = '2015/3', '2015/4'; /* campaign period */
    do i = 1 to 1e6;
      mailed=1;
      offer=put(rand("Uniform"),offer.);
      fmtuse=put(offer,$grroff.);
      respond=input(putn(rand("Uniform"),fmtuse),best12.);
      if respond then
        baltran=rand("Normal")*500+input(put(offer,$ABT.),best12.);
      else baltran=.;
      output;
    end;
  end;
  drop i fmtuse;
run;


