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

module.exports =
  activate: (state) ->
    @disposable = atom.commands.add 'atom-workspace',
      'tab-switcher:next': -> TabSwitcher.currentList()?.next()
      'tab-switcher:previous': -> TabSwitcher.currentList()?.previous()

  deactivate: ->
    @disposable.dispose()
    TabSwitcher.destroyLists()
