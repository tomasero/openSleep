# Project Name

BLE Char Demo

## Installation

Tested on Xcode 7.1.1 and OSX 10.10.5

Install Arduino Sketch on the RFduino Hardware<br>
Compile and run Cocoa application 

## Usage

I made this software to understand the mechanisms behind CoreBluetooth and how to interface with the RFduino. This is my first project in Cocoa programming. Maybe it is helpful for you as a reference on how to write apps for the RFduino. 

	- When actived the application scans for RFduinos and list detected devices in the table
	- To restart scanning press the refresh button on the bottom of the table. 
	- If the refresh button is disable, that means it is already scanning. 
	- Connect to RFduino by selecting from the list and click the connect button. 
	- After connection is established the connect button changes to disconnect button.
	- Write text to send to the RFduino

	- On the RFduino side use a serial monitor (for example in the Arduino software) to send and receive messages. 


## Contributing

Fork it

## History

TODO: Write history

## Credits

nandev

based on Apple's Bluetooth tutorial:
https://developer.apple.com/library/mac/samplecode/HeartRateMonitor/Introduction/Intro.html 

## License

MIT