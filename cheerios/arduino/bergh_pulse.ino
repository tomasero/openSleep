
#include "SPI.h"
int prevCount=1;
int countbeats[] = {
  0, 0, 0};
int prevbeat[] = {
  0, 0, 0};

//VARIABLES
int pulsePin = 0;                 // Pulse Sensor purple wire connected to analog pin 0
int blinkPin = 6; 

// these variables are volatile because they are used during the interrupt service routine!
volatile int BPM;                   // used to hold the pulse rate
volatile int Signal;                // holds the incoming raw data
volatile int IBI = 2000;             // holds the time between beats, must be seeded! 
volatile boolean Pulse = false;     // true when pulse wave is high, false when it's low
volatile boolean QS = false;        // becomes true when Arduoino finds a beat.

void setup(){
  Serial.begin(9600);             // we agree to talk fast!
  interruptSetup();                 // sets up to read Pulse Sensor signal every 2mS  
}

void loop(){
  delay(3000);
  heartBeat();
 
}

void heartBeat(){
if (QS == true){  
    Serial.print("BPM = ");
    Serial.println(BPM);
    Serial.flush();   

    countbeats[2] = BPM % 10;
    //How to handle the middle digit depends on if the
    //the speed is a two or three digit number
    if(BPM > 99){
      countbeats[1] = (BPM / 10) % 10;
    }
    else{
      countbeats[1] = BPM / 10;
    }
    //Grab the first digit
    countbeats[0] = BPM / 100;
    
    prevbeat[2] = prevCount % 10;
    if(prevCount > 99){
      prevbeat[1] = (prevCount / 10) % 10;
    }
    else{
      prevbeat[1] = prevCount / 10;
    }
    prevbeat[0] = prevCount / 100;
 
    QS = false;   
  }
}





