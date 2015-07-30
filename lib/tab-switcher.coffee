{CompositeDisposable} = require 'atom'
TabList = require './tab-list'
TabListView = require './tab-list-view'

TabSwitcher =
  reset: ->
    @settings =
      mode: 'local'
      fadeInDelay: 0

    @tabLists = {}

  currentList: ->
    if @settings.mode == 'local'
      pane = atom.workspace.getActivePane()
      return null if not pane

      tabList = @tabLists[pane.id]
      if tabList is undefined
        @tabLists[pane.id] = tabList = new TabList(pane)
        pane.onDidDestroy =>
          delete @tabLists[pane.id]

      tabList
    else
      @tabLists[0] ?= new TabList(atom.workspace)

  destroyLists: ->
    for paneId, tabList of @tabLists
      tabList.destroy()

  serialize: ->
    state = {version: 1}
    if @settings.mode == 'local'
      state.panes = atom.workspace.getPanes().map (pane) =>
        tabList = @tabLists[pane.id]
        if tabList then tabList.serialize() else null
    else
      state.workspace = @tabLists[0]?.serialize?()
    state

  deserialize: (state) ->
    return if state.version != 1
    # Note: deserialize is called before activate, so @settings is undefined.
    if atom.config.get('tab-switcher.mode') == 'local'
      panes = atom.workspace.getPanes()
      for paneState, i in (state.panes ? [])
        pane = panes[i]
        continue if paneState is null or pane is undefined
        @tabLists[pane.id] = new TabList(pane, paneState, state.version)
    else
      if state.workspace
        @tabLists[0] = new TabList(atom.workspace, state.workspace, state.version)

  settingsUpdated: (settings) ->
    @settings = settings
    for id, tabList of @tabLists
      tabList.settingsUpdated(settings)

TabSwitcher.reset()

module.exports =
  TabSwitcher: TabSwitcher
  TabList: TabList
  TabListView: TabListView

  config:
    fadeInDelay:
      title: 'Pause before displaying tab switcher, in seconds (default: 0)'
      description: 'Increasing this can reduce flicker when switching quickly.'
      type: 'number'
      default: 0
    mode:
      title: 'Mode'
      type: 'string'
      default: 'local'
      enum: ['local', 'global', 'tabless']

  activate: (state) ->
    @disposable = new CompositeDisposable

    @disposable.add atom.commands.add 'atom-workspace',
      'tab-switcher:next': -> TabSwitcher.currentList()?.next()
      'tab-switcher:previous': -> TabSwitcher.currentList()?.previous()
      'tab-switcher:save': -> TabSwitcher.currentList()?.saveCurrent()
      'tab-switcher:close': -> TabSwitcher.currentList()?.closeCurrent()

    if state?.version
      TabSwitcher.deserialize(state)

    @disposable.add atom.config.onDidChange 'tab-switcher.fadeInDelay', ->
      TabSwitcher.settingsUpdated atom.config.get('tab-switcher')

    @disposable.add atom.config.onDidChange 'tab-switcher.mode', ->
      TabSwitcher.settingsUpdated atom.config.get('tab-switcher')

    TabSwitcher.settingsUpdated atom.config.get('tab-switcher')

  deactivate: ->
    @disposable.dispose()
    TabSwitcher.destroyLists()

  serialize: ->
    TabSwitcher.serialize()
