{CompositeDisposable} = require 'atom'
TabListView = require './tab-list-view'

module.exports =
class TabList
  constructor: (pane, data, version) ->
    @pane = pane
    @lastId = 0
    @tabs = @_buildTabs(pane.getItems(), data, version)
    @currentIndex = null
    @view = new TabListView(@)
    @disposable = new CompositeDisposable

    for tab in @tabs
      @view.tabAdded(tab)

    @disposable.add @pane.onDidDestroy =>
      @destroy

    @disposable.add @pane.onDidAddItem (item) =>
      tab = {id: @lastId += 1, item: item.item}
      @tabs.push(tab)
      @view.tabAdded(tab)

    @disposable.add @pane.onDidRemoveItem (item) =>
      index = @_findItemIndex(item.item)
      @tabs.splice(index, 1)
      @view.tabRemoved(tab)

    @disposable.add @pane.observeActiveItem (item) =>
      @_moveItemToFront(item)

    @disposable.add @pane.onDidDestroy =>
      for tab in @tabs
        @view.tabRemoved(tab)
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

  destroy: ->
    @pane = null
    @disposable.dispose()
    @view.destroy()

  serialize: ->
    {tabs: @tabs.map (tab) -> {title: tab.item.getTitle?() or null}}

  next: ->
    if @tabs.length == 0
      @_setCurrentIndex(null)
    else
      index = (@currentIndex ? 0) + 1
      index -= @tabs.length if index >= @tabs.length
      @_setCurrentIndex(index)

  previous: ->
    if @tabs.length == 0
      @_setCurrentIndex(null)
    else
      index = (@currentIndex ? 0) - 1
      index += @tabs.length if index < 0
      @_setCurrentIndex(index)

  setCurrentId: (id) ->
    index = @tabs.map((tab) -> tab.id).indexOf(id)
    return if index == -1
    @_setCurrentIndex(index)

  selectId: (id) ->
    @setCurrentId(id)
    @_select()

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

  _setCurrentIndex: (index) ->
    if index == null
      @view.currentTabChanged(null)
      @currentIndex = null
    else
      @currentIndex = index
      @view.currentTabChanged(@tabs[index])
      @_start()

  _select: ->
    if @switching
      @switching = false
      if @currentIndex
        if 0 < @currentIndex < @tabs.length
          @pane.activateItem(@tabs[@currentIndex].item)
          @pane.activate()
        @currentIndex = null
        @view.currentTabChanged(null)
    @view.hide()
