//Include Libraries
#include <Servo.h>
#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>

//create an RF24 object
RF24 radio(9, 8);  // CE, CSN

//address through which two modules communicate.
const byte address[6] = "00001";
byte MyByteIN = 3;
Servo MyServo1;
int ServoPos1 = 110;


void setup()
{
  while (!Serial); {
    delay(10);
    }
    Serial.begin(9600);
  MyServo1.attach(7);
  radio.begin(); 
  radio.openReadingPipe(0, address);  //set the address
  radio.startListening();   //Set module as receiver
  MyServo1.write(ServoPos1);
  Serial.println("Reciever ready");
}

void loop()
{
  MyByteIN = 0; //  
  //Read the data if available in buffer
  if (radio.available()) {
    radio.read(&MyByteIN, sizeof(MyByteIN));
    Serial.println(MyByteIN);
  }
  if (MyByteIN == 1) {
    ServoPos1 = ServoPos1 + 1;
    if (ServoPos1 > 180) {
      ServoPos1 = 180;
    }
    MyServo1.write(ServoPos1);
    Serial.println(ServoPos1);
  }
  if (MyByteIN == 2) {
    ServoPos1 = ServoPos1 - 1;
    if (ServoPos1 == 0) {
      ServoPos1 = 1;
    }
    MyServo1.write(ServoPos1);
    Serial.println(ServoPos1);
  }
  if (MyByteIN == 3) {
    ServoPos1 = 90;
    MyServo1.write(ServoPos1);
    Serial.println(ServoPos1);
  }
}
