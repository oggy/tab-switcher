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
      tabList.serialize()
      if tabList then tabList.serialize() else null
    {version: 1, panes: panesState}

  deserialize: (state) ->
    return if state.version != 1
    panes = atom.workspace.getPanes()
    for paneState, i in state.panes
      pane = panes[i]
      continue if paneState is null or pane is undefined
      @tabLists[pane.id] = new TabList(pane, paneState, state.version)

module.exports =
  activate: (state) ->
    @disposable = atom.commands.add 'atom-workspace',
      'tab-switcher:next': -> TabSwitcher.currentList()?.next()
      'tab-switcher:previous': -> TabSwitcher.currentList()?.previous()
      'tab-switcher:save': -> TabSwitcher.currentList()?.saveCurrent()
      'tab-switcher:close': -> TabSwitcher.currentList()?.closeCurrent()

    if state?.version
      TabSwitcher.deserialize(state)

  deactivate: ->
    @disposable.dispose()
    TabSwitcher.destroyLists()

  serialize: ->
    TabSwitcher.serialize()
