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
      state: (if layer.state then layer.state else '/')
      css: layer.css
      json: layer.json
      tpl: layer.tpl
      label: layer.label
      ext: layer.ext
      config: (if layer.config then layer.config else {})
      data: layer.data
      tplString: layer.tplString
      htmlString: layer.htmlString
      childLayers: []
      childQueries: []
      childStates: []
      oncheck: (if layer.oncheck then layer.oncheck else @empty)
      onload: (if layer.onload then layer.onload else @empty)
      onshow: (if layer.onshow then layer.onshow else @empty)
      parentLayer: parentLayer
      node: null
      regState: null
      status: 'queue'
      id: 0
    @layers.push newParentLayer
    newParentLayer.id = @layers.length
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
        childLayer.query = param
        newParentLayer.childQueries.push(@compile(childLayer, newParentLayer))
    if layer.childStates
      for own param, childLayer of layer.childStates
        childLayer.state = param
        newParentLayer.childStates.push(@compile(childLayer, newParentLayer))
    @emit 'compile', layer, parentLayer
    newParentLayer

#x>
if not window?
  module.exports = Compile
else
  window.Compile = Compile
#<x
