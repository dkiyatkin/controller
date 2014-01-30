if not window?
  Module = require '../src/common.coffee'
else
  window.exports = {}
  window.events = exports
  Module = window.Module

# События

testOnEvent = (test, Module, cb) ->
  infra = new Module()
  infra.on "test_on_event", (param) ->
    test.ok param, "send params"
  infra.emit "test_on_event", true
  infra.emit "test_on_event", true
  test.strictEqual infra.getListeners("test_on_event").length, 1, "length on listeners"
  cb()

exports.testOnEvent = (test) ->
  test.expect 3
  testOnEvent test, Module, ->
    test.done()

exports.testOnceEventAndListeners = (test) ->
  infra = new Module()
  test.expect 4
  listeners = infra.getListeners("test_once_event")
  test.strictEqual listeners.length, 0, "length once listeners"
  infra.once "test_once_event", (param) ->
    test.ok param, "bad send params"
  test.strictEqual listeners.length, 1, "length once listeners"
  infra.emit "test_once_event", true
  infra.emit "test_once_event", false
  test.strictEqual listeners.length, 0, "length once listeners"
  test.done()

exports.testOnceEventAndListeners2 = (test) ->
  infra = new Module()
  listeners = infra.getListeners("test_once_event2")
  test.expect 2
  infra.once "test_once_event2", ->
    test.equal listeners.length, 0, "length once listeners0"
    test.done()
  test.equal listeners.length, 1, "length once listeners1"
  infra.emit "test_once_event2"
