module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    nodeunit: [
      #'test/module.coffee'
      #'test/logger.coffee'
      #'test/events.coffee'
      #'test/loader.coffee'
      #'test/selector.coffee'
      #'test/compile.coffee'
      #'test/state.coffee'
      'test/layer.coffee'
    ]
    replace:
      all:
        options:
          force: true,
          patterns: [
            {
              match: /#x>[\s\S]+?#<x/g,
              replacement: '',
              expression: true
            }
          ]
        files: [
          {
            expand: true
            flatten: true
            dest: 'build/'
            src: [
              'src/*.coffee'
            ]
          }
          {
            expand: true
            flatten: true
            dest: 'build/test/'
            src: [
              'test/*.coffee'
            ]
          }
        ]
    coffee:
      test:
        expand: true
        flatten: true
        cwd: 'build/test/',
        src: ['*.coffee']
        dest: 'build/test/'
        ext: '.js'
        options:
          bare: true
          join: true
      src:
        files:
          'build/supercontroller.js': [
            'build/supercontroller.coffee'
            #'build/common.coffee'
            #'build/logger.coffee'
            #'build/loader.coffee'
            #'build/layers.coffee'
            #'build/state.coffee'
          ]
        options:
          bare: true
          join: true
    umd:
      all:
        src: 'build/supercontroller.js'
        dest: 'build/supercontroller.umd.js'
        objectToExport: 'SuperController'
    uglify:
      min:
        options:
          mangle: false
          #banner: ''
        files:
          'dist/supercontroller.min.js': ['build/supercontroller.umd.js']
    clean: ['build']
  grunt.loadNpmTasks('grunt-contrib-nodeunit')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-umd')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-replace')
  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.registerTask('default', [
    'nodeunit'
    #'replace'
    #'coffee:test'
    #'coffee:src'
    #'umd'
  ])
