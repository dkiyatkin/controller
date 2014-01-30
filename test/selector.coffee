fs = require 'fs'
Selector = require('../src/selector.coffee')
jsdom = require("jsdom").jsdom

# Стандартный селектор selector.$
exports.setSelector = (test) ->
  setSelector = (selector) ->
    test.strictEqual selector.$('html body').find('#test_controller')[0].innerHTML , 'hello world', "selector"
    test.done()
  jsdom.env
    html: fs.readFileSync(__dirname + '/index.html', 'utf-8')
    features:
      QuerySelector: true
    done: (err, window) ->
      selector = new Selector({document: window.document})
      setSelector(selector)
