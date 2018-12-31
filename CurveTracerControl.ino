/*
 Copyright 2018 by Dennis Cabell
 KE8FZX

 This progran is intended to instument the Curve Tracer design published by Mr. Carlson's Lab on Patreon.  The original MCL
 design is available only to Patreaon subscribers.  This software is released Open Source but does not contain the original 
 MCL project information upon which it is built.  If you want to build this project, I suggest you join Mr. Carlson's Lab on 
 Patreon to get the original project that this program augments.

 This project adds the following functionality to the MCL Curve Tracer

 1) Frequency counter for the Sine Wave
 2) Peak sine wave vontage display
 3) Step generator with hi/lo voltage display

 The step generator uses an R2R ladder and is fed through a series of op amps.  A Potentiometer controls final amplitude 
 and an op amp inverts the steps so that negative steps can be used.  A switch selects resistors to limit output current 
 to 10, 100, or 1000 uA. See the scematic for more details.
 
 This program uses a 5 volt 16 MHz arduino with an ATMEGA328P.  Use of any other hardware may require alterations to the code. 
 A crystal oscillator rather than a resonator is preferred for frequency counter accuracy.

 The frequency counter in this program is limited to low frequencies.  It works for frreqeuncies up to ~1000 Hz, but will
 likely fail at 2000 Hz or before.  The tesed frequency range is 30 to 1070 Hz.
 
 This project is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.

 Code obtained from other authors are attributed in the files that contain their code.
 */

#include "RotaryEncoder.h"
#include "QuickStats.h"
#include <LiquidCrystal_I2C.h>

#define FREQ_SCALE_CAL   (float)1.0     // Multiplier to correct frequency
#define FREQ_OFFSET_CAL  (float)0.0     // Multiplier to correct frequency

#define PROBE_SCALE_CAL  (float)3.60    // Multiplier to read correct voltsge.  Modify to calibrate
#define PROBE_OFFSET_CAL (float)0.05    // +/- Offset to adjust, the same offset applies to all frequencies

#define STEP_SCALE_CAL   (float)3.242   // Multiplier to read correct voltsge.  Modify to calibrate
#define STEP_OFFSET_CAL  (float)0.014   // +/- Offset to adjust for proper zero volt reading

#define STEP_CYCLES         1           // how may probe cycles should pass for each step

#define STEP_COUNT_DISPLAY_DURATION 110 // How long to display the step count when it changes, before going back to high voltage display.  No specific units - higher is longer.

#define ENCODER_PINA        5           // Reverse pins A & B if the encoder movement is backwards
#define ENCODER_PINB        6
#define ENCODER_BTN         4

#define FREQ_COUNT_PIN      2
#define PROBE_VOLTAGE_PIN   A0
#define STEP_VOLTAGE_PIN    A2

#define MAX_TIMER_OVERFLOWS 32           // Will cause error display if probe frequnecy drops to about 1 Hz
#define HERTZ_SAMPLES       25           // How many samples of the frequency to use for the display.  The Mode of these is used.  Try increasing if display jitters.
#define VOLTAGE_SAMPLES     5            // How many samples of voltages to use for the display.  The Average of these is used.  Try increasing if display jitters, decrease if voltage display lags.
#define ADC_VOLTAGE_REF     5.021
                                         // 4 bit output to an R2R ladder
                                         // Don't change these.  These must be the first 4 pins of PORTB for the code to function properly
#define R2R_BIT1_PIN        8            // Low order bit - closest to the ground side
#define R2R_BIT2_PIN        9
#define R2R_BIT3_PIN        10
#define R2R_BIT4_PIN        11           // High order bit

// Note: These LCD I2C values may vary.  There are multiple versions of the I2C LCD boards.
// that use different address and pin assignments.  These worked for me but your hardware may differ and require changes.
#define LCD_I2C_ADDR        0x3F
//#define LCD_I2C_ADDR      0x27
#define I2C_EN_PIN          2
#define I2C_RW_PIN          1
#define I2C_RS_PIN          0
#define I2C_D4_PIN          4
#define I2C_D5_PIN          5
#define I2C_D6_PIN          6
#define I2C_D7_PIN          7
#define I2C_BL_PIN          3   //Back light
#define I2C_BACKLIGHT_POLARITY  POSITIVE

QuickStats stats;

LiquidCrystal_I2C lcd(LCD_I2C_ADDR,   // Set the LCD I2C address
                      I2C_EN_PIN,
                      I2C_RW_PIN,
                      I2C_RS_PIN,
                      I2C_D4_PIN,
                      I2C_D5_PIN,
                      I2C_D6_PIN,
                      I2C_D7_PIN,
                      I2C_BL_PIN,
                      I2C_BACKLIGHT_POLARITY);  

RotaryEncoder encoder2(ENCODER_PINB, ENCODER_PINA); 

volatile unsigned long freqInterruptTime1 = 0xFFFFFFFF;  
volatile int timerOverflows = 0;
volatile float highStepVoltage[VOLTAGE_SAMPLES] = {0};
volatile float lowStepVoltage[VOLTAGE_SAMPLES] = {0};
volatile float maxProbeVoltage[VOLTAGE_SAMPLES] = {0};
volatile bool probeFreqError = false;


volatile int stepIndex = 0;
volatile bool stepOutputActive = false;    

#define NUM_STEP_PROFILES 7

const byte stepProgression[NUM_STEP_PROFILES][16] = { // position 0 is the number of steps
                                {1,  15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0},  // one step always max voltage
                                {2,  15,  7,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0},  // two steps alternate max and half voltage
                                {3,  15,  8,  2,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0},  // 3 steps
                                {4,  15, 11,  7,  3,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0},  // 4 steps
                                {5,  15, 12,  9,  6,  3,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0},  // 5 steps
                                {8,  15, 13, 11,  9,  7,  5,  3,  1,  0,  0,  0,  0,  0,  0,  0},  // 8 steps
                                {15, 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1}   // 15 steps
                              };

void setup()
{
  lcd.begin(16, 2);
  lcd.clear();
  lcd.setCursor(0, 0);lcd.print(F("  Curve Tracer"));

  pinMode(PROBE_VOLTAGE_PIN,INPUT);
  pinMode(STEP_VOLTAGE_PIN,INPUT);
  pinMode(FREQ_COUNT_PIN,INPUT);
  pinMode(ENCODER_PINA, INPUT_PULLUP);
  pinMode(ENCODER_PINB, INPUT_PULLUP);
  pinMode(ENCODER_BTN, INPUT_PULLUP);

  digitalWrite(R2R_BIT1_PIN,LOW);
  digitalWrite(R2R_BIT2_PIN,LOW);
  digitalWrite(R2R_BIT3_PIN,LOW);
  digitalWrite(R2R_BIT4_PIN,LOW);

  pinMode(R2R_BIT1_PIN,OUTPUT);
  pinMode(R2R_BIT2_PIN,OUTPUT);
  pinMode(R2R_BIT3_PIN,OUTPUT);
  pinMode(R2R_BIT4_PIN,OUTPUT);
  
  Serial.begin(57600);
  Serial.println("Starting Curve Tracer Control"); 

  attachInterrupt(digitalPinToInterrupt(FREQ_COUNT_PIN),FreqCount,FALLING);

  encoder2.setPosition(0);

  PCICR |= (1 << PCIE2);    // This enables Pin Change Interrupt 2 that covers Port D - needed for encoder
  PCMSK2 |= (1 << PCINT21) | (1 << PCINT22);  // This enables the interrupt for pin 5 and 6 of Port D - needed for encoder

  delay(2000);
  lcd.clear();
  
  // Disable timer0 interrupt.  millis(), micros() and dealy() won't function aftger this, but this way timer0 interrupts
  // will not affect timer1, which is used for frequency counting.  All other timing in the sketch is based
  // on counting the cycles for the probe frequency, which is calculated using timer1.
  // and the FreqCount interrupt routine
  TIMSK0 &= ~_BV(TOIE0);

  SetupTimer1();
}

void SetupTimer1() {
  noInterrupts();
  TCCR1A = 0;// set entire TCCR1A register to 0
  TCCR1B = 0;// same for TCCR1B
  TCNT1  = 0;// initialize counter value to 0

  TIMSK1 |= _BV(TOIE1);// enable overflow interrupt

  TCCR1B |= _BV(CS11); // set prescaler to 1.  

  interrupts();
}

void FreqCount() {
  static byte cycleCount = 0;
  byte extraOverFlow = 0;
  // stop counter breifly while we check everything
  TCCR1B &= ~(_BV(CS10) | _BV(CS11) | _BV(CS12)); 
  if ((TIFR1 & bit (TOV1)) && freqInterruptTime1 < 1024) {  // if an overflow is pending, we want to count it
    extraOverFlow++;
  }  
  freqInterruptTime1 = TCNT1;
  TCNT1  = 0;// initialize counter value to 0  
  TCCR1B |= _BV(CS11); // re-enable timer set prescaler to 8.  Resolution 0.5 uS
  #define TICKS_TIMER_WAS_TURNED_OFF 4  // add to compensate for the timer being off breifly.  This wasnt measured, just a guess 

  freqInterruptTime1 += (timerOverflows + extraOverFlow) * 0xFFFF + TICKS_TIMER_WAS_TURNED_OFF; 
  timerOverflows = (extraOverFlow == 1) ? -1 : 0; // of an overflow is pending, compensate by setting to -1 so overflow interrupts will set it to 0
  
  cycleCount++;

  if (cycleCount % STEP_CYCLES == 0 || probeFreqError) {
    int stepCount = GenerateStep (stepIndex, stepOutputActive, probeFreqError);
    ReadVoltages(stepIndex, stepCount);
  }
}

ISR(TIMER1_OVF_vect) {
  timerOverflows++;
  timerOverflows = (timerOverflows > MAX_TIMER_OVERFLOWS) ? MAX_TIMER_OVERFLOWS: timerOverflows;  // too many overflows is a frequency error so hold same value
}

bool checkButton(bool _stepsActive) {
  bool stepsActive = _stepsActive;
  static bool prevStepsActive = !stepsActive;
  static bool buttonDown = false;
  static byte PrevButtonState = HIGH;
  
  byte buttonState = digitalRead(ENCODER_BTN);

  if ((buttonState == HIGH) && buttonDown)   {    // make sure button was down at leasst 1 full cycle before registering click
    stepsActive = !stepsActive;
    buttonDown = false;    
  } 
  if ((buttonState == LOW) && PrevButtonState == LOW) {
    buttonDown = true;
  }
  PrevButtonState = buttonState;
  
  if (prevStepsActive != stepsActive) {
    if (stepsActive) {
      lcd.setCursor(7, 0);lcd.print("         ");  
    } else {
      lcd.setCursor(7, 0);lcd.print("Steps Off");
    }
    prevStepsActive = stepsActive;     
  }
  return stepsActive;
}

void loop()
{
  static bool prevStepOutputActive = false;    
  static unsigned int stepDisplayCountdown = 0;
  static int prevStepIndex = 0;
  static bool stepIndexdisplayOn = false;

  while(1==1) {
    probeFreqError = !DisplayProbeFrequency();
    
    DisplayProbeMaxVoltage();
    DisplayStepVoltage(stepIndex, stepOutputActive, stepIndexdisplayOn); 
    
    stepOutputActive = checkButton(stepOutputActive);
    if (prevStepOutputActive != stepOutputActive) {
      prevStepIndex = -1;  // Set to invalid value so it looks like a step change to step display triggers
      //encoder2.setPosition(prevStepIndex);
    }

    stepIndex = getStepIndex(stepOutputActive, prevStepIndex);  
    if (prevStepIndex !=  stepIndex) {
       stepDisplayCountdown = STEP_COUNT_DISPLAY_DURATION;
       stepIndexdisplayOn = true;
       prevStepIndex = stepIndex;
       prevStepOutputActive = stepOutputActive;
    }
    if (probeFreqError) {  //if no input freqeuncey do this so displays are updated and step voltage turned off
      int stepCount = GenerateStep (stepIndex, stepOutputActive, probeFreqError);
      ReadVoltages(stepIndex, stepCount); 
    }
    if (stepIndexdisplayOn && stepDisplayCountdown > 0) {
      stepDisplayCountdown--;
    } else {
      stepIndexdisplayOn = false;
    }
  }
}

bool DisplayProbeFrequency(){
  #define HERTZ_SAMPLES 25
  static float hertzHistory[HERTZ_SAMPLES] = {0};
  static long prevHertz = -1;
  static long hertz = 0;
  float hertzFloat;
  hertzFloat = FREQ_SCALE_CAL * (float)1000000.0 / (float)(freqInterruptTime1)*2.0 + FREQ_OFFSET_CAL;
  hertzFloat = constrain(hertzFloat,0.0,9999.0);

  static int iHistory = 0;
  hertzHistory[iHistory] = round(hertzFloat);
  iHistory++;
  iHistory = (iHistory < HERTZ_SAMPLES) ? iHistory : 0;

  hertz = stats.mode(hertzHistory,HERTZ_SAMPLES,0.1);
  if (hertz != prevHertz) {
    prevHertz = hertz;
    lcd.setCursor(0,0);lcd.print("       ");
    lcd.setCursor(0,0);lcd.print(hertz);lcd.print("Hz");
    return true;
  }
  if (timerOverflows >= MAX_TIMER_OVERFLOWS || hertzFloat >= 9999.0 || hertz == 0 || hertz >= 9999 ) {
     lcd.setCursor(0,0);lcd.print("ERROR  ");
     return false;
  }  
}

int getStepIndex(bool stepsActive, int prevStepIndex) {
  static int stepIndex = 0;
  if (stepsActive) {
    int encoderPosition = encoder2.getPosition();
    if (encoderPosition != stepIndex || stepIndex != prevStepIndex) {
      //Serial.println(encoderPosition);
      stepIndex = constrain(encoderPosition,0,NUM_STEP_PROFILES-1);
      encoder2.setPosition(stepIndex);
      lcd.setCursor(7,0);
      if (stepProgression[stepIndex][0] == 1) {
        lcd.print("Single V ");        
      } else {
        lcd.print(stepProgression[stepIndex][0]);
        if (stepProgression[stepIndex][0] == 2) {
          lcd.print(" Step   ");    
        } else {
          lcd.print(" Steps  ");     
        }
      }
    }
  } else {
    encoder2.setPosition(stepIndex);
  }
  return stepIndex;
}

void DisplayStepVoltage(int stepIndex, bool stepsActive, bool stepIndexdisplayOn) {  
  if (stepsActive && !stepIndexdisplayOn && (stepProgression[stepIndex][0] != 1)) {
    // this is the max step voltage.  Don't overwrite step off message if steps are off. Dont overwrite single V message
    // also dont display until display time for step count expires
    lcd.setCursor(7,0);lcd.print(stats.average(highStepVoltage,VOLTAGE_SAMPLES),2);lcd.print(" Vhi ");
  } 
  if ((stepProgression[stepIndex][0] == 1) || !stepsActive) {
    lcd.setCursor(7,1);lcd.print(stats.average(highStepVoltage,VOLTAGE_SAMPLES),2);lcd.print(" V   ");     
  } else {   
    if (stepsActive && stepProgression[stepIndex][0] != 1) {
      // this is the min step voltage
      lcd.setCursor(7,1);lcd.print(stats.average(lowStepVoltage,VOLTAGE_SAMPLES),2);lcd.print(" Vlo ");
    }
  }
}

inline void ReadVoltages(int stepIndex, int stepCount) { 
  static byte passCount = 0;   //count passes so we can alternate if we read the setp voltage or probe voltage
  static float voltage = 0; 
  static bool checkStepVoltage = false;
  static byte probeVoltageIndex = 0;
  static byte highStepVoltageIndex = 0;
  static byte lowStepVoltageIndex = 0;

  // only check one voltage per step because analog read is slow, so figure out which to check
  // if the number of steps is <=2 then the prob voltage must alternate with the step/high low
  // otherwise read probe voltage during a middle step
  if (stepProgression[stepIndex][0] <= 2) {
    if (passCount++ % 2 == 0) {
      checkStepVoltage = true;
    } else {
      checkStepVoltage = false;
    }
  } else {
    if (stepCount == 1 || stepCount == stepProgression[stepIndex][0]) {
      checkStepVoltage = true;
    } else {
      checkStepVoltage = false;
    }
  }
  
  if (checkStepVoltage) {  
    if (stepCount == 1 || stepCount == stepProgression[stepIndex][0]) {
      voltage = analogRead(STEP_VOLTAGE_PIN);  // throw away first read after pin change for better accuracy
      voltage = analogRead(STEP_VOLTAGE_PIN); 
      voltage = (voltage * ADC_VOLTAGE_REF / 1024.0 * STEP_SCALE_CAL) + STEP_OFFSET_CAL;
      if (stepCount == 1) {
        highStepVoltage[highStepVoltageIndex++] = voltage;
        highStepVoltageIndex = (highStepVoltageIndex ==  VOLTAGE_SAMPLES) ? 0 : highStepVoltageIndex;      
      } 
      if (stepCount == stepProgression[stepIndex][0] || stepProgression[stepIndex][0] == 1) {
        lowStepVoltage[lowStepVoltageIndex++] = voltage;
        lowStepVoltageIndex = (lowStepVoltageIndex ==  VOLTAGE_SAMPLES) ? 0 : lowStepVoltageIndex;      
      } 
    }
  } else {
    voltage = analogRead(PROBE_VOLTAGE_PIN);  // throw away first read after pin change for better accuracy
    voltage = analogRead(PROBE_VOLTAGE_PIN); 
    maxProbeVoltage[probeVoltageIndex++] = (voltage * ADC_VOLTAGE_REF / 1024.0 * PROBE_SCALE_CAL) + PROBE_OFFSET_CAL;
    probeVoltageIndex = (probeVoltageIndex ==  VOLTAGE_SAMPLES) ? 0 : probeVoltageIndex;      
  }
}

void DisplayProbeMaxVoltage() {  
  lcd.setCursor(0,1);lcd.print(stats.average(maxProbeVoltage,VOLTAGE_SAMPLES),1);lcd.print("V ");
}

inline int GenerateStep (int stepIndex, bool stepsActive, bool probeFreqError) {
  static int stepCount = 1;
  stepCount++;
  stepCount = (stepCount > stepProgression[stepIndex][0]) ? 1 : stepCount;
  
  if (stepsActive && !probeFreqError) {
    // Set the R2R ladder bits on PORTB pins 8 9 10 11
    PORTB = (PORTB & 0xF0) | stepProgression[stepIndex][stepCount];
  } else {
    PORTB &= 0xF0; 
  }  
  return stepCount;
}

// The Interrupt Service Routine for Pin Change Interrupt 
// This routine will only be called on any signal change on encoder pins: exactly when we need to check.
// Encoder uses no cpu time if it is not changing, so other interrupt routins are only potentially affected while encoder is is being used
ISR(PCINT2_vect) {
  encoder2.tick(); // just call tick() to check the state.
}
