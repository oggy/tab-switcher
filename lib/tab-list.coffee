{CompositeDisposable} = require 'atom'
TabListView = require './tab-list-view'
Tabbable = require './tabbable'

module.exports =
class TabList
  constructor: (paneOrWorkspace, data, version) ->
    @tabbable = new Tabbable(paneOrWorkspace)
    @lastId = 0
    @tabs = @_buildTabs(@tabbable.getItems(), data, version)
    @currentIndex = null
    @view = new TabListView(@)
    @disposable = new CompositeDisposable
    @mode = 'local'

    @disposable.add @tabbable.onDidDestroy =>
      @destroy

    @disposable.add @tabbable.onDidAddItem (pane, item) =>
      tab = {id: @lastId += 1, pane: pane, item: item}
      @tabs.push(tab)
      @view.tabAdded(tab)

    @disposable.add @tabbable.onDidRemoveItem (pane, item) =>
      index = @_findItemIndex(pane, item)
      return if index is null
      @_removeTabAtIndex(index)

    @disposable.add @tabbable.observeActiveItem (pane, item) =>
      @_moveItemToFront(pane, item)

  settingsUpdated: (settings) ->
    @mode = settings.mode
    @view.settingsUpdated(settings)

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
    @tabbable.removeItem(tab.pane, tab.item)

  _moveItemToFront: (pane, item) ->
    index = @_findItemIndex(pane, item)
    if index
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
          activePane = atom.workspace.getActivePane()
          if @_shouldMoveTabToActivePane(tab, activePane)
            numItems = activePane.getItems().length
            tab.pane.moveItemToPane(tab.item, activePane, numItems)
            activePane.activateItem(tab.item)
          else
            @tabbable.activateItem(tab.pane, tab.item)
        @currentIndex = null
        @view.currentTabChanged(null)
      @view.hide()

  _shouldMoveTabToActivePane: (tab, activePane) ->
    @mode == 'tabless' and
      not (tab.pane is activePane) and
      not (tab.pane.getActiveItem() is tab.item)

  cancel: ->
    if @switching
      @switching = false
      unless @currentIndex is null
        @currentIndex = null
        @view.currentTabChanged(null)
    @view.hide()
