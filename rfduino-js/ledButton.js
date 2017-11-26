// RFduino Node Example
//
// Read the button state and control the LED on the RFduino RGB Pushbutton shield 
// http://www.rfduino.com/rfd22122-rgb-pushbutton-shield-accessory-board.html
// https://github.com/RFduino/RFduino/blob/master/libraries/RFduinoBLE/examples/LedButton/LedButton.ino
//
// (c) 2014 Don Coleman
var noble = require('noble'),
    rfduino = require('./rfduino'),
    _ = require('underscore');

// TODO why does this need to be wrapped?
var stop = function() {
    noble.stopScanning();
};

noble.on('scanStart', function() {
    console.log('Scan started');
    setTimeout(stop, 5000);
});

noble.on('scanStop', function() {
    console.log('Scan stopped');
});

var onDeviceDiscoveredCallback = function(peripheral) {
    console.log('\nDiscovered Peripherial ' + peripheral.uuid);

    // This example needs an RFduino running the *ledbtn* service
    if (_.contains(peripheral.advertisement.serviceUuids, rfduino.serviceUUID)) {
        console.log('RFduino is advertising \'' + rfduino.getAdvertisedServiceName(peripheral) + '\' service.');

        peripheral.on('connect', function() {
            peripheral.discoverServices();
        });

        peripheral.on('disconnect', function() {
            console.log('Disconnected');
        });

        peripheral.on('servicesDiscover', function(services) {

            var rfduinoService;

            for (var i = 0; i < services.length; i++) {
                if (services[i].uuid === rfduino.serviceUUID) {
                    rfduinoService = services[i];
                    break;
                }
            }

            if (!rfduinoService) {
                console.log('Couldn\'t find the RFduino service.');
                return;
            }

            rfduinoService.on('characteristicsDiscover', function(characteristics) {
                console.log('Discovered ' + characteristics.length + ' service characteristics');

                var receiveCharacteristic;
                var sendCharacteristic;                

                for (var i = 0; i < characteristics.length; i++) {
                    if (characteristics[i].uuid === rfduino.receiveCharacteristicUUID) {
                        receiveCharacteristic = characteristics[i];
                        break;
                    }
                }

                // receives the state of the button press on the rfduino shield
                if (receiveCharacteristic) {
                    receiveCharacteristic.on('read', function(data, isNotification) {
                        var buttonPressed = (data.readUInt8(0) === 1);
                        if (buttonPressed) { 
                            console.log("Button pressed");
                        } else {
                            console.log("Button released");
                        }
                    });

                    console.log('Subscribing for button notifications');
                    receiveCharacteristic.notify(true);
                }
                
                // TODO combine with loop above
                for (var i = 0; i < characteristics.length; i++) {
                    if (characteristics[i].uuid === rfduino.sendCharacteristicUUID) {
                        sendCharacteristic = characteristics[i];
                        break;
                    }
                }
                
                // toggle the LED on and off once a second
                var buffer = new Buffer(1);
                setInterval(function() { 
                    // toggle between 0 and 1
                    if (buffer[0] === 0x1) {
                        buffer[0] = 0x0;                        
                    } else { 
                        buffer[0] = 0x1;                        
                    }
                    sendCharacteristic.write(buffer, false) 
                }, 1000);
                
            });

            rfduinoService.discoverCharacteristics();

        });

        peripheral.connect();
    }
};

noble.on('stateChange', function(state) {
    if (state === 'poweredOn') {
        noble.startScanning([rfduino.serviceUUID], false);
    }
});

noble.on('discover', onDeviceDiscoveredCallback);
