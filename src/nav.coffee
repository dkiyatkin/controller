
    # по умолчанию ссылки включаются
    if not @options.links? then @options.links = false
    # Расширение позволяющие сборке работать со ссылками
    ignore_protocols = ["^javascript:", "^mailto:", "^http://", "^https://", "^ftp://", "^//"]
    ###
* Возвращает отформатированный вариант состояния.
*
* Убираеются двойные слэши, добавляются слэш в начале и в конце.
*
* @param {String} pathname Строка с именем состояния.
* @return {String} Отформатированный вариант состояния.
###
    @getState = (pathname) =>
      pathname = "/" unless pathname
      now_location = decodeURIComponent(location.pathname)
      pathname = decodeURIComponent(pathname)
      pathname = pathname.replace(/#.+/, "") # убрать location.hash
      pathname = now_location + "/" + pathname unless pathname[0] is "/"
      #if (pathname.slice(-1) != '/') pathname = pathname + '/'; // добавить последний слэш если его нет
      pathname = pathname.replace(/\/{2,}/g, "/") # заменять двойные слэши
      pathname
    # Поиск родительской ссылки
    parentA = (targ) =>
      if targ.nodeName is "A"
        targ
      else
        if (not targ.parentNode) or (targ.parentNode is "HTML")
          false
        else
          parentA targ.parentNode
    # Обработчик для ссылок
    handler = (e) =>
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
                  @state = @getState(href)
                  @check (cb) =>
                    @hash = targ.hash
                    cb()
                #var x = window.scrollY; var y = window.scrollX;
                catch e
                  window.location = href
    # Подмена всех ссылок и осуществление переходов по страницам.
    setHrefs = =>
      a = @$("a")
      i = a.length
      while --i >= 0
        a[i].onclick = handler
    if @options.links
      setHrefs()
      @on "start", =>
        window.scrollTo 0, 0 unless @noscroll
        @noscroll = false
      @on "end", => # Слои обработались
        setHrefs()

    if not @options.address_bar? then @options.address_bar = false
    # Включает управление адресной строкой
    if @options.address_bar
      @state = @getState(location.pathname)
      @log.debug "setting onpopstate event for back and forward buttons"
      setTimeout (=>
        window.onpopstate = (e) =>
          # кнопки вперед и назад и изменение хэштэга
          @log.debug "onpopstate"
          unless @hash
            now_state = @getState(location.pathname)
            @state = now_state
            @check (cb) =>
              @hash = location.hash
              cb()
      ), 1000 # chrome bug
      now_state = undefined
      # менять location.state в начале check
      @on "start", =>
        # изменение адресной строки
        now_state = @getState(location.pathname)
        unless @state is now_state # изменилась
          @log.debug "push state " + @state + " replace hash " + @hash
          history.pushState null, null, @state
      # менять location.hash в конце check
      @on "end", => # Слои обработались
        unless @state is now_state
          location.replace @hash if @hash
        else # очистить адрес от хэша
          @log.debug "replace state " + @state + " push hash " + @hash
          history.replaceState null, null, @state
          location.href = @hash if @hash
        @hash = ""
