{View} = require 'atom'

module.exports =
class TabSwitcherView extends View
  @content: ->
    @div class: 'tab-switcher overlay from-top', =>
      @div "The TabSwitcher package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->
    atom.workspaceView.command "tab-switcher:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    console.log "TabSwitcherView was toggled!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
