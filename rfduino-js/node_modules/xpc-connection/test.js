var XpcConnection = require('./index');

var bluedService = new XpcConnection('com.apple.blued');


bluedService.on('error', function(message) {
  console.log('error: ' + JSON.stringify(message, undefined, 2));
});


bluedService.on('event', function(event) {
  console.log('event: ' + JSON.stringify(event, undefined, 2));
});

bluedService.setup();

bluedService.sendMessage({
  kCBMsgId: 1, 
  kCBMsgArgs: {
    kCBMsgArgAlert: 1,
    kCBMsgArgName: 'node'
  }
});

setTimeout(function() {
  console.log('done');
}, 5000);
