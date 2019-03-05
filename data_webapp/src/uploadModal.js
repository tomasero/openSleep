import React, { Component } from 'react';
import './App.css';
import Modal from 'react-bootstrap/Modal';
import Button from 'react-bootstrap/Button';
import Form from 'react-bootstrap/Form'
import Col from 'react-bootstrap/Col'

class UploadModal extends Component {
	constructor(props) {
		super(props);

		this.state = {
			showModal: false,
			validated: false,
		}
	}

	handleClose() {
		this.setState({show: false});
	}
	handleShow() {
		this.setState({show: true});
	}

	handleSubmit(event) {
	    const form = event.currentTarget;
	   	event.preventDefault();
	    event.stopPropagation();
	    this.setState({ validated: true });
    }

	render() {
		return(
			<div>
			<div id = "up" className = "uploadButton" onClick={() => {this.handleShow()}}><p>+</p></div>
        <Modal 
        show={this.state.show} 
        onHide={() => {this.handleClose()}}
        size = "lg"
        >
			<Form 
			noValidate
			validated = {this.state.validated}
			onSubmit={e => this.handleSubmit(e)}
			>
          <Modal.Header closeButton>
            <Modal.Title>Upload/View New Data</Modal.Title>
          </Modal.Header>
          <Modal.Body>
          	<div className = "row">
          		<div style={{marginLeft: "auto", marginRight: "auto"}}>

          			<Form.Row>
		          	<Form.Group as={Col} controlId = "validationForm01">
		          		<Form.Label>User UUID</Form.Label>
		          		<Form.Control required type = "text" placeholder="User UUID"/>
			              <Form.Control.Feedback type="invalid">
			                Please enter a user uuid.
			              </Form.Control.Feedback>
		          	</Form.Group>
		          	<Form.Group as={Col} controlId = "validationForm02">
		          		<Form.Label>DateTime</Form.Label>
		          		<Form.Control required type = "text" placeholder="DateTime (%Y%M%D_H%m%s)"/>
			              <Form.Control.Feedback type="invalid">
			                Please enter a datetime.
			              </Form.Control.Feedback>		          	
		          	</Form.Group>
		          	</Form.Row>
		          </div>
          	</div>
          	<div className = "row">
          		<div className="col">
          			<p>Upload Experimental Parameters(optional)</p><input type="file"/>
          		</div>
          		<div className="col">
          			<p>Upload HBOSS (optional)</p><input type="file"/>
          		</div>
          	</div>
          	<div className = "row">
          	    <div className="col">
          			<p>Upload Triggers (optional)</p><input type="file"/>
          		</div>
          	    <div className="col">
          			<p>Upload DORMIO Data</p><input type="file"/>
          		</div>
          	</div>
          </Modal.Body>
          <Modal.Footer>
            <Button type = "submit" variant="info" >
              View Locally
            </Button>
            <Button type = "submit" variant="secondary" >
              Upload To Server
            </Button>
          </Modal.Footer>
		  </Form>
        </Modal>
        </div>
		);
	}
}

export default UploadModal;