#x>
if not window?
  Layer = require('../src/layer.coffee')
else
  window.exports = {}
  window.layer = exports
  Layer = window.Layer
#<x

exports.query = (test) ->
  test.expect 1
  controller = new Layer({
      index: {
        query: "#base_html"
      }
  })
  controller.state()
  test.strictEqual controller.layers[0].query, "#base_html", "query"
  test.done()

exports.layerListeners = (test) ->
  test.expect 2
  controller = new Infra({
    logger: 'DEBUG',
    index: {
      tag: "#base_html"
      onshow: (cb) ->
        test.ok true, "onshow"
        cb()
    }
  })
  controller.state()
  testfunc = ->
    test.ok true, "onchecked"

  infra.layers[0].oncheck testfunc
  infra.layers[0].onshow test.done

###
exports.layer = (test) ->
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
  #controller.state('/')
  #controller.state('/2')
  #controller.state('/about')
  #controller.state('/')
  #controller.state('/about')
  #controller.state('/2')
  controller.state()
  controller.cycle=333
  console.log controller.cycle
  controller2.state()
  console.log controller2.cycle
  console.log controller.cycle
  #test.expect 1
  #test.equal controller.layers.length, 8, 'length'
  test.done()
###
