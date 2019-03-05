import React, { Component } from 'react';
import CanvasJSChart from './canvas/canvasjs.react.js';

class Graph extends Component {

	getOnsetData() {

		if(this.props.onsets) {
			let stripLines = [];
			let falsePositiveColor = "#e26a6a";
			let truePositiveColor  = "#3fc380";
			for(let onsetChunk of this.props.onsets) {
				stripLines.push({
					startValue: onsetChunk["timeStamp"],
					endValue: onsetChunk["timeStamp"] + 0.5,
					color: (onsetChunk["falsePositive"] == "True") ? falsePositiveColor : truePositiveColor,
					label: onsetChunk["trigger"]
				})
			}

				return stripLines
			}
	}

	render() {
		const options = {
			theme: "light2",
			animationEnabled: true,
			zoomEnabled: true,
			title: {
				text: this.propstitle,
			},
			axisY: {
				title: this.props.yLabel,
				includeZero: false
			},
			axisX: {
				title: this.props.xLabel,
			},
			data: [{
				type: "spline",
				dataPoints: this.props.data,
			}
			]
		}

		if(this.props.plotOnsets) {
			options.axisX.stripLines = this.getOnsetData()
		}


		return (
			<div className = "Graph">
				<CanvasJSChart options = {options}/>
			</div>
		);
	}
}

export default Graph;