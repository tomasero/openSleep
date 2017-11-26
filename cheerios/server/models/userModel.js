var mongoose = require('mongoose'),
	UserSchema = require('../schemas/user.js');

module.exports = mongoose.model('User', UserSchema);