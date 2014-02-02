#x>
if not window?
  fs = require('fs')
  Layer = require('../src/layer.coffee')
  cheerio = require('cheerio')
  load = require('../lib/load.coffee')
  $ = cheerio.load(fs.readFileSync('./test/index.html'))
  Mustache = require('mustache')
else
  window.exports = {}
  window.layer = exports
  Layer = window.Layer
  Mustache = window.Mustache
#<x

exports.compileQuery = (test) ->
  test.expect 5
  controller = new Layer({
    $: $ || false,
    index: {
      query: "wrong query"
      oncheck: (cb) ->
        test.ok(false, 'no check')
        cb()
    }
  })
  controller.state(->
    test.strictEqual controller.layers[0].query, "wrong query", "query"
    test.strictEqual controller.layers[0].check, "not inserted", "insert"
    test.strictEqual controller.layers[0].status, "queue", "queue"
    test.strictEqual controller.layers[0].state, "^/.*$", "state"
    test.strictEqual controller.layers[0].regState[0], "/", "regState"
    test.done()
  )

exports.compileLayerListeners = (test) ->
  test.expect 2
  controller = new Layer(
    $: $ || false,
    logger: 'DEBUG',
    index:
      query: "wrong query"
      onshow: (cb) -> # не запустится
        test.ok true, "onshow"
        cb()
  )
  controller.state()

  testfunc = ->
    test.ok true, "onchecked"

  controller.layers[0].oncheck(testfunc)
  controller.layers[0].onshow(test.done)

exports.compileTestStates = (test) ->
  controller = new Layer(
    tplRender: Mustache.render,
    logger: 'DEBUG',
    $: $ || false,
    index:
      tpl: "path/to/tpl1"
      query: "#base_html"
      childStates:
        "Страница": # здесь будет добавлен слэш
          tpl: "path/to/tpl2"
          query: "#base_text"
  )
  controller.state()
  test.expect 3
  test.strictEqual controller.layers[1].state, "^/Страница/.*$", "state"
  test.strictEqual controller.layers[0], controller.layers[1].parentLayer, "parent"
  test.strictEqual controller.layers[0].childStates['Страница'], controller.layers[1], "states"
  test.done()

exports.compileTestTags = (test) ->
  controller = new Layer(
    logger: 'DEBUG',
    $: $ || false,
    index:
      tpl: "path/to/tpl1"
      state: "/Главная/" # здесь никто сам не добавит последний слэш
      query: "#base_html"
      childQueries:
        "#base_text":
          tpl: "path/to/tpl2"
  )
  controller.state()
  test.expect 3
  test.strictEqual controller.layers[0].state, controller.layers[1].state, "state"
  test.strictEqual controller.layers[0], controller.layers[1].parentLayer, "parent"
  test.strictEqual controller.layers[0].childQueries[controller.layers[1].query], controller.layers[1], "queries"
  test.done()

exports.compileTestDeep = (test) ->
  controller = new Layer(
    logger: 'DEBUG',
    $: $ || false,
    index:
      tpl: "path/to/tpl1"
      state: "/Главная/" # здесь никто сам не добавит последний слэш
      query: "#base_html"
      childQueries:
        "#base_text":
          tpl: "path/to/tpl2"
      childStates:
        "Страница": # здесь будет добавлен слэш
          tpl: "path/to/tpl3"
          query: "#base_text"
          childQueries:
            "#base_text":
              tpl: "path/to/tpl4"
          childStates:
            'Страница2':
              tpl: "path/to/tpl5"
              query: "#base_text"
            'Страница3':
              tpl: "path/to/tpl6"
              query: "#base_text"
  )
  controller.state()
  i = controller.layers.length
  test.expect 6
  while --i >= 0
    test.strictEqual 'path/to/tpl'+(controller.layers[i].id), controller.layers[i].tpl, "deep and order"
  test.done()

exports.checkLayer = (test) ->
  controller = new Layer(
    logger: 'DEBUG',
    $: $ || false,
    index:
      htmlString: "<div id=\"base_text\"></div>"
      query: "#base_html"
      childStates:
        "Страница": # здесь будет добавлен слэш
          tpl: "path/to/tpl2"
          query: "#noid"
  )
  controller.removeAllListeners "layer"
  controller.on 'layer', (layer, num) ->
    layer.status = 'loading'
    controller.state.circle.loading++
    setTimeout(->
      layer.status = 'show'
      controller.state.circle.loading--
      controller.emit 'circle'
    , 0)
  controller.state() # собрать layers
  test.expect 6
  controller.on "end", ->
    test.done()
  test.equal controller.layers[0].state, "^/.*$", "state1"
  test.equal controller.layers[1].state, "^/Страница/.*$", "state2"
  test.ok controller.checkLayer(controller.layers[0]), "status queue"
  test.strictEqual controller.checkLayer(controller.layers[0]), true, 'true'
  test.strictEqual controller.checkLayer(controller.layers[1]), 'no parent', 'no parent'
  controller.layers[0].show = true
  test.strictEqual controller.checkLayer(controller.layers[1]), "not inserted", 'not inserted'

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
