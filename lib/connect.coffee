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

module.exports = (options) ->
  functions = require(options.functions)
  Controller = functions(require(__dirname+'/../src/cache.coffee'))
  index = JSON.parse(fs.readFileSync(options.publicDir + options.layers, 'utf-8'))
  main = fs.readFileSync(options.index, 'utf-8')

  # Возвращает массив true/false для соответсвующих показанных/непоказанных слоев
  getVisibleLayers = (layers) ->
    visibleLayers = []
    i = layers.length
    while --i >= 0
      visibleLayers[i] = layers[i].show
    visibleLayers

  createElement = (tag) ->
    {
      tag: tag,
      setAttribute: (name, val) ->
        @[name] = val
    }

  getHtml = (options, state, req, cb) ->
    $ = cheerio.load(main, {
      ignoreWhitespace: false
      xmlMode: false
      lowerCaseTags: true
    })
    controller = new Controller({
      load: load
      logger: options.logger
      index: index
      tplRender: options.tplRender
      $: $
      links: false
      addressBar: false
      cache: false
    })
    controller.document =
      createElement: createElement
      title: $('title').html()
    controller.load.headers = req.headers
    controller.once 'end', ->
      $('title').html(controller.document.title)
      # TODO проверить как вставляется meta
      if not controller.statusCode then controller.statusCode = 200
      controller.load.cache.data[options.layers] = index
      serverCache = JSON.stringify(controller.load.cache).replace(/\//gim, "\\/")
      #serverCache = serverCache.replace(/\\\//gim, '/')
      raw = 'if (window.Controller) { Controller.server = {}; Controller.server.visibleLayers = ' + JSON.stringify(getVisibleLayers(controller.layers)) + ';Controller.server.cache = '+serverCache + ' }'
      script = '<script id="controller_server_cache" type="text/javascript">'+raw+'</script>'
      $('body').append(script)
      cb(controller.statusCode, $.html())
    controller.state(state)

  _controller = new Controller({
    index: index
    logger: options.logger
    links: false
    addressBar: false
    cache: false
  }) # этот контроллер нужен для проверки адресов, чтобы зря не грузилось все
  (req, res, next) ->
      state = decodeURI(req.originalUrl)
      unless url.parse(state).search # если есть ? значит это не сюда
        if _controller.checkExists(state)
          getHtml options, state, req, (statusCode, html) ->
            res.writeHead statusCode,
              "Content-Type": "text/html"
            res.end(html)
        else next()
      else next()

