var path = require('path'),
	webpack = require('webpack');

module.exports = {
	cache:true,
	debug:true,
	devtool: 'source-map',
	entry: {
		index: './client/index',
	},
	output:{
		path: path.join(__dirname, 'public/js'),
		publicPath: '/js',
		filename:'[name].bundle.js',
	},
	stats: {
		colors:true,
		modules:false,
		reasons:true
	},
	module: {
	    loaders: [
	      {test: /\.json$/, loader: 'json-loader'},
	      {test: /\.js$/, exclude: [/node_modules/], loader: 'babel-loader'},
	      {
	        test: /\.jsx$/,
	        exclude: [/node_modules/],
	        loaders: ['react-hot', 'babel-loader']
	      },
	      {test: /\.scss$/, loaders: ["style", "css", "sass?config=otherSassLoaderConfig"]},
	      {test: /\.css/, loader: 'style-loader!css-loader'}
	    ],
	    noParse: /\.min\.js/
  	},
	resolve: {
    	alias: {},
    	modulesDirectories: ['node_modules'],
    	extensions: ['', '.js', '.json', '.jsx', '.json', '.styl', '.css', '.scss']
  	},
  	
}