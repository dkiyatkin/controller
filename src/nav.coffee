#x>
unless window?
  Layer = require('../src/layer.coffee')
else
  Layer = window.Layer
#<x

class Nav extends Layer

  ###
  * Возвращает отформатированный вариант состояния.
  *
  * Убираеются двойные слэши, добавляются слэш в начале и в конце.
  *
  * @param {String} pathname Строка с именем состояния.
  * @return {String} Отформатированный вариант состояния.
  ###
  getState = (pathname) ->
    pathname = "/" unless pathname
    now_location = decodeURIComponent(location.pathname)
    pathname = decodeURIComponent(pathname)
    pathname = pathname.replace(/#.+/, "") # убрать location.hash
    pathname = now_location + "/" + pathname unless pathname[0] is "/"
    #if (pathname.slice(-1) != '/') pathname = pathname + '/'; // добавить последний слэш если его нет
    pathname = pathname.replace(/\/{2,}/g, "/") # заменять двойные слэши
    pathname

  # Поиск родительской ссылки
  parentA = (targ) ->
    if targ.nodeName is "A"
      targ
    else
      if (not targ.parentNode) or (targ.parentNode is "HTML")
        false
      else
        parentA targ.parentNode

  # Расширение позволяющие сборке работать со ссылками
  ignore_protocols = ["^javascript:", "^mailto:", "^http://", "^https://", "^ftp://", "^//"]

  # Подмена всех ссылок и осуществление переходов по страницам.
  setLinks: (handler) ->
    $a = @$("a")
    i = $a.length
    if location.origin # если совподает адрес сайта, то убираем его для отключения полной перезагрузки TODO возможно это нужно сделать в другом месте
      while --i >= 0
        href = $a[i].getAttribute('href')
        if href and (href.indexOf(location.origin) is 0)
          $a[i].setAttribute('href', href.slice(location.origin.length))
    i = $a.length
    while --i >= 0
      $a[i].onclick = handler
    return $a

  constructor: (options={}) ->
    super
    @getState = getState
    # по умолчанию ссылки включаются
    if not options.links? then options.links = true
    if options.links
      handler = (e) => # Обработчик для ссылок
        e = e or window.event
        #e.stopPropagation ? e.stopPropagation() : (e.cancelBubble=true);
        if not e.metaKey and not e.shiftKey and not e.altKey and not e.ctrlKey
          targ = e.target or e.srcElement
          targ = parentA(targ)
          if targ
            href = targ.getAttribute("href")
            ignore = false
            if href
              unless targ.getAttribute("target")
                i = ignore_protocols.length
                while --i >= 0
                  ignore = true if RegExp(ignore_protocols[i], "gim").test(href)
                unless ignore
                  try
                    (if e.preventDefault then e.preventDefault() else (e.returnValue = false))
                    @state @getState(href), =>
                      @hash = targ.hash
                  #var x = window.scrollY; var y = window.scrollX;
                  catch e
                    console.error e
                    # window.location = href # TODO
      @setLinks(handler)
      @on "start", ->
        window.scrollTo 0, 0 unless @noscroll
        @noscroll = false
      @on "end", -> # Слои обработались
        @setLinks(handler)
    # Включает управление адресной строкой
    if not options.addressBar? then options.addressBar = true
    if options.addressBar
      @log.debug("setting onpopstate event for back and forward buttons")
      setTimeout (=>
        window.onpopstate = (e) => # кнопки вперед и назад и изменение хэштэга
          @log.debug("onpopstate")
          unless @hash
            nowState = @getState(location.pathname)
            @state nowState, =>
              @hash = location.hash
      ), 1000 # chrome bug
      nowState = undefined
      @on "start", -> # менять location.state в начале check # изменение адресной строки
        nowState = @getState(location.pathname)
        unless @state.circle.state is nowState # изменилась
          @log.debug "push state " + @state.circle.state + " replace hash " + @hash
          history.pushState null, null, @state.circle.state
      @on "end", -> # Слои обработались # менять location.hash в конце check
        unless @state.circle.state is nowState
          location.replace @hash if @hash
        else # очистить адрес от хэша
          @log.debug "replace state " + @state.circle.state + " push hash " + @hash
          history.replaceState null, null, @state.circle.state
          location.href = @hash if @hash
        @hash = ""

#x>
if not window?
  module.exports = Nav
else
  window.Nav = Nav
#<x
