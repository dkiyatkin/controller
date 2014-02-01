if not window?
  Loader = require('../src/loader.coffee')
  load = require('../lib/load.coffee')
  #connect = require('connect')
else
  window.exports = {}
  window.loader = exports
  Loader = window.Loader

exports.loadFile = (test) ->
  test.expect 4
  text_file = "/test/index.html"
  if window?
    loader = new Loader()
  else
    #try
    #connect().use(connect.static(__dirname)).listen(3000)
    #catch e console.log e
    loader = new Loader({
      load: load
    })
  loader.load text_file, (err, data) ->
    test.ok not err, "errors"
    test.ok data, "data"
    test.equal data.split(" ")[0], "<!DOCTYPE", "simple text load"
    test.equal loader.load.cache.text[text_file], data, "check cache"
    test.done()
