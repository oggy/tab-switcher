{View} = require 'atom-space-pen-views'
{Tabbable, TabSwitcher} = require '../lib/tab-switcher'
{matchers} = require './helpers'

describe "Tabbable", ->
  class TestItem extends View
    @lastId: 0
    @content: -> @div ''

    constructor: ->
      @id = TestItem.lastId += 1
      super

  beforeEach ->
    @addMatchers(matchers)
    waitsForPromise ->
      atom.workspace.open().then (editor) ->
        atom.workspace.getActivePane().destroyItem(editor)
        # Instantiating a tab list view requires this.
        atom.views.getView(atom.workspace)
        TabSwitcher.reset()

    @pane1 = atom.workspace.getActivePane()
    @item1 = new TestItem
    @pane1.addItem(@item1)

    @pane2 = @pane1.splitRight()
    @item2 = new TestItem
    @pane2.addItem(@item2)

    @pane1.focus()

  describe "for a workspace", ->
    beforeEach ->
      @tabbable = new Tabbable(atom.workspace)

    describe "getItems", ->
      it "returns all items in the wrapped pane", ->
        expect(@tabbable.getItems()).toEqualById([[@pane1, @item1], [@pane2, @item2]])

    describe "onDidDestroy", ->
      it "does not fire when a pane is destroyed", ->
        numEvents = 0
        @tabbable.onDidDestroy -> ++numEvents
        @pane1.destroy()
        expect(numEvents).toEqual(0)

    describe "onDidAddItem", ->
      it "fires when an item is added to any pane", ->
        events = []
        @tabbable.onDidAddItem (pane, item) -> events.push([pane, item])
        item = new TestItem
        @pane1.addItem(item)
        expect(events).toEqualById([[@pane1, item]])

    describe "onWillRemoveItem", ->
      it "fires when an item is removed from any pane", ->
        events = []
        @tabbable.onWillRemoveItem (pane, item) -> events.push([pane, item])
        @pane1.removeItem(@item1)
        expect(events).toEqualById([[@pane1, @item1]])

      it "fires when a new item is removed from an existing pane", ->
        events = []
        @tabbable.onWillRemoveItem (pane, item) -> events.push([pane, item])
        newItem = new TestItem
        @pane1.addItem(newItem)
        @pane1.removeItem(newItem)
        expect(events).toEqualById([[@pane1, newItem]])

      it "fires when an item is removed from a new pane", ->
        events = []
        @tabbable.onWillRemoveItem (pane, item) -> events.push([pane, item])
        newPane = @pane2.splitRight()
        newItem = new TestItem
        newPane.addItem(newItem)
        newPane.removeItem(newItem)
        expect(events).toEqualById([[newPane, newItem]])

    describe "onDidRemoveItem", ->
      removeItem = (pane, item) ->
        # TODO: This won't fire if we remove the item without destroying it.
        # Probably never happens when wrapping a workspace, but not intuitive.
        pane.destroyItem(item)

      it "fires when an item is removed from any pane", ->
        events = []
        @tabbable.onDidRemoveItem (pane, item) -> events.push([pane, item])
        removeItem(@pane1, @item1)
        expect(events).toEqualById([[@pane1, @item1]])

      it "fires when a new item is removed from an existing pane", ->
        events = []
        @tabbable.onDidRemoveItem (pane, item) -> events.push([pane, item])
        newItem = new TestItem
        @pane1.addItem(newItem)
        removeItem(@pane1, newItem)
        expect(events).toEqualById([[@pane1, newItem]])

      it "fires when an existing item is removed from a new pane", ->
        events = []
        @tabbable.onDidRemoveItem (pane, item) -> events.push([pane, item])
        newPane = @pane2.splitRight()
        newItem = new TestItem
        newPane.addItem(newItem)
        removeItem(newPane, newItem)
        expect(events).toEqualById([[newPane, newItem]])

    describe "observeActiveItem", ->
      it "fires for the current active item", ->
        events = []
        @tabbable.observeActiveItem (pane, item) -> events.push([pane, item])
        expect(events).toEqualById([[@pane1, @item1]])

      it "does not fire immediately if there is no item in the active pane", ->
        events = []
        @pane1.destroyItem(@item1)
        @tabbable.observeActiveItem (pane, item) -> events.push([pane, item])
        expect(events).toEqualById([])

      it "does not fire immediately if there is no active pane", ->
        @pane1.destroy()
        @pane2.destroy()
        events = []
        @tabbable.observeActiveItem (pane, item) -> events.push([pane, item])
        expect(events).toEqualById([])

      it "fires once for existing items when activated", ->
        events = []
        @tabbable.observeActiveItem (pane, item) -> events.push([pane, item])
        @pane2.focus()
        expect(events).toEqualById([[@pane1, @item1], [@pane2, @item2]])

      it "fires once for new items in existing panes when activated", ->
        events = []
        @tabbable.observeActiveItem (pane, item) -> events.push([pane, item])
        expect(events).toEqualById([[@pane1, @item1]])

        newItem = new TestItem
        @pane1.addItem(newItem)
        @pane1.activateItem(newItem)
        expect(events).toEqualById([[@pane1, @item1], [@pane1, newItem]])

      it "fires once for items in new panes when activated", ->
        events = []
        @tabbable.observeActiveItem (pane, item) -> events.push([pane, item])
        newPane = @pane2.splitRight()
        @pane1.focus()
        events.splice(0)

        newItem = new TestItem
        newPane.addItem(newItem)
        newPane.focus()

        expect(events).toEqualById([[newPane, newItem]])

      it "does not fire when an empty pane is focused", ->
        events = []
        @tabbable.observeActiveItem (pane, item) -> events.push([pane, item])
        @pane2.destroyItem(@item2)
        events.splice(0)

        @pane2.focus()
        expect(events).toEqualById([])

      it "does not fire when the last item in a pane is destroyed", ->
        events = []
        @tabbable.observeActiveItem (pane, item) -> events.push([pane, item])
        events.splice(0)

        @pane1.destroyItem(@item2)
        expect(events).toEqualById([])

    describe "observeItems", ->
      it "fires once for every existing item in every pane", ->
        events = []
        @tabbable.observeItems (item) -> events.push(item)
        expect(events).toEqualById([@item1, @item2])

      it "fires once for every item added in any pane", ->
        events = []
        @tabbable.observeItems (item) -> events.push(item)
        events.splice(0)

        newItem1 = new TestItem
        @pane1.addItem(newItem1)
        newItem2 = new TestItem
        @pane2.addItem(newItem2)
        expect(events).toEqualById([newItem1, newItem2])

    describe "removeTab", ->
      it "removes the given item from its pane", ->
        @tabbable.removeTab(@pane1, @item1)
        expect(@pane1.getItems()).toEqualById([])

    describe "activateItem", ->
      it "activates the given pane and item", ->
        @tabbable.activateItem(@pane2, @item2)
        expect(atom.workspace.getActivePane()).toBe(@pane2)
        expect(atom.workspace.getActivePaneItem()).toBe(@item2)

  describe "for a pane", ->
    beforeEach ->
      @tabbable = new Tabbable(@pane1)

    describe "getItems", ->
      it "returns all items in the wrapped pane", ->
        expect(@tabbable.getItems()).toEqualById([[@pane1, @item1]])

    describe "onDidDestroy", ->
      it "fires when only the wrapped pane is destroyed", ->
        numEvents = 0
        @tabbable.onDidDestroy -> ++numEvents
        @pane1.destroy()
        expect(numEvents).toEqual(1)

        @pane2.destroy()
        expect(numEvents).toEqual(1)

    describe "onDidAddItem", ->
      it "fires when an item is added only to the wrapped pane", ->
        events = []
        @tabbable.onDidAddItem (pane, item) -> events.push([pane, item])
        newItem1 = new TestItem
        @pane1.addItem(newItem1)
        expect(events).toEqualById([[@pane1, newItem1]])

        newItem2 = new TestItem
        @pane2.addItem(newItem2)
        expect(events).toEqualById([[@pane1, newItem1]])

    describe "onWillRemoveItem", ->
      it "fires when an existing item is removed only from the wrapped pane", ->
        events = []
        @tabbable.onWillRemoveItem (pane, item) -> events.push([pane, item])
        @pane1.removeItem(@item1)
        expect(events).toEqualById([[@pane1, @item1]])

        @pane2.removeItem(@item2)
        expect(events).toEqualById([[@pane1, @item1]])

      it "fires when a new item is removed from the wrapped pane", ->
        events = []
        @tabbable.onWillRemoveItem (pane, item) -> events.push([pane, item])
        newItem = new TestItem
        @pane1.addItem(newItem)
        @pane1.removeItem(newItem)
        expect(events).toEqualById([[@pane1, newItem]])

    describe "onDidRemoveItem", ->
      it "fires when an existing item is removed only from the wrapped pane", ->
        events = []
        @tabbable.onDidRemoveItem (pane, item) -> events.push([pane, item])
        @pane1.removeItem(@item1)
        expect(events).toEqualById([[@pane1, @item1]])

        @pane2.addItem(@item2)
        expect(events).toEqualById([[@pane1, @item1]])

      it "fires when a new item is removed from the wrapped pane", ->
        events = []
        @tabbable.onDidRemoveItem (pane, item) -> events.push([pane, item])
        newItem = new TestItem
        @pane1.addItem(newItem)
        @pane1.removeItem(newItem)
        expect(events).toEqualById([[@pane1, newItem]])

    describe "observeActiveItem", ->
      it "fires for the current active item if the pane is active", ->
        events = []
        @tabbable.observeActiveItem (pane, item) -> events.push([pane, item])
        expect(events).toEqualById([[@pane1, @item1]])

      it "fires for the current active item if the pane is inactive", ->
        events = []
        @pane2.focus()
        @tabbable.observeActiveItem (pane, item) -> events.push([pane, item])
        expect(events).toEqualById([[@pane1, @item1]])

      it "does not fire immediately if there is no active item", ->
        events = []
        @pane1.destroyItem(@item1)
        @tabbable.observeActiveItem (pane, item) -> events.push([pane, item])
        expect(events).toEqualById([])

      it "fires once for existing items when activated", ->
        existingItem = new TestItem
        @pane1.addItem(existingItem)

        events = []
        @tabbable.observeActiveItem (pane, item) -> events.push([pane, item])
        @pane1.activateItem(existingItem)
        expect(events).toEqualById([[@pane1, @item1], [@pane1, existingItem]])

      it "fires once for new items when activated", ->
        events = []
        @tabbable.observeActiveItem (pane, item) -> events.push([pane, item])
        expect(events).toEqualById([[@pane1, @item1]])

        newItem = new TestItem
        @pane1.addItem(newItem)
        @pane1.activateItem(newItem)
        expect(events).toEqualById([[@pane1, @item1], [@pane1, newItem]])

      it "does not fire when the pane is focused when empty", ->
        events = []
        @pane1.destroyItem(@item1)
        @pane2.focus()

        @tabbable.observeActiveItem (pane, item) -> events.push([pane, item])
        events.splice(0)
        @pane1.focus()
        expect(events).toEqualById([])

      it "does not fire when the last item in the pane is destroyed", ->
        events = []
        @tabbable.observeActiveItem (pane, item) -> events.push([pane, item])
        events.splice(0)

        @pane1.destroyItem(@item1)
        expect(events).toEqualById([])

    describe "observeItems", ->
      it "fires once for every existing item in the pane", ->
        events = []
        @tabbable.observeItems (item) -> events.push(item)
        expect(events).toEqualById([@item1])

      it "fires once for every item added in the pane", ->
        events = []
        @tabbable.observeItems (item) -> events.push(item)
        events.splice(0)

        newItem1 = new TestItem
        @pane1.addItem(newItem1)
        newItem2 = new TestItem
        @pane2.addItem(newItem2)
        expect(events).toEqualById([newItem1])

    describe "removeTab", ->
      it "removes the given item from its pane", ->
        @tabbable.removeTab(@pane1, @item1)
        expect(@pane1.getItems()).toEqualById([])

    describe "activateItem", ->
      it "activates the given item", ->
        item3 = new TestItem
        @pane1.addItem(item3)
        @tabbable.activateItem(@pane1, item3)
        expect(atom.workspace.getActivePaneItem()).toBe(item3)
