//
//  AppDelegate.h
//  BLE Chat Demo
//
//  Created by Nan Zhao on 12/4/15.
//  Copyright © 2015 MIT Media Lab. All rights reserved.
//  You may use, distribute and modify this code under the
//  terms of the MIT license

#import <Cocoa/Cocoa.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>



//Relate the Array Controller to the Table View
//https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/TableView/PopulatingViewTablesWithBindings/PopulatingView-TablesWithBindings.html
//1)Array Controller Class CBperiferal
//2)Array Controller Bind to Delegate, self.BLEDevices
//3)Table Columb Bind to Array Controller, Key Path for example name (attribute of CBperiferal)
//4)Table View Cell Bind to Table Cell View, Key Path objectValue.name
//4)Table View set Selection Indexes binding to the Array Controller's selectionIndexes controller key
@property (weak) IBOutlet NSArrayController *arrayController;
@property (weak) IBOutlet NSTableView *tableView;



//stores all the BLE devices that was found
@property (copy) NSMutableArray *BLEDevices;


//this button is pressed to connect and disconnet from the selected BLE device
@property (weak) IBOutlet NSButton *connectButton;

//this field is not used right now but is reserved for status display
@property (weak) IBOutlet NSTextField *connectionIndicator;

//this button is used to refresh the list of discovered BLE devices
//by pressing it you start scanning, you terminate scanning when you connect to a device
@property (weak) IBOutlet NSButton *refreshButton;

//this field support the user text input
@property (weak) IBOutlet NSTextField *textField;

//this fiels shows the chat message
@property (unsafe_unretained) IBOutlet NSTextView *chatTextView;


- (IBAction)refreshButtonPressed:(id)sender;
- (IBAction)connectButtonPressed:(id)sender;
- (IBAction)sendButtonPressed:(id)sender;
- (IBAction)textFieldEntered:(id)sender;

- (void) startScan;
- (void) stopScan;
- (BOOL) isLECapableHardware;

@end
