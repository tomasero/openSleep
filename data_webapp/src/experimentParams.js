import React, { Component } from 'react';
import Table from 'react-bootstrap/Table';

class ExperimentParams extends Component {
	constructor(props) {
		super(props);
		this.experimentParams = props.experimentParams
	} 

	getParameterRows() {
		let rows = []
		for(let paramKey in this.experimentParams) {
			rows.push(
				<tr>
					<td>{paramKey}</td>
					<td>{this.experimentParams[paramKey]}</td>
				</tr>
				);
		}
		return rows;
	}


	render() {

		const parameterRows = this.getParameterRows()

		return (
			<div className = "ExperimentParams">
				<Table striped bordered hover responsive size="sm">
					<thead>
						<tr>
						<th>Parameter</th>
						<th>Value</th>
						</tr>
					</thead>
					<tbody>
						{parameterRows}
					</tbody>
				</Table>
			</div>
		);
	}
}

export default ExperimentParams;