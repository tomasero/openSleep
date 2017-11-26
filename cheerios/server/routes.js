var		path = require('path'),
 		express = require('express'),
		router	= express.Router(),
		passport = require('passport'),
		ejs = require('ejs');



module.exports = function () {

	//View Routes
	//get request to out ROOT dir fetch index.html
	router.get('/', function(req, res){
		res.render(path.normalize(__dirname + 'views/index.ejs'));
		console.log("hello world");
	});

	router.get('/users', function (req, res, next) {
  	 	res.render('users', {user: {name: req.user.displayName,
	  							 image: req.user.image}});
	});

	router.get('/logout', function (req, res){
		req.logout(); res.redirect('/');
	})

	//Twitter Routes 
	router.route('/twitter/callback')
		.get(passport.authenticate('twitter', {
		successReturnToOrRedirect: '/users',
		failure: '/error/'
 	}));

	router.route('/twitter')
		.get(passport.authenticate('twitter'));

	return router;
};








