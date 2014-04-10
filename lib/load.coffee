# Переопределение на серверный загрузчик
# Путь считывается с помощью web-сервера, проксируя основной запрос

path = require 'path'
url = require 'url'
request = require 'request'

load = (file, options, cb) ->
  if not @headers then @headers = host: '127.0.0.1:3000' # тестирование
  pathUrl = url.parse(encodeURI(file), true)
  pathUrl.href = path.normalize(pathUrl.href)
  unless pathUrl.host
    #pathUrl.href = path.join(encodeURI(state), pathUrl.href) unless pathUrl.href[0] is "/"
    pathUrl.href = "http://" + @headers.host + pathUrl.href
  delete (@headers["accept-encoding"]) # TODO
  #console.log pathUrl.href
  request
    headers: @headers
    url: pathUrl.href
    timeout: 30000
  , (error, response, body) ->
    if not error and response.statusCode is 200
      cb null, body
    else
      cb error || response.statusCode

### тестирование
load = (file, options={}, cb) ->
  options.url = 'http://127.0.0.1:3000/' + file
  request options, (error, response, body) ->
    if not error and response.statusCode is 200
      cb null, body
    else
      cb error || response.statusCode
###

module.exports = load
