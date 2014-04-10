#x>
unless window?
  Logger = require('./logger.coffee')
  Promise = require('es6-promise').Promise
else
  Logger = window.Logger
  Promise = window.Promise
#<x

class Loader extends Logger

  # XMLHttpRequest - иксмлхэттэпэреквест
  createRequestObject = () ->
    unless XMLHttpRequest?
      ->
        try
          return new ActiveXObject("Msxml2.XMLHTTP.6.0")
        try
          return new ActiveXObject("Msxml2.XMLHTTP.3.0")
        try
          return new ActiveXObject("Msxml2.XMLHTTP")
        try
          return new ActiveXObject("Microsoft.XMLHTTP")
        throw new Error("This browser does not support XMLHttpRequest.")
    else new XMLHttpRequest()

  # TODO controller -> this

  # Выполнить js
  globalEval = (data, controller) =>
    head = controller.$('head')
    script = controller.document.createElement("script")
    script.type = "text/javascript"
    script.text = data
    head.insertBefore script, head.firstChild
    head.removeChild script

  # Кросс-доменный запрос
  setXDR = (path, controller) =>
    script = controller.document.createElement("script")
    script.type = "text/javascript"
    head = controller.$('head')
    script.src = path
    head.insertBefore script, head.firstChild
    head.removeChild script

  # Очистка кэша по регекспу
  _clearRegCache = (clean, obj) ->
    for own key of obj
      delete (obj[key]) if clean.test(key)

  ###*
  * Общий низкоуровневый загрузчик, является promise, callback не обязателен.
  * Загружает переданный путь не используя кэширование.
  * @param {String} url Путь для загрузки.
  * @param {Object} options Параметры для загрузки.
  * @param {Function} callback Callback функция, первый агрумент содержит ошибку запроса, второй строку полученных данных с сервера.
  * @param {Boolean} options.timestamp
  * @param {String} options.method
  * @param {String} options.params
  * @param {String} options.type text по-умолчанию. (json, TODO: html, jsonp, script, text)
  * @param {Number} options.timeout ms
  ###
  _load = (url, options, cb) ->
    new Promise((resolve, reject) ->
      try
        timeout = false
        req = new createRequestObject()
        if options.timestamp
          if url.indexOf('?') is -1
            url = url+'?timestamp='+new Date().getTime()
          else
            url = url+'&timestamp='+new Date().getTime()
        req.open options.method || "GET", url, if options.async? then options.async else true
        params = null
        if options.method is 'POST'
          req.setRequestHeader 'Content-Type', 'application/x-www-form-urlencoded; charset=utf-8'
          params = options.params
        if options.type is 'json'
          req.setRequestHeader 'Content-Type', 'application/x-www-form-urlencoded; charset=utf-8'
          req.setRequestHeader 'Accept', 'application/json, text/javascript'
        else
          req.setRequestHeader 'Content-Type', 'text/plain; charset=utf-8'
        req.setRequestHeader 'If-Modified-Since', 'Sat, 1 Jan 2005 00:00:00 GMT'
        req.setRequestHeader 'X-Requested-With', 'XMLHttpRequest'
        req.onreadystatechange = ->
          if req.readyState is 4
            unless timeout
              if req.status is 200
                resolve req.responseText
                cb null, req.responseText if cb
              else
                error = Error(req.statusText)
                reject error
                cb error if cb
        req.send params # через запад на восток, через север, через юг, возвращайся, сделав круг
        if options.timeout
          setTimeout (->
            timeout = true
            req.abort()
            error = Error('timeout')
            reject error
            cb error if cb
          ), options.timeout
      catch e
        reject e
        cb e if cb
    )

  constructor: (options = {}) ->
    super
    ###*
    * Загрузчик с использованием кэша
    * Загружает переданный путь, если он уже загружен то будет получен кэшированный ответ.
    * options.type
    * options.method
    *
    * @param {String} path Путь для загрузки.
    * @param {Object} options Параметры для загрузки.
    * @param {Function} callback Callback функция, первый агрумент содержит ошибку запроса, второй строку ответ сервера.
    ###
    @load = (path, options={}, cb) =>
      cb = options if not cb
      if (!@load.cache.text[path]?)
        unless @load.loading[path]
          @load[path] = true
          @load.load path, options, (err, ans) =>
            @load.cache.text[path] = ans
            @log.error "error load " + path if err
            @load.loading[path] = false
            @emit "loaded: " + path, err
            cb err, @load.cache.text[path]
        else
          @log.debug "multiply loading: " + path
          @once "loaded: " + path, (err) =>
            cb err, @load.cache.text[path]
      else cb null, @load.cache.text[path]

    ###*
    * Объект хранит кэш-данные.
    * Примеры:
    * controller.load.cache.css['css-code'] // если true, то указанный css-код применился.
    * controller.load.cache.text['path/to/file'] // возвращает загруженный текст по указанному пути.
    * controller.load.cache.data['path/to/file'] // возвращает объект, полученный из текста по указанному пути.
    ###
    @load.cache =
      css: {}
      data: {}
      text: {}

    ###*
    * Высокоуровневый загрузчик файлов для контроллера с поддержкой кэширования
    * Применение стилей и выполнение скриптов на странице
    ###

    ###
    load = (path, options, callback) ->
    load.js ->
    load.css ->
    load.json ->
    load.script ->
    load.load ->
    ###

    @load.loading = {} # файлы, которые сейчас загружаются
    @load.load = options.load || _load  # загрузчик файлов, ура, ура


    ###*
    * Загружает переданный путь как JSON-объект, если он уже загружен то будет получен кэшированный ответ.
    *
    * @param {String} path Путь для загрузки.
    * @param {Object} options Параметры для загрузки.
    * @param {Function} callback Callback функция, первый агрумент содержит ошибку запроса, второй JSON-объект ответ сервера.
    ###
    @load.json = (path, options={}, cb) =>
      cb = options if not cb
      options.type = 'json'
      if (!@load.cache.data[path]?)
        @load path, options, (err, text) =>
          try
            @load.cache.data[path] = JSON.parse(text)
          catch e
            @log.error "wrong json data " + path
          cb err, @load.cache.data[path]
      else cb null, @load.cache.data[path]

    ###*
    * Загружает переданный путь и выполняет его как javascript-код, если он уже загружен то будет выполнен повторно.
    * После чего выполняет полученные данные как js-код в глобальной области.
    *
    * @param {String} path Путь для загрузки.
    * @param {Object} options Параметры для загрузки.
    * @param {Function} callback Callback функция, единственный агрумент содержит ошибку выполнения команды.
    ###
    @load.js = (path, options={}, cb) =>
      cb = options if not cb
      if (/^http(s){0,1}:\/\//.test(path) or /^\/\//.test(path))
        setXDR path, @ # <-
        cb null
      else
        options.type = 'text'
        @load path, (err, options, ans) ->
          if not err
            try
              globalEval ans, @ # <-
              cb null
            catch e
              @log.error "wrong js " + path
              cb e
          else cb err
    _busy = false

    ###*
    * Выполняет script вставленный в DOM.
    * @param {Object} node DOM-узел тэга script.
    ###
    @load.script = (node) =>
      if _busy
        setTimeout (->
          @load.script node
        ), 1
        return
      _busy = true
      if node.src
        @load.js node.src, (err) ->
          _busy = false
      else
        try
          globalEval node.innerHTML, @
        catch e
          @log.error "Ошибка в скрипте."
        _busy = false

    ###*
    * Вставляет стили на страницу и применяет их.
    * @param {String} code Код css для вставки в документ.
    ###
    @load.css = (code) =>
      return if @load.cache.css[code] #Почему-то если это убрать после нескольких перепарсиваний стили у слоя слетают..
      @load.cache.css[code] = true
      style = @document.createElement("style") #создани style с css
      style.type = "text/css"
      if style.styleSheet
        style.styleSheet.cssText = code
      else
        style.appendChild @document.createTextNode(code)
      head = @$('head')
      head.insertBefore style, head.lastChild #добавили css на страницу

    ###*
    * Очищает кэш в зависимости от переданного параметра.
    * @param {String|Object} [clean] Если передан RegExp, функция удаляет весь кэш, пути которого совпадают с регулярными выражением.
    * Если передана строка, удаляется кэш, пути которого равны строке. Если ничего не передано очищается весь кэш.
    ###
    @load.clearCache = (clean) =>
      if !clean?
        @load.cache.data = {}
        @load.cache.text = {}
      else if clean.constructor is RegExp
        _clearRegCache clean, @load.cache.data
        _clearRegCache clean, @load.cache.text
      else
        delete (@load.cache.data[clean])
        delete (@load.cache.text[clean])


#x>
if not window?
  module.exports = Loader
else
  window.Loader = Loader
#<x
