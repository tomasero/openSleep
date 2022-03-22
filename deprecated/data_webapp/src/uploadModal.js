import React, { Component } from 'react';
import './App.css';
import Modal from 'react-bootstrap/Modal';
import Button from 'react-bootstrap/Button';
import Form from 'react-bootstrap/Form'
import Col from 'react-bootstrap/Col'
import axios from 'axios';
import Alert from 'react-bootstrap/Alert'
import Overlay from 'react-bootstrap/Overlay'
import Popover from 'react-bootstrap/Popover'
import OverlayTrigger from 'react-bootstrap/OverlayTrigger'

class UploadModal extends Component {

	constructor(props) {
		super(props);

		this.state = {
			showModal: false,
			validated: false,
			validationText: {
				dateTime: "Please enter a dateTime",
				userUUID: "Please Enter a User UUID",
			},
			alertText: "Something Went Wrong",
			showAlert: false,
			replaceRemoteVersion: false,
		}
		this.fileReader = new FileReader();
		this.props = props;
		this.endpoint = "http://localhost:5000/dataUpload"
		this.httpClient = axios.create();
		this.httpClient.defaults.timeout = 5000;
	}

	handleClose() {
		this.setState({show: false});
	}

	handleShow() {
		this.hideAlert();
		this.setState({show: true});
	}

	handleSubmit(event) {

		console.log("State on submit:", this.state);
	    const form = event.currentTarget;
	   	event.preventDefault();
	    event.stopPropagation();
	    if(!this.isValidUserUUID(this.state.uploadModalData.deviceUUID)) {
	    	this.setState({
	    		validationText: {
	    			...this.state.validationText,
	    			userUUID: "No Special Characters!"
	    		}
	    	})
	    };
	    if(!this.isValidDateTime(this.state.uploadModalData.datetime)) {
	    	this.setState({
	    		validationText: {
	    			...this.state.validationText,
	    			dateTime: "Datetime Format: %YYYY%MM%%DD_%H24%M%S"
	    		}
	    	})	    
	    };
	    this.setState({ validated: true });
    }
    handleExpParamsFile(event) {
    	console.log(event.target.files[0]);
    	this.setState({
    		expParams: event.target.files[0],
    	});
    }

    handleHBOSSFile(event) {
    	console.log(event.target.files[0]);
    	this.setState({
    		hboss: event.target.files[0],
    	});
    }

    handleTriggersFile(event) {
    	console.log(event.target.files[0]);
    	this.setState({
    		triggers: event.target.files[0],
    	});
    }

    handleDORMIODataFile(event) {
    	console.log("DORMIO ",event.target.files[0]);
    	this.setState({
    		dormioData: event.target.files[0],
    	});
    }

    handleDormioDataRead(e) {
    	this.setState({
    		uploadModalData: {
    			...this.state.uploadModalData,
    			dormioData: e.currentTarget.result,
    		}
    	});
    	if(this.state.hboss) {
    		this.fileReader.onloadend = this.handleHBOSSRead;
    		this.fileReader.readAsText(this.state.hboss);
    	} else {
    		this.doneViewLocally();
    	}
    }

    handleHBOSSRead(e) {
    	this.setState({
    		uploadModalData: {
    			...this.state.uploadModalData,
    			hboss: e.currentTarget.result,
    		}
    	});      	
    	if(this.state.triggers) {
    		this.fileReader.onloadend = this.handleTriggersRead;
    		this.fileReader.readAsText(this.state.triggers);
    	} else {
    		this.doneViewLocally();
    	 }
    }
    handleTriggersRead(e) {
    	this.setState({
    		uploadModalData: {
    			...this.state.uploadModalData,
    			triggers: e.currentTarget.result,
    		}
    	});
    	if(this.state.expParams) {
    		this.fileReader.onloadend = this.handleExpParamsRead;
    		this.fileReader.readAsText(this.state.expParams);
    	} else {
    		this.doneViewLocally();
    	 }
    }
    handleExpParamsRead(e) {
    	this.setState({
    		uploadModalData: {
    			...this.state.uploadModalData,
    			expParams: e.currentTarget.result,
    		}
    	});

    		this.doneViewLocally();
    }

    viewLocally() {
    	if(this.state.dormioData) {
    		this.fileReader.onloadend = this.handleDormioDataRead.bind(this);
    		this.fileReader.readAsText(this.state.dormioData);
    		this.handleClose();
    	}
    }

    doneViewLocally() {
    	this.props.onViewLocal(this.state.uploadModalData);
    	delete this.state.uploadModalData;
    }

    isUserUUIDFormControlValid() {
    	if(this.state.uploadModalData) {
    		if(this.state.uploadModalData.deviceUUID) {
    			return this.isValidUserUUID(this.state.uploadModalData.deviceUUID);
    		}
    		return true;
    	}
    	return true;
    }

    isDateTimeFormControlValid(){
    	if(this.state.uploadModalData) {
    		if(this.state.uploadModalData.datetime){
    			return this.isValidDateTime(this.state.uploadModalData.datetime);
    		}
    		return true;
    	}
    	return true;    
    }

	isValidUserUUID(str){
    	var pattern = new RegExp(/[~`!#$%\^&*+=\-\[\]\\';,/{}|\\":<>\?]/); //unacceptable chars
    	return !pattern.test(str);
	}

	isValidDateTime(str) {
		if(str.length == 15) {
			const year = parseInt(str.substring(0,4));
			const month = parseInt(str.substring(4, 6));
			const day = parseInt(str.substring(6, 8));
			const hour = parseInt(str.substring(9, 11));
			const minute = parseInt(str.substring(11,13));
			const seconds = parseInt(str.substring(13,15));

			return (month >= 1 && month < 13) && (day >= 1 && day < 32) && 
					(hour>=0 && hour < 24) && (minute >= 0 && minute < 60) &&
					(seconds >= 0 && seconds < 60)

		} else {
			return false;
		}
	}

    checkValidity() {
    	return this.isValidUserUUID(this.state.uploadModalData.deviceUUID) && this.isValidDateTime(this.state.uploadModalData.datetime);
    }

    handleUserUUIDInputChange(e) {
    	this.setState({
    		uploadModalData: {
    			...this.state.uploadModalData,
    			deviceUUID: e.target.value,
    		}
    	});
    }
    handleDatetimeInputChange(e) {
    	this.setState({
    		uploadModalData: {
    			...this.state.uploadModalData,
    			datetime: e.target.value,
    		}
    	});
    }

    handleReplaceRemoteCheckBox(e) {
    	console.log(e.target.checked);
    	this.setState({
    		replaceRemoteVersion: e.target.checked,
    	});
    }

    handleAlreadyExistsError(res) {
    	if(res.data.msg === "Already Exists") {
    		this.setState({
    			alertText: "Data from that user at that datetime already exists",
    			showAlert: true,
    		})
    	}
    }


    hideAlert() {
		this.setState({
			showAlert: false,
		})
    }

    handleUpload() {

    	this.hideAlert();

    	console.log("handleUpload called");
    	const data = new FormData();

    	if(this.state.dormioData) {
    		data.append('dormioData', this.state.dormioData, this.state.dormioData.name);
    	}
    	if(this.state.hboss) {
    		data.append('hboss', this.state.hboss, this.state.hboss.name);
    	}
    	if(this.state.triggers) {
    		data.append('triggers', this.state.triggers, this.state.triggers.name);
    	}
    	if(this.state.expParams) {
    		data.append('expParams', this.state.expParams, this.state.expParams.name);
    	}
    	data.set('deviceUUID', this.state.uploadModalData.deviceUUID);
    	data.set('datetime', this.state.uploadModalData.datetime);
    	data.set('replaceRemoteVersion', this.state.replaceRemoteVersion);

    	this.httpClient
    		.post(this.endpoint, data, {
    			onUploadProgress: ProgressEvent => {
    				console.log("Progress: ", ProgressEvent.loaded/ProgressEvent.total * 100)
    			},
    		})
    		.then(res => {
    			console.log("Data upload response", res);
    			this.handleAlreadyExistsError(res);
    		})
    		.catch(error => {
    			this.setState({
    				alertText: "Upload Failed",
    				showAlert: true
    			})
    		});
    }

    renderAlert() {
    	if(this.state.showAlert) {
	    	return (
	    		<p className = "alertText">
	            	{this.state.alertText}
	            </p>
	            );
    	}
    }

    renderInfoPopOver() {
    	return(
	    	<Popover className = "infoPopOver" id = "popover-basic" title = "Data Format">
	    		<ul>
	    		<li>Experiment Parameters: .csv : $parameter$ , $value$ </li>
	    		<li>Dormio Data: .csv : flex,ecg,eda \newline </li>
	    		<li>HBOSS: .csv : mean, max, startTimePredict, endTimePredict</li>
	    		<li>Triggers: .csv : EDA,2019-01-25 03:49:40.794231,$False Positive?$</li>
	    		</ul>
	    	</Popover>
	    )
    }
    renderInfoButton() {
    	return(
		  <OverlayTrigger className = "infoButton" trigger="click" placement="right" overlay={this.renderInfoPopOver()}>
		    <Button className ="infoButton" variant="info">Info</Button>
		  </OverlayTrigger>
		  )
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
            	                         {this.renderInfoButton()}

          </Modal.Header>
          <Modal.Body>
          	<div className = "row">

		          	<Form.Group as={Col} md = "6" controlId = "validationForm01">
		          		<Form.Label>User UUID</Form.Label>
		          		<Form.Control required isInvalid = {!this.isUserUUIDFormControlValid()} type = "text" placeholder="User UUID" onChange={(e) => this.handleUserUUIDInputChange(e)}
		          		/>
			              <Form.Control.Feedback type="invalid">
			                Please enter a user uuid.
			              </Form.Control.Feedback>
		          	</Form.Group>
		          	<Form.Group as={Col} md = "6" controlId = "validationForm02">
		          		<Form.Label>DateTime</Form.Label>
		          		<Form.Control required isInvalid = {!this.isDateTimeFormControlValid()} type = "text" placeholder="DateTime (%Y%M%D_H%m%s)" onChange={(e) => this.handleDatetimeInputChange(e)}
		          			/>
			              <Form.Control.Feedback type="invalid">
			              {this.state.validationText.dateTime}
			              </Form.Control.Feedback>		          	
		          	</Form.Group>
          	</div>
          	<div className = "row fileRow">
          		<div className="col">
          			<p className = "fileLabel">Upload Experimental Parameters(optional)</p><input type="file"
          			onChange={e => this.handleExpParamsFile(e)}/>
          		</div>
          		<div className="col">
          			<p className = "fileLabel">Upload HBOSS (optional)</p><input type="file"
          			onChange={e => this.handleHBOSSFile(e)} accept = ".csv"/>
          		</div>
          	</div>
          	<div className = "row fileRow">
          	    <div className="col">
          			<p className = "fileLabel">Upload Triggers (optional)</p><input type="file"
          			onChange={e => this.handleTriggersFile(e)} accept=".csv"/>
          		</div>
          	    <div className="col">
          			<p className = "fileLabel">Upload DORMIO Data</p><input type="file"
          			onChange={e => this.handleDORMIODataFile(e)} accept=".csv"/>
          		</div>
          	</div>
          	<div className = "row">
          		<div className = "col">
	              <Form.Check type="checkbox" label="Replace Remote Version (If Duplicate)" onChange={(e) => this.handleReplaceRemoteCheckBox(e)}/>
	             </div>
	             <div className = "col">
	           	</div>
          	</div>
          </Modal.Body>
          <Modal.Footer>
          	{this.renderAlert()}
            <Button type = "submit" variant="info" onClick = {() => this.viewLocally()}>
              View Locally
            </Button>
            <Button type = "submit" variant="secondary" onClick = {() => this.handleUpload()} >
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