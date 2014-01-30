#x>
unless window?
  Layers = require('../src/layers.coffee')
else
  Layers = window.Layers
#<x

###*
* Управление состоянием контроллера
###
class State extends Layers

  constructor: (@options={}) ->
    super
    @runs = 0 # количество запусков

    @on 'start', (state, cb) ->
      @log.debug('first circle, queue: ' + @listeners('queue').length)
      @runs++
      @circle =
        interrupt: false # прерывание
        count: 0 # счетчик, сбрасывается в каждом круге
        occupied: {} # забитые тэги, за определенными слоями
        loading: 0 # ассинхронная загрузка
        state: state
        limit: (if @options.limit then @options.limit else 100) # количество возможных кругов чека
        queue: (if @options.queue then @options.queue else 1) # насколько большая может быть очередь для чеков
        length: @layers.length
        cb: (if cb then cb else null) # callback функция @check
        timeout: (if @options.timeout then @options.timeout else 10000) # сколько может длиться
        time: Date.now() # время начала
      if @circle.state # совпавшее состояние слоя, может быть не полностью равным @circle.state
        i = @circle.length
        while --i >= 0
          @layers[i].status = 'queue'
        @emit 'circle'
      else
        @log.warn('no set circle.state')
        @emit 'end'

    # Пробежаться по слоям, запустить ассинхронные изменения и занять ихний результат, назначить ожидание circle.loading++
    # по завершению изменения если есть loading, то применить его и запускать цикл опять emit('circle')
    # цикл работает сверяясь с уже занятыми результатами
    @on 'circle', () =>
      i = @circle.length
      while --i >= 0
        if @layers[i].status is 'queue'
          @circle.num = i
          if @checkLayer(layer) # показанные слои заходят, тк для них тоже нужно забить места # Скрыть и убрать из цикла те слои, которые будут замещены вставленным слоем
            @apply(layer) # Вставиться, запустить обработчики
          else if layer.node # Если слой виден, и не прошел проверки, но ни один другой слой его не скрыл, слой все равно должен скрыться
            @hide(layer)
      listeners = @listeners('circle')
      if ++@circle.count >= @circle.limit
        @log.warn @circle.limit + ' limit'
        listeners.splice(0, listeners.length)
        @circle.loading = 0
      if @circle.timeout < (Date.now()-@circle.time)
        @log.warn @circle.timeout + ' timeout'
        listeners.splice(0, listeners.length)
        @circle.loading = 0
      if listeners.length > 1 # появились дополнительные подписчики
        @emit 'circle'
      else if not @circle.loading
        @emit 'end'

    @on 'end', =>
      @log.debug('end, circle.count: ' + @circle.count + ', number of runs: ' + @runs)
      @circle.cb => delete @circle
      @emit 'queue'

  ###
  * Проверяет слой, может ли он быть вставлен, возвращает в очередь при неудаче.
  * Если **layer.status** равен shows и есть такой node, то это этот самый слой.
  * Если слой будет замещен где то в одном из тэгов, то он скрывается во всех.
  * Слой сначала скрывается, а потом на его пустое место вставляется другой.
  * @param {Object} layer Описание слоя.
  ###
  checkLayer: (layer) ->
    true

  hide: (layer) ->
    layer.status = 'hide'
    layer.node = null
    if layer.childLayers # скрыть детей
      i = layer.childLayers.length
      while --i >= 0
        @hide layer.childLayers[i]

  apply: (layer) ->
    layer.status = 'show'
    layer.node = true
    @emit 'circle'
    ###
        external layer, =>
          layer.oncheck =>
            load layer, =>
              layer.onload =>
                show layer, =>
                  layer.onshow =>
                    if UPDATE cycle()
                    else cb()
    ###

  ###*
  * Запуск контроллера. Применить состояние.
  * Как только обрабатывается очередной слой, срабатывает событие layer. Пробежка по слоям происходит в обратном порядке.
  * @param {String} state Состояние к которому нужно перейти, по-умолчанию '/'.
  * @param {Function} cb Callback-функция.
  ###
  state: (state='/', cb) ->
    if not cb and Object::toString.call(state) is '[object Function]'
      cb = state
      state='/'
    if @circle # уже запущен, мутим очередь
      @log.debug('state queue')
      @circle.interrupt = true
      @once 'queue', =>
        @state state, cb
      listeners = @listeners 'queue'
      listeners.splice 0, listeners.length - @circle.queue
    else # не запущен
      @compile() unless @layers
      @log.info('empty layers') unless @layers.length
      @emit 'start', state, cb

#x>
if not window?
  module.exports = State
else
  window.State = State
#<x
