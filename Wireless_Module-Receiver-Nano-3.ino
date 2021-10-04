// RetroChallenge - 2021/10
// Using the C64 to control a remote control car
// Code for Arduino Nano in RC car
// Initital byte transfer test 4
// Allowing for all directions
// and controlling power to steering using
// millisecond timing flag and variable

//Include Libraries
#include <Servo.h>
#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>

//create an RF24 object
RF24 radio(7, 8);  // CE, CSN
const byte address[6] = "00001"; //address through which two modules communicate.

byte MyByteIN = 3;
unsigned long previousTime = 0;
// unsigned long currentTime = millis();
unsigned long TurningTime = 0;    // Turning time is calculated from mills 
boolean TTFlag = false; // Steering is currently centered
int enB = 9; // Blue - Steering PWM pin
int in4 = 5; // green
int in3 = 4; // yellow
int enA = 3; // Brown - Rear wheels PWM for power level
int in1 = 2; // orange
int in2 = 10; // red


void setup()
{
  while (!Serial); {
    delay(10);
    }
    Serial.begin(9600);
  pinMode(enA, OUTPUT);
  pinMode(enB, OUTPUT);
  pinMode(in1, OUTPUT);
  pinMode(in2, OUTPUT);
  pinMode(in3, OUTPUT);
  pinMode(in4, OUTPUT);
  radio.begin(); 
  radio.openReadingPipe(0, address);  //set the address
  radio.startListening();   //Set module as receiver
  analogWrite(enB, 0); // cut power to steering motor
  analogWrite(enA, 0); // cut power to rear motor
  Serial.println("Reciever ready");
  // previousTime = currentTime;
}

void loop()
{
  if (radio.available()) {
    radio.read(&MyByteIN, sizeof(MyByteIN));
    Serial.println(MyByteIN);
    previousTime = millis();
  }
  if (MyByteIN == 3) {  // This is a centering event
  analogWrite(enB, 0); // cut power to steeriing motor
  analogWrite(enA, 0); // cut power to rear motor too
  if (TTFlag = true) {
    if (TurningTime > 0 ) {
      TurningTime = TurningTime - (millis()-previousTime);
      if (TurningTime > 1000) { TurningTime = 0; } 
      }
      if (TurningTime <= 0) {
        TurningTime = 0;
        TTFlag = false;
        // previousTime = millis();
      }
    } else {
    TurningTime=0;
    previousTime=millis();
    }
  }
  if (MyByteIN == 1) {  // Turn on Steering motor (Left)
  digitalWrite(in3, LOW);
  digitalWrite(in4, HIGH);
  if (TTFlag = false) {  // steering is centred
    TTFlag = true;
    analogWrite(enB, 250);
    TurningTime = 0;
    previousTime = millis();
  } else {
    TurningTime = millis() - previousTime;
    if (TurningTime < 600) {
      analogWrite(enB, 250); // apply full power to turning motor
      }
      else {
        analogWrite(enB, 150); // lower power to hold in truned position
        TurningTime = 600;
      }
   }
 }
  if (MyByteIN == 2) {  // Turn on Steering motor (Right)
  digitalWrite(in3, HIGH);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
  digitalWrite(in4, LOW);
  if (TTFlag = false) {  // steering is centred
    TTFlag = true;
    analogWrite(enB, 250);
    TurningTime = 0;
    previousTime = millis();
  } else {
    TurningTime = millis() - previousTime;
    if (TurningTime < 600) {
      analogWrite(enB, 250); // apply full power to turning motor
      }
      else {
        analogWrite(enB, 150); // lower power to hold in truned position
        TurningTime = 600;
      }
    }
  }
  if (MyByteIN == 4) {  // Drive forward
  digitalWrite(in1, LOW);
  digitalWrite(in2, HIGH);
  analogWrite(enA, 250);
  analogWrite(enB, 0); // cut power to steeriing motor
  if (TTFlag = true) {
    if (TurningTime > 0 ) {
      TurningTime = TurningTime - (millis()-previousTime);
      if (TurningTime > 1000) { TurningTime = 0; } 
      }
      if (TurningTime <= 0) {
        TurningTime = 0;
        TTFlag = false;
        // previousTime = millis();
      }
    } else {
    TurningTime=0;
    previousTime=millis();
    }  
  }
  if (MyByteIN == 5) {  // Drive backwards
  digitalWrite(in1, HIGH);
  digitalWrite(in2, LOW);
  analogWrite(enA, 250);
  analogWrite(enB, 0); // cut power to steeriing motor
  if (TTFlag = true) {
    if (TurningTime > 0 ) {
      TurningTime = TurningTime - (millis()-previousTime);
      if (TurningTime > 1000) { TurningTime = 0; } 
      }
      if (TurningTime <= 0) {
        TurningTime = 0;
        TTFlag = false;
        // previousTime = millis();
      }
    } else {
    TurningTime=0;
    previousTime=millis();
    }  
  }
  if (MyByteIN == 6) {  // Drive forward and right
  digitalWrite(in1, LOW);
  digitalWrite(in2, HIGH);
  analogWrite(enA, 250);
  digitalWrite(in3, HIGH);  // Right direction                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
  digitalWrite(in4, LOW);
  if (TTFlag = false) {  // steering is centred
    TTFlag = true;
    analogWrite(enB, 250);
    TurningTime = 0;
    previousTime = millis();
  } else {
    TurningTime = millis() - previousTime;
    if (TurningTime < 600) {
      analogWrite(enB, 250); // apply full power to turning motor
      }
      else {
        analogWrite(enB, 150); // lower power to hold in truned position
      }
    }  
  }
  if (MyByteIN == 9) {  // Drive forward and left
  digitalWrite(in1, LOW);
  digitalWrite(in2, HIGH);
  analogWrite(enA, 250);
  digitalWrite(in3, LOW);  // Left direction                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
  digitalWrite(in4, HIGH);
  if (TTFlag = false) {  // steering is centred
    TTFlag = true;
    analogWrite(enB, 250);
    TurningTime = 0;
    previousTime = millis();
  } else {
    TurningTime = millis() - previousTime;
    if (TurningTime < 600) {
      analogWrite(enB, 250); // apply full power to turning motor
      }
      else {
        analogWrite(enB, 150); // lower power to hold in truned position
      }
    }  
  }
  if (MyByteIN == 7) {  // Drive backwards and right
  digitalWrite(in1, HIGH);
  digitalWrite(in2, LOW);
  analogWrite(enA, 250);
  digitalWrite(in3, HIGH);  // Right direction                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
  digitalWrite(in4, LOW);
  if (TTFlag = false) {  // steering is centred
    TTFlag = true;
    analogWrite(enB, 250);
    TurningTime = 0;
    previousTime = millis();
  } else {
    TurningTime = millis() - previousTime;
    if (TurningTime < 600) {
      analogWrite(enB, 250); // apply full power to turning motor
      }
      else {
        analogWrite(enB, 150); // lower power to hold in truned position
      }
    }  
  }
  if (MyByteIN == 8) {  // Drive backwards and left
  digitalWrite(in1, HIGH);
  digitalWrite(in2, LOW);
  analogWrite(enA, 250);
  digitalWrite(in3, LOW);  // Left direction                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
  digitalWrite(in4, HIGH);
  if (TTFlag = false) {  // steering is centred
    TTFlag = true;
    analogWrite(enB, 250);
    TurningTime = 0;
    previousTime = millis();
  } else {
    TurningTime = millis() - previousTime;
    if (TurningTime < 600) {
      analogWrite(enB, 250); // apply full power to turning motor
      }
      else {
        analogWrite(enB, 150); // lower power to hold in truned position
      }
    }  
  }
  Serial.println(TurningTime);
  Serial.println(millis()-previousTime);
  delay(50);
}
