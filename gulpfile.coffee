gulp = require('gulp')
concat = require('gulp-concat')
clean = require('gulp-clean')
uglify = require('gulp-uglify')
coffee = require('gulp-coffee')
nodeunit = require('gulp-nodeunit')
header = require('gulp-header')
# wrap = require('gulp-wrap-umd')
rename = require('gulp-rename')
replace = require('gulp-replace')
# nodeunit-runner = require('gulp-nodeunit-runner')
# require 'coffee-script/register'
pkg = require('./package.json')
banner = [
  "/*!"
  " * <%= pkg.name %> v<%= pkg.version %> (<%= pkg.homepage %>)"
  " * Copyright (c) 2014 <%= pkg.author %>"
  " * Licensed under <%= pkg.licenses[0].type %> (<%= pkg.licenses[0].url %>)"
  " */"
  ""
].join("\n")

testFiles = [
  'test/module.coffee'
  'test/logger.coffee'
  'test/events.coffee'
  'test/loader.coffee'
  'test/selector.coffee'
  'test/compile.coffee'
  'test/state.coffee'
  'test/layer.coffee'
]
srcFiles = [
  'src/common.coffee'
  'src/logger.coffee'
  # 'src/events.coffee'
  'src/loader.coffee'
  'src/selector.coffee'
  'src/compile.coffee'
  'src/state.coffee'
  'src/layer.coffee'
]

gulp.task 'nodeunit', ->
  gulp.src(testFiles).pipe(nodeunit())

gulp.task 'coffee', ['clean'], ->
  gulp.src(srcFiles)
    .pipe(replace(/#x>[\s\S]+?#<x/gim, '')) # replace
    .pipe(concat('layer-control.coffee')) # concat
    .pipe(coffee({bare: true, sourceMap: true})) # coffee
    # .pipe(wrap({ namespace: 'LayerControl' })) # umd
    .pipe(rename((path) ->
      if path.extname is '.map'
        path.basename = path.basename.replace(/\.js$/,'')
      return
    ))
    .pipe(header(banner, { pkg : pkg } ))
    .pipe(gulp.dest('./dist/')) # write

gulp.task 'compress', ['coffee'], ->
  gulp.src('./dist/layer-control.js')
    .pipe(uglify({outSourceMap: true, mangle: false}))
    .pipe(rename((path) ->
      if path.extname is '.map'
        path.basename = path.basename.replace(/\.js$/,'')
      else
        path.basename += ".min"
      return
    ))
    .pipe(header(banner, { pkg : pkg } ))
    .pipe(gulp.dest('./dist/'))

gulp.task 'make', ['compress']

gulp.task 'clean', ->
  gulp.src('./dist/', {read: false})
    .pipe(clean())

#TODO umd
