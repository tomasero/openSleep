import React, { Component } from 'react';
import ReactDOM from 'react-dom';
import Form from 'react-bootstrap/Form'
import Button from 'react-bootstrap/Button'
import { PropTypes } from 'react'

class DataInput extends Component {

	onSubmit() {
		let userFormControl = ReactDOM.findDOMNode(this.refs.userFormControl);
		let dateTimeFormControl = ReactDOM.findDOMNode(this.refs.dateTimeFormControl);
		this.props.onSubmit(userFormControl.value, dateTimeFormControl.value);
	}

	constructor(props) {
		super(props)
		this.props = props
	}

	renderUserAutoComplete() {

		let options = [];

		for(let i = 0; i < 200; i++) {
			options.push(
				<option value = {i.toString()}/>
				);
		}

		return options;
	}

	render() {
		const userAutoComplete = this.renderUserAutoComplete();

		return (
			<div className = "DataInput">
			<div className ="row">
				<div className = "col">
				</div>
				<div className = "col-2">
				  <div class="form-group">

			 <input list = "userAutoComplete" ref = 'userFormControl' placeholder="User (uuidPrefix + deviceUUID)" className = "form-control"/>
		 		        <datalist id="userAutoComplete">
		 		        		{userAutoComplete}
      					</datalist>
              	</div>
				 </div>
				 <div className = "col-3">
				 	<div className = "row">
				 	<div className = "col-8">
				 					  <div class="form-group">

				 		<input list = "dateTimeAutoComplete" ref = 'dateTimeFormControl' placeholder="DateTime (%Y%M%D_H%m%s)" className = "form-control"/>
				 		        <datalist id="dateTimeAutoComplete">
              					</datalist>
				 	</div>
				 	</div>
				 	<div className = "col-4">
				  	<Button variant="secondary" onClick = {() => this.onSubmit()}>Submit</Button>
				  	</div>
				  	</div>
				 </div>
				<div className = "col">
				</div>
			</div>
			</div>
		);
	}
}

export default DataInput;