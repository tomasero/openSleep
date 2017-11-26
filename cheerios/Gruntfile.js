var _ = require('underscore');
var path = require('path');

module.exports = function(grunt) {

  var webpackConfig = require('./webpack.config');

  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    webpack: {
      app: _.extend({}, webpackConfig, {
        progress: true, // Don't show progress
        // Defaults to true

        failOnError: true, // don't report error to grunt if webpack find errors
        // Use this if webpack errors are tolerable and grunt should continue

        watch: false, // use webpacks watcher
        // You need to keep the grunt process alive

        keepalive: false // don't finish the grunt task
        // Use this in combination with the watch option
      }),
      watch: _.extend({}, webpackConfig, {
        progress: false, // Don't show progress
        // Defaults to true

        failOnError: false, // don't report error to grunt if webpack find errors
        // Use this if webpack errors are tolerable and grunt should continue

        watch: true, // use webpacks watcher
        // You need to keep the grunt process alive

        keepalive: true // don't finish the grunt task
        // Use this in combination with the watch option
      })
    },
    nodemon:{
      dev: {
        script: './server.js',
        options:{
          nodeArgs:['--debug'],
          ignore:['node_modules/**'],
          watch:['cheerios']
        }
      }
    }
  });


  
  grunt.loadNpmTasks('grunt-webpack');
  grunt.loadNpmTasks('grunt-nodemon');

  grunt.registerTask('watch', ['webpack:watch']);
  grunt.registerTask('bundle', ['webpack:app']);
  grunt.registerTask('start', ['nodemon:dev']);

};
