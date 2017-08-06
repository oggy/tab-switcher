{CompositeDisposable} = require 'atom'
TabList = require './tab-list'

TabSwitcher =
  tabLists: new Map

  currentList: ->
    pane = atom.workspace.getActivePane()
    return null if not pane

    if !@tabLists.has(pane)
      @tabLists.set(pane, new TabList(pane))
      pane.onDidDestroy =>
        @tabLists.delete(pane)

    return @tabLists.get(pane)

  destroyLists: ->
    @tabLists.forEach (tabList, pane) ->
      tabList.destroy()

  serialize: ->
    panesState = atom.workspace.getPanes().map (pane) =>
      tabList = @tabLists.get(pane)
      if tabList then tabList.serialize() else null
    {version: 1, panes: panesState}

  deserialize: (state) ->
    return if state.version != 1
    panes = atom.workspace.getPanes()

    if state.panes
      panesState = state.panes.filter((x) => x)
      assignments = TabList.assignPanes(panes, panesState)
      assignments.forEach (data, paneId) =>
        pane = panes.find (pane) -> pane.id == paneId
        @tabLists.set(pane, new TabList(pane, data, state.version))

  updateAnimationDelay: (delay) ->
    @tabLists.forEach (tabList, id) ->
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
