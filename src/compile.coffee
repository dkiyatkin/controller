#x>
unless window?
  Selector = require('../src/selector.coffee')
else
  Selector = window.Selector
#<x

class Compile extends Selector

  constructor: (@options={}) ->
    #Logger.call @, @options
    super
    @log.debug('init')

  # TODO not working
  externalLayer: (layer, cb) -> # Правило: Слои здесь точно скрыты
    if layer.ext and not layer.extData
      @log.debug "new external", layer.ext
      @load layer.ext, (err, data) ->
        layer.extData = {}
        unless err
          try
            try
              layer.extData = eval_("(" + data + ")")
            catch e
              layer.extData = eval_(data)
            layers = @layers
            @compile layer.extData
            layer.extData = @layers
            @layers = layers
            # обновить конфиг
            # TODO: это сделать рекурсивно и все вынести в функции
            if layer.config and layer.extData[0].config
              for own param of layer.extData[0].config
                layer.config[param] = layer.extData[0].config[param] unless layer.config[param]
            # переопределить слой
            for own prop of layer.extData[0]
              layer[prop] = layer.extData[0][prop] unless layer[prop]
            # обновить события
            eList = ["onload", "oncheck", "onshow"]
            i = 0
            len = eList.length
            while i < len
              ((prop) ->
                value = layer["_" + prop]
                if value
                  layer[prop] = (cb) ->
                    try
                      value.call layer, cb
                    catch e
                      @log.error prop + " " + e
                      cb()
              ) eList[i]
              i++
            # добавить новые
            len = layer.extData.length
            if len
              num = @layers.indexOf(layer)
              i = 1
              while i < len
                num++
                @layers.splice num, 0, layer.extData[i]
                i++
            cb()
          catch e
            @log.error "wrong ext", layer.ext
            cb()
        else cb()
    else cb()

  compile: (index=@options.index, parentLayer) ->
    if not parentLayer # recompile
      @layers = []
      parentLayer = @layers
      parentLayer.show = true # always showed
      @labels = {}
    parentLayer.childLayers = []
    if index.splice
      for i in [0...index.length]
        @compileLayer(index[i], parentLayer)
    else
      @compileLayer(index, parentLayer)

  ###*
  * @param {Object} layer Слой для сборки
  * @param {Object} parentLayer Собранный родительский слой
  *
  * TODO параметры слоя не проверяются на правильность
  ###
  compileLayer: (layer, parentLayer) ->
    newParentLayer =
      query: layer.query
      state: layer.state || parentLayer.state || '/'
      css: layer.css
      json: layer.json
      jsontpl: layer.jsontpl
      tpl: layer.tpl
      tpltpl: layer.tpltpl
      label: layer.label
      ext: layer.ext
      config: layer.config || {}
      data: layer.data
      tplString: layer.tplString
      htmlString: layer.htmlString
      childLayers: []
      childQueries: {}
      childStates: {}
      oncheck: layer.oncheck || @empty
      onload: layer.onload || @empty
      onshow: layer.onshow || @empty
      parentLayer: parentLayer
      node: null
      regState: null
      status: 'queue'
      id: 0
    @layers.push newParentLayer
    newParentLayer.id = layer.id || @layers.length
    if layer.label
      layerLabels = layer.label.split(' ')
      for i in [0...layerLabels.length]
        if layerLabels[i] # not empty
          @labels[layerLabels[i]] = [] if not @labels[layerLabels[i]]
          @labels[layerLabels[i]].push newParentLayer
    parentLayer.childLayers.push newParentLayer
    if layer.childLayers
      @compile layer.childLayers, newParentLayer
    if layer.childQueries
      for own param, childLayer of layer.childQueries
        childLayer.query = param # тэги не прибавляются
        newParentLayer.childQueries[param] = @compile(childLayer, newParentLayer)
    if layer.childStates
      for own param, childLayer of layer.childStates
        if (param[0] is "^") or (param.slice(-1) is "$") # если есть спец символы то наследование state не происходит
          childLayer.state = param
        else
          childLayer.state = newParentLayer.state + param + "/"
        newParentLayer.childStates[param] = @compile(childLayer, newParentLayer)
    @emit 'compile', layer, parentLayer
    if not ((newParentLayer.state[0] is "^") or (newParentLayer.state.slice(-1) is "$")) # если есть спец символы то state не изменяем
      newParentLayer.state = '^'+newParentLayer.state+'.*$'
    newParentLayer

#x>
if not window?
  module.exports = Compile
else
  window.Compile = Compile
#<x
