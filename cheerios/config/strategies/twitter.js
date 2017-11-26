var passport = require('passport');
var TwitterStrategy = require('passport-twitter').Strategy;

module.exports = function (){
	console.log('user func');
	passport.use(new TwitterStrategy({
		consumerKey: 'hzsd4gWlbRcOcf6wTDVyqRhSN',
		consumerSecret: 'nHMgUliQXpKnJIDnL2JdUe3Fzc8mhd1P62TUdNmBeGEIbCRmRx',
		callbackURL: 'http://localhost:3000/twitter/callback',
		passReqToCallback: true
	},
	function (req, token, tokenSecret, profile, done){
		var user = {};
		console.log('user func');
        	//user.email = profilt6e.emails[0].value;
        	user.image = profile._json.profile_image_url;
        	user.displayName = profile.displayName;

        	user.twitter = {};
        	user.twitter.id = profile.id;
        	user.twitter.token = token;

        	done(null, user);
        

	}))
};