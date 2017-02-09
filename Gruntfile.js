module.exports = function (grunt) {
	'use strict';

  grunt.initConfig({
    mochaTest: {
      test: {
        options: {
          reporter: 'spec',
          require: ['coffee-script', 'coffee-coverage/register-istanbul']
        },
        src: ['test/**/*.coffee']
      }
    },
    makeReport: {
        src: 'coverage/*.json',
        options: {
            type: 'text',
        }
    },
    release: {
      options: {
        tagName: 'v<%= version %>',
        commitMessage: 'Prepared to release <%= version %>.'
      }
    },
    watch: {
      files: ['Gruntfile.js', 'src/**/*.coffee', 'test/**/*.coffee'],
      tasks: ['test']
    },
    coffeelint: {
      app: ['scripts/*.coffee', 'test/*.coffee'],
      options: {
        'arrow_spacing': {'level': 'warn'},
        'braces_spacing': {'level': 'warn'},
        'max_line_length': {'value': 120, 'level': 'warn'},
        'no_empty_functions': {'level': 'warn'},
        'no_empty_param_list': {'level': 'warn'},
        'no_interpolation_in_single_quotes': {'level': 'warn'},
        'no_this': {'level': 'warn'},
        'no_unnecessary_double_quotes': {'level': 'warn'},
        'space_operators': {'level': 'warn'},
        'spacing_after_comma': {'level': 'warn'}
      }
    }
  });


  grunt.loadNpmTasks('grunt-coffeelint');
  grunt.loadNpmTasks('grunt-mocha-test');
  grunt.loadNpmTasks('grunt-istanbul');

  grunt.registerTask('test', ['mochaTest', 'makeReport']);

	grunt.loadNpmTasks('grunt-release');
};
