#x>
unless window?
  Nav = require('../src/nav.coffee')
else
  Nav = window.Nav
#<x

# Загружает кэш, вставленный на странице сервером.
class Cache extends Nav

  empty2 = ->
  getCache = ->
    Controller = window.Controller
    @load.cache = Controller.server.cache
    i = @layers.length
    while --i >= 0
      layer = @layers[i]
      layer.show = Controller.server.visibleLayers[i]
      if layer.show
        # КЭШ
        layer.data = @load.cache.data[layer.json] if not layer.data and layer.json and @load.cache.data[layer.json]
        layer.tplString = @load.cache.text[layer.tpl] if not layer.htmlString and not layer.tplString and layer.tpl and @load.cache.text[layer.tpl]
        layer.regState = @state.circle.state.match(new RegExp(layer.state, "im"))
        # Событие показа
        try
          layer.onshow.bind(layer)(empty2)
        catch e
          @log.error "onshow() " + i + " " + e


  # Вспомогательные средства для работы со слоями

  # Перепарсить слой при следующем чеке.
  # @param {Object} layer Слой, который будет перепарсен.
  reparseLayer = (layer) =>
    layer.show = false
    # если есть данные для загрузки, убрать данные сохраненные у слоя
    layer.data = false if layer.json
    # если есть шаблон для загрузки, убрать текст сохраненный у слоя
    if layer.tpl
      layer.tplString = ""
      layer.htmlString = ""
    else layer.htmlString = "" if layer.tplString
    # если есть наследники, то скрыть их и показать заново
    if layer.childLayers
      i = layer.childLayers.length
      while --i >= 0
        #@reparseLayer(layer.childLayers[l]);
        layer.childLayers[i].show = false

  # Перепарсить все слои.
  # @return {Undefined}
  reparseAll = =>
    i = @layers.length
    while --i >= 0
      @reparseLayer @layers[i]

  ###
                  var externals = 0;
                  var waitExternals = function(cb) {
                          if (externals) {
                                  setTimeout(function() {
                                          waitExternals(cb)
                                  }, 100);
                          } else cb();
                  }
  
                  @externalLayer = function(path) {
                          externals++;
                          var layer = {};
                          @load(path + 'layer.js', function(err, ans) {
                                  externals--;
                                  eval(ans);
                          });
                          return layer;
                  }
                  // Переопределим compile, для загрузки externals
                  var compile = @compile;
                  @compile = function(index, cb) {
                          waitExternals(function() {
                                  compile(index, cb);
                          });
                  }
  ###

  # Проверяет, существуют ли check при переданном состоянии.
  # @param {String} state Проверяемое состояние.
  checkExists = (state) ->
    @compile() unless @layers
    exist = undefined
    i = @layers.length
    while --i >= 0
      exist = new RegExp(@layers[i].state).test(state)
      #console.log(state, @layers[i].state);
      break if exist
    exist

  # Заменяет шаблонные данные в параметрах слоя.
  # oncheck-функция.
  # @param {Object} layer, слой если не передан, то будет считаться значением в this.
  oncheckTplOptions = (layer) ->
    layer = this unless layer
    layer.tpl = @tplRender layer.tpl, layer
    layer.json = @tplRender layer.json, layer

  head = (headObj) ->
    @on "start", =>
      @meta = {}
      @meta.keywords = headObj.meta.keywords
      @meta.description = headObj.meta.description
      @statusCode = 200
      @title = false
    @on "end", =>
      if not @title # если до этого не определился вручную
        if @statusCode is 404
          @title = headObj.title["404"]
        else if @state.circle.state is "/"
          @title = headObj.title.main
        else
          @title = @state.circle.state.replace(/\/+$/, "").replace(/^\/+/, "").split("/").reverse().join(" / ")+headObj.title.sub
        @lastStatusCode = @statusCode
      @document.title = @title
      # установить метатэги
      @meta.keywords = "" unless @meta.keywords
      @meta.description = "" unless @meta.description
      $head = @$("head")
      description = @$("meta[name=description]")
      keywords = @$("meta[name=keywords]")
      if (keywords and keywords.length isnt 0)
        $head.removeChild(keywords)
      if (description and description.length isnt 0)
        $head.removeChild(description)
      meta = @document.createElement("meta")
      meta.setAttribute "name", 'description'
      meta.setAttribute "content", @meta.description
      $head.appendChild meta
      meta = @document.createElement("meta")
      meta.setAttribute "name", 'keywords'
      meta.setAttribute "content", @meta.keywords
      $head.appendChild meta

  constructor: (options={}) ->
    super
    @head = head
    @oncheckTplOptions = oncheckTplOptions
    @checkExists = checkExists
    @reparseAll = reparseAll
    @reparseLayer = reparseLayer
    #if not options.title? then options.title = true
    if not options.cache? then options.cache = false
    #var controller_server_cache = document.getElementById('controller_server_cache');
    #controller_server_cache.parentNode.removeChild(controller_server_cache);
    if options.cache
      @once "start", =>
        try
          getCache()
        catch e # можно открыть просто index.html
          @log.warn "fail cache"

#x>
if not window?
  module.exports = Cache
else
  window.Cache = Cache
#<x
