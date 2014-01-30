#x>
if not window?
  Layers = require('../src/layers.coffee')
else
  window.exports = {}
  window.layers = exports
  Layers = window.Layers
#<x

exports.compile = (test) ->
  index = {
    label: 'main',
    childLayers: [
      {
        label: 'one',
        childLayers: [
          {
            label: 'three'
          }
        ]
      }, {
        label: 'two'
      }
    ]
  }

  controller = new Layers(
    logger:'DEBUG'
    quiet: true
  )
  controller.compile(index)
  test.expect 9
  test.equal controller.layers.length, 4, 'length'
  test.equal controller.layers[0].label, 'main', 'main'
  test.equal controller.layers[1].label, 'one', 'one'
  test.equal controller.layers[2].label, 'three', 'three'
  test.equal controller.layers[3].label, 'two', 'two'
  test.equal controller.layers[0].parentLayer, controller.layers, 'parentLayer'
  test.equal controller.layers[3].parentLayer, controller.layers[0], 'parentLayer2'
  test.ok controller.layers[1] in controller.layers[0].childLayers, 'childLayers'
  test.ok controller.labels['two'][0] in controller.layers[0].childLayers, 'childLayers2 and myApp.labels'
  test.done()

exports.compile2 = (test) ->
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
          'page2': {
            query: 'page'
            label: 'page2'
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
  controller = new Layers(
    logger:'DEBUG'
    quiet: true
  )
  controller2 = new Layers(
    logger:'DEBUG'
    quiet: true
  )
  cmpl = 0
  controller.on 'compile', (layer, parentLayer) ->
    cmpl++
  controller.compile(index)
  controller2.compile(index)
  controller.labels['main'][0].test = 1
  test.expect 7
  test.equal controller.layers.length, cmpl, 'event compile layer'
  test.equal controller.labels['main'][0].state, '/', 'state'
  test.equal controller.labels['page2'][0].state, 'page2', 'state 2'
  test.equal controller.labels['main'][0].childQueries[0], controller.labels['page'][0], 'eq childQueries[i] and labels[j]'
  test.notEqual controller.labels['main'][0], controller2.labels['main'][0], 'not eq layers for different controllers'
  test.ok controller.labels['main'][0].test, 'not eq layers for different controllers 1'
  test.ok !controller2.labels['main'][0].test, 'not eq layers for different controllers 2'
  test.done()
