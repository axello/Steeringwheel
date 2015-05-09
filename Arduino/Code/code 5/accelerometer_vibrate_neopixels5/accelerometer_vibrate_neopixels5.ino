#include <Wire.h> 
#include <ADXL345.h> 
#include <Adafruit_NeoPixel.h>

#define PIN 6 

const int MAXVIB=180; // 180 is 3.6V if Vin is 5V (Arduino Uno)

const int potPin = A0;  // Analog input pin that the potentiometer is attached to
const int motorPin = 3; // Analog output pin that the vibration motor is attached to
//int ledPin = 6;      // PWM pin that the LED is on.  n.b. PWM 0 is on digital pin 9
int outputValue = 0;        // value output to the PWM (analog out)
boolean ledOn = false;
boolean motorOn = false;
int shakeTimer = 0;
int lightTimer = 0;
 
ADXL345 adxl; //variable adxl is an instance of the ADXL345 library 
Adafruit_NeoPixel strip = Adafruit_NeoPixel(60, PIN, NEO_GRB + NEO_KHZ800);
 
void setup(){ 

Serial.begin(9600);
//  pinMode(ledPin, OUTPUT);
  pinMode(motorPin, OUTPUT);
  pinMode(potPin, INPUT);
 
 adxl.powerOn(); 
 strip.begin();
 strip.show();  
} 

void loop(){ 
    
 //clearStrip (); 
 int x,y,z; 
 adxl.readAccel(&x, &y, &z); //read the accelerometer values and store them in variables x,y,z 

   uint16_t acceleration = abs(x>>1) + abs(y>>1);
 
   // read the analog in value:
  // int  sensitivity = analogRead(potPin);   
  uint16_t upper_sensitivity = analogRead(potPin) + 4;
  uint16_t lower_sensitivity = upper_sensitivity - 8; 
 
  uint16_t led5 = 0;
  uint16_t led4 = (lower_sensitivity / 5) * 1;
  uint16_t led3 = (lower_sensitivity / 5) * 2;
  uint16_t led2 = (lower_sensitivity / 5) * 3;
  uint16_t led1 = (lower_sensitivity / 5) * 4;
  
  if (acceleration > upper_sensitivity) {
    clearStrip ();
    // map it to the range of the analog out:
    outputValue = map(acceleration, upper_sensitivity, 512, 0, MAXVIB);  
    // turn motor on accordingly  
      analogWrite(motorPin, outputValue);
    motorOn = true;
} else 

if (acceleration > lower_sensitivity) {
   // all leds off 
      analogWrite(motorPin, 0);
      motorOn=false;
    clearStrip ();
         
  } else if (acceleration > led1) {
      analogWrite(motorPin, 0);
      motorOn=false;
    // one led on
       for(int i = 12; i<18; i++){
        strip.setPixelColor(i, strip.Color(0, 50, 0)); 
        strip.show();
      }       
  } else if (acceleration > led2) {
      analogWrite(motorPin, 0);
      motorOn=false;
   // two led on
          for(int i = 9; i<21; i++){
          strip.setPixelColor(i, strip.Color(0, 50, 0)); 
          strip.show();
        }       
  } else if (acceleration > led3) {
      analogWrite(motorPin, 0);
      motorOn=false;
   // three leds on
        for( int i = 6; i<24; i++){
          strip.setPixelColor(i, strip.Color(0, 50, 0)); 
          strip.show();
        }        
  } else if (acceleration > led4) {
      analogWrite(motorPin, 0);
      motorOn=false;
   // four leds on
        for(int i = 3; i<27; i++){
          strip.setPixelColor(i, strip.Color(0, 50, 0)); 
          strip.show();
        }   
  } else if (acceleration > led5) {
      analogWrite(motorPin, 0);
      motorOn=false;
   // five leds on
        for(int i = 0; i<30; i++){
          strip.setPixelColor(i, strip.Color(0, 50, 0)); 
          strip.show();
        }
  } else 
   
{
    // turn motor off
  /*    motorOn = false;
      analogWrite(motorPin, 0);
      */
  }
 
 
 /////////////////////////////////////////////////////////////////////////
 
 
/* 
 
  if (acceleration<=15) {
    shakeTimer--;
    if( shakeTimer == 0){
      motorOn = false;
      analogWrite(motorPin, 0);
    }
    lightTimer--;
    if( lightTimer ==0){
      clearStrip ();
    }   
  }
  else if (acceleration < (sensitivity-15)/5)
  {
    lightTimer = 20;
    shakeTimer--;
    if( shakeTimer == 0){
      motorOn = false;
      analogWrite(motorPin, 0);
    }
    if (motorOn == false){
      for(  int i = 12; i<18; i++){
        strip.setPixelColor(i, strip.Color(0, 50, 0)); 
        strip.show();
      }   
    }    
  }
  
    else if (acceleration < ((sensitivity-15)/5)*2)
    {
      lightTimer = 20;
      shakeTimer--;
      if( shakeTimer == 0){
        motorOn = false;
        analogWrite(motorPin, 0);
      }
      if (motorOn == false){
        for( int i = 9; i<21; i++){
          strip.setPixelColor(i, strip.Color(0, 50, 0)); 
          strip.show();
        }   
      }   
    } 
    else if (acceleration < ((sensitivity-15)/5)*3)
    {
      lightTimer = 20;
      shakeTimer--;
      if( shakeTimer == 0){
        motorOn = false;
        analogWrite(motorPin, 0);
      }
      if (motorOn == false){
        for( int i = 6; i<24; i++){
          strip.setPixelColor(i, strip.Color(0, 50, 0)); 
          strip.show();
        }   
      }  
    }  
  
    else if (acceleration < ((sensitivity-15)/5)*4)
    {
      lightTimer = 20;
      shakeTimer--;
      if( shakeTimer == 0){
        motorOn = false;
        analogWrite(motorPin, 0);
      }
      if (motorOn == false){
        for( int i = 3; i<27; i++){
          strip.setPixelColor(i, strip.Color(0, 50, 0)); 
          strip.show();
        }   
      }
    }  
    else if (acceleration < ((sensitivity-15)/5)*5)
    {
      lightTimer = 20;
      shakeTimer--;
      if( shakeTimer == 0){
        motorOn = false;
        analogWrite(motorPin, 0);
      }
    
      if (motorOn == false){
        for( int i = 0; i<30; i++){
          strip.setPixelColor(i, strip.Color(0, 50, 0)); 
          strip.show();
        }
      } 
    }  
   else if (acceleration > (sensitivity)) {
    // change the analog out value:
      clearStrip ();
      shakeTimer = 20;
      analogWrite(motorPin, outputValue);
      motorOn = true;
    } 
  
  else {
   return;
  }
    
  */
  
 // Output x,y,z values - Commented out 
 Serial.print("acc:"); 
 Serial.print(acceleration);
 Serial.print('\t'); 
 Serial.print("sens:");
 Serial.print(upper_sensitivity);
 Serial.print('\t'); 
 Serial.print(lower_sensitivity);
 Serial.print('\t'); 
 Serial.print(x); 
 Serial.print('\t'); 
 Serial.println(y); 
 //Serial.print('\t'); 
 //Serial.println(z); 
 delay(50); 

} 

void clearStrip() {
  for( int i = 0; i<30; i++){
    strip.setPixelColor(i, 0x000000); strip.show();
  }
}
