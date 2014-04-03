functions = (Controller) ->
  class Controller extends Controller
    constructor: (options={}) ->
      super

if not window?
  module.exports = functions
else
  window.Controller = functions(window.Controller)
