unless window?
  Module = require('../src/common.coffee')
else
  Module = window.Module
###*
* Интерфейс управления отладочными сообщениями.
* Примеры:
* controller.log.error('test error'); // вернет и выведет в консоль 'test error'
* controller.log.warning('test warning'); // вернет и выведет в консоль 'test warning'
* controller.log.info('test info'); // вернет и выведет в консоль 'test info'
* controller.log.logger = 'WARNING'; // выбрать уровень логгера
* // доступны 4 соответсвующих уровня: ERROR, WARNING (выбран по умолчанию), INFO и DEBUG
* controller.log.debug('test debug'); // ничего не произойдет, потому что логгер задан уровнем выше
* controller.log.history; // история всех сообщений контроллера
###
class Logger extends Module
  loggers = ['ERROR', 'WARNING', 'INFO', 'DEBUG'] # Возможные варианты логирования
  _log = (msg, log_level, log) ->
    if loggers.indexOf(log.logger) >= log_level
      msg = '[' + new Date().toGMTString() + '] ' + loggers[log_level] + ' ' + msg.join(' ')
      if not log.quiet
        console.log msg if log_level is 3
        console.info msg if log_level is 2
        console.warn msg if log_level is 1
        console.error msg if log_level is 0
      log.history += '\n' + msg
      msg
  constructor: (options={}) ->
    @log = # логгирование непонятных ситуаций
      history: ''
      logger: options.logger || 'WARNING' # уровень серьезности
      quiet: options.quiet || false # у стен есть уши
      debug: (msg...) -> _log(msg, 3, @)
      info: (msg...) -> _log(msg, 2, @)
      warn: (msg...) -> _log(msg, 1, @)
      error: (msg...) -> _log(msg, 0, @)

#x>
if not window?
  module.exports = Logger
else
  window.Logger = Logger
#<x
