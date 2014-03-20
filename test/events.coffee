if not window?
  Module = require '../src/common.coffee'
else
  window.exports = {}
  window.events = exports
  Module = window.Module

# События

exports.testEventsOrder = (test) ->
  controller = new Module()
  a = 0
  controller.once 'test', ->
    a++
    test.strictEqual(a, 1, '1')
  controller.once 'test', ->
    a++
    test.strictEqual(a, 2, '2')
  controller.once 'test', ->
    a++
    test.strictEqual(a, 3, '3')
  controller.emit('test')
  test.done()

testOnEvent = (test, Module, cb) ->
  controller = new Module()
  controller.on "test_on_event", (param) ->
    test.ok param, "send params"
  controller.emit "test_on_event", true
  controller.emit "test_on_event", true
  test.strictEqual controller.listeners("test_on_event").length, 1, "length on listeners"
  cb()

exports.testOnEvent = (test) ->
  test.expect 3
  testOnEvent test, Module, ->
    test.done()

exports.testOnceEventAndListeners = (test) ->
  controller = new Module()
  test.expect 4
  listeners = controller.listeners("test_once_event")
  test.strictEqual listeners.length, 0, "length once listeners"
  controller.once "test_once_event", (param) ->
    test.ok param, "bad send params"
  test.strictEqual listeners.length, 1, "length once listeners"
  controller.emit "test_once_event", true
  controller.emit "test_once_event", false
  test.strictEqual listeners.length, 0, "length once listeners"
  test.done()

exports.testOnceEventAndListeners2 = (test) ->
  controller = new Module()
  listeners = controller.listeners("test_once_event2")
  test.expect 2
  controller.once "test_once_event2", ->
    test.equal listeners.length, 0, "length once listeners0"
    test.done()
  test.equal listeners.length, 1, "length once listeners1"
  controller.emit "test_once_event2"
