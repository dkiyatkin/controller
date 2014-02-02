  if not @options.cache? then @options.cache = false
    # Загружает кэш, вставленный на странице сервером.

    empty2 = ->
    getCache = =>
      Infra = window.Infra
      @load.cache = Infra.server.cache
      i = @layers.length
      while --i >= 0
        layer = @layers[i]
        layer.show = Infra.server.showns[i]
        if layer.show
          # КЭШ
          layer.data = @load.cache.data[layer.json] if not layer.data and layer.json and @load.cache.data[layer.json]
          layer.tplString = @load.cache.text[layer.tpl] if not layer.htmlString and not layer.tplString and layer.tpl and @load.cache.text[layer.tpl]
          layer.reg_state = @state.match(new RegExp(layer.state, "im"))
          # Событие показа
          try
            layer.onshow.bind(layer)(empty2)
          catch e
            @log.error "onshow() " + i + " " + e
    
    #var infra_server_cache = document.getElementById('infra_server_cache');
    #infra_server_cache.parentNode.removeChild(infra_server_cache);
    if @options.cache
      @once "start", =>
        try
          getCache()
        catch e # можно открыть просто index.html
          @log.warn "fail cache"

    # Вспомогательные средства для работы со слоями

    # * Перепарсить слой при следующем чеке.
    # *
    # * @param {Object} layer Слой, который будет перепарсен.
    #
    @reparseLayer = (layer) =>
      layer.show = false
      # если есть данные для загрузки, убрать данные сохраненные у слоя
      layer.data = false if layer.json
      # если есть шаблон для загрузки, убрать текст сохраненный у слоя
      if layer.tpl
        layer.tplString = ""
        layer.htmlString = ""
      else layer.htmlString = "" if layer.tplString
      # если есть наследники, то скрыть их и показать заново
      if layer.childs
        i = layer.childs.length
        while --i >= 0
          #@reparseLayer(layer.childs[l]);
          layer.childs[i].show = false
    
    #
    # * Перепарсить все слои.
    # *
    # * @return {Undefined}
    #
    @reparseAll = =>
      i = @layers.length
      while --i >= 0
        @reparseLayer @layers[i]

    #!
    #                var externals = 0;
    #                var waitExternals = function(cb) {
    #                        if (externals) {
    #                                setTimeout(function() {
    #                                        waitExternals(cb)
    #                                }, 100);
    #                        } else cb();
    #                }
    #
    #                @externalLayer = function(path) {
    #                        externals++;
    #                        var layer = {};
    #                        @load(path + 'layer.js', function(err, ans) {
    #                                externals--;
    #                                eval(ans);
    #                        });
    #                        return layer;
    #                }
    #                // Переопределим compile, для загрузки externals
    #                var compile = @compile;
    #                @compile = function(index, cb) {
    #                        waitExternals(function() {
    #                                compile(index, cb);
    #                        });
    #                }
    #
    _checkExists = (state, cb) =>
      exist = undefined
      i = @layers.length
      while --i >= 0
        exist = new RegExp(@layers[i].state).test(state)
        #console.log(state, @layers[i].state);
        break if exist
      cb exist
    
    #
    # * Проверяет, существуют ли check при переданном состоянии.
    # *
    # * @param {String} state Проверяемое состояние.
    # * @param {Function} cb Callback-функция, один агрумент результат проверки.
    #
    @checkExists = (state, cb) =>
      unless @layers.length
        @compile @index
        _checkExists state, cb
      else
        _checkExists state, cb

    #
    # * Заменяет шаблонные данные в параметрах слоя.
    # * oncheck-функция.
    # *
    # * @param {Function} cb Callback-функция.
    # * @param {Object} layer, слой если не передан, то будет считаться значением в this.
    #
    @oncheckTplOptions = (cb, layer) =>
      layer = this unless layer
      counter = 2
      _cb = =>
        cb() if --counter is 0
      @tplParser layer.tpl, layer, (data) =>
        layer.tpl = data
        _cb()
      @tplParser layer.json, layer, (data) =>
        layer.json = data
        _cb()

    ###
if not @options.title? then @options.title = true
###
    @head = (headObj) =>
      @on "start", =>
        @meta = {}
        @meta.keywords = headObj.meta.keywords
        @meta.description = headObj.meta.description
        @status_code = 200
        @title = false
      @on "end", =>
        if not @title # если до этого не определился вручную
          if @status_code is 404
            @title = headObj.title["404"]
          else if @state is "/"
            @title = headObj.title.main
          else
            @title = @state.replace(/\/+$/, "").replace(/^\/+/, "").split("/").reverse().join(" / ") + headObj.title.sub
          @last_status_code = @status_code
        @document.title = @title
        # установить метатэги
        @meta.keywords = "" unless @meta.keywords
        @meta.description = "" unless @meta.description
        head = @$("head")
        description = @$("meta[name=description]")
        keywords = @$("meta[name=keywords]")
        if (keywords and keywords.length isnt 0)
          head.removeChild(keywords)
        if (description and description.length isnt 0)
          head.removeChild(description)
        meta = @document.createElement("meta")
        meta.setAttribute "name", 'description'
        meta.setAttribute "content", @meta.description
        head.appendChild meta
        meta = @document.createElement("meta")
        meta.setAttribute "name", 'keywords'
        meta.setAttribute "content", @meta.keywords
        head.appendChild meta
