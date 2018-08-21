var events = require('events');

var binding = require('./build/Release/binding.node');
var XpcConnection = binding.XpcConnection;

inherits(XpcConnection, events.EventEmitter);

// extend prototype
function inherits(target, source) {
  for (var k in source.prototype) {
    target.prototype[k] = source.prototype[k];
  }
}

module.exports = XpcConnection;
