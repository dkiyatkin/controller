if not window?
  Loader = require('../src/loader.coffee')
  connect = require('connect')
  request = require('request')
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
      load: (file, options, cb) ->
        cb = options if not cb
        options = {} if not options
        options.url = 'http://127.0.0.1:3000/' + file
        request options, (error, response, body) ->
          if not error and response.statusCode is 200
            cb null, body
          else
            cb error || response.statusCode
    })
  loader.load text_file, (err, data) ->
    test.ok not err, "errors"
    test.ok data, "data"
    test.equal data.split(" ")[0], "<!DOCTYPE", "simple text load"
    test.equal loader.load.cache.text[text_file], data, "check cache"
    test.done()
