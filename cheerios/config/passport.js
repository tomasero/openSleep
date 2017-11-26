var passport = require('passport');

module.exports = function(app){

	app.use(passport.initialize());
	app.use(passport.session());

	//places user object into session
	passport.serializeUser(function (user, done){
	  done(null, user);
	});

	passport.deserializeUser(function (user, done){
	  done(null, user);
	});
	
	require('./strategies/twitter')();
	

};