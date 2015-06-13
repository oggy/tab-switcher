class TabSwitcher
  constructor: (pane) ->
    @pane = pane

  itemActivated: (item) ->
    keyup = (event) =>
      if not (event.ctrlKey or event.altKey or event.shiftKey or event.metaKey)
        @moveTab(item)
        document.removeEventListener 'keyup', keyup
        document.removeEventListener 'mouseup', keyup
    document.addEventListener 'keyup', keyup
    document.addEventListener 'mouseup', keyup

  moveTab: (item) ->
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
