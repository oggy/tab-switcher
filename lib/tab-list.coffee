{CompositeDisposable} = require 'atom'
TabListView = require './tab-list-view'
Tabbable = require './tabbable'

find = (list, predicate) ->
  for element in list
    return element if predicate(element)
  null

module.exports =
class TabList
  constructor: (paneOrWorkspace, data, version) ->
    @tabbable = new Tabbable(paneOrWorkspace)
    @lastId = 0
    @tabs = @_buildTabs(@tabbable.getItems(), data, version)
    @currentIndex = null
    @view = new TabListView(@)
    @disposable = new CompositeDisposable

    @disposable.add @tabbable.onDidDestroy =>
      @destroy()

    @disposable.add @tabbable.onDidAddItem (pane, item) =>
      tab = {id: @lastId += 1, pane: pane, item: item}
      @tabs.push(tab)
      @view.tabAdded(tab)

    @disposable.add @tabbable.onWillRemoveItem (pane, item) =>
      if pane.getActiveItem() is item
        if paneOrWorkspace is atom.workspace
          tab = find @tabs, (tab) -> tab.item isnt item and tab.pane is pane
        else
          tab = find @tabs, (tab) -> tab.item isnt item

        if tab
          tab.pane.activateItem(tab.item)

    @disposable.add @tabbable.onDidRemoveItem (pane, item) =>
      index = @_findItemIndex(pane, item)
      if index is null
        return console.warn "item to remove not found"
      @_removeTabAtIndex(index)

    @disposable.add @tabbable.observeActiveItem (pane, item) =>
      @_moveItemToFront(pane, item)

    @disposable.add @tabbable.observeItems (item) =>
      return if !item.onDidChangeTitle
      @disposable.add item.onDidChangeTitle =>
        tab = find @tabs, (tab) -> tab.item is item
        @view.tabUpdated(tab)

  updateAnimationDelay: (delay) ->
    @view.updateAnimationDelay(delay)

  _buildTabs: (items, data, version) ->
    tabs = items.map ([pane, item]) => {id: @lastId += 1, pane: pane, item: item}
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
    @tabbable = null
    @tabs = []
    @disposable?.dispose()
    @disposable = null
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
    @_start()

  previous: ->
    if @tabs.length == 0
      @_setCurrentIndex(null)
    else
      index = (@currentIndex ? 0) - 1
      index += @tabs.length if index < 0
      @_setCurrentIndex(index)
    @_start()

  setCurrentId: (id) ->
    index = @tabs.map((tab) -> tab.id).indexOf(id)
    if index == -1
      return console.warn "setCurrentId: can't find tab id", id
    @_setCurrentIndex(index)

  saveCurrent: ->
    tab = @tabs[@currentIndex]
    if tab is undefined
      return console.warn "saveCurrent: invalid index selected", @currentIndex
    tab.item.save?()

  closeCurrent: ->
    tab = @tabs[@currentIndex]
    if tab is undefined
      return console.warn "closeCurrent: invalid index selected", @currentIndex
    @tabbable.removeItem(tab.pane, tab.item)

  _moveItemToFront: (pane, item) ->
    index = @_findItemIndex(pane, item)
    unless index is null
      tabs = @tabs.splice(index, 1)
      @tabs.unshift(tabs[0])
      @view.tabsReordered()

  _findItemIndex: (pane, item) ->
    for tab, index in @tabs
      if tab.pane is pane and tab.item is item
        return index
    return null

  _removeTabAtIndex: (index) ->
    if index == @currentIndex
      if index == @tabs.length - 1
        newCurrentIndex = if index == 0 then null else @currentIndex - 1
      else
        newCurrentIndex = @currentIndex
    else if index < @currentIndex
      newCurrentIndex = @currentIndex - 1

    removed = @tabs.splice(index, 1)
    @view.tabRemoved(removed[0])

    if newCurrentIndex isnt null
        @_setCurrentIndex(newCurrentIndex)

  _start: (item) ->
    if not @switching
      @switching = true
      @view.show()

  _setCurrentIndex: (index) ->
    if index == null
      @currentIndex = null
      @view.currentTabChanged(null)
    else
      @currentIndex = index
      @view.currentTabChanged(@tabs[index])

  select: ->
    if @switching
      @switching = false
      unless @currentIndex is null
        if 0 <= @currentIndex < @tabs.length
          tab = @tabs[@currentIndex]
          @tabbable.activateItem(tab.pane, tab.item)
        @currentIndex = null
        @view.currentTabChanged(null)
      @view.hide()

  cancel: ->
    if @switching
      @switching = false
      unless @currentIndex is null
        @currentIndex = null
        @view.currentTabChanged(null)
    @view.hide()
