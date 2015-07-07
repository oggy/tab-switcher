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
    disposable = new CompositeDisposable
    @getPanes().forEach (pane) ->
      disposable.add pane.onDidAddItem (item) =>
        callback(pane, item.item)
    disposable

  onWillRemoveItem: (callback) ->
    disposable = new CompositeDisposable
    @getPanes().forEach (pane) ->
      disposable.add pane.onWillRemoveItem (item) =>
        callback(pane, item.item)
    disposable

  onDidRemoveItem: (callback) ->
    disposable = new CompositeDisposable
    @getPanes().forEach (pane) ->
      disposable.add pane.onDidRemoveItem (item) ->
        callback(pane, item.item)

      disposable.add pane.onDidDestroy ->
        pane.getItems().forEach (item) ->
          callback(pane, item)
    disposable

  observeActiveItem: (callback) ->
    disposable = new CompositeDisposable

    if @workspace
      @getPanes().forEach (pane) ->
        disposable.add pane.onDidChangeActiveItem (item) ->
          if atom.workspace.getActivePane() is pane
            callback(pane, item)
      @workspace.onDidChangeActivePane (pane) ->
        callback(pane, pane.getActiveItem())
    else
      disposable.add @pane.onDidChangeActiveItem (item) =>
        callback(@pane, item)

    activePane = atom.workspace.getActivePane()
    callback(activePane, activePane.getActiveItem())
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
