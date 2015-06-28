{CompositeDisposable, Emitter} = require 'atom'
TabListView = require './tab-list-view'

module.exports =
class TabList
  constructor: (pane, data, version) ->
    @pane = pane
    @lastId = 0
    @tabs = @_buildTabs(pane.getItems(), data, version)
    @currentIndex = null
    @emitter = new Emitter
    @view = new TabListView(@)
    @disposable = new CompositeDisposable

    for tab in @tabs
      @emitter.emit 'did-add-tab', tab

    @disposable.add @pane.onDidDestroy =>
      @destroy

    @disposable.add @pane.onDidAddItem (item) =>
      tab = {id: @lastId += 1, item: item.item}
      @tabs.push(tab)
      @emitter.emit 'did-add-tab', tab

    @disposable.add @pane.onDidRemoveItem (item) =>
      index = @_findItemIndex(item.item)
      @tabs.splice(index, 1)
      @emitter.emit 'did-remove-tab', tab

    @disposable.add @pane.observeActiveItem (item) =>
      @_moveItemToFront(item)

    @disposable.add @pane.onDidDestroy =>
      for tab in @tabs
        @emitter.emit 'did-remove-tab', tab
      @tabs = []

  _buildTabs: (items, data, version) ->
    tabs = items.map (item) => {id: @lastId += 1, item: item}
    if data
      titleOrder = data.tabs.map (item) -> item.title
      newTabs = 0
      ordering = tabs.map (tab, index) ->
        key = titleOrder.indexOf(tab.item.getTitle?() or null)
        if key == -1
          key = titleOrder.length + newTabs
          newTabs += 1
        {tab: tab, key: key}

      tabs = ordering.sort((a, b) -> a.key - b.key).map((o) -> o.tab)
    tabs

  onDidAddTab: (callback) ->
    @emitter.on 'did-add-tab', callback

  onDidRemoveTab: (callback) ->
    @emitter.on 'did-remove-tab', callback

  destroy: ->
    @pane = null
    @disposable.dispose()
    @view.destroy()

  serialize: ->
    {tabs: @tabs.map (tab) -> {title: tab.item.getTitle?() or null}}

  next: ->
    if @tabs.length == 0
      @currentIndex = null
      return

    @currentIndex ?= 0
    @currentIndex += 1
    @currentIndex = 0 if @currentIndex >= @tabs.length
    @_start()

  previous: ->
    if @tabs.length == 0
      @currentIndex = null
      return

    @currentIndex ?= 0
    @currentIndex -= 1
    @currentIndex += @tabs.length if @currentIndex < 0
    @_start()

  _moveItemToFront: (item) ->
    index = @_findItemIndex(item)
    unless index == -1
      tabs = @tabs.splice(index, 1)
      @tabs.unshift(tabs[0])

  _findItemIndex: (item) ->
    for tab, index in @tabs
      if tab.item == item
        return index
    return null

  _start: (item) ->
    if not @switching
      @switching = true
      keyup = (event) =>
        if not (event.ctrlKey or event.altKey or event.shiftKey or event.metaKey)
          @_select()
          document.removeEventListener 'keyup', keyup
          document.removeEventListener 'mouseup', keyup
      document.addEventListener 'keyup', keyup
      document.addEventListener 'mouseup', keyup
    @view.show()

  _select: ->
    if @switching
      @switching = false
      if @currentIndex
        if 0 < @currentIndex < @tabs.length
          @pane.activateItem(@tabs[@currentIndex].item)
          @pane.activate()
        @currentIndex = null
    @view.hide()
