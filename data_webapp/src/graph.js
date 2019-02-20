import React, { Component } from 'react';
import CanvasJSChart from './canvas/canvasjs.react.js';

class Graph extends Component {
	constructor(props) {
		super(props);
		this.data = props.data;
		this.onsets = props.onsets;
		this.showOnsets = props.showOnsets;
		this.title = props.title;
		this.yLabel = props.yLabel;
		this.xLabel = props.xLabel;
		console.log(this.data)
	}

	render() {
		const options = {
			theme: "light2",
			animationEnabled: true,
			zoomEnabled: true,
			title: {
				text: this.title,
			},
			axisY: {
				title: this.yLabel,
				includeZero: false
			},
			axisX: {
				title: this.xLabel,
			},
			data: [{
				type: "spline",
				dataPoints: this.data,
			}],
		}

		return (
			<div className = "Graph">
				<CanvasJSChart options = {options}/>
			</div>
		);
	}
}

export default Graph;