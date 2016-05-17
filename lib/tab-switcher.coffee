{CompositeDisposable} = require 'atom'
TabList = require './tab-list'

TabSwitcher =
  tabLists: {}

  currentList: ->
    pane = atom.workspace.getActivePane()
    return null if not pane

    tabList = @tabLists[pane.id]
    if tabList is undefined
      @tabLists[pane.id] = tabList = new TabList(pane)
      pane.onDidDestroy =>
        delete @tabLists[pane.id]

    return tabList

  destroyLists: ->
    for paneId, tabList of @tabLists
      tabList.destroy()

  serialize: ->
    panesState = atom.workspace.getPanes().map (pane) =>
      tabList = @tabLists[pane.id]
      if tabList then tabList.serialize() else null
    {version: 1, panes: panesState}

  deserialize: (state) ->
    return if state.version != 1
    panes = atom.workspace.getPanes()
    if state.panes
      for paneState, i in state.panes
        pane = panes[i]
        continue if paneState is null or pane is undefined
        @tabLists[pane.id] = new TabList(pane, paneState, state.version)

  updateAnimationDelay: (delay) ->
    for id, tabList of @tabLists
      tabList.updateAnimationDelay(delay)

module.exports =
  config:
    fadeInDelay:
      type: 'number',
      default: 0.1,
      title: 'Pause before displaying tab switcher, in seconds'
      description: 'Increasing this can reduce flicker when switching quickly.'
    reorderTabs:
      type: 'boolean'
      default: false
      title: 'Reorder tabs to match the list'

  activate: (state) ->
    @disposable = new CompositeDisposable

    @disposable.add atom.commands.add 'atom-workspace',
      'tab-switcher:next': -> TabSwitcher.currentList()?.next()
      'tab-switcher:previous': -> TabSwitcher.currentList()?.previous()
      'tab-switcher:select': -> TabSwitcher.currentList()?.select()
      'tab-switcher:cancel': -> TabSwitcher.currentList()?.cancel()
      'tab-switcher:save': -> TabSwitcher.currentList()?.saveCurrent()
      'tab-switcher:close': -> TabSwitcher.currentList()?.closeCurrent()

    if state?.version
      TabSwitcher.deserialize(state)

    @disposable.add atom.config.observe 'tab-switcher.fadeInDelay', (value) ->
      TabSwitcher.updateAnimationDelay(value)

  deactivate: ->
    @disposable.dispose()
    TabSwitcher.destroyLists()

  serialize: ->
    TabSwitcher.serialize()

  currentList: ->
    TabSwitcher.currentList()
