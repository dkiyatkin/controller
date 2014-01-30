if not window?
  Module = require '../src/common.coffee'
else
  window.exports = {}
  window.module = exports
  Module = window.Module

# Проверяем инициализацию класса
exports.oneInit = (test) ->
  controller = new Module({logger:'DEBUG', quiet: true})
  test.done()

exports.manyInit = (test) ->
  test.expect 1
  controller = new Module({logger:'DEBUG', quiet: true})
  controller2 = new Module({logger:'DEBUG', quiet: true})
  test.ok controller isnt controller2, "new obj"
  test.done()
