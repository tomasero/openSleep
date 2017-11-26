# node-xpc-connection

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/sandeepmistry/node-xpc-connection?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


Connection binding for node.js

## Supported data types

 * int32/uint32
 * string
 * array
 * buffer
 * uuid
 * object

## Example

```javascript
var XpcConnection = require('xpc-connection');

var xpcConnection = new XpcConnection('<Mach service name>');

xpcConnection.on('error', function(message) {
    ...
});

xpcConnection.on('event', function(event) {
    ...
});

xpcConnection.setup();

var mesage = {
    ... 
};

xpcConnection.sendMessage(mesage);
```

## Build Errors

Before creating a new issue for build errors, please set your path to the following:

```sh
/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/X11/bin
```

MacPorts and other similiar tools might be adding an incompatible compiler to your PATH (see issue [#2](https://github.com/sandeepmistry/node-xpc-connection/issues/2)) for more details.

[![Analytics](https://ga-beacon.appspot.com/UA-56089547-1/sandeepmistry/node-xpc-connection?pixel)](https://github.com/igrigorik/ga-beacon)

