#x>
unless window?
  State = require('../src/state.coffee')
else
  State = window.State
#<x

class Layer extends State

  _busyQueries = (node, queries) ->
    i = queries.length
    while --i >= 0
      if node.find(queries[queries[i]]).length
        return true
    return false

  # state устраивает или нет
  _stateOk = (regState, state) ->
    if regState and regState[0]
      if state is regState[0]
        return true
    return false

  # Скрыть слои которые замещает переданный слой, убрать их из цикла
  # Правила:
  # переданный слой обязательно будет показан, и не может быть скрыт в этом state()
  # в показанном слое не могут быть дочерние слои
  displaceLayers = (layer) ->
    layer.status = 'displace layers'
    i = @state.circle.length
    while --i >= 0
      if @layers[i].show
        if layer.query is @layers[i].query
        else if @$(layer.query) is @$(@layers[i].query) # wtf? TODO
          @disableLayer @layers[i]
        else
          if @$(layer.query).find(@layers[i].query).length
            @disableLayer @layers[i]

  # получить шаблон слоя
  getLayerTemplate = (layer, cb) ->
    unless layer.tplString? # данные не загружены
      if layer.tpl # если есть путь для загрузки
        @load layer.tpl, (err, txt) =>
          layer.tplString = txt unless err
          cb()
      else cb()
    else cb()

  # получить данные слоя
  getLayerData = (layer, cb) ->
    unless layer.data? # данные не загружены
      if layer.json # если есть путь для загрузки
        @load.json layer.json, (err, data) =>
          layer.data = data unless err
          cb()
      else cb()
    else cb()

  # приготовить слой к вставке, получить нужные данные слоя
  loadLayer = (layer, cb) -> # Правило: Слои здесь точно скрыты
    counter = 2
    if layer.htmlString
      cb()
    else if layer.tpl or layer.tplString
      @getLayerTemplate layer, =>
        if --counter is 0
          layer.onload => # все данные загружены
            layer.htmlString = @tplRender layer.tplString, layer
            cb()
      @getLayerData layer, =>
        if --counter is 0
          layer.onload => # все данные загружены
            layer.htmlString = @tplRender layer.tplString, layer
            cb()
    else cb 1

  ###*
  * Проверяет слой, может ли он быть вставлен, возвращает в очередь при неудаче.
  *
  * Если **layer.status** равен shows и есть такой node, то это этот самый слой.
  * Если слой будет замещен где то в одном из тэгов, то он скрывается во всех.
  * Слой сначала скрывается, а потом на его пустое место вставляется другой.
  *
  * @param {Object} layer Описание слоя.
  ###
  checkLayer = (layer) ->
    if not layer.parentLayer.show
      return 'no parent'
    if @state.circle.queries[layer.query] # query не наследуются в отличии от state
      return 'query already exists ' + layer.query
    layer.node = @$(layer.query) unless layer.node
    if not layer.node.length # вставляется ли слой
      return 'not inserted'
    if not layer.show
      if _busyQueries(layer.node, Object.keys(@state.circle.queries)) # нет ли в запросе слоя других занятых, этот слой должен быть скрыт
        return 'busy tags'
    if not _stateOk(layer.regState, @state.circle.state) # подходит ли state
      return 'state mismatch'
    return true

  # Скрыть и убрать из цикла те слои, которые будут замещены вставленным слоем
  enableLayer = (layer) ->
    layer.status = 'enable'
    @state.circle.queries[layer.query] = layer # Изменить условия проверок для других слоев, занимаем тэги
    @displaceLayers(layer) unless layer.show # этот слой может быть показан с прошлого @state
    @once 'circle', => # пропустить круг
      if @state.circle.interrupt
        @log.debug "check interrupt 1"
        #@emit 'circle'
      else
        @state.circle.loading++
        @externalLayer layer, =>
          layer.oncheck => # сработает у всех слоев которые должны быть показаны
            layer.nowState = @state.circle.state
            layer.status = 'insert'
            if layer.show
              @state.circle.loading--
              #@emit 'circle'
            else
              @loadLayer layer, (err) =>
                if err
                  @log.error "layer can not be inserted", layer.id
                  layer.status = 'wrong insert'
                  @state.circle.loading--
                  #@emit 'circle'
                else
                  if @state.circle.interrupt
                    @log.debug "check interrupt 2"
                    @state.circle.loading--
                    #@emit 'circle'
                  else
                    @$(layer.query).html(layer.htmlString)
                    layer.lastState = @state.circle.state
                    layer.show = true
                    layer.onshow =>
                      @state.circle.loading--
                      #@emit 'circle'

  # скрыть слой и всех его потомков
  disableLayer = (layer) ->
    i = layer.childLayers.length # скрыть детей
    while --i >= 0
      @disableLayer layer.childLayers[i]
    @$(layer.query).html('') # скрыть слой
    layer.show = false # отметка что слой скрыт
    layer.status = 'disable'
    delete layer.node

  constructor: (options={}) ->
    super
    @getLayerTemplate = getLayerTemplate
    @getLayerData = getLayerData
    @loadLayer = loadLayer
    @displaceLayers = displaceLayers
    @checkLayer = checkLayer
    @enableLayer = enableLayer
    @disableLayer = disableLayer
    @on 'layer', (layer, num) -> # Пойти на проверки, забить результаты, запустить изменения (загрузка, показ, скрытие)
      layer.check = @checkLayer(layer) # проверяет на ошибки и возвращает true либо текст ошибки
      if layer.check is true # показанные слои заходят, так как для них тоже нужно забить места
        @enableLayer(layer) # вставиться, запустить обработчики
      else if layer.show # если слой виден, и не прошел проверки, но ни один другой слой его не скрыл, слой все равно должен скрыться
        @disableLayer(layer)

#x>
if not window?
  module.exports = Layer
else
  window.Layer = Layer
#<x
