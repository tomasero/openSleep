var socket = io.connect('http://localhost:3000');
var flex = 0,
    hr = 0,
    old_hr = 0, 
    thresh = 10,
    bpm = 0,
    eda = 0;
var time1 = new Date().getTime()/1000|0;
var time2 = new Date().getTime()/1000|0;
var delay = 20;
socket.on('data', function (data) {
    newData = new Uint32Array(data);
    old_hr = hr ;
    flex = newData[0];
    hr = newData[1];
    eda = newData[2];
    console.log(newData[0]);
    console.log(newData[1]);
    console.log(newData[2]);
    $('#flex').text(flex);
    $('#hr').text(hr);
    $('#eda').text(eda);
    if(hr - old_hr > thresh)
	{bpm += 1 ;
 	 }
    time2 = new Date().getTime()/1000|0;
    if(time2 - time1 >=60)
	{ console.log(bpm);
	  time1 = time2 ;
	  bpm = 0 ;
	}


});
document.addEventListener("DOMContentLoaded", function(){
      //....
  var n = 1000,
      dataFlex = d3.range(n).map(() => {return 0;});
      dataHR = d3.range(n).map(() => {return 0;});
      dataEDA = d3.range(n).map(() => {return 0;});
  var svg = d3.select("#flex-value"),
      margin = {top: 20, right: 20, bottom: 20, left: 40},
      width = svg.attr("width") - margin.left - margin.right,
      height = svg.attr("height") - margin.top - margin.bottom,
      g = svg.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var x = d3.scaleLinear()
  .domain([0, n - 1])
    .range([0, width]);

    var y = d3.scaleLinear()
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
      //.ease(d3.easeLinear)
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
      //.ease(d3.easeLinear)
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
