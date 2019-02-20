import React, { Component } from 'react';
import Form from 'react-bootstrap/Form'
import Button from 'react-bootstrap/Button'

class DataInput extends Component {
	constructor(props) {
		super(props);
		this.onSubmit = props.onSubmit
	}

	render() {
		return (
			<div className = "DataInput">
			<div className ="row">
				<div className = "col">
				</div>
				<div className = "col-2">
				 <Form.Control placeholder="User (uuidPrefix + deviceUUID)" />
				 </div>
				 <div className = "col-3">
				 	<div className = "row">
				 	<div className = "col-8">
				 		<Form.Control placeholder="DateTime (%Y%M%D_H%m%s)" />
				 	</div>
				 	<div className = "col-4">
				  	<Button variant="secondary">Submit</Button>
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