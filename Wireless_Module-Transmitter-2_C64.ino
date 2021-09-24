// ***********************************
// * C 6 4   RS232 to Arduino UNO    *
// *  Then transmit via Wireless     * 
// * Communication Using NRF24L01    *
// * to a 2nd NRF24L01 connected to  *
// * a 2nd Arduino UNO (reciever)    *
// *  Code for Master (Arduino UNO)  *
// *       By Steve Smit             *
// * Version 1-2 - 18th Sep 2021     *
// * Test responses to byte commands * 
// ***********************************

//Include Libraries
#include <SoftwareSerial.h>
#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>

//create an RF24 object
RF24 radio(9, 8);  // CE, CSN

//address through which two modules communicate.
const byte address[6] = "00001";

SoftwareSerial mySerial(2,3); // Rx, Tx
char myCharIN;
int myByteIN;
char myCharOUT;
int myByteOUT;


void setup()
{
  while (!Serial);{
    ; // wait for serial port to connect. Needed for Native USB only
  }
  Serial.begin(9600);
  mySerial.begin(1200);
  radio.begin();    
  radio.openWritingPipe(address); //set the address
  radio.stopListening();  //Set module as transmitter
  Serial.println("Transmitter Ready");
}


void loop()
{
  if (mySerial.available()) {
    myByteIN = mySerial.read();

  //Send message to receiver
  // const char text[] = "Commodore 64";
  // radio.write(&text, sizeof(text));
  Serial.println(myByteIN);
  radio.write(&myByteIN, sizeof(myByteIN));
  
  delay(10);
  }
}
