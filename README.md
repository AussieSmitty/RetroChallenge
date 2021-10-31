# RetroChallenge
Using the Commodore 64 to control a remote control car. Control of the RC car can be via a joystick and recorded (to a floppy disk) for later autonomous 'play back' by the C64. The C64 will use RS232 to a microcontroller with a wireless transceiver that can connect to the RC car. 

By Steve Smit
Started at the end of September 2021

The code on the Arduinos used in this project is written using the IDE in the standard C++.
There is 2 source codes, one (UNO) for the transmitter side connected to the Commodore 64 via RS232, and the other (Nano) for the reciever in the RC Car.

The code on the Commodore 64 will initially be in BASIC, butwas re-written in assember.
(I used CBM Prg Studio IDE to write and compile the source)
(I then used D64 Editor to add the compiled program to a .D64 virtual floppy drive)
(I used DRACOPY to copy the .D64 contents from SD card in an SD2IEC over to a real floppy in a 1541 disk drive)

This project has been entered in the RetroChallenge 2021/10 competion.
