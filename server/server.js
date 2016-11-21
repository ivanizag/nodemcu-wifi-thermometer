var dgram = require('dgram');
var net = require('net');

var LISTEN_PORT = 23322;
var STATSD_HOST = '192.168.1.101';
var STATSD_PORT = 8125;

var buffer = "";

var knownKeys = {
  'home.nodemcu.temperature.sensor28ffb288a115046e': 'home.nodemcu.temperature.salon',
  'home.nodemcu.temperature.sensor28ff02859015034a': 'home.nodemcu.temperature.habJorge'
};


function processLine(line) {
  console.log("PROCESS: " + line);

  // Key translation
  var split = line.split(":");
  split[0] = knownKeys[split[0]] || split[0];
  line = split.join(":");

  var socket = dgram.createSocket('udp4');
  var buf = new Buffer(line);
  socket.send(buf, 0, buf.length, STATSD_PORT, STATSD_HOST);
  console.log("SEND:" + line);
}

function processBuffer() {
  var parts = buffer.split("\r\n");
  for (i=0; i<parts.length-1; i++) {
    processLine(parts[i]);
  }
  buffer = parts[parts.length-1];
}

net.createServer(function(s) {
  console.log('Connection from ' + s.remoteAddress + ':' + s.remotePort);

  s.on('data', function(data) {
    console.log('Data received, ' + data.length);
    console.log(data);
    buffer += data;
    processBuffer();
  });
}).listen(LISTEN_PORT);
