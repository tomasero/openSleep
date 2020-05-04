

#include <bluefruit.h>


// BLE Service
BLEDis  bledis;
BLEUart bleuart;
BLEBas  blebas;

//Analog Pin Configuration
int hr = A2 , eda = A0 , flex = A1 ;

int led = 12 ;

void setup() {
    pinMode(led,OUTPUT);
    Serial.begin(115200);
    Serial.println("sleepDuino v1.1");
    Serial.println("---------------------------\n");
    blinkLED(5);
    bleSetup();
}

void loop()
{

    int numVals = 3;
    int vals[numVals];
    int cnt = numVals * 4 ;
    uint8_t buf[cnt];

    vals[0] = analogRead(flex);
    vals[1] = analogRead(hr);
    vals[2] = analogRead(eda);

    for (int _i=0; _i<numVals; _i++)
        memcpy(&buf[_i*sizeof(int)], &vals[_i], sizeof(int));
    bleuart.write( buf, cnt );
    delay(50);
    digitalToggle(led);
    waitForEvent();
}

void blinkLED(int n){
    for(int i = 0 ; i < n ; i++){
        digitalWrite(led,HIGH);
        delay(250);
        digitalWrite(led,LOW);
        delay(250);
        //Serial.println("---------------------------\n");
    }
}


void bleSetup(){
    Bluefruit.configPrphBandwidth(BANDWIDTH_MAX);
    Bluefruit.begin();
    Bluefruit.setTxPower(4);
    Bluefruit.setName("sleepDuino");
    Bluefruit.setConnectCallback(connect_callback);
    Bluefruit.setDisconnectCallback(disconnect_callback);
    bledis.setManufacturer("MIT Media Lab");
    bledis.setModel("V1.2");
    bledis.begin();
  // Configure and Start BLE Uart Service
    bleuart.begin();
    Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
    Bluefruit.Advertising.addTxPower();
    Bluefruit.Advertising.addService(bleuart);
    Bluefruit.ScanResponse.addName();
    Bluefruit.Advertising.restartOnDisconnect(true);
    Bluefruit.Advertising.setInterval(32, 244);   
    Bluefruit.Advertising.setFastTimeout(30);     
    Bluefruit.Advertising.start(0); 
}

void connect_callback(uint16_t conn_handle)
{
  char central_name[32] = { 0 };
  Bluefruit.Gap.getPeerName(conn_handle, central_name, sizeof(central_name));

  Serial.print("Connected to ");
  Serial.println(central_name);
}

void disconnect_callback(uint16_t conn_handle, uint8_t reason)
{
  (void) conn_handle;
  (void) reason;
  Serial.println();
  Serial.println("Disconnected");
}

void rtos_idle_callback(void){
  // Don't call any other FreeRTOS blocking API()
  // Perform background task(s) here
}
