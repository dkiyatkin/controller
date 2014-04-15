#x>
unless window?
  Loader = require('../src/loader.coffee')
else
  Loader = window.Loader
#<x

# выборка и вставка html элементов
class Selector extends Loader

  uniqueId = (length=8) ->
    id = ""
    id += Math.random().toString(36).substr(2) while id.length < length
    id.substr 0, length

  # Получить у элемента значение css-свойства
  getStyle = (el, cssprop) ->
    if el.currentStyle #IE
      el.currentStyle[cssprop]
    else if window.document.defaultView and window.document.defaultView.getComputedStyle #Firefox
      window.document.defaultView.getComputedStyle(el, "")[cssprop]
    else #try and get inline style
      el.style[cssprop]

  constructor: (options={}) ->
    super

    pasteHTML = (el, html) =>
      if /<(style+)([^>]+)*(?:>)/g.test(html) or /<(script+)([^>]+)*(?:>)/g.test(html)
        window.LayerControl.scriptautoexec = false
        tempid = "layerControl_" + uniqueId() # Одинаковый id нельзя.. если будут вложенные вызовы будет ошибка
        html = "<span id=\"" + tempid + "\" style=\"display:none\">" + "<style>#" + tempid + "{ width:3px }</style>" + "<script type=\"text/javascript\">window.LayerControl.scriptautoexec=true;</script>" + "1</span>" + html
        el.innerHTML = html
        unless window.LayerControl.scriptautoexec
          scripts = el.getElementsByTagName("script")
          i = 1
          script = undefined
          while script = scripts[i]
            @load.script script
            i++
        bug = @document.getElementById(tempid)
        if bug
          b = getStyle(bug, "width")
          if b isnt "3px"
            _css = el.getElementsByTagName("style")
            i = 0
            css = undefined
            while css = _css[i]
              t = css.cssText #||css.innerHTML; для IE будет Undefined ну и бог с ним у него и так работает а сюда по ошибке поподаем
              @load.css t
              i++
          el.removeChild bug
      else el.innerHTML = html

    html = (htmlString) ->
      if htmlString?
        if @.length?
          i = @length
          while --i >= 0
            # @[i].innerHTML = htmlString
            pasteHTML(@[i], htmlString)
        else
          # @.innerHTML = htmlString
          pasteHTML(@, htmlString)
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

    ###*
    * Возвращает NodeList
    * controller.$('sel'), controller.$('sel').find('sel2')
    * @return {Array||Object} NodeList Список элементов, NodeList.length.
    ###
    @$ = options.$ || selector # селектор, вставка элементов в документ и в сознание
    @document = window.document if window? # документ документ документ


#x>
if not window?
  module.exports = Selector
else
  window.Selector = Selector
#<x
