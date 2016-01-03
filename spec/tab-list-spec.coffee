{TabSwitcher, TabList} = require '../lib/tab-switcher'
{matchers} = require './helpers'

describe "TabSwitcher", ->
  makeTabList = (numItems) ->
    pane = atom.workspace.getActivePane()
    if numItems == 0
      pane.removeItem(pane.getItems()[0])
    else
      for i in [1...numItems]
        item = atom.workspace.buildTextEditor()
        pane.addItem(item, 1)
    new TabList(pane)

  beforeEach ->
    @addMatchers(matchers)
    atom.views.getView(atom.workspace)  # So TabListView can be attached
    waitsForPromise ->
      atom.workspace.open().then (editor) =>
        TabSwitcher.reset()

  describe "constructor", ->
    beforeEach ->
      @tabList = makeTabList(2)
      @pane = @tabList.tabbable.pane
      [@item0, @item1] = @pane.getItems()
      spyOn(@item0, "getTitle").andReturn("Item 1")
      spyOn(@item1, "getTitle").andReturn("Item 2")

    it "creates a tab list with entries for each current tab", ->
      expect(@tabList.tabs.length).toEqual(2)
      expect((tab.pane for tab in @tabList.tabs)).toEqualById([@pane, @pane])
      expect((tab.item for tab in @tabList.tabs)).toEqualById([@item0, @item1])

    it "adds newly added items to the back of the list", ->
      newItem = atom.workspace.buildTextEditor()
      spyOn(newItem, "getTitle").andReturn("Item 3")
      @pane.addItem(newItem, 0)
      expect(@tabList.tabs.length).toEqual(3)
      expect(@tabList.tabs[2].item).toEqualById(newItem)

    it "removes items from the list when they're removed from the tabbable", ->
      @pane.removeItem(@item0)
      expect(@tabList.tabs.length).toEqual(1)
      expect((tab.item for tab in @tabList.tabs)).toEqual([@item1])

    it "moves items to the front when they're activated", ->
      @pane.activateItem(@item1)
      expect((tab.item for tab in @tabList.tabs)).toEqual([@item1, @item0])

  describe "next", ->
    describe "for an empty TabList", ->
      beforeEach ->
        @tabList = makeTabList(0)
        @pane = @tabList.tabbable.pane

      it "does not set a current index", ->
        expect(@tabList.currentIndex).toBe(null)
        @tabList.next()
        expect(@tabList.currentIndex).toBe(null)

    describe "for a nonempty TabList", ->
      beforeEach ->
        @tabList = makeTabList(3)
        @pane = @tabList.tabbable.pane

      it "cycles forward through tabs, starting at 1", ->
        expect(@tabList.currentIndex).toBe(null)

        @tabList.next()
        expect(@tabList.currentIndex).toBe(1)

        @tabList.next()
        expect(@tabList.currentIndex).toBe(2)

        @tabList.next()
        expect(@tabList.currentIndex).toBe(0)

        @tabList.next()
        expect(@tabList.currentIndex).toBe(1)

  describe "previous", ->
    describe "for an empty TabList", ->
      beforeEach ->
        @tabList = makeTabList(0)
        @pane = @tabList.tabbable.pane

      it "does not set a current index", ->
        expect(@tabList.currentIndex).toBe(null)
        @tabList.previous()
        expect(@tabList.currentIndex).toBe(null)

    describe "for a nonempty TabList", ->
      beforeEach ->
        @tabList = makeTabList(3)
        @pane = @tabList.tabbable.pane

      it "cycles backward through tabs, starting at the last one", ->
        expect(@tabList.currentIndex).toBe(null)

        @tabList.previous()
        expect(@tabList.currentIndex).toBe(2)

        @tabList.previous()
        expect(@tabList.currentIndex).toBe(1)

        @tabList.previous()
        expect(@tabList.currentIndex).toBe(0)

        @tabList.previous()
        expect(@tabList.currentIndex).toBe(2)

  describe "setCurrentId", ->
    it "does not set a current index if the id is exist", ->
      @tabList = makeTabList(0)
      @pane = @tabList.tabbable.pane
      expect(@tabList.currentIndex).toBe(null)
      @tabList.setCurrentId(1)
      expect(@tabList.currentIndex).toBe(null)

    it "sets the current item to the one with the given id", ->
      @tabList = makeTabList(3)
      @pane = @tabList.tabbable.pane
      expect(@tabList.currentIndex).toBe(null)
      @tabList.setCurrentId(@tabList.tabs[2].id)
      expect(@tabList.currentIndex).toBe(2)

    it "does nothing if there is no item with the given id", ->
      @tabList = makeTabList(3)
      @pane = @tabList.tabbable.pane
      expect(@tabList.currentIndex).toBe(null)
      maxId = (tab.id for tab in @tabList.tabs)
      @tabList.setCurrentId(maxId + 1)
      expect(@tabList.currentIndex).toBe(null)

  describe "saveCurrent", ->
    beforeEach ->
      @tabList = makeTabList(2)
      @pane = @tabList.tabbable.pane
      @items = @pane.getItems()
      @spies = (spyOn(item, "save") for item in @items)

    it "saves the current item if possible", ->
      @tabList.setCurrentId(2)
      @tabList.saveCurrent()
      expect(@spies[1]).toHaveBeenCalled()

    it "doesn't save the item if it doesn't have a save method", ->
      @tabList.setCurrentId(2)
      delete @items[1].save
      expect(@spies[1]).not.toHaveBeenCalled()

    it "does nothing if there is no current item", ->
      @tabList.saveCurrent()
      expect(@spies[0]).not.toHaveBeenCalled()
      expect(@spies[1]).not.toHaveBeenCalled()

  describe "closeCurrent", ->
    it "removes the current item from the tabbable", ->
      @tabList = makeTabList(3)
      @items = @tabList.tabbable.pane.getItems()

      @tabList.setCurrentId(2)
      @tabList.closeCurrent()

      items = (tab.item for tab in @tabList.tabs)
      expect(items).toEqualById([@items[0], @items[2]])

    it "does nothing if there are no items", ->
      @tabList = makeTabList(0)
      @tabList.closeCurrent()
      expect(@tabList.tabs.length).toEqual(0)

  describe "select", ->
    describe "in local mode", ->
      beforeEach ->
        @tabList = makeTabList(3)
        @pane = @tabList.tabbable.pane
        @items = @pane.getItems()

      it "activates the current item", ->
        expect(@pane.getActiveItem()).toEqualById(@items[0])
        @tabList.next()
        @tabList.select()
        expect(@pane.getActiveItem()).toEqualById(@items[1])

      it "clears the current item", ->
        @tabList.next()
        expect(@tabList.currentIndex).toBe(1)
        @tabList.select()
        expect(@tabList.currentIndex).toBe(null)

      it "does nothing if there is no current item", ->
        expect(@pane.getActiveItem()).toEqualById(@items[0])
        @tabList.select()
        expect(@pane.getActiveItem()).toEqualById(@items[0])

      it "moves the selected item to the top of the list", ->
        expect(@pane.getActiveItem()).toEqualById(@items[0])
        @tabList.next()
        @tabList.select()
        items = (tab.item for tab in @tabList.tabs)
        expect(items).toEqualById([@items[1], @items[0], @items[2]])

    describe "in global mode", ->
      beforeEach ->
        @pane1 = atom.workspace.getActivePane()
        @item1 = @pane1.getItems()[0]
        @pane2 = @pane1.splitRight()
        @item2 = atom.workspace.buildTextEditor()
        @pane2.addItem(@item2)
        atom.config.set('tab-switcher.global', true)
        @tabList = new TabList(atom.workspace)

        pairs = ([tab.pane, tab.item] for tab in @tabList.tabs)
        expect(pairs).toEqualById([[@pane2, @item2], [@pane1, @item1]])

      it "activates the pane of the current item if necessary", ->
        expect(atom.workspace.getActivePane()).toEqualById(@pane2)
        expect(@pane2.getActiveItem()).toEqualById(@item2)
        @tabList.next()
        @tabList.select()
        expect(atom.workspace.getActivePane()).toEqualById(@pane1)
        expect(@pane1.getActiveItem()).toEqualById(@item1)

  describe "cancel", ->
    beforeEach ->
      @tabList = makeTabList(2)
      @pane = @tabList.tabbable.pane

    it "it clears the current item", ->
      @tabList.next()
      expect(@tabList.currentIndex).toBe(1)
      @tabList.cancel()
      expect(@tabList.currentIndex).toBe(null)

    it "does not activate the current item", ->
      initialActiveItem = @pane.getActiveItem()
      expect(initialActiveItem).toEqualById(@pane.getItems()[0])

      @tabList.next()
      @tabList.cancel()
      expect(@pane.getActiveItem()).toEqualById(initialActiveItem)

    it "does not move the selected item to the top", ->
      initialTabIds = (tab.id for tab in @tabList.tabs)
      @tabList.next()
      @tabList.cancel()
      expect((tab.id for tab in @tabList.tabs)).toEqual(initialTabIds)
