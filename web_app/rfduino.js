module.exports = {
	serviceUUID: '2220',
	receiveCharacteristicUUID: '2221',
	sendCharacteristicUUID: '2222',
	disconnectCharacteristicUUID: '2223',

	getAdvertisedServiceName: function(peripheral) {
		// RFduino provide one BluetoothService
		// The Arduino api allows the device to advertise what service the hardware is providing, e.g. 'temp', 'rgb', 'ledbtn'
		// The data is sent in the manufacturer data string
		// The temperature sketch sends [0,0,102,105,108,101]       
		// remove the first 2 characters, remaining data is the name of the RFduino service
		return peripheral.advertisement.manufacturerData.slice(2).toString();
	}
};