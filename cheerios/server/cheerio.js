var sp = require("serialport"),
	serialPort = new sp("/dev/cu.usbmodem1411", {
    baudRate: 9600,
    parser: new sp.parsers.Readline('\r\n')
  });

module.exports = function (socket){

	serialPort.on('open',function() {
	  console.log('Port open');
	});

	serialPort.on('data', function(data) {
	  socket.emit('BPM', data);
	  console.log(data);
	});
}
