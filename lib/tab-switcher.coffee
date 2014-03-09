TabSwitcherView = require './tab-switcher-view'

module.exports =
  tabSwitcherView: null

  activate: (state) ->
    @tabSwitcherView = new TabSwitcherView(state.tabSwitcherViewState)

  deactivate: ->
    @tabSwitcherView.destroy()

  serialize: ->
    tabSwitcherViewState: @tabSwitcherView.serialize()
