fs = require("fs")
path = require("path")
url = require("url")
cheerio = require('cheerio')
cheerio.prototype.getAttribute = cheerio.prototype.attr
cheerio.prototype.setAttribute = cheerio.prototype.attr
#cheerio.prototype.appendChild = cheerio.prototype.append
cheerio.prototype.appendChild = (node) ->
  cheerio(@).append('<'+node.tag+' name="'+node.name+'" content="'+node.content+'"')

cheerio.prototype.removeChild = (node) ->
  if (node and node.length)
    parent = @
    node.remove()

load = require('./load.coffee')

# Возвращает массив true/false для соответсвующих показанных/непоказанных слоев 
getShownLayers = (layers) ->
  shown_layers = []
  i = layers.length
  while --i >= 0
    shown_layers[i] = layers[i].show
  shown_layers

pasteHTML = (tag, html) ->
  @$(tag).html(html)

getInfraHtml = (options, state, req, cb) ->
  $ = cheerio.load options.index,
    ignoreWhitespace: false
    xmlMode: false
    lowerCaseTags: true
  document =
    title: $('title').html()
    createElement: (tag) ->
      {
        tag: tag,
        setAttribute: (name, val) ->
          @[name] = val
      }
    getElementsByTagName: (tag) ->
      tags = $(tag)
      array = []
      l = tags.length
      i = -1
      while ++i < l
        array.push($(tags[i]))
      array
  infra = new options.Infra
    load: load
    logger: options.logger
    loader: false
    index: options.layers_data
    tplParser: options.tplParser
    document: document
    $: $
  infra.pasteHTML = pasteHTML
  infra.load.headers = req.headers
  infra.state = state
  infra.once 'end', ->
    $('title').html(document.title)
    if not infra.status_code then infra.status_code = 200
    infra.load.cache.data[options.layers] = options.layers_data
    server_cache = JSON.stringify(infra.load.cache).replace(/\//gim, "\\/")
    #server_cache = server_cache.replace(/\\\//gim, '/')
    raw = 'if (window.Infra) { Infra.server = {}; Infra.server.showns = ' + JSON.stringify(getShownLayers(infra.layers)) + ';Infra.server.cache = '+server_cache + ' }'
    script = '<script id="infra_server_cache" type="text/javascript">'+raw+'</script>'
    $('body').append(script)
    cb infra.status_code, $.html()
  infra.check()

module.exports = (options) ->
  options.layers_data = JSON.parse(fs.readFileSync(options.root + options.layers, 'utf-8'))
  _infra = new options.Infra {index: options.layers_data, logger: options.logger}
  (req, res, next) ->
    try
      state = decodeURI(req.originalUrl)
      unless url.parse(state).search # если есть ? значит это не к infrajs
        _infra.checkExists state, (exist) ->
          if exist
            getInfraHtml options, state, req, (status_code, html) ->
              res.writeHead status_code,
                "Content-Type": "text/html"
              res.end html
              ###
          # проверка на последний слэш
          else unless state.slice(-1) is "/"
            state = state + "/"
            _infra.checkExists state, (exist) ->
              if exist
                res.writeHead 301, # moved permanently
                  Location: req.originalUrl + "/"
                res.end()
              else next()
              ###
          else next()
      else next()
    catch e
      console.log e
      res.writeHead 301, # moved permanently
        Location: "/"
      res.end()

