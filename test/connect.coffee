fs = require('fs')
http = require('http')
connect = require('connect')
Mustache = require('mustache')
layerControl = require('../lib/connect.coffee')

app = connect()
server = http.createServer(app)
app
  .use(layerControl(
    logger: 'DEBUG'
    index: __dirname + '/../test/test.html' # доступен клиенту для самостоятельной сборки, тут меняется возвращается другой
    functions: __dirname + '/../test/functions.coffee'
    layers: '/test/layers.json' # будет положен в load.cache
    tplRender: Mustache.render
    publicDir: __dirname + "/../"
  ))

exports.ConnectMiddleware = (test) ->
  server.listen(8010)
  console.log 'listen ' + 8010 + ' ...'
  server.close()
  test.done()
