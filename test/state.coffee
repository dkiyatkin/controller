#x>
if not window?
  State = require('../src/state.coffee')
else
  window.exports = {}
  window.state = exports
  State = window.State
#<x

exports.simpleState = (test) ->
  state = new State({logger: 'DEBUG', loader: false, index: {}})
  state.log.logger = 'WARNING'
  state.state (cb) ->
    cb()
    test.ok true, "simple"
    test.done()

# Проверка блокирования чека, сработает первый и последний
exports.manyState = (test) ->
  state = new State({logger: 'DEBUG', loader: false, index: {}, delay: 5000})
  state.log.logger = 'WARNING'
  state.state = '/'
  a = 0
  test.expect 2
  state.state (cb) ->
    test.ok true, "queue"
    a++
    cb()
  state.state (cb) ->
    test.ok false, "queue"
    a++
    cb()
  state.state (cb) ->
    test.ok false, "queue"
    a++
    cb()
  state.state (cb) ->
    test.ok false, "queue"
    a++
    cb()
  state.state (cb) ->
    a++
    test.strictEqual a, 2, "last"
    cb()
    test.done()

exports.state = (test) ->
  index = {
    query: 'body',
    label: 'body',
    childLayers: [
      {
        query: 'header',
        label: 'header',
        childQueries: {
          'nav': {
            label: 'header_nav',
          }
        }
      }, {
        query: 'main',
        label: 'main',
        childQueries: {
          'page': {
            state: '/',
            label: 'page'
          }
        },
        childStates: {
          '\d+': {
            query: 'page',
            label: 'page2'
          },
          'about': {
            query: 'page',
            label: 'about'
          }
        }
      }, {
        query: 'footer',
        label: 'footer',
        childQueries: {
          'nav': {
            label: 'footer_nav',
          }
        }
      }
    ]
  }
  controller = new State(
    logger:'DEBUG'
    quiet: false
    index: index
  )
  controller2 = new State(
    logger:'DEBUG'
    quiet: false
    index: index
  )
  ###
  controller.state('/')
  controller.state('/2')
  controller.state('/about')
  controller.state('/')
  controller.state('/about')
  controller.state('/2')
  ###
  controller.state()
  controller.cycle=333
  console.log controller.cycle
  controller2.state()
  console.log controller2.cycle
  console.log controller.cycle
  #test.expect 1
  #test.equal controller.layers.length, 8, 'length'
  test.done()
