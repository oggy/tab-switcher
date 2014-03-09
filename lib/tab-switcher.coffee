class TabSwitcher
  constructor: (@paneView) ->
    @pane = @paneView.model
    @timeouts = 0

  nextTab: ->
    @pane.activateNextItem()
    @waitAndRotate()

  previousTab: ->
    @pane.activatePreviousItem()
    @waitAndRotate()

  waitAndRotate: ->
    item = @pane.getActiveItem()
    @timeouts += 1
    setTimeout((=> @timeout(item)), 1000)

  timeout: (item) ->
    if @timeouts == 0
      return

    @timeouts -= 1
    if @timeouts == 0
      @pane.moveItem(item, 0)

TabSwitcher.find = (event) ->
  $pane = event.targetView().closest('.pane')
  data = $pane.data('tab-switcher')
  if data is undefined
    data = new TabSwitcher($pane.data('view'))
    $pane.data('tab-switcher', data)
  data

module.exports =
  activate: (state) ->
    atom.workspaceView.command 'tab-switcher:next-tab', (event) =>
      TabSwitcher.find(event).nextTab()

    atom.workspaceView.command 'tab-switcher:previous-tab', (event) =>
      TabSwitcher.find(event).previousTab()

  deactivate: ->

  serialize: ->
