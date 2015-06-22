{CompositeDisposable} = require 'atom'
TabListView = require './tab-list-view'

class TabSwitcher
  constructor: (pane) ->
    @pane = pane
    @tabs = pane.getItems().map (item) -> {item: item}
    @selection = null
    @view = new TabListView(@)
    @disposable = new CompositeDisposable()

    @disposable.add @pane.onDidDestroy =>
      @destroy
      delete TabSwitcher.instances[@pane.id]

    @disposable.add @pane.onDidAddItem (item) =>
      tab = {item: item.item}
      @tabs.push(tab)
      @view.initializeTab(tab)

    @disposable.add @pane.onDidRemoveItem (item) =>
      index = @_findItemIndex(item.item)
      @tabs.splice(index, 1)

    @disposable.add @pane.observeActiveItem (item) =>
      @_moveItemToFront(item)

    @disposable.add @pane.onDidDestroy =>
      @tabs = []

  destroy: ->
    @pane = null
    @disposable.dispose()
    @view.destroy()

  next: ->
    if @tabs.length == 0
      @selection = null
      return

    @selection ?= 0
    @selection += 1
    @selection = 0 if @selection >= @tabs.length
    @_start()

  previous: ->
    if @tabs.length == 0
      @selection = null
      return

    @selection ?= 0
    @selection -= 1
    @selection += @tabs.length if @selection < 0
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
          @_stop()
          document.removeEventListener 'keyup', keyup
          document.removeEventListener 'mouseup', keyup
      document.addEventListener 'keyup', keyup
      document.addEventListener 'mouseup', keyup
    @view.show()

  _stop: ->
    if @switching
      @switching = false
      if @selection
        if 0 < @selection < @tabs.length
          @pane.activateItem(@tabs[@selection].item)
        @selection = null
    @view.hide()

  @current: ->
    pane = atom.workspace.getActivePane()
    @find(pane)

  @find: (pane) ->
    return null if not pane
    instance = TabSwitcher.instances[pane.id]
    return instance if instance
    instance = new TabSwitcher(pane)
    TabSwitcher.instances[pane.id] = instance

  @destroyAll: ->
    for pane_id, tabSwitcher of @instances
      tabSwitcher.destroy()

  @instances: {}

module.exports =
  activate: (state) ->
    @disposable = atom.commands.add 'atom-workspace',
      'tab-switcher:next': -> TabSwitcher.current()?.next()
      'tab-switcher:previous': -> TabSwitcher.current()?.previous()

  deactivate: ->
    @disposable.dispose()
    TabSwitcher.destroyAll()
