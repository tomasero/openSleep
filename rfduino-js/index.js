// RFduino Node Example

// Discover and read temperature from RFduinos running the Temperature Sketch
// https://github.com/RFduino/RFduino/blob/master/libraries/RFduinoBLE/examples/Temperature/Temperature.ino
//
// (c) 2014 Don Coleman
var noble = require('../noble'),
    rfduino = require('./rfduino'),
    _ = require('underscore');

 // Set Up HTTP Server                                                                                                                                                                                                                  
var express = require('express');
var app = express();

app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
app.use(express.static(__dirname + '/assets'));
app.get('/', function(req, res){
  //render the index.jade template
  //don't provide variables - we'll use socket.io for that
  res.render('index');
});

var server = app.listen(3000);
var io = require('socket.io').listen(server);
var sock = null;
var fs = require('fs');
var stream = null;
io.sockets.on('connection', function (socket) {
  sock = socket;
  sock.on('user', function (data) {
    if (data.recording == 'start') {
      stream = fs.createWriteStream(data.file);
      stream.write(data.firstName);
      stream.write('|');
      stream.write(data.secondName);
      stream.write('|');
      stream.write(data.age);
      stream.write('|');
      stream.write(data.gender);
    } else {
      stream.end();
      stream = null;
    }
    console.log(data);
  });
});

function sendData(data) {
  if (sock != null) {
    sock.emit('data', data);
    if (stream != null) {
      stream.write('|');
      flex = data.readUInt32LE(0);
      hr = data.readUInt32LE(4);
      eda = data.readUInt32LE(8);
      stream.write(flex + "," + hr + "," + eda);
    } else {
      flex = data.readUInt32LE(0);
      hr = data.readUInt32LE(4);
      eda = data.readUInt32LE(8);
      console.log(flex + "," + hr + "," + eda);
    }
  }
}

// TODO why does this need to be wrapped?
var stop = function() {
    noble.stopScanning();
};

noble.on('scanStart', function() {
    console.log('Scan started');
    //setTimeout(stop, 5000);
});

noble.on('scanStop', function() {
    console.log('Scan stopped');
});

var onDeviceDiscoveredCallback = function(peripheral) {
    console.log('\nDiscovered Peripherial ' + peripheral.uuid);

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

                for (var i = 0; i < characteristics.length; i++) {
                    if (characteristics[i].uuid === rfduino.receiveCharacteristicUUID) {
                        receiveCharacteristic = characteristics[i];
                        break;
                    }
                }

                if (receiveCharacteristic) {
                    receiveCharacteristic.on('read', function(data, isNotification) {
                        //console.log(peripheral.uuid);
                        //console.log(data);
                        sendData(data);
                    });

                    console.log('Subscribing for temperature notifications');
                    receiveCharacteristic.notify(true);
                }

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
