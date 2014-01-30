#x>
unless window?
  Loader = require('../src/loader.coffee')
else
  Loader = window.Loader
#<x

class Layers extends Loader

  constructor: (options={}) ->
    #Logger.call @, @options
    super
    @log.debug('init')

  compile: (index=@options.index, parentLayer) ->
    if not parentLayer # recompile
      @layers = []
      parentLayer = @layers
      @labels = {}
    parentLayer.childLayers = []
    if index.splice
      for i in [0...index.length]
        @compileLayer(index[i], parentLayer)
    else
      @compileLayer(index, parentLayer)

  empty = (cb) -> cb()
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
      oncheck: (if layer.oncheck then layer.oncheck else empty)
      onload: (if layer.onload then layer.onload else empty)
      onshow: (if layer.onshow then layer.onshow else empty)
      parentLayer: parentLayer
      node: null
      regState: null
      status: 'queue'
    @layers.push newParentLayer
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
  module.exports = Layers
else
  window.Layers = Layers
#<x
