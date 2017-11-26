var express = require('express'),
	app = express(),
	server = require('http').Server(app),
	io = require('socket.io')(server),
	path = require('path'),
	parser = require('body-parser'),
	cookieParser = require('cookie-parser'),
	passport = require('passport'),
	logger = require('morgan'),
	session = require('express-session'),
	mongoose = require('mongoose'),
	UserModel = require('./server/models/userModel.js'),
	port = 3000,
	router = require('./server/routes');

app.use(session({
	secret: 'anything',
	resave: true,
  	saveUninitialized: true,
  	cookie: { secure: false }}));



require('./config/passport')(app);	

// app.use(passport.initialize());
// app.use(passport.session());


mongoose.connect('mongodb://localhost:27017/cheerios');
console.log("Connected to database Cheerios");
    
app.use(logger('dev'));
app.use(parser.json());
app.use(parser.urlencoded({extended:false}));
app.use(cookieParser());
app.use(express.static(__dirname + '/public'));

app.set('view engine', 'ejs');
app.set('views', path.normalize( __dirname +'/server/views'));
//app.set('views', path.join(__dirname, '/server/views'));

app.get('/', function(req, res){
	res.render('index', {});

}); 

app.use(passport.initialize());
app.use(passport.session());

app.use(router());

/*
********** Configure Routes
*/

//app.use('/', routes);
// app.use('/users', users);



// catch 404 and froward to error handler

/*app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handlers

// development error handler
// will print stacktrace
if (app.get('env') === 'development') {
  app.use(function (err, req, res, next) {
    res.status(err.status || 500);
    res.render('error', {
      message: err.message,
      error: err
    });
  });
}

// production error handler
// no stacktraces leaked to user
app.use(function (err, req, res, next) {
  res.status(err.status || 500);
  res.render('error', {
    message: err.message,
    error: {}
  });
});
*/
module.exports = app;


server.listen(port, function(){
	console.log("Server is available at http://localhost:" + port);	
});


//Socket connection
// io.on('connection', function (socket){
	
// 	require('./server/cheerio.js')(socket);
// 	console.log("Socket IO is connected");

// });

