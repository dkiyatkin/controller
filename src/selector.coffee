class Selector
  constructor: (@options={}) ->

    @document = @options.document || (window.document if window?)

    ###*
    * Возвращает NodeList
    * controller.$('sel'), controller.$('sel').find('sel2')
    * @return {Array||Object} NodeList Список элементов, NodeList.length.
    ###
    @$ = @options.$ || (selector) =>
      node_parent = @document.querySelectorAll(selector)
      node_parent.find = (selector) ->
        node_child = []
        if node_parent.length > 1
          i = node_parent.length
          while --i >= 0
            node = node_parent[i].querySelectorAll(selector)
            ii = node.length
            while --ii >= 0
              node_child.push(node[ii])
        else if node_parent.length == 1
          node_child = node_parent[0].querySelectorAll(selector)
        node_child
      node_parent

if window?
  window.SuperController.Selector = Selector
else
  module.exports = Selector
