# Cheerios
Heartbeat monitor system with twitter and an arduino
## Technologies Used
- C++
- Node JS
- React JS
- Socket.io

Cheerios is an application that I built to track your heartbeat with an arduino. 
You are able to sign in with Twitter and use the sensor on the arduino to calculate your heartbeat. 
I wrote the heartbeat calculations in C++ for the arduino. Then I built the backend in Node.js and used a library
I found that listens over the serial port that the arduino is plugged into. I build the frontend in React to display the data 
I was getting from the Arduino. I used web sockets to make sure the data was in real time. There is also a heart that 
appears on the screen that beats and your heart rate displays beneath it. 
