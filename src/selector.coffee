#x>
unless window?
  Loader = require('../src/loader.coffee')
else
  Loader = window.Loader
#<x

# выборка и вставка html элементов
class Selector extends Loader

  html = (htmlString) ->
    if htmlString
      if @.length?
        i = @length
        while --i >= 0
          @[i].innerHTML = htmlString
      else
        @.innerHTML = htmlString
      return @
    else
      if @.length?
        return @[@length-1].innerHTML
      else
        return @.innerHTML

  find = (query) ->
    node_child = []
    node_child.find = find
    node_child.html = html
    if @length > 1
      i = @length
      while --i >= 0
        node = @[i].querySelectorAll(query)
        ii = node.length
        while --ii >= 0
          node[ii].find = find
          node[ii].html = html
          node_child.push(node[ii])
    else if @length == 1
      node_child = @[0].querySelectorAll(query)
      node_child.find = find
      node_child.html = html
    node_child

  selector = (query) ->
    node_parent = window.document.querySelectorAll(query)
    node_parent.find = find
    node_parent.html = html
    node_parent

  constructor: (options={}) ->
    super

    ###*
    * Возвращает NodeList
    * controller.$('sel'), controller.$('sel').find('sel2')
    * @return {Array||Object} NodeList Список элементов, NodeList.length.
    ###
    @$ = options.$ || selector

#x>
if not window?
  module.exports = Selector
else
  window.Selector = Selector
#<x
