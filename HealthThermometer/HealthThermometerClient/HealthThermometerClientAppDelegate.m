/*
     File: HealthThermometerClientAppDelegate.m
 Abstract: Implementatin of Health Thermometer Client app using Bluetooth Low Energy (LE) Health Thermometer Service. This app demonstrats the use of CoreBluetooth APIs for LE devices.
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import "HealthThermometerClientAppDelegate.h"

@implementation HealthThermometerClientAppDelegate

@synthesize window;
@synthesize scanSheet;
@synthesize deviceName;
@synthesize manufactureName;
@synthesize tempType;
@synthesize tempString;
@synthesize timeStampString;
@synthesize connectStatus;
@synthesize mesurementType;
@synthesize temperatureMeasurementChar;
@synthesize intermediateTempChar;
@synthesize thermometers;
@synthesize arrayController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{    
    self.thermometers = [NSMutableArray array];
    /* autoConnect = TRUE; */  /* uncomment this line if you want to automatically connect to previosly known peripheral */
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    if( autoConnect )
    {
        [self startScan];
    }
}

- (void) dealloc
{
    [self stopScan];
    
    [testPeripheral setDelegate:nil];
    [testPeripheral release];
    
    [thermometers release];
        
    [manager release];
    [temperatureMeasurementChar release];
    [intermediateTempChar release];
    
    [super dealloc];
}

/* 
 Disconnect peripheral when application terminate 
 */
- (void) applicationWillTerminate:(NSNotification *)notification
{
    if(testPeripheral)
    {
        [manager cancelPeripheralConnection:testPeripheral];
    }
}

#pragma mark - Scan sheet methods
/* 
 Open scan sheet to discover thermometer peripherals if it is LE capable hardware 
 */
- (IBAction)openScanSheet:(id)sender 
{
    if( [self isLECapableHardware] )
    {
        autoConnect = FALSE;
        [arrayController removeObjects:thermometers];
        [NSApp beginSheet:self.scanSheet modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
        [self startScan];
    }
}

/*
 Close scan sheet once device is selected
 */
- (IBAction)closeScanSheet:(id)sender 
{
    [NSApp endSheet:self.scanSheet returnCode:NSAlertDefaultReturn];
    [self.scanSheet orderOut:self];    
}

/*
 Close scan sheet without choosing any device
 */
- (IBAction)cancelScanSheet:(id)sender
{
    [NSApp endSheet:self.scanSheet returnCode:NSAlertAlternateReturn];
    [self.scanSheet orderOut:self];
}

/* 
 This method is called when Scan sheet is closed. Initiate connection to selected thermometer peripheral
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo 
{    
    [self stopScan];
    if(returnCode == NSAlertDefaultReturn)
    {            
        NSIndexSet *indexes = [self.arrayController selectionIndexes];
        if ([indexes count] != 0) 
        {
            NSUInteger anIndex = [indexes firstIndex];
            testPeripheral = [self.thermometers objectAtIndex:anIndex];
            [testPeripheral retain];
            [progressIndicator setHidden:FALSE];
            [progressIndicator startAnimation:self];
            [connectButton setTitle:@"Cancel"];
            [manager connectPeripheral:testPeripheral options:nil];
        }
    }
}

#pragma mark - Connect Button
/*
 This method is called when connect button pressed and it takes appropriate actions depending on device connection state
 */
- (IBAction)connectButtonPressed:(id)sender
{
    if(testPeripheral && ([testPeripheral state] == CBPeripheralStateConnected))
    {
        /* Disconnect peripheral if its already connected */
        [manager cancelPeripheralConnection:testPeripheral];
    }
    else if (testPeripheral)
    {
        /* Device is not connected, cancel pending connection */
        [progressIndicator setHidden:TRUE];
        [progressIndicator stopAnimation:self];
        [connectButton setTitle:@"Connect"];
        [manager cancelPeripheralConnection:testPeripheral];
        [self openScanSheet:nil];
    }
    else
    {
        /* No outstanding connection, open scan sheet */
        [self openScanSheet:nil];
    }
}

#pragma mark - Start/Stop Scan methods
/*
 Request CBCentralManager to scan for health thermometer peripherals using service UUID 0x1809
 */
- (void)startScan 
{    
    NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:FALSE], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
    
    [manager scanForPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"2220"]] options:options];
}

/*
 Request CBCentralManager to stop scanning for health thermometer peripherals
 */
- (void)stopScan
{
    [manager stopScan];
}


#pragma mark - Start/Stop notification/indication
/*
 Start or stop receiving notification or indication on interested characteristics
 */
- (IBAction)startButtonPressed:(id)sender
{
    BOOL notify;
    
    if([[startStopButton title] isEqualToString:@"Start"])
    {
        notify = TRUE;
    }
    else
    {
        notify = FALSE;
    }

    if(self.intermediateTempChar)
    {
        /* Set notification on intermediate temperature measurement characteristic */
        [testPeripheral setNotifyValue:notify forCharacteristic:self.intermediateTempChar];
    }
    else if( self.temperatureMeasurementChar)
    {
        /* Set indication on temperature measurement characteristic */
        [testPeripheral setNotifyValue:notify forCharacteristic:self.temperatureMeasurementChar];
    }
}

#pragma mark - LE Capable Platform/Hardware check
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
    
    [self cancelScanSheet:nil];
    
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:state];
    [alert addButtonWithTitle:@"OK"];
    [alert setIcon:[[[NSImage alloc] initWithContentsOfFile:@"Thermometer"] autorelease]];
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
    return FALSE;
}

#pragma mark - CBManagerDelegate methods
/*
 Invoked whenever the central manager's state is updated.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central 
{
    [self isLECapableHardware];
}

/*
 Invoked when the central discovers thermometer peripheral while scanning.
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
  if (@available(macOS 10_13, *)) {
    NSLog(@"Did discover peripheral. peripheral: %@ rssi: %@, UUID: %@ advertisementData: %@ ", peripheral, RSSI, peripheral.identifier, advertisementData);
  } else {
    // Fallback on earlier versions
  }
   
    NSMutableArray *peripherals = [self mutableArrayValueForKey:@"thermometers"];
    if( ![self.thermometers containsObject:peripheral] )
        [peripherals addObject:peripheral];
     
    /* Retreive already known devices */
    if(autoConnect)
    {
      if (@available(macOS 10_13, *)) {
        [manager retrievePeripherals:[NSArray arrayWithObject:(id)peripheral.identifier]];
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
        [progressIndicator setHidden:FALSE];
        [progressIndicator startAnimation:self];
        testPeripheral = [peripherals objectAtIndex:0];
        [testPeripheral retain];
        [connectButton setTitle:@"Cancel"];
        [manager connectPeripheral:testPeripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    }
}

/*
 Invoked whenever a connection is succesfully created with the peripheral. 
 Discover available services on the peripheral
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Did connect to peripheral: %@", peripheral);
        
    self.connectStatus = @"Connected";
    [connectButton setTitle:@"Disconnect"];
    [progressIndicator setHidden:TRUE];
    [progressIndicator stopAnimation:self];
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
}

/*
 Invoked whenever an existing connection with the peripheral is torn down. 
 Reset local variables
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Did Disconnect to peripheral: %@ with error = %@", peripheral, [error localizedDescription]);
    self.connectStatus = @"Not Connected";
    self.deviceName = @"";
    self.timeStampString = @"";
    self.tempType = @"";
    self.tempString = @"";
    self.mesurementType = @"";
    self.manufactureName = @"";
    [connectButton setTitle:@"Connect"];
    [startStopButton setTitle:@"Start"];
    if( testPeripheral )
    {
        [testPeripheral setDelegate:nil];
        [testPeripheral release];
        testPeripheral = nil;
    }
}

/*
 Invoked whenever the central manager fails to create a connection with the peripheral.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Fail to connect to peripheral: %@ with error = %@", peripheral, [error localizedDescription]);
    [connectButton setTitle:@"Connect"];
    if( testPeripheral )
    {
        [testPeripheral setDelegate:nil];
        [testPeripheral release];
        testPeripheral = nil;
    }
}

#pragma mark - CBPeripheralDelegate methods
/*
 Invoked upon completion of a -[discoverServices:] request.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) 
    {
        NSLog(@"Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    for (CBService * service in peripheral.services)
    {
        NSLog(@"Service found with UUID: %@", service.UUID);
        
        if([service.UUID isEqual:[CBUUID UUIDWithString:@"2220"]])
        {
            /* Thermometer Service - discover termperature measurement, intermediate temperature measturement and measurement interval characteristics */
            [testPeripheral discoverCharacteristics:[NSArray arrayWithObjects:[CBUUID UUIDWithString:@"2A1E"], [CBUUID UUIDWithString:@"2A1C"], [CBUUID UUIDWithString:@"2222"], nil] forService:service];
        }
        else if([service.UUID isEqual:[CBUUID UUIDWithString:@"2220"]])
        {
            /* Device Information Service - discover manufacture name characteristic */
            [testPeripheral discoverCharacteristics:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"2222"]] forService:service];
        }
        else if ( [service.UUID isEqual:[CBUUID UUIDWithString:@"1800"]] )
        {
            /* GAP (Generic Access Profile) - discover device name characteristic */
            [testPeripheral discoverCharacteristics:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"2A00"]]  forService:service];
        }
    }
}

/*
 Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error 
{
    if (error) 
    {
        NSLog(@"Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    
    if([service.UUID isEqual:[CBUUID UUIDWithString:@"2220"]])
    {

        for (CBCharacteristic * characteristic in service.characteristics)
        {
            /* Set indication on temperature measurement */
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2222"]])
            {
                self.temperatureMeasurementChar = characteristic;
              NSLog(@"%@", self.temperatureMeasurementChar);
              NSLog(@"Found a Temperature Measurement Characteristic");
            }
            /* Set notification on intermediate temperature measurement */
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2222"]])
            {
                self.intermediateTempChar = characteristic;
                NSLog(@"%@", self.intermediateTempChar);
                NSLog(@"Found a Intermediate Temperature Measurement Characteristic");
            }            
            /* Write value to measurement interval characteristic */
            if( [characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2222"]])
            {
              NSLog(@"%@", characteristic.value);
                char val = '2';
                NSData * valData = [NSData dataWithBytes:(void*)&val length:sizeof(val)];
              [testPeripheral readValueForCharacteristic:characteristic];
                [testPeripheral writeValue:valData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                NSLog(@"Found a Temperature Measurement Interval Characteristic - Write interval value");
            }
        }
    }
    
    if([service.UUID isEqual:[CBUUID UUIDWithString:@"2220"]])//180A
    {
        for (CBCharacteristic * characteristic in service.characteristics)
        {
            /* Read manufacturer name */
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2222"]])//2A29
            {                
                [testPeripheral readValueForCharacteristic:characteristic];
                NSLog(@"Found a Device Manufacturer Name Characteristic - Read manufacturer name");
            }           
        } 
    }
    
    if ( [service.UUID isEqual:[CBUUID UUIDWithString:@"2220"]] )//1800
    {
        for (CBCharacteristic *characteristic in service.characteristics) 
        {
            /* Read device name */
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2222"]])
            {                
                [testPeripheral readValueForCharacteristic:characteristic];
                NSLog(@"Found a Device Name Characteristic - Read device name");
            }
        }
    }
}

/*
 Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
  NSLog(@"didUpdateValue");
  NSLog(@"%@", characteristic.value);
  if (error)
    {
        NSLog(@"Error updating value for characteristic %@ error: %@", characteristic.UUID, [error localizedDescription]);
        return;
    }
  NSLog(@"%@", characteristic.UUID);
    /* Updated value for temperature measurement received */
    if(([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A1E"]] || [characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A1C"]]) && characteristic.value)
    {
        NSData * updatedValue = characteristic.value;
      NSLog(@"data");
      
        uint8_t* dataPointer = (uint8_t*)[updatedValue bytes];

        uint8_t flags = dataPointer[0]; dataPointer++;
        int32_t tempData = (int32_t)CFSwapInt32LittleToHost(*(uint32_t*)dataPointer); dataPointer += 4;
        NSLog(@"%d", tempData);
//        int8_t exponent = (int8_t)(tempData >> 24);
//        int32_t mantissa = (int32_t)(tempData & 0x00FFFFFF);
//
//        if( tempData == 0x007FFFFF )
//        {
//            NSLog(@"Invalid temperature value received");
//            return;
//        }
//
//        float tempValue = (float)(mantissa*pow(10, exponent));
//        self.tempString = [NSString stringWithFormat:@"%.1f", tempValue];
//
//        /* measurement type */
//        if(flags & 0x01)
//        {
//            self.mesurementType = @"ºF";
//        }
//        else
//        {
//            self.mesurementType = @"ºC";
//        }
//
//        /* timestamp */
//        if( flags & 0x02 )
//        {
//            uint16_t year = CFSwapInt16LittleToHost(*(uint16_t*)dataPointer); dataPointer += 2;
//            uint8_t month = *(uint8_t*)dataPointer; dataPointer++;
//            uint8_t day = *(uint8_t*)dataPointer; dataPointer++;
//            uint8_t hour = *(uint8_t*)dataPointer; dataPointer++;
//            uint8_t min = *(uint8_t*)dataPointer; dataPointer++;
//            uint8_t sec = *(uint8_t*)dataPointer; dataPointer++;
//
//            NSString * dateString = [NSString stringWithFormat:@"%d %d %d %d %d %d", year, month, day, hour, min, sec];
//
//            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
//            [dateFormat setDateFormat: @"yyyy MM dd HH mm ss"];
//            NSDate* date = [dateFormat dateFromString:dateString];
//
//            [dateFormat setDateFormat:@"EEE MMM dd, yyyy"];
//            NSString* dateFormattedString = [dateFormat stringFromDate:date];
//
//            [dateFormat setDateFormat:@"h:mm a"];
//            NSString* timeFormattedString = [dateFormat stringFromDate:date];
//
//            [dateFormat release];
//
//            if( dateFormattedString && timeFormattedString )
//            {
//                self.timeStampString = [NSString stringWithFormat:@"%@ at %@", dateFormattedString, timeFormattedString];
//            }
//        }
//
//        /* temperature type */
//        if( flags & 0x04 )
//        {
//            uint8_t type = *(uint8_t*)dataPointer;
//            NSString* location = nil;
//
//            switch (type)
//            {
//                case 0x01:
//                    location = @"Armpit";
//                    break;
//                case 0x02:
//                    location = @"Body - general";
//                    break;
//                case 0x03:
//                    location = @"Ear";
//                    break;
//                case 0x04:
//                    location = @"Finger";
//                    break;
//                case 0x05:
//                    location = @"Gastro-intenstinal Tract";
//                    break;
//                case 0x06:
//                    location = @"Mouth";
//                    break;
//                case 0x07:
//                    location = @"Rectum";
//                    break;
//                case 0x08:
//                    location = @"Toe";
//                    break;
//                case 0x09:
//                    location = @"Tympanum - ear drum";
//                    break;
//                default:
//                    break;
//            }
//            if (location)
//            {
//                self.tempType = [NSString stringWithFormat:@"Body location: %@", location];
//            }
//        }
    }
    
    /* Value for device name received */
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A00"]])
    {
        self.deviceName = [[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"Device Name = %@", self.deviceName);
    }
    
    /* Value for manufacturer name received */
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A29"]]) 
    {
        self.manufactureName = [[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"Manufacturer Name = %@", self.manufactureName);
    }
}

/*
 Invoked upon completion of a -[writeValue:forCharacteristic:] request.
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error 
{
    if (error) 
    {
        NSLog(@"Error writing value for characteristic %@ error: %@", characteristic.UUID, [error localizedDescription]);
        return;
    }
}

/*
 Invoked upon completion of a -[setNotifyValue:forCharacteristic:] request.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error 
{
    if (error) 
    {
        NSLog(@"Error updating notification state for characteristic %@ error: %@", characteristic.UUID, [error localizedDescription]);
        return;
    }
    
    NSLog(@"Updated notification state for characteristic %@ (newState:%@)", characteristic.UUID, [characteristic isNotifying] ? @"Notifying" : @"Not Notifying");
    
    if( ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A1C"]]) ||
       ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A1E"]]) )
    {
        /* Set start/stop button depending on characteristic notifcation/indication */
        if( [characteristic isNotifying] )
        {
            [startStopButton setTitle:@"Stop"];
        }
        else
        {
            [startStopButton setTitle:@"Start"];
        }
    }     
}

@end

@implementation ThermometerView

-(void)drawRect:(NSRect)rect
{
    rect = [self bounds];
    [[NSColor blackColor] set];
    NSRectFill(rect);
    
    [self setNeedsDisplay:YES];
}


@end

