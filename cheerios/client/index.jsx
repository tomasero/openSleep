var React = require('react');
var ReactDOM = require('react-dom');

var socket = io.connect('localhost:3000');

var Main = React.createClass({

	displayName: "Cheerio",
	
	getInitialState: function() {
		return {
			items: []
		}
	},

	componentDidMount: function () {

	  var self = this;	 

      socket.on('BPM', function (data) {      	
      	self.addItemToState(data);
      });

	},

	render: function(){
		return (
				<ul>
					{this.getItemNodes()}
				</ul>
		);
	},

	getItemNodes: function() {
		return this.state.items.map(function(item){
			return (<li>{item}</li>)
		})
	},

	addItemToState: function(item){
		var items = this.state.items;
		items.push(item);
		//setState causes react to re-render the view.
		this.setState({items: items});

	}

});

ReactDOM.render(<Main />, document.getElementById('app'));

var Photo = React.createClass({

  render: function() {
    return (
      <div className='heart'>
        <img src={this.props.src} />
       
      </div>
    );
  }
});

React.render(<Photo src='/svg/cheeriosLogoOrange.svg' />, document.getElementById('heartBeat'));

















