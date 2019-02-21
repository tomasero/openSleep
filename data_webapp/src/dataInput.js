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
		this.state = {}
	}

	renderUserAutoComplete() {
		if(this.props.usersAndDates) {
			let options = [];
			for(let user in this.props.usersAndDates) {
				options.push(
					<option key = {user} value = {user}/>
					);
			}

			return options;
		}

	}

	renderDateAutoComplete() {
		const user = this.state.user;
		if(user && this.props.usersAndDates && this.props.usersAndDates.hasOwnProperty(user)) {
			let options = [];
			console.log(this.state, this.props.usersAndDates);
			for(let date of this.props.usersAndDates[user]) {
				options.push(
					<option key = {date} value = {date}/>
					);
			}

			return options;
		}
	}

	handleUserChange(e) {
		this.setState({
			user: e.target.value,
		})
	}

	render() {
		const userAutoComplete = this.renderUserAutoComplete();
		const dateAutoComplete = this.renderDateAutoComplete();
		return (
			<div className = "DataInput">
			<div className ="row">
				<div className = "col">
				</div>
				<div className = "col-2">
				  <div class="form-group">

			 <input list = "userAutoComplete" ref = 'userFormControl' placeholder="User (uuidPrefix + deviceUUID)" className = "form-control" onChange = {(e) => this.handleUserChange(e)}/>
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
				 		        		{dateAutoComplete}
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