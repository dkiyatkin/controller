/*!
 * layer-control v0.0.2 (https://github.com/dkiyatkin/controller)
 * Copyright (c) 2014 Dmitriy Kiyatkin <info@dkiyatkin.com> (http://dkiyatkin.com)
 * Licensed under MIT (https://github.com/dkiyatkin/controller/raw/master/LICENSE)
 */
(function() {
  var Cache, Compile, Layer, LayerControl, Loader, Logger, Module, Nav, Selector, State, mixOf, moduleKeywords,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __slice = [].slice;

  moduleKeywords = ['extended', 'included'];

  Module = (function(_super) {
    __extends(Module, _super);

    function Module() {
      return Module.__super__.constructor.apply(this, arguments);
    }

    Module.extend = function(obj) {
      var key, value, _ref;
      for (key in obj) {
        value = obj[key];
        if (__indexOf.call(moduleKeywords, key) < 0) {
          this[key] = value;
        }
      }
      if ((_ref = obj.extended) != null) {
        _ref.apply(this);
      }
      return this;
    };

    Module.include = function(obj) {
      var key, value, _ref;
      for (key in obj) {
        value = obj[key];
        if (__indexOf.call(moduleKeywords, key) < 0) {
          this.prototype[key] = value;
        }
      }
      if ((_ref = obj.included) != null) {
        _ref.apply(this);
      }
      return this;
    };

    Module.prototype.empty = function(cb) {
      if (cb) {
        return cb();
      }
    };

    return Module;

  })(EventEmitter);

  mixOf = function() {
    var Mixed, base, method, mixin, mixins, name, _i, _ref;
    base = arguments[0], mixins = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    Mixed = (function(_super) {
      __extends(Mixed, _super);

      function Mixed() {
        return Mixed.__super__.constructor.apply(this, arguments);
      }

      return Mixed;

    })(base);
    for (_i = mixins.length - 1; _i >= 0; _i += -1) {
      mixin = mixins[_i];
      _ref = mixin.prototype;
      for (name in _ref) {
        method = _ref[name];
        Mixed.prototype[name] = method;
      }
    }
    return Mixed;
  };


  /**
  * Интерфейс управления отладочными сообщениями.
  * Примеры:
  * controller.log.error('test error'); // вернет и выведет в консоль 'test error'
  * controller.log.warning('test warning'); // вернет и выведет в консоль 'test warning'
  * controller.log.info('test info'); // вернет и выведет в консоль 'test info'
  * controller.log.logger = 'WARNING'; // выбрать уровень логгера
  * // доступны 4 соответсвующих уровня: ERROR, WARNING (выбран по умолчанию), INFO и DEBUG
  * controller.log.debug('test debug'); // ничего не произойдет, потому что логгер задан уровнем выше
  * controller.log.history; // история всех сообщений контроллера
   */

  Logger = (function(_super) {
    var loggers, _log;

    __extends(Logger, _super);

    loggers = ['ERROR', 'WARNING', 'INFO', 'DEBUG'];

    _log = function(msg, log_level, log) {
      if (loggers.indexOf(log.logger) >= log_level) {
        msg = '[' + new Date().toGMTString() + '] ' + loggers[log_level] + ' ' + msg.join(' ');
        if (!log.quiet) {
          if (log_level === 3) {
            console.log(msg);
          }
          if (log_level === 2) {
            console.info(msg);
          }
          if (log_level === 1) {
            console.warn(msg);
          }
          if (log_level === 0) {
            console.error(msg);
          }
        }
        log.history += '\n' + msg;
        return msg;
      }
    };

    function Logger(options) {
      if (options == null) {
        options = {};
      }
      this.log = {
        history: '',
        logger: options.logger || 'WARNING',
        quiet: options.quiet || false,
        debug: function() {
          var msg;
          msg = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return _log(msg, 3, this);
        },
        info: function() {
          var msg;
          msg = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return _log(msg, 2, this);
        },
        warn: function() {
          var msg;
          msg = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return _log(msg, 1, this);
        },
        error: function() {
          var msg;
          msg = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return _log(msg, 0, this);
        }
      };
    }

    return Logger;

  })(Module);

  Loader = (function(_super) {
    var createRequestObject, globalEval, setXDR, _clearRegCache, _load;

    __extends(Loader, _super);

    createRequestObject = function() {
      if (typeof XMLHttpRequest === "undefined" || XMLHttpRequest === null) {
        return function() {
          try {
            return new ActiveXObject("Msxml2.XMLHTTP.6.0");
          } catch (_error) {}
          try {
            return new ActiveXObject("Msxml2.XMLHTTP.3.0");
          } catch (_error) {}
          try {
            return new ActiveXObject("Msxml2.XMLHTTP");
          } catch (_error) {}
          try {
            return new ActiveXObject("Microsoft.XMLHTTP");
          } catch (_error) {}
          throw new Error("This browser does not support XMLHttpRequest.");
        };
      } else {
        return new XMLHttpRequest();
      }
    };

    globalEval = function(data, controller) {
      var head, script;
      head = controller.$('head');
      script = controller.document.createElement("script");
      script.type = "text/javascript";
      script.text = data;
      head.insertBefore(script, head.firstChild);
      return head.removeChild(script);
    };

    setXDR = function(path, controller) {
      var head, script;
      script = controller.document.createElement("script");
      script.type = "text/javascript";
      head = controller.$('head');
      script.src = path;
      head.insertBefore(script, head.firstChild);
      return head.removeChild(script);
    };

    _clearRegCache = function(clean, obj) {
      var key, _results;
      _results = [];
      for (key in obj) {
        if (!__hasProp.call(obj, key)) continue;
        if (clean.test(key)) {
          _results.push(delete obj[key]);
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };


    /**
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
     */

    _load = function(url, options, cb) {
      return new Promise(function(resolve, reject) {
        var e, params, req, timeout;
        try {
          timeout = false;
          req = new createRequestObject();
          if (options.timestamp) {
            if (url.indexOf('?') === -1) {
              url = url + '?timestamp=' + new Date().getTime();
            } else {
              url = url + '&timestamp=' + new Date().getTime();
            }
          }
          req.open(options.method || "GET", url, options.async != null ? options.async : true);
          params = null;
          if (options.method === 'POST') {
            req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=utf-8');
            params = options.params;
          }
          if (options.type === 'json') {
            req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=utf-8');
            req.setRequestHeader('Accept', 'application/json, text/javascript');
          } else {
            req.setRequestHeader('Content-Type', 'text/plain; charset=utf-8');
          }
          req.setRequestHeader('If-Modified-Since', 'Sat, 1 Jan 2005 00:00:00 GMT');
          req.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
          req.onreadystatechange = function() {
            var error;
            if (req.readyState === 4) {
              if (!timeout) {
                if (req.status === 200) {
                  resolve(req.responseText);
                  if (cb) {
                    return cb(null, req.responseText);
                  }
                } else {
                  error = Error(req.statusText);
                  reject(error);
                  if (cb) {
                    return cb(error);
                  }
                }
              }
            }
          };
          req.send(params);
          if (options.timeout) {
            return setTimeout((function() {
              var error;
              timeout = true;
              req.abort();
              error = Error('timeout');
              reject(error);
              if (cb) {
                return cb(error);
              }
            }), options.timeout);
          }
        } catch (_error) {
          e = _error;
          reject(e);
          if (cb) {
            return cb(e);
          }
        }
      });
    };

    function Loader(options) {
      var _busy;
      if (options == null) {
        options = {};
      }
      Loader.__super__.constructor.apply(this, arguments);

      /**
      * Загрузчик с использованием кэша
      * Загружает переданный путь, если он уже загружен то будет получен кэшированный ответ.
      * options.type
      * options.method
      *
      * @param {String} path Путь для загрузки.
      * @param {Object} options Параметры для загрузки.
      * @param {Function} callback Callback функция, первый агрумент содержит ошибку запроса, второй строку ответ сервера.
       */
      this.load = (function(_this) {
        return function(path, options, cb) {
          if (options == null) {
            options = {};
          }
          if (!cb) {
            cb = options;
          }
          if (_this.load.cache.text[path] == null) {
            if (!_this.load.loading[path]) {
              _this.load[path] = true;
              return _this.load.load(path, options, function(err, ans) {
                _this.load.cache.text[path] = ans;
                if (err) {
                  _this.log.error("error load " + path);
                }
                _this.load.loading[path] = false;
                _this.emit("loaded: " + path, err);
                return cb(err, _this.load.cache.text[path]);
              });
            } else {
              _this.log.debug("multiply loading: " + path);
              return _this.once("loaded: " + path, function(err) {
                return cb(err, _this.load.cache.text[path]);
              });
            }
          } else {
            return cb(null, _this.load.cache.text[path]);
          }
        };
      })(this);

      /**
      * Объект хранит кэш-данные.
      * Примеры:
      * controller.load.cache.css['css-code'] // если true, то указанный css-код применился.
      * controller.load.cache.text['path/to/file'] // возвращает загруженный текст по указанному пути.
      * controller.load.cache.data['path/to/file'] // возвращает объект, полученный из текста по указанному пути.
       */
      this.load.cache = {
        css: {},
        data: {},
        text: {}
      };

      /**
      * Высокоуровневый загрузчик файлов для контроллера с поддержкой кэширования
      * Применение стилей и выполнение скриптов на странице
       */

      /*
      load = (path, options, callback) ->
      load.js ->
      load.css ->
      load.json ->
      load.script ->
      load.load ->
       */
      this.load.loading = {};
      this.load.load = options.load || _load;

      /**
      * Загружает переданный путь как JSON-объект, если он уже загружен то будет получен кэшированный ответ.
      *
      * @param {String} path Путь для загрузки.
      * @param {Object} options Параметры для загрузки.
      * @param {Function} callback Callback функция, первый агрумент содержит ошибку запроса, второй JSON-объект ответ сервера.
       */
      this.load.json = (function(_this) {
        return function(path, options, cb) {
          if (options == null) {
            options = {};
          }
          if (!cb) {
            cb = options;
          }
          options.type = 'json';
          if (_this.load.cache.data[path] == null) {
            return _this.load(path, options, function(err, text) {
              var e;
              try {
                _this.load.cache.data[path] = JSON.parse(text);
              } catch (_error) {
                e = _error;
                _this.log.error("wrong json data " + path);
              }
              return cb(err, _this.load.cache.data[path]);
            });
          } else {
            return cb(null, _this.load.cache.data[path]);
          }
        };
      })(this);

      /**
      * Загружает переданный путь и выполняет его как javascript-код, если он уже загружен то будет выполнен повторно.
      * После чего выполняет полученные данные как js-код в глобальной области.
      *
      * @param {String} path Путь для загрузки.
      * @param {Object} options Параметры для загрузки.
      * @param {Function} callback Callback функция, единственный агрумент содержит ошибку выполнения команды.
       */
      this.load.js = (function(_this) {
        return function(path, options, cb) {
          if (options == null) {
            options = {};
          }
          if (!cb) {
            cb = options;
          }
          if (/^http(s){0,1}:\/\//.test(path) || /^\/\//.test(path)) {
            setXDR(path, _this);
            return cb(null);
          } else {
            options.type = 'text';
            return _this.load(path, function(err, options, ans) {
              var e;
              if (!err) {
                try {
                  globalEval(ans, this);
                  return cb(null);
                } catch (_error) {
                  e = _error;
                  this.log.error("wrong js " + path);
                  return cb(e);
                }
              } else {
                return cb(err);
              }
            });
          }
        };
      })(this);
      _busy = false;

      /**
      * Выполняет script вставленный в DOM.
      * @param {Object} node DOM-узел тэга script.
       */
      this.load.script = (function(_this) {
        return function(node) {
          var e;
          if (_busy) {
            setTimeout((function() {
              return this.load.script(node);
            }), 1);
            return;
          }
          _busy = true;
          if (node.src) {
            return _this.load.js(node.src, function(err) {
              return _busy = false;
            });
          } else {
            try {
              globalEval(node.innerHTML, _this);
            } catch (_error) {
              e = _error;
              _this.log.error("Ошибка в скрипте.");
            }
            return _busy = false;
          }
        };
      })(this);

      /**
      * Вставляет стили на страницу и применяет их.
      * @param {String} code Код css для вставки в документ.
       */
      this.load.css = (function(_this) {
        return function(code) {
          var head, style;
          if (_this.load.cache.css[code]) {
            return;
          }
          _this.load.cache.css[code] = true;
          style = _this.document.createElement("style");
          style.type = "text/css";
          if (style.styleSheet) {
            style.styleSheet.cssText = code;
          } else {
            style.appendChild(_this.document.createTextNode(code));
          }
          head = _this.$('head');
          return head.insertBefore(style, head.lastChild);
        };
      })(this);

      /**
      * Очищает кэш в зависимости от переданного параметра.
      * @param {String|Object} [clean] Если передан RegExp, функция удаляет весь кэш, пути которого совпадают с регулярными выражением.
      * Если передана строка, удаляется кэш, пути которого равны строке. Если ничего не передано очищается весь кэш.
       */
      this.load.clearCache = (function(_this) {
        return function(clean) {
          if (clean == null) {
            _this.load.cache.data = {};
            return _this.load.cache.text = {};
          } else if (clean.constructor === RegExp) {
            _clearRegCache(clean, _this.load.cache.data);
            return _clearRegCache(clean, _this.load.cache.text);
          } else {
            delete _this.load.cache.data[clean];
            return delete _this.load.cache.text[clean];
          }
        };
      })(this);
    }

    return Loader;

  })(Logger);

  Selector = (function(_super) {
    var find, html, selector;

    __extends(Selector, _super);

    html = function(htmlString) {
      var i;
      if (htmlString) {
        if (this.length != null) {
          i = this.length;
          while (--i >= 0) {
            this[i].innerHTML = htmlString;
          }
        } else {
          this.innerHTML = htmlString;
        }
        return this;
      } else {
        if (this.length != null) {
          return this[this.length - 1].innerHTML;
        } else {
          return this.innerHTML;
        }
      }
    };

    find = function(query) {
      var i, ii, node, node_child;
      node_child = [];
      node_child.find = find;
      node_child.html = html;
      if (this.length > 1) {
        i = this.length;
        while (--i >= 0) {
          node = this[i].querySelectorAll(query);
          ii = node.length;
          while (--ii >= 0) {
            node[ii].find = find;
            node[ii].html = html;
            node_child.push(node[ii]);
          }
        }
      } else if (this.length === 1) {
        node_child = this[0].querySelectorAll(query);
        node_child.find = find;
        node_child.html = html;
      }
      return node_child;
    };

    selector = function(query) {
      var node_parent;
      node_parent = window.document.querySelectorAll(query);
      node_parent.find = find;
      node_parent.html = html;
      return node_parent;
    };

    function Selector(options) {
      if (options == null) {
        options = {};
      }
      Selector.__super__.constructor.apply(this, arguments);

      /**
      * Возвращает NodeList
      * controller.$('sel'), controller.$('sel').find('sel2')
      * @return {Array||Object} NodeList Список элементов, NodeList.length.
       */
      this.$ = options.$ || selector;
    }

    return Selector;

  })(Loader);

  Compile = (function(_super) {
    __extends(Compile, _super);

    function Compile(options) {
      this.options = options != null ? options : {};
      Compile.__super__.constructor.apply(this, arguments);
      this.log.debug('init');
    }

    Compile.prototype.externalLayer = function(layer, cb) {
      if (layer.ext && !layer.extData) {
        this.log.debug("new external", layer.ext);
        return this.load(layer.ext, function(err, data) {
          var e, eList, i, layers, len, num, param, prop, _ref, _ref1;
          layer.extData = {};
          if (!err) {
            try {
              try {
                layer.extData = eval_("(" + data + ")");
              } catch (_error) {
                e = _error;
                layer.extData = eval_(data);
              }
              layers = this.layers;
              this.compile(layer.extData);
              layer.extData = this.layers;
              this.layers = layers;
              if (layer.config && layer.extData[0].config) {
                _ref = layer.extData[0].config;
                for (param in _ref) {
                  if (!__hasProp.call(_ref, param)) continue;
                  if (!layer.config[param]) {
                    layer.config[param] = layer.extData[0].config[param];
                  }
                }
              }
              _ref1 = layer.extData[0];
              for (prop in _ref1) {
                if (!__hasProp.call(_ref1, prop)) continue;
                if (!layer[prop]) {
                  layer[prop] = layer.extData[0][prop];
                }
              }
              eList = ["onload", "oncheck", "onshow"];
              i = 0;
              len = eList.length;
              while (i < len) {
                (function(prop) {
                  var value;
                  value = layer["_" + prop];
                  if (value) {
                    return layer[prop] = function(cb) {
                      try {
                        return value.call(layer, cb);
                      } catch (_error) {
                        e = _error;
                        this.log.error(prop + " " + e);
                        return cb();
                      }
                    };
                  }
                })(eList[i]);
                i++;
              }
              len = layer.extData.length;
              if (len) {
                num = this.layers.indexOf(layer);
                i = 1;
                while (i < len) {
                  num++;
                  this.layers.splice(num, 0, layer.extData[i]);
                  i++;
                }
              }
              return cb();
            } catch (_error) {
              e = _error;
              this.log.error("wrong ext", layer.ext);
              return cb();
            }
          } else {
            return cb();
          }
        });
      } else {
        return cb();
      }
    };

    Compile.prototype.compile = function(index, parentLayer) {
      var i, _i, _ref, _results;
      if (index == null) {
        index = this.options.index;
      }
      if (!parentLayer) {
        this.layers = [];
        parentLayer = this.layers;
        parentLayer.show = true;
        this.labels = {};
      }
      parentLayer.childLayers = [];
      if (index.splice) {
        _results = [];
        for (i = _i = 0, _ref = index.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
          _results.push(this.compileLayer(index[i], parentLayer));
        }
        return _results;
      } else {
        return this.compileLayer(index, parentLayer);
      }
    };


    /**
    * @param {Object} layer Слой для сборки
    * @param {Object} parentLayer Собранный родительский слой
    *
    * TODO параметры слоя не проверяются на правильность
     */

    Compile.prototype.compileLayer = function(layer, parentLayer) {
      var childLayer, i, layerLabels, newParentLayer, param, _i, _ref, _ref1, _ref2;
      newParentLayer = {
        query: layer.query,
        state: layer.state || parentLayer.state || '/',
        css: layer.css,
        json: layer.json,
        jsontpl: layer.jsontpl,
        tpl: layer.tpl,
        tpltpl: layer.tpltpl,
        label: layer.label,
        ext: layer.ext,
        config: layer.config || {},
        data: layer.data,
        tplString: layer.tplString,
        htmlString: layer.htmlString,
        childLayers: [],
        childQueries: {},
        childStates: {},
        oncheck: layer.oncheck || this.empty,
        onload: layer.onload || this.empty,
        onshow: layer.onshow || this.empty,
        parentLayer: parentLayer,
        node: null,
        regState: null,
        status: 'queue',
        id: 0
      };
      this.layers.push(newParentLayer);
      newParentLayer.id = layer.id || this.layers.length;
      if (layer.label) {
        layerLabels = layer.label.split(' ');
        for (i = _i = 0, _ref = layerLabels.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
          if (layerLabels[i]) {
            if (!this.labels[layerLabels[i]]) {
              this.labels[layerLabels[i]] = [];
            }
            this.labels[layerLabels[i]].push(newParentLayer);
          }
        }
      }
      parentLayer.childLayers.push(newParentLayer);
      if (layer.childLayers) {
        this.compile(layer.childLayers, newParentLayer);
      }
      if (layer.childQueries) {
        _ref1 = layer.childQueries;
        for (param in _ref1) {
          if (!__hasProp.call(_ref1, param)) continue;
          childLayer = _ref1[param];
          childLayer.query = param;
          newParentLayer.childQueries[param] = this.compile(childLayer, newParentLayer);
        }
      }
      if (layer.childStates) {
        _ref2 = layer.childStates;
        for (param in _ref2) {
          if (!__hasProp.call(_ref2, param)) continue;
          childLayer = _ref2[param];
          if ((param[0] === "^") || (param.slice(-1) === "$")) {
            childLayer.state = param;
          } else {
            childLayer.state = newParentLayer.state + param + "/";
          }
          newParentLayer.childStates[param] = this.compile(childLayer, newParentLayer);
        }
      }
      this.emit('compile', layer, parentLayer);
      if (!((newParentLayer.state[0] === "^") || (newParentLayer.state.slice(-1) === "$"))) {
        newParentLayer.state = '^' + newParentLayer.state + '.*$';
      }
      return newParentLayer;
    };

    return Compile;

  })(Selector);


  /**
  * Управление состоянием контроллера
   */

  State = (function(_super) {
    var updateRestrictions, _getListeners;

    __extends(State, _super);

    updateRestrictions = function(circle, listeners) {
      var restrictions;
      restrictions = '';
      if (++circle.count >= circle.limit) {
        restrictions += '\n' + circle.limit + ' limit';
      }
      if (circle.timeout < (Date.now() - circle.time)) {
        restrictions += '\n' + circle.timeout + ' timeout';
      }
      restrictions.trim();
      if (restrictions) {
        listeners.splice(0, listeners.length);
        circle.loading = 0;
      }
      return restrictions;
    };

    _getListeners = function(event, eventObject) {
      var listeners;
      if (eventObject.listeners) {
        listeners = eventObject.listeners(event);
      } else if (eventObject._events) {
        listeners = eventObject._events[event];
      }
      return listeners;
    };

    function State(options) {
      if (options == null) {
        options = {};
      }
      State.__super__.constructor.apply(this, arguments);
      this.tplRender = options.tplRender;

      /**
      * Запуск контроллера. Применить приложение в соответсвующие состояние.
      * Как только обрабатывается очередной слой, срабатывает событие layer.
      * Пробежка по слоям происходит в обратном порядке.
      * @param {String} state Состояние к которому нужно перейти, по-умолчанию '/'.
      * @param {Function} cb Callback-функция.
       */
      this.state = function(state, cb) {
        var listeners;
        if (state == null) {
          state = '/';
        }
        if (cb == null) {
          cb = this.empty;
        }
        if ((cb === this.empty) && (Object.prototype.toString.call(state) === '[object Function]')) {
          cb = state;
          state = '/';
        }
        if (this.state.circle && this.state.circle.run) {
          this.log.debug('state queue');
          this.state.circle.interrupt = true;
          this.once('queue', (function(_this) {
            return function() {
              return _this.state(state, cb);
            };
          })(this));
          listeners = _getListeners('queue', this);
          return listeners.splice(0, listeners.length - this.state.circle.queue);
        } else {
          if (!this.layers) {
            this.compile();
          }
          if (!this.layers.length) {
            this.log.info('empty layers');
          }
          return this.emit('start', state, cb);
        }
      };
      this.state.runs = 0;
      this.on('start', function(state, cb) {
        var i, listeners;
        listeners = _getListeners('queue', this) || [];
        this.log.debug('first circle, queue: ' + listeners.length);
        this.state.runs++;
        this.state.circle = {
          interrupt: false,
          count: 0,
          queries: {},
          loading: 0,
          state: (state ? state + '' : void 0),
          limit: (options.limit ? options.limit : 100),
          queue: (options.queue ? options.queue : 1),
          length: this.layers.length,
          cb: (cb ? cb : null),
          timeout: (options.timeout ? options.timeout : 10000),
          time: Date.now(),
          run: true
        };
        if (this.state.circle.state) {
          i = this.state.circle.length;
          while (--i >= 0) {
            this.layers[i].status = 'queue';
            this.layers[i].regState = this.state.circle.state.match(new RegExp(this.layers[i].state, "im"));
            if (this.layers[i].jsontpl) {
              this.layers[i].json = this.tplRender(this.layers[i].jsontpl, this.layers[i]);
            }
            if (this.layers[i].tpltpl) {
              this.layers[i].tpl = this.tplRender(this.layers[i].tpltpl, this.layers[i]);
            }
            delete this.layers[i].node;
          }
          return this.emit('circle');
        } else {
          this.log.warn('no set circle.state');
          return this.emit('end');
        }
      });
      this.on('circle', function() {
        var run;
        run = this.state.runs;
        return setTimeout((function(_this) {
          return function() {
            var i, listeners, restrictions;
            if (_this.state.circle.run && (run === _this.state.runs)) {
              i = _this.state.circle.length;
              while (--i >= 0) {
                if (_this.layers[i].status === 'queue') {
                  _this.state.circle.num = i;
                  _this.emit('layer', _this.layers[i], i);
                }
              }
              restrictions = updateRestrictions(_this.state.circle, _getListeners('circle', _this));
              if (restrictions) {
                _this.log.warn(restrictions);
              }
              listeners = _getListeners('circle', _this);
              if (listeners.length > 1) {
                return _this.emit('circle');
              } else if (!_this.state.circle.loading) {
                return _this.emit('end');
              }
            }
          };
        })(this), 0);
      });
      this.on('end', function() {
        this.log.debug('end, circle.count: ' + this.state.circle.count + ', number of runs: ' + this.state.runs);
        this.state.circle.run = false;
        this.state.circle.cb();
        return this.emit('queue');
      });
    }

    return State;

  })(Compile);

  Layer = (function(_super) {
    var checkLayer, disableLayer, displaceLayers, enableLayer, getLayerData, getLayerTemplate, loadLayer, _busyQueries, _stateOk;

    __extends(Layer, _super);

    _busyQueries = function(node, queries) {
      var i;
      i = queries.length;
      while (--i >= 0) {
        if (node.find(queries[queries[i]]).length) {
          return true;
        }
      }
      return false;
    };

    _stateOk = function(regState, state) {
      if (regState && regState[0]) {
        if (state === regState[0]) {
          return true;
        }
      }
      return false;
    };

    displaceLayers = function(layer) {
      var i, _results;
      layer.status = 'displace layers';
      i = this.state.circle.length;
      _results = [];
      while (--i >= 0) {
        if (this.layers[i].show) {
          if (layer.query === this.layers[i].query) {

          } else if (this.$(layer.query) === this.$(this.layers[i].query)) {
            _results.push(this.disableLayer(this.layers[i]));
          } else {
            if (this.$(layer.query).find(this.layers[i].query).length) {
              _results.push(this.disableLayer(this.layers[i]));
            } else {
              _results.push(void 0);
            }
          }
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    getLayerTemplate = function(layer, cb) {
      if (layer.tplString == null) {
        if (layer.tpl) {
          return this.load(layer.tpl, (function(_this) {
            return function(err, txt) {
              if (!err) {
                layer.tplString = txt;
              }
              return cb();
            };
          })(this));
        } else {
          return cb();
        }
      } else {
        return cb();
      }
    };

    getLayerData = function(layer, cb) {
      if (layer.data == null) {
        if (layer.json) {
          return this.load.json(layer.json, (function(_this) {
            return function(err, data) {
              if (!err) {
                layer.data = data;
              }
              return cb();
            };
          })(this));
        } else {
          return cb();
        }
      } else {
        return cb();
      }
    };

    loadLayer = function(layer, cb) {
      var counter;
      counter = 2;
      if (layer.htmlString) {
        return cb();
      } else if (layer.tpl || layer.tplString) {
        this.getLayerTemplate(layer, (function(_this) {
          return function() {
            if (--counter === 0) {
              return layer.onload(function() {
                layer.htmlString = _this.tplRender(layer.tplString, layer);
                return cb();
              });
            }
          };
        })(this));
        return this.getLayerData(layer, (function(_this) {
          return function() {
            if (--counter === 0) {
              return layer.onload(function() {
                layer.htmlString = _this.tplRender(layer.tplString, layer);
                return cb();
              });
            }
          };
        })(this));
      } else {
        return cb(1);
      }
    };


    /**
    * Проверяет слой, может ли он быть вставлен, возвращает в очередь при неудаче.
    *
    * Если **layer.status** равен shows и есть такой node, то это этот самый слой.
    * Если слой будет замещен где то в одном из тэгов, то он скрывается во всех.
    * Слой сначала скрывается, а потом на его пустое место вставляется другой.
    *
    * @param {Object} layer Описание слоя.
     */

    checkLayer = function(layer) {
      if (!layer.parentLayer.show) {
        return 'no parent';
      }
      if (this.state.circle.queries[layer.query]) {
        return 'query already exists ' + layer.query;
      }
      if (!layer.node) {
        layer.node = this.$(layer.query);
      }
      if (!layer.node.length) {
        return 'not inserted';
      }
      if (!layer.show) {
        if (_busyQueries(layer.node, Object.keys(this.state.circle.queries))) {
          return 'busy tags';
        }
      }
      if (!_stateOk(layer.regState, this.state.circle.state)) {
        return 'state mismatch';
      }
      return true;
    };

    enableLayer = function(layer) {
      layer.status = 'enable';
      this.state.circle.queries[layer.query] = layer;
      if (!layer.show) {
        this.displaceLayers(layer);
      }
      return this.once('circle', (function(_this) {
        return function() {
          if (_this.state.circle.interrupt) {
            return _this.log.debug("check interrupt 1");
          } else {
            _this.state.circle.loading++;
            return _this.externalLayer(layer, function() {
              return layer.oncheck(function() {
                layer.nowState = _this.state.circle.state;
                layer.status = 'insert';
                if (layer.show) {
                  return _this.state.circle.loading--;
                } else {
                  return _this.loadLayer(layer, function(err) {
                    if (err) {
                      _this.log.error("layer can not be inserted", layer.id);
                      layer.status = 'wrong insert';
                      return _this.state.circle.loading--;
                    } else {
                      if (_this.state.circle.interrupt) {
                        _this.log.debug("check interrupt 2");
                        return _this.state.circle.loading--;
                      } else {
                        _this.$(layer.query).html(layer.htmlString);
                        layer.lastState = _this.state.circle.state;
                        layer.show = true;
                        return layer.onshow(function() {
                          return _this.state.circle.loading--;
                        });
                      }
                    }
                  });
                }
              });
            });
          }
        };
      })(this));
    };

    disableLayer = function(layer) {
      var i;
      i = layer.childLayers.length;
      while (--i >= 0) {
        this.disableLayer(layer.childLayers[i]);
      }
      this.$(layer.query).html('');
      layer.show = false;
      layer.status = 'disable';
      return delete layer.node;
    };

    function Layer(options) {
      if (options == null) {
        options = {};
      }
      Layer.__super__.constructor.apply(this, arguments);
      this.getLayerTemplate = getLayerTemplate;
      this.getLayerData = getLayerData;
      this.loadLayer = loadLayer;
      this.displaceLayers = displaceLayers;
      this.checkLayer = checkLayer;
      this.enableLayer = enableLayer;
      this.disableLayer = disableLayer;
      this.on('layer', function(layer, num) {
        layer.check = this.checkLayer(layer);
        if (layer.check === true) {
          return this.enableLayer(layer);
        } else if (layer.show) {
          return this.disableLayer(layer);
        }
      });
    }

    return Layer;

  })(State);

  Nav = (function(_super) {

    /*
    * Возвращает отформатированный вариант состояния.
    *
    * Убираеются двойные слэши, добавляются слэш в начале и в конце.
    *
    * @param {String} pathname Строка с именем состояния.
    * @return {String} Отформатированный вариант состояния.
     */
    var getState, handler, ignore_protocols, parentA, setHrefs;

    __extends(Nav, _super);

    getState = function(pathname) {
      var now_location;
      if (!pathname) {
        pathname = "/";
      }
      now_location = decodeURIComponent(location.pathname);
      pathname = decodeURIComponent(pathname);
      pathname = pathname.replace(/#.+/, "");
      if (pathname[0] !== "/") {
        pathname = now_location + "/" + pathname;
      }
      pathname = pathname.replace(/\/{2,}/g, "/");
      return pathname;
    };

    parentA = function(targ) {
      if (targ.nodeName === "A") {
        return targ;
      } else {
        if ((!targ.parentNode) || (targ.parentNode === "HTML")) {
          return false;
        } else {
          return parentA(targ.parentNode);
        }
      }
    };

    ignore_protocols = ["^javascript:", "^mailto:", "^http://", "^https://", "^ftp://", "^//"];

    handler = function(e) {
      var href, i, ignore, targ;
      e = e || window.event;
      if (!e.metaKey && !e.shiftKey && !e.altKey && !e.ctrlKey) {
        targ = e.target || e.srcElement;
        targ = parentA(targ);
        if (targ) {
          href = targ.getAttribute("href");
          ignore = false;
          if (href) {
            if (!targ.getAttribute("target")) {
              i = ignore_protocols.length;
              while (--i >= 0) {
                if (RegExp(ignore_protocols[i], "gim").test(href)) {
                  ignore = true;
                }
              }
              if (!ignore) {
                try {
                  if (e.preventDefault) {
                    e.preventDefault();
                  } else {
                    e.returnValue = false;
                  }
                  this.state = this.getState(href);
                  return this.check((function(_this) {
                    return function(cb) {
                      _this.hash = targ.hash;
                      return cb();
                    };
                  })(this));
                } catch (_error) {
                  e = _error;
                  return window.location = href;
                }
              }
            }
          }
        }
      }
    };

    setHrefs = function() {
      var a, i, _results;
      a = this.$("a");
      i = a.length;
      _results = [];
      while (--i >= 0) {
        _results.push(a[i].onclick = handler);
      }
      return _results;
    };

    function Nav(options) {
      var nowState;
      if (options == null) {
        options = {};
      }
      Nav.__super__.constructor.apply(this, arguments);
      this.getState = getState;
      if (options.links == null) {
        options.links = true;
      }
      if (options.links) {
        setHrefs();
        this.on("start", function() {
          if (!this.noscroll) {
            window.scrollTo(0, 0);
          }
          return this.noscroll = false;
        });
        this.on("end", function() {
          return setHrefs();
        });
      }
      if (options.addressBar == null) {
        options.addressBar = true;
      }
      if (options.addressBar) {
        this.state = this.getState(location.pathname);
        this.log.debug("setting onpopstate event for back and forward buttons");
        setTimeout(((function(_this) {
          return function() {
            return window.onpopstate = function(e) {
              var nowState;
              _this.log.debug("onpopstate");
              if (!_this.hash) {
                nowState = _this.getState(location.pathname);
                _this.state = nowState;
                return _this.check(function(cb) {
                  _this.hash = location.hash;
                  return cb();
                });
              }
            };
          };
        })(this)), 1000);
        nowState = void 0;
        this.on("start", function() {
          nowState = this.getState(location.pathname);
          if (this.state !== nowState) {
            this.log.debug("push state " + this.state + " replace hash " + this.hash);
            return history.pushState(null, null, this.state);
          }
        });
        this.on("end", function() {
          if (this.state !== nowState) {
            if (this.hash) {
              location.replace(this.hash);
            }
          } else {
            this.log.debug("replace state " + this.state + " push hash " + this.hash);
            history.replaceState(null, null, this.state);
            if (this.hash) {
              location.href = this.hash;
            }
          }
          return this.hash = "";
        });
      }
    }

    return Nav;

  })(Layer);

  Cache = (function(_super) {
    var checkExists, empty2, getCache, head, oncheckTplOptions, reparseAll, reparseLayer;

    __extends(Cache, _super);

    empty2 = function() {};

    getCache = function() {
      var Controller, e, i, layer, _results;
      Controller = window.Controller;
      this.load.cache = Controller.server.cache;
      i = this.layers.length;
      _results = [];
      while (--i >= 0) {
        layer = this.layers[i];
        layer.show = Controller.server.visibleLayers[i];
        if (layer.show) {
          if (!layer.data && layer.json && this.load.cache.data[layer.json]) {
            layer.data = this.load.cache.data[layer.json];
          }
          if (!layer.htmlString && !layer.tplString && layer.tpl && this.load.cache.text[layer.tpl]) {
            layer.tplString = this.load.cache.text[layer.tpl];
          }
          layer.regState = this.state.circle.state.match(new RegExp(layer.state, "im"));
          try {
            _results.push(layer.onshow.bind(layer)(empty2));
          } catch (_error) {
            e = _error;
            _results.push(this.log.error("onshow() " + i + " " + e));
          }
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    reparseLayer = function(layer) {
      var i, _results;
      layer.show = false;
      if (layer.json) {
        layer.data = false;
      }
      if (layer.tpl) {
        layer.tplString = "";
        layer.htmlString = "";
      } else {
        if (layer.tplString) {
          layer.htmlString = "";
        }
      }
      if (layer.childLayers) {
        i = layer.childLayers.length;
        _results = [];
        while (--i >= 0) {
          _results.push(layer.childLayers[i].show = false);
        }
        return _results;
      }
    };

    reparseAll = function() {
      var i, _results;
      i = Cache.layers.length;
      _results = [];
      while (--i >= 0) {
        _results.push(Cache.reparseLayer(Cache.layers[i]));
      }
      return _results;
    };


    /*
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
     */

    checkExists = function(state) {
      var exist, i;
      if (!this.layers) {
        this.compile();
      }
      exist = void 0;
      i = this.layers.length;
      while (--i >= 0) {
        exist = new RegExp(this.layers[i].state).test(state);
        if (exist) {
          break;
        }
      }
      return exist;
    };

    oncheckTplOptions = function(layer) {
      if (!layer) {
        layer = this;
      }
      layer.tpl = this.tplRender(layer.tpl, layer);
      return layer.json = this.tplRender(layer.json, layer);
    };

    head = function(headObj) {
      this.on("start", (function(_this) {
        return function() {
          _this.meta = {};
          _this.meta.keywords = headObj.meta.keywords;
          _this.meta.description = headObj.meta.description;
          _this.statusCode = 200;
          return _this.title = false;
        };
      })(this));
      return this.on("end", (function(_this) {
        return function() {
          var $head, description, keywords, meta;
          if (!_this.title) {
            if (_this.statusCode === 404) {
              _this.title = headObj.title["404"];
            } else if (_this.state.circle.state === "/") {
              _this.title = headObj.title.main;
            } else {
              _this.title = _this.state.circle.state.replace(/\/+$/, "").replace(/^\/+/, "").split("/").reverse().join(" / ") + headObj.title.sub;
            }
            _this.lastStatusCode = _this.statusCode;
          }
          _this.document.title = _this.title;
          if (!_this.meta.keywords) {
            _this.meta.keywords = "";
          }
          if (!_this.meta.description) {
            _this.meta.description = "";
          }
          $head = _this.$("head");
          description = _this.$("meta[name=description]");
          keywords = _this.$("meta[name=keywords]");
          if (keywords && keywords.length !== 0) {
            $head.removeChild(keywords);
          }
          if (description && description.length !== 0) {
            $head.removeChild(description);
          }
          meta = _this.document.createElement("meta");
          meta.setAttribute("name", 'description');
          meta.setAttribute("content", _this.meta.description);
          $head.appendChild(meta);
          meta = _this.document.createElement("meta");
          meta.setAttribute("name", 'keywords');
          meta.setAttribute("content", _this.meta.keywords);
          return $head.appendChild(meta);
        };
      })(this));
    };

    function Cache(options) {
      if (options == null) {
        options = {};
      }
      Cache.__super__.constructor.apply(this, arguments);
      this.head = head;
      this.oncheckTplOptions = oncheckTplOptions;
      this.checkExists = checkExists;
      this.reparseAll = reparseAll;
      this.reparseLayer = reparseLayer;
      if (options.cache == null) {
        options.cache = true;
      }
      if (options.cache) {
        this.once("start", (function(_this) {
          return function() {
            var e;
            try {
              return getCache();
            } catch (_error) {
              e = _error;
              return _this.log.warn("fail cache");
            }
          };
        })(this));
      }
    }

    return Cache;

  })(Nav);

  LayerControl = (function(_super) {
    __extends(LayerControl, _super);

    function LayerControl(options) {
      if (options == null) {
        options = {};
      }
      LayerControl.__super__.constructor.apply(this, arguments);
    }

    return LayerControl;

  })(Cache);

  if (typeof window === "undefined" || window === null) {
    module.exports = LayerControl;
  } else {
    window.LayerControl = LayerControl;
  }

}).call(this);

/*
//# sourceMappingURL=layer-control.map
*/
