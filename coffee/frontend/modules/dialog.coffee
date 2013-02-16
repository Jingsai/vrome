class Dialog
  [dialogMode, searchFunc, lastKeyword, newTab] = [null, null, null, null, null]

  [search_result, selected_class, quick_num, notice_id] = ["__vrome_search_result", "__vrome_selected", "__vrome_quick_num", "__vrome_dialog_notice"]


  dialogBox = ->
    if $("#__vrome_dialog").length == 0
      $("body").prepend $("<div>", {id: "__vrome_dialog", style: "bottom: #{CmdBox.cmdBox().outerHeight()}px"})
    $("#__vrome_dialog")

  setResultBox = (results, append=false) ->
    $(".#{search_result}").remove() unless append
    for result in results
      if $.isArray result
        setResultBox result, true
      else
        dialogBox().append $("<div>", {class: search_result}).append result
    setSelected 0

  setSelected = (num=0) =>
    [@selected, results] = [num, $(".#{search_result}")]
    $(".#{selected_class}").removeClass selected_class
    notice $(results[@selected]).addClass(selected_class).find("a").attr("href")

    $(".#{quick_num}").remove()
    for result, index in results[@selected..@selected+9]
      $(result).prepend $("<span>", {class: quick_num}).text(index+1)

    $(".#{quick_num}").get(-1)?.scrollIntoViewIfNeeded()
    $(".#{quick_num}").get(0)?.scrollIntoViewIfNeeded()


  notice = (msg) ->
    cmdBox = $(CmdBox.cmdBox())
    if $("##{notice_id}").length == 0
      # 12 = padding-left (10) + border (1) x 2
      style = "right: #{cmdBox.outerWidth()}px; height:#{cmdBox.outerHeight()}px; line-height:#{cmdBox.outerHeight()}px; width: #{dialogBox().outerWidth() - cmdBox.outerWidth() - 12}px"
      $("body").prepend $("<div>", id: notice_id, style: style)
    $("##{notice_id}").text(msg)


  @start: (title, content, search_func, newtab, callback) ->
    [dialogMode, lastKeyword, newTab, searchFunc] = [true, null, newtab, search_func]
    CmdBox.set title: title, pressDown: handleInput, pressUp: callback, content: content
    searchFunc CmdBox.get().content

  @stop: (force) ->
    return unless dialogMode or force
    box.remove() for box in [dialogBox(), $("##{notice_id}"), CmdBox]
    dialogMode = false

  @draw: (msg) ->
    return false unless dialogMode
    sources = msg.urls or msg.sources

    if sources.length is 0
      setResultBox [$("<div>").html("No results found!")]
    else
      setResultBox for source in sources
        if $.isArray(source.url)
          "<a href='#{u}'>#{u}</a>" for u in source.url
        else
          "<a href='#{source.url}'>#{source.title} -- #{source.url}</a>"

  next = (direction=1) =>
    setSelected rabs(@selected + direction, $(".#{search_result}").length)

  prev = (dirction=-1) ->
    next dirction


  handleInput = (e) =>
    key = getKey(e)

    if key.match(/<C-(\d)>|<Up>|<S-Tab>|<Down>|<Tab>|Control/)
      if key.match(/<C-(\d)>/)
        next Number(RegExp.$1)
        @openCurrent()
      prev() if key is Option.get("autocomplete_prev")
      next() if key is Option.get("autocomplete_next")
      prev 10 if key is Option.get("autocomplete_prev_10")
      next 10 if key is Option.get("autocomplete_next_10")
      KeyEvent.stopPropagation e
      return

    setTimeout delayToWaitKeyDown, 20 unless isEscapeKey(key)

  delayToWaitKeyDown = ->
    keyword = CmdBox.get().content
    searchFunc lastKeyword = keyword if lastKeyword isnt keyword

  @openCurrentNewTab: => @open true
  @open: (keep_open) =>
    setTimeout @openCurrent, 500, keep_open

  @openCurrent: (keep_open) -> #Boolean
    return false if !dialogMode
    href = $(".#{selected_class}").find("a").prop("href")
    Post action: "Tab.openUrl", url: href, newtab: keep_open or newTab
    stop() unless keep_open


root = exports ? window
root.Dialog = Dialog