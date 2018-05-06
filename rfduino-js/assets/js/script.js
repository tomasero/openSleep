var socket = io.connect('http://localhost:3000');
var flex = 0,
    hr = 0,
    oldHr = 0, 
    thresh = 50,
    bpm = 0,
    eda = 0;
var prev = new Date().getTime()/1000;
var now = new Date().getTime()/1000;
var lastBeat = new Date().getTime()/1000;
var delay = 20;
var buffer = [];
var bpmInit = false;

var num_threads = 2;
var MT = new Multithread(num_threads);

socket.on('data', function (data) {
    newData = new Uint32Array(data);
    oldHr = hr ;
    flex = newData[0];
    hr = newData[1];
    eda = newData[2];
    buffer.push(hr);
    if (bpmInit) {
      buffer.shift();
    }
    $('#flex').text(flex);
    $('#eda').text(eda);
    if(hr - oldHr > thresh && now - lastBeat > .4){
      document.getElementById("channel-bpm").style.background = 'rgba(255,0,0,0.8)';
      lastBeat = new Date().getTime()/1000;
    } else {
      document.getElementById("channel-bpm").style.background = 'rgba(255,0,0,0.1)';
    }
    now = new Date().getTime()/1000;
    if (!bpmInit) {
      if(now - prev >= 60) { 
        MT.process(processBPM, setBPM)(buffer, thresh);
  	    prev = now;
        bpmInit = true;
  	  }
    } else {
      if(now - prev >= 1) {
        MT.process(processBPM, setBPM)(buffer, thresh);
        prev = now;
  	  }
    }
});

function setBPM(_bpm) {
  $('#bpm').text(_bpm);
}

function processBPM(buffer, thresh) {
  _bpm = 0;
  _prev = 0;
  lastBeat = -3;
  var i;
  for (i = 1; i < buffer.length; i++) {
    _now = buffer[i];
    _prev = buffer[i-1];
    if (_now - _prev > thresh && i - lastBeat > 4) {
      _bpm++;
      lastBeat = i;
    }
  }
  //console.log("before setBPM");
  return _bpm;
  //setBPM(_bpm);
}

var recording = false;
document.addEventListener("DOMContentLoaded", function(){
  document.getElementById("submit").addEventListener("click", function(){
      recording = !recording;
      if (recording) {
        document.getElementById("submit").value = "Stop recording";
        document.getElementById("first-name").disabled = true;
        document.getElementById("last-name").disabled = true;
        document.getElementById("age").disabled = true;
        document.getElementById("gender").disabled = true;
        document.getElementById("file").disabled = true;
        document.getElementById("recording").style.background = "rgba(255, 0, 0, 0.5)";
      } else {
        document.getElementById("submit").value = "Start recording";
        document.getElementById("first-name").disabled = false;
        document.getElementById("last-name").disabled = false;
        document.getElementById("age").disabled = false;
        document.getElementById("gender").disabled = false;
        document.getElementById("file").disabled = false;
        document.getElementById("recording").style.background = "rgba(0, 0, 0, 0.1)";
      }
      var firstName = document.getElementById("first-name").value;
      var lastName = document.getElementById("last-name").value;
      var age = document.getElementById("age").value;
      var gender = document.getElementById("gender").value;
      var file = document.getElementById("file").value;
      data = {
        'recording': recording ? "start" : "stop",
        'firstName': firstName,
        'secondName': lastName,
        'age': age,
        'gender': gender,
        'file': file,
      }
      socket.emit("user", data);        
  });
      //....
  var n = 1000,
      dataFlex = d3.range(n).map(() => {return 0;});
      dataHR = d3.range(n).map(() => {return 0;});
      dataEDA = d3.range(n).map(() => {return 0;});
  var svg = d3.select("#plot"),
      margin = {top: 20, right: 20, bottom: 20, left: 40},
      width = parseInt(svg.style("width").slice(0, -2));
      width = width  - margin.left - margin.right,
      height = parseInt(svg.style("height").slice(0, -2));
      height = height - margin.top - margin.bottom,
      g = svg.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  var x = d3.scaleLinear()
    .domain([0, n - 1])
    .range([0, width]);

  var y = d3.scaleLinear()
    //.domain([0, 300])
    .domain([0, 1023])
    .range([height, 0]);

  var lineFlex = d3.line()
    .x(function(d, i) { return x(i); })
    .y(function(d, i) { return y(d); });
  var lineHR = d3.line()
    .x(function(d, i) { return x(i); })
    .y(function(d, i) { return y(d); })
    .curve(d3.curveCardinal);
  var lineEDA = d3.line()
    .x(function(d, i) { return x(i); })
    .y(function(d, i) { return y(d); });

  g.append("defs").append("clipPath")
  .attr("id", "clip")
  .append("rect")
  .attr("width", width)
  .attr("height", height);

  g.append("g")
  .attr("class", "axis axis--x")
  .attr("transform", "translate(0," + y(0) + ")")
  .call(d3.axisBottom(x));

  g.append("g")
  .attr("class", "axis axis--y")
  .call(d3.axisLeft(y));

  g.append("g")
    .attr("clip-path", "url(#clip)")
  .append("path")
    .datum(dataFlex)
    .attr("class", "line-flex")
  .transition()
    .duration(delay)
    .ease(d3.easeLinear)
    .on("start", tick);
  
  g.append("g")
    .attr("clip-path", "url(#clip)")
  .append("path")
    .datum(dataHR)
    .attr("class", "line-hr")
  .transition()
    .duration(delay)
    .ease(d3.easeLinear)
    //.ease(d3.easeElasticInOut)
    .on("start", tick);
  
  g.append("g")
    .attr("clip-path", "url(#clip)")
  .append("path")
    .datum(dataEDA)
    .attr("class", "line-eda")
  .transition()
    .duration(delay)
    .ease(d3.easeLinear)
    .on("start", tick);
  
  function tick() {
    // Push a new data point onto the back.
    dataFlex.push(flex);
    dataHR.push(hr);
    dataEDA.push(eda);
    // Redraw the line.
    d3.select(this)
      .attr("d", lineFlex)
      .attr("d", lineHR)
      .attr("d", lineEDA)
      .attr("transform", null);
    // Slide it to the left.
    d3.active(this)
      .attr("transform", "translate(" + x(-1) + ",0)")
      .transition()
      .on("start", tick);
    // Pop the old data point off the front.
    dataFlex.shift();
    dataHR.shift();
    dataEDA.shift();
  }
});
