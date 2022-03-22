#include <RFduinoBLE.h>
 
int flexPin = 2;
int edaPin = 4;
int hrvPin = 6;

int flexReading;
int hrvReading;
int edaReading;

void setup(void) {
  Serial.begin(9600);   // We'll send debugging information via the Serial monitor
  pinMode(flexPin, INPUT);
  pinMode(hrvPin, INPUT);
  pinMode(edaPin, INPUT);

  RFduinoBLE.advertisementData = "data";
//  RFduinoBLE.advertisementInterval = 1000;

  // Initialize BLE stack
  RFduinoBLE.begin();
}

void RFduinoBLE_onReceive(char *data, int len) {

  // display the first recieved byte

  Serial.println(data[0]);

}
 
void loop(void) {
  // Reading
  flexReading = analogRead(flexPin);
  delay(1);                           // clear ADC
  flexReading = analogRead(flexPin);
  hrvReading = analogRead(hrvPin);
  delay(1);                           // clear ADC
  hrvReading = analogRead(hrvPin);
  edaReading = analogRead(edaPin);
  delay(1);                           // clear ADC
  edaReading = analogRead(edaPin);

//  // Plotting
  Serial.print(hrvReading);
  Serial.print(",");
  Serial.print(flexReading);
  Serial.print(",");
  Serial.println(edaReading);

  // Bluetooth
  int vals[3];
  vals[0] = flexReading;
  vals[1] = hrvReading;
  vals[2] = edaReading;
  char buf[12]; // Arduino int size is 4 bytes
  for (int _i=0; _i<3; _i++)
      memcpy(&buf[_i*sizeof(int)], &vals[_i], sizeof(int));
  while (!RFduinoBLE.send((const char*)buf, 12));   // send data
  
  delay(100);
}
