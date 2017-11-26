var mongoose = require('mongoose');
var Schema = mongoose.Schema;


var UserSchema = new Schema ({
	displayName: {
		type: String
	},
	image: {
		type: String
	},
	email: {
		type: String
	},
	twitter: {
		type: Object
	}
});



module.exports = UserSchema;

