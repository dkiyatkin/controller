gulp = require("gulp")
concat = require('gulp-concat')
clean = require('gulp-clean')
uglify = require('gulp-uglify')
coffee = require('gulp-coffee')
nodeunit = require("gulp-nodeunit")
wrap = require('gulp-wrap-umd')
# nodeunit-runner = require('gulp-nodeunit-runner')
# require "coffee-script/register"

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
    .pipe concat 'layer-control.coffee' # concat
    .pipe(coffee({bare: true, sourceMap: true})) # coffee
    # .pipe(wrap({ namespace: 'LayerControl' })) # umd
    .pipe(gulp.dest('./dist/')) # write

gulp.task 'compress', ['coffee'], ->
  gulp.src('dist/layer-control.js')
    .pipe(uglify({outSourceMap: true, mangle: false}))
    .pipe(gulp.dest('./dist/min/'))

gulp.task 'make', ['compress']

gulp.task 'clean', ->
  gulp.src('./dist/', {read: false})
    .pipe(clean())

#TODO banner, umd, clean, replace
