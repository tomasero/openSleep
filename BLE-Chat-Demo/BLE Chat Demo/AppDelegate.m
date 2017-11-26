//
//  AppDelegate.m
//  BLE Chat Demo
//
//  Created by Nan Zhao on 12/4/15.
//  Copyright © 2015 MIT Media Lab. All rights reserved.
//  You may use, distribute and modify this code under the
//  terms of the MIT license

#import "AppDelegate.h"


@interface AppDelegate (){
    CBCentralManager *manager;
    CBPeripheral *peripheral;
    
    //autoconnect to the last known netowrk
    BOOL autoConnect;
    
    //needed for communication with the RFDuino
    //BLE sending characteritics
    CBCharacteristic *send_characteristic;
    //BLE disconnect chatacteristics
    CBCharacteristic *disconnect_characteristic;
    
    //BLE service loaded
    bool loadedService;
    
    //indicated whether I am connected to a BLE device, used to updated connectButton
    bool isConnected;
    
    //buffers the last few reveiced and send text
    NSMutableArray *incomingTextArray;
}

@property (weak) IBOutlet NSWindow *window;
@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.BLEDevices = [NSMutableArray array];
    isConnected = false;
    incomingTextArray = [NSMutableArray array];
    autoConnect = true;
    loadedService = false;
    
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    if( autoConnect )
    {
        [self startScan];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    if(peripheral)
    {
        [manager cancelPeripheralConnection:peripheral];
    }
    
    [self stopScan];
}

- (IBAction)refreshButtonPressed:(id)sender {
    
    //disable refresh button while scanning
    [self.refreshButton setEnabled:false];
    //[self.refreshButton setTransparent:true];
    
    if (peripheral)
    {
        /* Disconnect if it's already connected */
        /* Device is not connected, cancel pendig connection */
        [manager cancelPeripheralConnection:peripheral];
    }
    
    /* No outstanding connection, scan for peripherals*/
    if( [self isLECapableHardware] )
    {
        autoConnect = FALSE;
        [self.arrayController removeObjects:self.BLEDevices];
        [self startScan];
    }
}

- (IBAction)connectButtonPressed:(id)sender {
    if(!isConnected){
        [self stopScan];
        
        //enable refresh button
        [self.refreshButton setEnabled:true];
        //[self.refreshButton setTransparent:false];
        
        NSLog(@"DEBUG: Now selected row: %li", self.tableView.selectedRow);
        NSInteger selectedRow = self.tableView.selectedRow;
        
        //if a device is selected then connect to the device
        if (selectedRow >= 0)
        {
            peripheral = [self.BLEDevices objectAtIndex:selectedRow];
            [manager connectPeripheral:peripheral options:nil];
            [self.connectButton setTitle:@"Connecting ..."];
        }
    }else{
        if(peripheral && isConnected)
        {
            /* Disconnect if it's already connected */
            [manager cancelPeripheralConnection:peripheral];
        }
    }
}

- (IBAction)sendButtonPressed:(id)sender {
    [self updateWithUserText];
    
}

- (IBAction)textFieldEntered:(id)sender {
    [self updateWithUserText];
}


#pragma mark - Incoming Data

/*
 Update UI with incoming text received from device
 */
- (void) updateWithIncomingText:(NSString *)data
{
    //1) add new text to text buffer array
    //2) remove the first line when more than 10 lines
    //3) generate new text string as attributedstring
    //4) display attributed string
    
    //update text object array
    NSText *textObject=[[NSText alloc]init];
    [textObject setString:data];
    [textObject setAlignment:NSTextAlignmentRight];
    [textObject setTextColor:[NSColor blackColor]];
    [incomingTextArray addObject:textObject];
    if  ([incomingTextArray count]>10) {
        [incomingTextArray removeObjectAtIndex:0];
    }
    
    //update text in text view
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc]init];
    for(NSText *thisTextObject in incomingTextArray){
        NSMutableAttributedString *thisAttrString = [[NSMutableAttributedString alloc] initWithString:thisTextObject.string];
        [thisAttrString setAlignment:thisTextObject.alignment range:NSMakeRange(0,thisAttrString.length)];
        [attrString appendAttributedString:thisAttrString];
    }
    [self.chatTextView setEditable:YES];
    [self.chatTextView setString:@""];
    [self.chatTextView insertText:attrString];
    [self.chatTextView setEditable:NO];
    
}

- (void) updateWithUserText
{
    //append \n to user string
    NSString * userString = [NSString stringWithFormat:@"%@%@",[self.textField stringValue], @"\n"];
    //reset input text field
    [self.textField setStringValue:@""];

    //update text object array
    NSText *textObject=[[NSText alloc]init];
    [textObject setString:userString];
    [textObject setAlignment:NSTextAlignmentLeft];
    [textObject setTextColor:[NSColor grayColor]];
    [incomingTextArray addObject:textObject];
    if  ([incomingTextArray count]>10) {
        [incomingTextArray removeObjectAtIndex:0];
    }
    
    //update text in text view
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc]init];
    for(NSText *thisTextObject in incomingTextArray){
        NSMutableAttributedString *thisAttrString = [[NSMutableAttributedString alloc] initWithString:thisTextObject.string];
        [thisAttrString setAlignment:thisTextObject.alignment range:NSMakeRange(0,thisAttrString.length)];
        [attrString appendAttributedString:thisAttrString];
    }
    [self.chatTextView setEditable:YES];
    [self.chatTextView setString:@""];
    [self.chatTextView insertText:attrString];
    [self.chatTextView setEditable:NO];

    // prepare data to send
    // each substring will be 20 characters long
    NSInteger startingPoint = 0;
    NSInteger substringLength = 20;
    // loop through the array as many times as the substring length fits into the test
    // string
    for (NSInteger i = 0; i < (float)userString.length / (float)substringLength; i++) {
        NSString *substring = [[NSString alloc]init];
        if (startingPoint+substringLength>userString.length) {
            substring = [userString substringWithRange:NSMakeRange(startingPoint, userString.length-startingPoint)];
        }else {
            substring = [userString substringWithRange:NSMakeRange(startingPoint, substringLength)];
        }
        startingPoint += substringLength;
        
        //send to BLE device
        [self send:[substring dataUsingEncoding:NSUTF8StringEncoding]];
    }
}



- (void)send:(NSData *)data
{
    NSInteger max_data = 20;
    
    if (! loadedService) {
        @throw [NSException exceptionWithName:@"sendData" reason:@"please wait for ready callback" userInfo:nil];
    }
    
    if ([data length] > max_data) {
        @throw [NSException exceptionWithName:@"sendData" reason:@"max data size exceeded" userInfo:nil];
    }
    
    [peripheral writeValue:data forCharacteristic:send_characteristic type:CBCharacteristicWriteWithoutResponse];
    
    //NSLog(@"rfduino send data");
}



#pragma mark - Start/Stop Scan methods
/*
 Uses CBCentralManager to check whether the current platform/hardware supports Bluetooth LE. An alert is raised if Bluetooth LE is not enabled or is not supported.
 */
- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    
    switch ([manager state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            return FALSE;
            
    }
    
    NSLog(@"Central manager state: %@", state);
    return FALSE;
}

/*
 Request CBCentralManager to scan for BLE peripherals using service UUID 0x2220
 */
- (void) startScan
{
    [manager scanForPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"2220"]] options:nil];
}

/*
 Request CBCentralManager to stop scanning for heart rate peripherals
 */
- (void) stopScan
{
    [manager stopScan];
}

#pragma mark - CBCentralManager delegate methods
/*
 Invoked whenever the central manager's state is updated.
 */
- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    [self isLECapableHardware];
}

/*
 Invoked when the central discovers BLE peripheral while scanning.
 */
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)aPeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSMutableArray *peripherals = [self mutableArrayValueForKey:@"BLEDevices"];
    if( ![self.BLEDevices containsObject:aPeripheral] )
        [peripherals addObject:aPeripheral];
    
    /* Retreive already known devices */
    if(autoConnect)
    {
      if (@available(macOS 10.13, *)) {
        [manager retrievePeripheralsWithIdentifiers:[NSArray arrayWithObject:(id)aPeripheral.identifier]];
      } else {
        // Fallback on earlier versions
      }
    }
}

/*
 Invoked when the central manager retrieves the list of known peripherals.
 Automatically connect to first known peripheral
 */
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Retrieved peripheral: %lu - %@", [peripherals count], peripherals);
    
    [self stopScan];
    
    /* If there are any known devices, automatically connect to it.*/
    if([peripherals count] >=1)
    {
        //change connectButton function to disconnect
        [self.connectButton setTitle:@"Disconnect"];
        
        peripheral = [peripherals objectAtIndex:0];
        [manager connectPeripheral:peripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    }
}

/*
 Invoked whenever a connection is succesfully created with the peripheral.
 Discover available services on the peripheral
 */
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral
{
    [aPeripheral setDelegate:self];
    [aPeripheral discoverServices:nil];
    
    //change connectButton function to disconnect
    [self.connectButton  setTitle:@"Disconnect"];
    isConnected = true;
}

/*
 Invoked whenever an existing connection with the peripheral is torn down.
 Reset local variables
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    //change connectButton function to connect
    [self.connectButton setTitle:@"Connect"];
    isConnected = false;
    loadedService = false;
    
    //forget about any peripherals
    if( peripheral )
    {
        [peripheral setDelegate:nil];
        peripheral = nil;
    }
}

/*
 Invoked whenever the central manager fails to create a connection with the peripheral.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    NSLog(@"Fail to connect to peripheral: %@ with error = %@", aPeripheral, [error localizedDescription]);
    //change connectButton function to connect
    [self.connectButton setTitle:@"Connect"];
    
    //forget about any peripherals
    if( peripheral )
    {
        [peripheral setDelegate:nil];
        peripheral = nil;
    }
}


#pragma mark - CBPeripheral delegate methods
/*
 Invoked upon completion of a -[discoverServices:] request.
 Discover available characteristics on interested services
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    for (CBService *aService in aPeripheral.services)
    {
        NSLog(@"Service found with UUID: %@", aService.UUID);
        
        /* RFduino Service */
        // @"2221" receive
        // @"2222" send
        // @"2223" disconnect
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"2220"]])
        {
            NSArray *characteristics = [NSArray arrayWithObjects:[CBUUID UUIDWithString:@"2221"], [CBUUID UUIDWithString:@"2222"], [CBUUID UUIDWithString:@"2223"], nil];
            [aPeripheral discoverCharacteristics:characteristics forService:aService];
        }
    }
}

/*
 Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 Perform appropriate operations on interested characteristics
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"2220"]]) {
            
            loadedService = true;
        
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2221"]]) {
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2222"]]) {
                    send_characteristic = characteristic;
                } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2223"]]) {
                    disconnect_characteristic = characteristic;
                }
            }
            
        }
    }
    //https://www.bluetooth.com/specifications/gatt/characteristics
    if ( [service.UUID isEqual:[CBUUID UUIDWithString:@"1800"]] ) //0x1800 is the Generic Access Service Identifier
    {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            /* Read device name */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A00"]]) //CBUUIDDeviceNameString 0x2A00
            {
                [aPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a Device Name Characteristic");
            }
        }
    }
    
}

/*
 Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    /* Updated received data */
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2221"]])
    {
        if( (characteristic.value)  || !error )
        {
            NSString * incomingData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
            NSLog(@"Received: %@", incomingData);
            [self updateWithIncomingText:incomingData];
        }
    }
    /* Value for device Name received */
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A00"]])
    {
        NSString * deviceName = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"Device Name = %@", deviceName);
    }
    
}




@end
