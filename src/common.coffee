#x>
if not window?
  EventEmitter = require('eventemitter2').EventEmitter2
else
  EventEmitter = window.EventEmitter2
console.log 123
#<x

moduleKeywords = ['extended', 'included']

class Module extends EventEmitter

  @extend: (obj) ->
    for key, value of obj when key not in moduleKeywords
      @[key] = value
    obj.extended?.apply(@)
    this

  @include: (obj) ->
    for key, value of obj when key not in moduleKeywords
      @::[key] = value # Assign properties to the prototype
    obj.included?.apply(@)
    this

  empty: (cb) ->
    cb() if cb

mixOf = (base, mixins...) ->
  class Mixed extends base
  for mixin in mixins by -1 #earlier mixins override later ones
    for name, method of mixin::
      Mixed::[name] = method
  Mixed

#x>
if not window?
  module.exports = Module
else
  window.Module = Module
#<x
