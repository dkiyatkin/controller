if not window?
  Logger = require '../src/logger.coffee'
else
  window.exports = {}
  window.logger = exports
  Logger = window.Logger

exports.logger = (test) ->
  test.expect 3
  logger = new Logger()
  logger.log.logger = "WARNING"
  test.equal(logger.log.debug("logger", "sdf"), `undefined`, "logger level 1")
  logger.log.logger = "INFO"
  logger.log.quiet = true
  test.equal(logger.log.error("logger", "sdf").split(" ").slice(-3).join(" "), "ERROR logger sdf", "logger level 2")
  controller2 = new Logger({logger:'DEBUG', quiet: true})
  test.notEqual(logger.log.history.length, controller2.log.history.length, 'one string, two string')
  test.done()
