// INPUT SELECTOR : PRE SECTION : PARAMETRIC EQ : PANNER : FADER : MASTER SECTION

import("stdfaust.lib");

// ----------------------------------------------------------------------------- INPUT SELECTOR

insel = ba.selectn(18,channel) : _
  with{
    channel = nentry("[0] Input Channel Selector
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

// ----------------------------------------------------------------------------- PRE SECTION

presec = pre_group(ba.bypass1(lop,fi.lowpass(HO,HC)) : ba.bypass1(hip,fi.highpass(LO,LC))) : gain : rpol
with{
	pre_group(x) = vgroup("[1] PRE SECTION ",x);
  
  lop = 1 - checkbox("[3] HC");

  HO = 2;//nentry("order", 2, 1, 8, 1);
  HC = hslider("[1] High Cut [unit:Hz]", 8000, 20, 20000, 1) : si.smoo;

  hip = 1 - checkbox("[4] LC");

  LO = 2;//nentry("order", 2, 1, 8, 1);
  LC = hslider("[2] Low Cut [unit:Hz]", 500, 20, 20000, 1) : si.smoo;

	gain = pre_group(*(hslider("[5] Gain [unit:dB]", 0, -24, +24, 0.1) : ba.db2linear : si.smoo));

	rpol = pre_group(*(1 - (checkbox("[6] Reverse Phase")*(2))));
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
panpot(x) = (c)*x,   sqrt(c)*x,    de.fdelay3(64, max(del(r,d,alpha), 0) + 1), // LEFT SIDE = LINEAR : SQRT : ITD
            (1-c)*x, sqrt(1-c)*x , de.fdelay3(64, max(-del(r,d,alpha), 0) + 1) : // RIGHT SIDE = LINEAR : SQRT : ITD
            ba.selectn(3, pmode), ba.selectn(3, pmode) :
            mute, mute
			with {
        pan_group(x) = vgroup("[0]", x);

        a = pan_group(hgroup("[1]", vslider("[1] Angle [style:knob][unit:deg]", 0,-90,90,1)));

        c = (a -90.0)/-180.0 : si.smoo;

        d = pan_group(nentry("[3] Ears distance [unit:cm] [tooltip: It works only with ITD]",17,15,20,0.1) / 100);
        r = pan_group(nentry("[2] Radius [unit:cm] [tooltip: It works only with ITD]",100,15,5000,1) / 100);

        alpha = ((a +90.0)*ma.PI) /180.0 : si.smoo;

        quad(x) = x*x;
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

fader	= *(hgroup("[10]", vslider("[1]", 0, -96, +12, 0.1)) : ba.db2linear : si.smoo);

// ----------------------------------------------------------------------------- MUTE

voice(v) = vgroup("[1] CH %w",
           vgroup("", insel : hmeter) : presec : peq <:
           hgroup("[90] CH %w",
           panpot : fader, fader : met_group(vmeter), met_group(vmeter)))
             with{
    pf_group(x) = vgroup("[90]", x);
    met_group(x) = hgroup("[97]",x);
    w = v+(01);
  };

// ----------------------------------------------------------------------------- STEREO OUT

stereo = hgroup("[99] MAIN OUT", (fader, fader : vmeter, vmeter));

process = si.bus(18) <: hgroup("BIGSLAVE-R", par(i, 8, voice(i)) :> stereo );
