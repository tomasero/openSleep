import React, { Component } from 'react';
import logo from './logo.svg';
import './App.css';

import {getDate} from './dateFormatter';

class App extends Component {

  constructor(props) {
    super(props);
    this.state = {
      user: "testing-2AC84546-C29F-4463-9ACF-391702D2AA62",
      dateTimeOfSession: "20190127_154047"
    }
    this.serverURL = "http://68.183.114.149:5000/"
    // this.serverURL = "http://localhost:5000/"
  }

  componentDidMount() {
    this.getData();
  }

  buildUrl(url, parameters) {
      let qs = "";
      for (const key in parameters) {
          if (parameters.hasOwnProperty(key)) {
              const value = parameters[key];
              qs +=
                  encodeURIComponent(key) + "=" + encodeURIComponent(value) + "&";
          }
      }
      if (qs.length > 0) {
          qs = qs.substring(0, qs.length - 1); //chop off last "&"
          url = url + "?" + qs;
      }

      return url;
  }

  setSensorData(data) {
    let flex = []
    let ppm = []
    let eda = []

    for(let chunk of data.split("|")) {
      const splitChunk = chunk.split(',')
      flex.push(splitChunk[0])
      ppm.push(splitChunk[1])
      eda.push(splitChunk[2])
    }

    this.setState({
      data:{
        ...this.state.data,
        flex: flex,
        ppm: ppm,
        eda: eda
      }
    });
    console.log(this.state)
  }

  setTriggersData(data) {
    let triggers = []

    let startTime = getDate("%Y%m%d_%H%M%S", this.state.dateTimeOfSession);

    for(let chunk of data.split("|")) {
      let chunkSplit = chunk.split(",");
      let timeStamp = getDate("%Y-%m-%d %H:%M:%S.%f", chunkSplit[1]);
      triggers.push({"trigger": chunkSplit[0], 
                    "falsePositive":chunkSplit[2], 
                    "timeStamp": (timeStamp - startTime)/1000.0})

    }
    this.setState({
      data: {
        ...this.state.data,
        triggers: triggers,
      }
    })
    console.log(this.state)
  }

  setHBOSSData(data) {
    let hboss = []
    let startTime = getDate("%Y%m%d_%H%M%S", this.state.dateTimeOfSession);

    for(let chunk of data.split("|")) {
      let splitChunk = chunk.split(',')
      let d= new Date();
      let offset = d.getTimezoneOffset() * 60000
      let timeStamp = new Date(parseFloat(splitChunk[2])  * 1000 + offset)
      hboss.push({"meanHBOSS":splitChunk[0], "maxHBOSS":splitChunk[1], "timeStamp":(timeStamp - startTime)/1000.0})
    }
    this.setState({
      data: {
        ...this.state.data,
        hboss: hboss,
      }
    })
    console.log(this.state)
  }

  getData() {
    const config = {
        method: "GET",
        headers: {},
        mode: 'cors',
      };

    fetch(
      this.buildUrl(this.serverURL+"data", {
        deviceUUID: this.state.user,
        datetime: this.state.dateTimeOfSession
      }), config)
      .then(
        (res) => {
          res.json().then((data) => {
            this.setSensorData(data["dormioSensorData"])
          })
        });
    fetch(
      this.buildUrl(this.serverURL+"getTriggers", {
        deviceUUID: this.state.user,
        datetime: this.state.dateTimeOfSession
      }),config )
      .then(
        (res) => {
          res.json().then((data) => {
            this.setTriggersData(data["triggers"])
          })
        });
    fetch(
      this.buildUrl(this.serverURL+"getHBOSS", {
        deviceUUID: this.state.user,
        datetime: this.state.dateTimeOfSession
      }),config)
      .then(
        (res) => {
          res.json().then((data) => {
            this.setHBOSSData(data["hboss"])
          })
        });
  }

  render() {
    return (
      <div className="App">
        <h1 style={{marginTop: 0}}>Dreamcatcher Dormio Data</h1>
      </div>
    );
  }
}

export default App;
