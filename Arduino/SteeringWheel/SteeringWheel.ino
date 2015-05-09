// #include <RBL_services.h>

#include "Adafruit_NeoPixel.h"
#include <SPI.h>
#include <boards.h>
#include <RBL_nRF8001.h>
#include <services.h>

// pin modes
//#define INPUT                 0x00 // defined in wiring.h
//#define OUTPUT                0x01 // defined in wiring.h
#define ANALOG                  0x02 // analog pin in analogInput mode
#define PWM                     0x03 // digital pin in PWM output mode
#define SERVO                   0x04 // digital pin in Servo output mode


// Parameter 1 = number of pixels in strip
// Parameter 2 = pin number (most are valid)
// Parameter 3 = pixel type flags, add together as needed:
//   NEO_RGB     Pixels are wired for RGB bitstream
//   NEO_GRB     Pixels are wired for GRB bitstream
//   NEO_KHZ400  400 KHz bitstream (e.g. FLORA pixels)
//   NEO_KHZ800  800 KHz bitstream (e.g. High Density LED strip)
// Adafruit_NeoPixel strip = Adafruit_NeoPixel(1, 7, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel strip = Adafruit_NeoPixel(30, 6, NEO_GRB + NEO_KHZ800);

#define DELAY 500

int R = 0;
int G = 0;
int B = 0;

static byte buf_len = 0;
unsigned long milliSeconds;
boolean noReturn;

void setup() 
{
    Serial.begin(115200);
  Serial.println("BLE SteeringWheel");

  strip.begin();
  strip.show(); // Initialize all pixels to 'off'

  ble_begin();
  milliSeconds = millis();
  noReturn = false;
}

void loop() 
{
  if (millis() > (milliSeconds + DELAY) && noReturn) {
    Serial.println("");
    noReturn = false;
  }
  
  while(ble_available()) {
    byte cmd;
    cmd = ble_read();
    
    // temp
//        switch (cmd)
//    {
//      case 'R':      // RGB values
//      {
//        byte pin = ble_read();
//        R = ble_read();
//        G = ble_read();
//        B = ble_read();
//        
//        uint32_t color = strip.Color(R, G, B);
//        reportRGBValues(color);
//        strip.setPixelColor(pin, R,G,B);
//        strip.show();
//
//      } break;
//      case 'V': // query protocol version
//        {
//          byte buf[] = {'V', 0x00, 0x00, 0x01};
//          ble_write_string(buf, 4);
//        }
//        break;
//      
//      case 'C': // query board total pin count
//        {
//          byte buf[2];
//          buf[0] = 'C';
//          buf[1] = 'C'; 
//          ble_write_string(buf, 2);
//        }        
//        break;
//      
//      case 'M': // query pin mode
//        {  
//          byte pin = ble_read();
//          byte buf[] = {'M', pin, 1}; // report pin mode
//          ble_write_string(buf, 3);
//        }  
//        break;
//      
//        case 'S': // set pin mode
//        {
//          byte pin = ble_read();
//          byte mode = ble_read();
//          setPin(pin,mode);
//          reportPinDigitalData(pin);
//
//        }
//        break;
//
//      case 'G': // query pin data
//        {
//          byte pin = ble_read();
//          reportPinDigitalData(pin);
//        }
//        break;
//        
//      case 'T': // set pin digital state
//        {
//          byte pin = ble_read();
//          byte state = ble_read();
//          
//          digitalWrite(pin, state);
//          reportPinDigitalData(pin);
//        }
//        break;
//      
//      case 'N': // set PWM
//        {
//          byte pin = ble_read();
//          byte value = ble_read();
//          
//          analogWrite(pin, value);
//          reportPinPWMData(pin);
//        }
//        break;
//      
//      case 'O': // set Servo
//        {
//          byte pin = ble_read();
//          byte value = ble_read();
//          reportPinServoData(pin);
//        }
//        break;
//      
//      case 'A': // query all pin status
//          reportPinCapability(0);
//         reportPinDigitalData(0);
//        
//        {
//          uint8_t str[] = "ABC";
//          sendCustomData(str, 3);
//        }
//       
//        break;
//          
//      case 'P': // query pin capability
//        {
//          byte pin = ble_read();
//          reportPinCapability(pin);
//        }
//        break;
//        
//      case 'Z':
//        {
//          byte len = ble_read();
//          byte buf[len];
//          for (int i=0;i<len;i++)
//            buf[i] = ble_read();
//          Serial.println("->");
//          Serial.print("Received: ");
//          Serial.print(len);
//          Serial.println(" byte(s)");
//          Serial.print(" Hex: ");
//          for (int i=0;i<len;i++)
//            Serial.print(buf[i], HEX);
//          Serial.println();
//        }
//    }

    /// end temp
    // Parse data here
    switch (cmd)
    {
        case 'S': // set pin mode
        {
          byte pin = ble_read();
          byte mode = ble_read();
          setPin(pin,mode);
        }
        break;
        case 'T': // set pin digital state
        {
          byte pin = ble_read();
          byte state = ble_read();
          
          digitalWrite(pin, state);
        }
        break;
        case 'N': // set PWM
        {
          byte pin = ble_read();
          byte value = ble_read();
          analogWrite(pin, value);
        }
        break;
      case 'R':      // RGB values
      {
        byte pin = ble_read();
        R = ble_read();
        G = ble_read();
        B = ble_read();
        
        uint32_t color = strip.Color(R, G, B);
   //     reportRGBValues(color);
       Serial.print(pin);
       Serial.print(" ");
        strip.setPixelColor(pin, R,G,B);
        strip.show();
        milliSeconds = millis();
        noReturn = true;

      } break;
    }
   
  }
  ble_do_events();
}

// Fill the dots one after the other with a color
void colorWipe(uint32_t c) 
{
  for(uint16_t i=0; i<strip.numPixels(); i++) 
  {
      strip.setPixelColor(i, c);
  }
  strip.show();

}

void setPin(byte pin, byte mode)
{
  /* ToDo: check the mode is in its capability or not */
  /* assume always ok */
    pinMode(pin, mode);
  
    if (mode == OUTPUT)
    {
      digitalWrite(pin, LOW);
    }
    else if (mode == INPUT)
    {
      digitalWrite(pin, HIGH);
    }
    else if (mode == ANALOG)
    {
          pinMode(pin, LOW);
    }
    else if (mode == PWM)
    {
        pinMode(pin, OUTPUT);
        analogWrite(pin, 0);
    }
}

void reportRGBValues(uint32_t color)
{
//  if (IS_PIN_SERVO(pin))
//    servos[PIN_TO_SERVO(pin)].write(value);
//  pin_servo[pin] = value;

  byte blue = color & 0xFF;
  byte green = (color & 0xFF00) >> 8;
  byte red = (color & 0xFF0000) >> 16;
  
  byte buf[] = {'R', 'G', 'B', red, green, blue};
  Serial.print("RGB: ");
  Serial.print(red);
  Serial.print(green);
  Serial.println(blue);
}


void ble_write_string(byte *bytes, uint8_t len)
{
  if (buf_len + len > 20)
  {
    for (int j = 0; j < 15000; j++)
      ble_do_events();
    
    buf_len = 0;
  }
  
  for (int j = 0; j < len; j++)
  {
    ble_write(bytes[j]);
    buf_len++;
  }
    
  if (buf_len == 20)
  {
    for (int j = 0; j < 15000; j++)
      ble_do_events();
    
    buf_len = 0;
  }  
}


void sendCustomData(uint8_t *buf, uint8_t len)
{
  uint8_t data[20] = "Z";
  memcpy(&data[1], buf, len);
  ble_write_string(data, len+1);
}

void reportPinCapability(byte pin)
{
  byte buf[] = {'P', pin, 0x00};
  byte pin_cap = 0;
                    
  buf[2] = pin_cap;
  ble_write_string(buf, 3);
}


void reportPinDigitalData(byte pin)
{
  byte state = digitalRead(pin);
  byte buf[] = {'G', pin, 1, 1};         
  ble_write_string(buf, 4);
}

void reportPinPWMData(byte pin)
{
  byte buf[] = {'G', pin, 1, 1};         
  ble_write_string(buf, 4);
}



void reportPinServoData(byte pin)
{
//  if (IS_PIN_SERVO(pin))
//    servos[PIN_TO_SERVO(pin)].write(value);
//  pin_servo[pin] = value;
  
  byte buf[] = {'G', pin, 1, 1};         
  ble_write_string(buf, 4);
}

byte reportPinAnalogData()
{
  if (!ble_connected())
    return 0;
    
  static byte pin = 0;
  byte report = 0;
     
  return report;
}

