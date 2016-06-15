{CompositeDisposable} = require 'atom'
TabListView = require './tab-list-view'

find = (list, predicate) ->
  for element in list
    return element if predicate(element)
  null

module.exports =
class TabList
  constructor: (pane, data, version) ->
    @pane = pane
    @lastId = 0
    @tabs = @_buildTabs(pane.getItems(), data, version)
    @currentIndex = null
    @view = new TabListView(@)
    @disposable = new CompositeDisposable

    @disposable.add @pane.onDidDestroy =>
      @destroy

    @disposable.add @pane.onDidAddItem (item) =>
      tab = {id: @lastId += 1, item: item.item}
      @tabs.push(tab)
      @view.tabAdded(tab)

    @disposable.add @pane.onWillRemoveItem (event) =>
      if @pane.getActiveItem() is event.item
        tab = find @tabs, (tab) -> tab.item isnt event.item
        if tab
          @pane.activateItem(tab.item)

    @disposable.add @pane.onDidRemoveItem (item) =>
      index = @_findItemIndex(item.item)
      return if index is null
      @_removeTabAtIndex(index)

    @disposable.add @pane.observeActiveItem (item) =>
      @_moveItemToFront(item)
      # Atom relies on tab indices not changing during this hook, so we need to
      # delay this. (#39)
      moveTab = =>
        if atom.config.get 'tab-switcher.reorderTabs'
          @pane.moveItem(item, 0)
      setTimeout(moveTab, 0)

    @disposable.add @pane.observeItems (item) =>
      return if !item.onDidChangeTitle
      @disposable.add item.onDidChangeTitle =>
        tab = find @tabs, (tab) -> tab.item is item
        @view.tabUpdated(tab)

  updateAnimationDelay: (delay) ->
    @view.updateAnimationDelay(delay)

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
    @tabs = []
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
    return if index == -1
    @_setCurrentIndex(index)

  saveCurrent: ->
    tab = @tabs[@currentIndex]
    return if tab is undefined
    tab.item.save?()

  closeCurrent: ->
    tab = @tabs[@currentIndex]
    return if tab is undefined
    @pane.removeItem(tab.item)

  _moveItemToFront: (item) ->
    index = @_findItemIndex(item)
    unless index is null
      tabs = @tabs.splice(index, 1)
      @tabs.unshift(tabs[0])
      @view.tabsReordered()

  _findItemIndex: (item) ->
    for tab, index in @tabs
      if tab.item == item
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
          @pane.activateItem(@tabs[@currentIndex].item)
          @pane.activate()
        @currentIndex = null
        @view.currentTabChanged(null)
      @view.hide()

  cancel: ->
    if @switching
      @switching = false
      unless @currentIndex is null
        @currentIndex = null
        @view.currentTabChanged(null)
    @pane.activate()
    @view.hide()
