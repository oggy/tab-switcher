class TabSwitcher
  constructor: (pane) ->
    @pane = pane
    @timeouts = 0

  itemActivated: (item) ->
    @timeouts += 1
    setTimeout((=> @timeout(item)), 1000)

  timeout: (item) ->
    return if @timeouts == 0

    @timeouts -= 1
    if @timeouts == 0
      unless @pane.isDestroyed() or item not in @pane.getItems()
        @pane.moveItem(item, 0)

TabSwitcher.find = (pane) ->
  instance = TabSwitcher.instances[pane.id]
  return instance if instance
  instance = new TabSwitcher(pane)
  TabSwitcher.instances[pane.id] = instance

TabSwitcher.instances = {}

module.exports =
  activate: (state) ->
    @disposable = atom.workspace.onDidChangeActivePaneItem (item) =>
      pane = atom.workspace.getActivePane()
      TabSwitcher.find(pane).itemActivated(item)

  deactivate: ->
    @disposable.dispose()
