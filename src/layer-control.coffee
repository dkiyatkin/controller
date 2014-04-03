#x>
unless window?
  Cache = require('../src/cache.coffee')
else
  Cache = window.Cache
#<x

# здесь финал
class LayerControl extends Cache
  constructor: (options={}) ->
    super

if not window?
  module.exports = LayerControl
else
  window.LayerControl = LayerControl
