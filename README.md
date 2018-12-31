# CurveTracerControl

 This program is intended to instrument the Curve Tracer design published by Mr. Carlson's Lab on Patreon.  The original MCL
 design is available only to Patreon subscribers.  This software is released Open Source but does not contain the original 
 MCL project information upon which it is built.  If you want to build this project, I suggest you join Mr. Carlson's Lab on 
 Patreon to get the original project that this program augments.

 This project adds the following functionality to the MCL Curve Tracer

 1) Frequency counter for the Sine Wave
 2) Peak sine wave voltage display
 3) Step generator with hi/lo voltage display

 The step generator uses an R2R ladder and is fed through a series of op amps.  A Potentiometer controls final amplitude 
 and an op amp inverts the steps so that negative steps can be used.  A switch selects resistors to limit output current 
 to 10, 100, or 1000 uA. See the schematic for more details.
 
 This program uses a 5 volt 16 MHz Arduino with an ATMEGA328P.  Use of any other hardware may require alterations to the code. 
 A crystal oscillator rather than a resonator is preferred for frequency counter accuracy.

 The frequency counter in this program is limited to low frequencies.  It works for frequencies up to ~1000 Hz, but will
 likely fail at 2000 Hz or before.  The tested frequency range is 30 to 1070 Hz.
 
 Copyright 2018 by Dennis Cabell
 KE8FZX
