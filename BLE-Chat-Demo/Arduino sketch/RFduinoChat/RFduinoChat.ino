/*
2015 Nan Zhao
RFDUINO example scetch to implement a simple chat app
text input via serial is buffered until '\n' is received and send to receiver
input text is echoed
*/

#include <RFduinoBLE.h>

boolean isConnected;
const int buf_size = 20; //only allows 20 characters
char buf[buf_size];
boolean returnDetected;
int counter;

// pin 3 on the RGB shield is the green led
// (shows when the RFduino is advertising or not)
int advertisement_led = 3;

// pin 2 on the RGB shield is the red led
// (goes on when the RFduino has a connection from the iPhone, and goes off on disconnect)
int connection_led = 2;

void setup() {
  // led used to indicate that the RFduino is advertising
  pinMode(advertisement_led, OUTPUT);
  
  // led used to indicate that the RFduino is connected
  pinMode(connection_led, OUTPUT);

  // this is the data we want to appear in the advertisement
  // (if the deviceName and advertisementData are too long to fix into the 31 byte
  // ble advertisement packet, then the advertisementData is truncated first down to
  // a single byte, then it will truncate the deviceName)
  RFduinoBLE.advertisementData = "my Chat";
  RFduinoBLE.deviceName = "my BLE";
 
  // start the BLE stack
  RFduinoBLE.begin();
  
  isConnected = false;
  Serial.begin(9600);
  returnDetected = false;
  counter = 0;
}

void loop() {
  // switch to lower power mode
  if(isConnected){
    while(Serial.available() && counter < buf_size && !returnDetected){
      char incoming = Serial.read();
      if(incoming =='\n')
        returnDetected = true;  
      buf[counter]=incoming;  
      counter++;  
    }
    if(returnDetected || counter>=buf_size){
      RFduinoBLE.send(buf, counter);
      Serial.write((byte*)buf, counter);
      returnDetected = false;
      counter = 0;
    }
  }
}

void RFduinoBLE_onReceive(char *data, int len) {
  Serial.print("received: ");
  Serial.write((byte*)data,len);
  Serial.println();
}

void RFduinoBLE_onAdvertisement(bool start)
{
  // turn the green led on if we start advertisement, and turn it
  // off if we stop advertisement
  
  if (start)
    digitalWrite(advertisement_led, HIGH);
  else
    digitalWrite(advertisement_led, LOW);
}

void RFduinoBLE_onConnect()
{
  digitalWrite(connection_led, HIGH);
  isConnected=true;
  Serial.println("DEBUG: connected");
}

void RFduinoBLE_onDisconnect()
{
  digitalWrite(connection_led, LOW);
  isConnected=false;
  Serial.println("DEBUG: disconnected");
}
