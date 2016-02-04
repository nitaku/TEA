module.exports = (grunt) ->
  grunt.initConfig
    concat:
      dist:
        src: ['lib/d3.v3.min.js', 'lib/lodash.min.js', 'lib/backbone-min.js', 'lib/backbone.d3view.js', 'lib/jison.min.js']
        dest: 'lib/libs.js'
    coffee:
      compile:
        options:
          join: true
          sourceMap: true
        files:
          'app.js':
            [
              '*/*.coffee'
              'main.coffee'
            ]
    watch:
      files: [
        'main.coffee',
        '*/*.coffee'
      ]
      tasks:
        [
          'coffee',
          'concat'
        ]

  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'default', ['coffee', 'concat']
