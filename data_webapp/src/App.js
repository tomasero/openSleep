import React, { Component } from 'react';
import logo from './logo.svg';
import './App.css';

import Graph from './graph';
import {getDate} from './dateFormatter';
import Button from 'react-bootstrap/Button';
import ExperimentParams from './experimentParams';
import DataInput from './dataInput';

class App extends Component {

  constructor(props) {
    super(props);
    this.state = {
      // user: "user1",
      // dateTimeOfSession: "20190220_220405"
    }
    this.serverURL = "http://68.183.114.149:5000/"
    this.dormioSampleRate = 10.0 // hz

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
    let idx = 0;
    for(let chunk of data.split("|")) {
      const splitChunk = chunk.split(',')
      let xPoint = idx * (1.0/this.dormioSampleRate)
      flex.push({y : parseInt(splitChunk[0]), x: xPoint});
      ppm.push({y : parseInt(splitChunk[1]), x: xPoint});
      eda.push({y : parseInt(splitChunk[2]), x: xPoint});
      idx+=1;
    }

    this.setState({
      data:{
        ...this.state.data,
        flex: flex,
        ppm: ppm,
        eda: eda
      }
    });
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
  }

  setHBOSSData(data) {
    let meanHBOSS = []
    let maxHBOSS = []
    let startTime = getDate("%Y%m%d_%H%M%S", this.state.dateTimeOfSession);

    for(let chunk of data.split("|")) {
      let splitChunk = chunk.split(',')
      let d= new Date();
      let offset = d.getTimezoneOffset() * 60000
      let timeStamp = new Date(parseFloat(splitChunk[2])  * 1000 + offset)
      meanHBOSS.push({y: parseFloat(splitChunk[0]), x: (timeStamp - startTime)/1000.0})
      maxHBOSS.push({y: parseFloat(splitChunk[1]), x: (timeStamp - startTime)/1000.0})
    }
    this.setState({
      data: {
        ...this.state.data,
        meanHBOSS: meanHBOSS,
        maxHBOSS : maxHBOSS,
      }
    })
    console.log(this.state)
  }

  setExperimentParameters(params) {
    let experimentParameters = {}
    for(let paramValPair of params.split('\n')) {
        let paramValArr = paramValPair.split(',')
        experimentParameters[paramValArr[0]] = paramValArr[1];
    }
    this.setState({
      experimentParameters: experimentParameters
    })
  }

  getData() {
    const config = {
        method: "GET",
        headers: {},
        mode: 'cors',
      };

    if(this.state.user && this.state.dateTimeOfSession && this.state.user != "" && this.state.dateTimeOfSession != "")  {
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
    fetch(
      this.buildUrl(this.serverURL+"getParams", {
        deviceUUID: this.state.user,
        datetime: this.state.dateTimeOfSession
      }),config)
      .then(
        (res) => {
          res.json().then((data) => {
            this.setExperimentParameters(data.parameters);
          })
        });


    }
    fetch(
        this.serverURL+"getUsers",config)
      .then(
        (res) => {
          res.json().then((data) => {
            this.setState({
              usersAndDates:data,
            })
          })
        });   
  }

  onSubmit(user, dateTimeOfSession) {
    console.log("onSubmit", user, dateTimeOfSession);
    this.setState({
      user: user,
      dateTimeOfSession: dateTimeOfSession,
    }, () => {
      this.getData();
    });

  }

  renderGraph(dataPoints, title, yLabel, xLabel) {
    if(dataPoints) {
      return <Graph data = {dataPoints} title = {title} yLabel = {yLabel} xLabel = {xLabel}/>
    }
  }

  renderGraphs() {
    if(this.state.data) {

      return (
          <div>
            <div className = "row">
              <div className = "col">
                {this.renderGraph(this.state.data.flex, "FLEX", "FLEX", "Time (sec)")}
              </div>
              <div className = "col">
                {this.renderGraph(this.state.data.eda, "EDA", "EDA", "Time (sec)")}
              </div>
            </div>

            <div className = "row">
              <div className = "col">
                {this.renderGraph(this.state.data.ppm, "PPM", "PPM", "Time (sec)")}
              </div>
              <div className = "col">
                {this.renderGraph(this.state.data.meanHBOSS, "HBOSS Mean", "HBOSS", "Time (sec)")}
              </div>
            </div>

            <div className = "row">
              <div className = "col">
                {this.renderGraph(this.state.data.maxHBOSS, "HBOSS Max", "Hboss", "Time (sec)")}
              </div>
              <div className = "col">
              </div>
            </div>
          </div>
        );
    }
  }

  renderExperimentParameters() {
    if(this.state.experimentParameters) {
      return (
          <div>

            <ExperimentParams experimentParams = {this.state.experimentParameters}/>

          </div>
        );
    }
  }
  
  renderDataInput() {
    return (
        <DataInput  onSubmit = {(user, dateTimeOfSession) => this.onSubmit(user, dateTimeOfSession)} usersAndDates = {this.state.usersAndDates}/>
      );
  }

  render() {
    return (
      <div className="App">
        <h1 style={{marginTop: 0}}>Dreamcatcher Dormio Data</h1>
        <div className = "container-fluid">
            {this.renderDataInput()}
            <div className = "row">
              <div className = "col">
                {this.renderExperimentParameters()}
                </div>
            </div>
          {this.renderGraphs()}
        </div>

      </div>
    );
  }
}

export default App;
