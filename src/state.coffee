#x>
unless window?
  Compile = require('../src/compile.coffee')
else
  Compile = window.Compile
#<x

###*
* Управление состоянием контроллера
###
class State extends Compile

  updateRestrictions = (circle, listeners) ->
    restrictions = ''
    if ++circle.count >= circle.limit
      restrictions += '\n' + circle.limit + ' limit'
    if circle.timeout < (Date.now()-circle.time)
      restrictions += '\n' + circle.timeout + ' timeout'
    restrictions.trim()
    if restrictions
      listeners.splice(0, listeners.length)
      circle.loading = 0
    restrictions

  _getListeners = (event, eventObject) ->
    if eventObject.listeners
      listeners = eventObject.listeners event
    else if eventObject._events
      listeners = eventObject._events[event]
    listeners

  constructor: (options={}) ->
    super
    @tplRender = options.tplRender

    ###*
    * Запуск контроллера. Применить приложение в соответсвующие состояние.
    * Как только обрабатывается очередной слой, срабатывает событие layer.
    * Пробежка по слоям происходит в обратном порядке.
    * @param {String} state Состояние к которому нужно перейти, по-умолчанию '/'.
    * @param {Function} cb Callback-функция.
    ###
    @state = (state='/', cb=@empty) ->
      if (cb is @empty) and (Object::toString.call(state) is '[object Function]')
        cb = state
        state='/'
      unless @state.circle # не запущен
        @compile() unless @layers
        @log.info('empty layers') unless @layers.length
        @emit 'start', state, cb
      else # уже запущен, мутим очередь
        @log.debug('state queue')
        @state.circle.interrupt = true
        @once 'queue', =>
          @state state, cb
        listeners = _getListeners('queue', @)
        listeners.splice 0, listeners.length - @state.circle.queue

    @state.runs = 0 # количество запусков

    @on 'start', (state, cb) ->
      listeners = _getListeners('queue', @)||[]
      @log.debug('first circle, queue: ' + listeners.length)
      @state.runs++
      @state.circle =
        interrupt: false # прерывание
        count: 0 # счетчик, сбрасывается в каждом круге
        queries: {} # забитые запросы, за определенными слоями
        loading: 0 # ассинхронная загрузка, если 0 то выход из цикла
        state: (if state then state+'')
        limit: (if options.limit then options.limit else 100) # количество возможных кругов чека
        queue: (if options.queue then options.queue else 1) # насколько большая может быть очередь для чеков
        length: @layers.length
        cb: (if cb then cb else null) # callback функция @state
        #@delay = 1 # размер паузы между циклами в милисекундах
        timeout: (if options.timeout then options.timeout else 10000) # сколько может длиться
        time: Date.now() # время начала
      if @state.circle.state # совпавшее состояние слоя, может быть не полностью равным @state.circle.state
        i = @state.circle.length
        while --i >= 0 # firstCircle
          @layers[i].status = 'queue'
          @layers[i].regState = @state.circle.state.match(new RegExp(@layers[i].state, "im"))
          @layers[i].json = @tplRender(@layers[i].jsontpl, @layers[i]) if @layers[i].jsontpl
          @layers[i].tpl = @tplRender(@layers[i].tpltpl, @layers[i]) if @layers[i].tpltpl
          delete @layers[i].node
        @emit 'circle'
      else
        @log.warn('no set circle.state')
        @emit 'end'

    # Пробежаться по слоям, запустить ассинхронные изменения и занять ихний результат, назначить ожидание circle.loading++
    # по завершению изменения если есть loading, то применить его и запускать цикл опять emit('circle')
    # цикл работает сверяясь с уже занятыми результатами
    # показанные слои заходят, тк для них тоже нужно забить места
    # Скрыть и убрать из цикла те слои, которые будут замещены вставленным слоем
    # Вставиться, запустить обработчики
    # Если слой виден, и не прошел проверки, но ни один другой слой его не скрыл, слой все равно должен скрыться
    @on 'circle', () ->
      i = @state.circle.length
      while --i >= 0
        if @layers[i].status is 'queue'
          @state.circle.num = i
          @emit 'layer', @layers[i], i
      restrictions = updateRestrictions(@state.circle, _getListeners('circle', @))
      log.warn(restrictions) if restrictions
      listeners = _getListeners('circle', @)
      if listeners.length > 1 # появились дополнительные подписчики, только once для пропуска круга
        @emit 'circle'
      else if not @state.circle.loading
        @emit 'end'

    @on 'end', ->
      @log.debug('end, circle.count: ' + @state.circle.count + ', number of runs: ' + @state.runs)
      @state.circle.cb()
      delete @state.circle
      @emit 'queue'

#x>
if not window?
  module.exports = State
else
  window.State = State
#<x
