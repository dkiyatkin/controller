#x>
if not window?
  State = require('../src/state.coffee')
else
  window.exports = {}
  window.state = exports
  State = window.State
#<x

exports.simpleState = (test) ->
  test.expect 1
  state = new State({logger: 'DEBUG', index: {}})
  state.log.logger = 'WARNING'
  state.removeAllListeners('start')
  state.on 'start', (state, cb) ->
    cb -> test.ok true, "simple"
  state.state '/', (cb) -> # нужен ли здесь вообще аргумент в калбэке
    cb()
    test.done()

exports.noStateCheckEnd = (test) ->
  test.expect 3
  state = new State({logger: 'DEBUG', quiet: true, index: {}})
  state.state false, () ->
    test.ok(state.log.history.indexOf('no set circle.state') isnt -1, 'no set state')
  state2 = new State({logger: 'DEBUG', index: {}})
  state2.removeAllListeners('layer')
  state2.on 'layer', (layer, num) ->
    test.ok(true, 'one layer')
  state2.state () ->
    test.ok(state2.log.history.indexOf('no set circle.state') is -1)
    test.done()

# Проверка блокирования смены состояния, она должна сработать на первой и последней попытке
exports.manyState = (test) ->
  state = new State({logger: 'WARNING', index: {}})
  state.removeAllListeners('layer')
  state.on 'layer', (layer, num) ->
    layer.status = 'loading'
    state.state.circle.loading++
    setTimeout(->
      layer.status = 'show'
      state.state.circle.loading--
      state.emit 'circle'
    , 0)
  a = 0
  test.expect 3
  state.state 1, () ->
    test.ok true, "queue"
    a++
  state.state 2, () ->
    test.ok false, "queue"
    a++
  state.state 3, () ->
    test.ok false, "queue"
    a++
  state.state 4, () ->
    test.ok false, "queue"
    a++
  state.state 5, () ->
    a++
    test.strictEqual a, 2, "last"
    test.strictEqual state.state.runs, 2, "runs"
    test.done()
