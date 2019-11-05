declare filename "BIGSLAVE-R.dsp";
declare name "BIGSLAVE-R";

// INPUT SELECTOR : PRE SECTION : PARAMETRIC EQ : PANNER : FADER : MASTER SECTION

import("stdfaust.lib");

// --------------------------------------------------FIREFICE 800 INPUT SELECTOR

insel = ba.selectn(18,channel) : _
  with{
    channel = nentry("[01] Input Channel Selector
                    [style:menu{'Analog IN 1':0;
                    'Analog IN 2':1;
                    'Analog IN 3':2;
                    'Analog IN 4':3;
                    'Analog IN 5':4;
                    'Analog IN 6':5;
                    'Analog IN 7':6;
                    'Analog IN 8':7;
                    'Analog IN 9':8;
                    'Analog IN 10':9;
                    'ADAT IN 1':10;
                    'ADAT IN 2':11;
                    'ADAT IN 3':12;
                    'ADAT IN 4':13;
                    'ADAT IN 5':14;
                    'ADAT IN 6':15;
                    'ADAT IN 7':16;
                    'ADAT IN 8':17}]", 0, 0, 18, 1) : int;
};

// ----------------------------------------------------------------- PRE SECTION

presec = hgroup("[06] PRE SECTION",
          ba.bypass1(lop,fi.lowpass(HO,HC)) :
          ba.bypass1(hip,fi.highpass(LO,LC))) :
         hgroup("[07]PHASE & GAIN" , gain : rpol)
with{
  lop = 1 - checkbox("[03] HC");
  HO = 2;
  HC = hslider ("[04] High Cut [unit:Hz] [style:knob] [scale:exp]", 8000, 20, 20000, 0.1) : si.smoo;
  hip = 1 - checkbox("[01] LC");
  LO = 2;
  LC = hslider ("[02] Low Cut [unit:Hz] [style:knob] [scale:exp]", 500, 20, 20000, 0.1) : si.smoo;
  rpol = *(1 - (checkbox("[05] Reverse Phase")*(2)));
  gain = *(hslider("[06] Gain [unit:dB] [style:knob]", 0, -24, +24, 0.1) : ba.db2linear : si.smoo);
};

// ----------------------------------------------------------------------------- EQ SECTION

peq = fi.low_shelf(LL,FL) : fi.peak_eq(LP1,FP1,BP1) : fi.peak_eq(LP2,FP2,BP2) : fi.high_shelf(LH,FH)
with{
	eq_group(x) = vgroup("[2] PARAMETRIC EQ",x);
	hs_group(x) = eq_group(hgroup("[1] High Shelf [tooltip: Provides a boost or cut above some frequency]", x));
	LH = hs_group(vslider("[0] Gain [unit:dB] [style:knob] [tooltip: Amount of boost or cut in decibels]", 0,-36,36,.1) : si.smoo);
	FH = hs_group(vslider("[1] Freq [unit:Hz] [style:knob] [tooltip: Transition-frequency from boost (cut) to unity gain]", 8000,100,19999,1) : si.smoo);
	pq1_group(x) = eq_group(hgroup("[2] Band [tooltip: Parametric Equalizer sections]", x));
	LP1 = pq1_group(vslider("[0] Gain 1 [unit:dB] [style:knob] [tooltip: Amount of local boost or cut in decibels]",0,-36,36,0.1) : si.smoo);
	FP1 = pq1_group(vslider("[1] Freq 1 [unit:Hz] [style:knob] [tooltip: Peak Frequency]", 2500,0,20000,1)) : si.smoo;
	Q1  = pq1_group(vslider("[2] Q 1 [style:knob] [scale:log] [tooltip: Quality factor (Q) of the peak = center-frequency/bandwidth]",40,1,1000,0.1) : si.smoo);
	BP1 = FP1/Q1;
  pq2_group(x) = eq_group(hgroup("[3] Band [tooltip: Parametric Equalizer sections]", x));
	LP2 = pq2_group(vslider("[0] Gain 2 [unit:dB] [style:knob] [tooltip: Amount of local boost or cut in decibels]", 0,-36,36,0.1));
	FP2 = pq2_group(vslider("[1] Freq 2 [unit:Hz] [style:knob] [tooltip: Peak Frequency]", 500,0,20000,1)) : si.smoo;
	Q2  = pq2_group(vslider("[2] Q 2 [style:knob] [scale:log] [tooltip: Quality factor (Q) of the peak = center-frequency/bandwidth]", 40,1,1000,0.1) : si.smoo);
	BP2 = FP2/Q2;
	ls_group(x) = eq_group(hgroup("[4] Low Shelf [tooltip: Provides a boost or cut below some frequency",x));
	LL = ls_group(vslider("[0] Gain [unit:dB] [style:knob] [tooltip: Amount of boost or cut in decibels]", 0,-36,36,0.1) : si.smoo);
	FL = ls_group(vslider("[1] Freq [unit:Hz] [style:knob] [tooltip: Transition-frequency from boost (cut) to unity gain]", 200,20,5000,1): si.smoo);
};

// ----------------------------------------------------------------------------- PANNER
// ITD + IID/distanza
panpot(x) = (c)*x, // LEFT SIDE LINEAR
            sqrt(c)*x, // LEFT SIDE SQRT
            de.fdelay3(64, max(del(r,d,alpha), 0) + 1), // LEFT SIDE ITD
            (1-c)*x, // RIGHT SIDE LINEAR
            sqrt(1-c)*x , // RIGHT SIDE SQRT
            de.fdelay3(64, max(-del(r,d,alpha), 0) + 1) : // RIGHT SIDE ITD
            ba.selectn(3, pmode), ba.selectn(3, pmode) :
            mute, mute
			with {
        pan_group(x) = vgroup("[0]", x);
        // angolo di incidenza per tutti i panner
        a = pan_group(hgroup("[1]", vslider("[1] Angle [style:knob][unit:deg]", 0,-90,90,1)));
        // riscalamento tra 0 e 1 per i panner lineare e quadratico
        c = (a -90.0)/-180.0 : si.smoo;
        // distanza delle orecchie
        d = 17; //pan_group(nentry("[3] Ears distance [unit:cm] [tooltip: It works only with ITD]",17,15,20,0.1) / 100);
        // raggio tra sorgente e testa
        r = pan_group(nentry("[2] ITD Radius [unit:cm",100,15,5000,1) / 100);
        // radianti di a
        alpha = ((a +(90.0))*ma.PI)/180.0 : si.smoo;
        // quadrato di x
        quad(x) = x*x;
        // differenza tra le due orecchie
        delta(r,d,alpha) = sqrt(quad(r) - d*r*cos(alpha) + quad(d)/4) -
                           sqrt(quad(r) + d*r*cos(alpha) + quad(d)/4);
        del(r,d,alpha) = delta(r,d,alpha) / pm.speedOfSound * ma.SR;
        pmode = pan_group(hgroup("[0]", nentry("[1] PAN MODE [style:menu{'Linear':0;'Equal Gain':1;'ITD PAN':2}]", 1, 0, 3, 1)) : int);
        mute = pan_group(*(1 - checkbox("[4] MUTE")));
			};

// ----------------------------------------------------------------------------- FADER
vmeter(x)		= attach(x, envelop(x) : vbargraph("[5][unit:dB]", -70, +5));
hmeter(x)		= attach(x, envelop(x) : hbargraph("[5][unit:dB]", -70, +5));
envelop = abs : max ~ -(1.0/ma.SR) : max(ba.db2linear(-70)) : ba.linear2db;
fader	= *(vslider("[10] Vol", 0, -96, +12, 0.1) : ba.db2linear : si.smoo);

// ------------------------------------------------------------------------VOICE
voice(v) = vgroup("[01] CH %w",
           vgroup("PRE SECTION", insel : hmeter) : presec : peq <:
           hgroup("[90] CH %w",
           panpot : fader, fader : met_group(vmeter), met_group(vmeter)))
             with{
    pf_group(x) = vgroup("[90]", x);
    met_group(x) = hgroup("[97] LR",x);
    w = v+(01);
  };

// ----------------------------------------------------------------------------- STEREO OUT

stereo = hgroup("[99] MAIN OUT", (fader, fader : vmeter, vmeter));

process = si.bus(18) <: hgroup("BIGSLAVE-R", par(i, 8, voice(i)) :> stereo );
