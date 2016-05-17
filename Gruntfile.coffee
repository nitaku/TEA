module.exports = (grunt) ->
  grunt.initConfig
    concat:
      dist:
        src: ['lib/d3.v3.min.js', 'lib/lodash.min.js', 'lib/backbone-min.js', 'lib/backbone.d3view.js', 'lib/backbone.nativeajax.js', 'lib/jison.min.js', 'lib/tsort.js', 'lib/cola.v3.min.js', 'lib/codemirror.min.js', 'lib/codemirror_mode_simple.js', 'lib/searchcursor.min.js', "lib/peg-0.9.0.min.js"]
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
