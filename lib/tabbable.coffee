{CompositeDisposable, Pane} = require 'atom'
TabListView = require './tab-list-view'

module.exports =
class Tabbable
  constructor: (paneOrWorkspace) ->
    if paneOrWorkspace is atom.workspace
      @workspace = paneOrWorkspace
    else
      @pane = paneOrWorkspace

  getPanes: ->
    if @workspace then @workspace.getPanes() else [@pane]

  getItems: ->
    @getPanes().map (pane) =>
      pane.getItems().map (item) =>
        [pane, item]
    .reduce ((result, pairs) -> result.concat(pairs)), []

  onDidDestroy: (callback) ->
    if @pane
      @pane.onDidDestroy(callback)
    else
      new CompositeDisposable

  onDidAddItem: (callback) ->
    if @workspace
      @workspace.onDidAddPaneItem (event) =>
        callback(event.pane, event.item)
    else
      @pane.onDidAddItem (event) =>
        callback(@pane, event.item)

  onWillRemoveItem: (callback) ->
    if @workspace
      disposable = new CompositeDisposable
      disposable.add @workspace.observePanes (pane) ->
        subscription = pane.onWillRemoveItem (event) ->
          callback(pane, event.item)

        disposable.add subscription
        disposable.add pane.onDidDestroy (event) -> disposable.remove(subscription)
      disposable
    else
      @pane.onWillRemoveItem (event) =>
        callback(@pane, event.item)

  onDidRemoveItem: (callback) ->
    if @workspace
      @workspace.onDidDestroyPaneItem (event) =>
        callback(event.pane, event.item)
    else
      @pane.onDidRemoveItem (event) =>
        callback(@pane, event.item)

  observeActiveItem: (callback) ->
    disposable = new CompositeDisposable

    if @workspace
      @getPanes().forEach (pane) ->
        disposable.add pane.onDidChangeActiveItem (item) ->
          if atom.workspace.getActivePane() is pane
            callback(pane, item)
      @workspace.onDidChangeActivePane (pane) ->
        item = pane.getActiveItem()
        callback(pane, pane.getActiveItem()) if item

      pane = atom.workspace.getActivePane()
    else
      disposable.add @pane.onDidChangeActiveItem (item) =>
        callback(@pane, item) if item

      pane = @pane

    activeItem = pane.getActiveItem()
    callback(pane, activeItem) if activeItem
    disposable

  observeItems: (callback) ->
    if @workspace
      @workspace.observePaneItems(callback)
    else
      @pane.observeItems(callback)

  removeTab: (pane, item) ->
    pane.removeItem(item)

  activateItem: (pane, item) ->
    pane.activateItem(item)
    pane.activate()
