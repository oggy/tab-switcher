{TabSwitcher,TabList} = require '../lib/tab-switcher'

describe "TabSwitcher", ->
  beforeEach ->
    waitsForPromise ->
      atom.workspace.open().then (editor) =>
        # Instantiating a tab list view requires this.
        atom.views.getView(atom.workspace)

        TabSwitcher.reset()

  describe ".currentList", ->
    describe "in local mode", ->
      beforeEach ->
        atom.config.set('tab-switcher.global', false)

      it "returns a tab list for the pane in local mode", ->
        pane1 = atom.workspace.getActivePane()
        pane2 = pane1.splitRight()

        tabList = TabSwitcher.currentList()
        expect(tabList.tabbable.pane).toBe(pane2)

      it "returns the same tab list if called again", ->
        tabList1 = TabSwitcher.currentList()
        tabList2 = TabSwitcher.currentList()
        expect(tabList1).toBe(tabList2)

    describe "in global mode", ->
      beforeEach ->
        atom.config.set('tab-switcher.global', true)

      it "returns the global tab list", ->
        tabList = TabSwitcher.currentList()
        expect(tabList.tabbable.workspace).toBe(atom.workspace)

      it "returns the same tab list if called again", ->
        tabList1 = TabSwitcher.currentList()
        tabList2 = TabSwitcher.currentList()
        expect(tabList1).toBe(tabList2)

  describe "serialize", ->
    describe "in local mode", ->
      beforeEach ->
        atom.config.set('tab-switcher.global', false)

      it "serializes tab lists for each pane", ->
        pane1 = atom.workspace.getActivePane()
        pane1TabList = TabSwitcher.currentList()
        pane2 = pane1.splitRight()
        pane2TabList = TabSwitcher.currentList()

        data = TabSwitcher.serialize()
        expect(data.version).toEqual 1
        expect(data.workspace).toBeUndefined()
        expect(data.panes.length).toEqual 2
        expect(data.panes[0]).toEqual(pane1TabList.serialize())
        expect(data.panes[1]).toEqual(pane2TabList.serialize())

      it "serializes uninstantiated tab lists as null", ->
        pane1 = atom.workspace.getActivePane()
        pane2 = pane1.splitRight()
        pane2TabList = TabSwitcher.currentList()

        data = TabSwitcher.serialize()
        expect(data.panes[0]).toBeNull()
        expect(data.panes[1]).not.toBeNull()

    describe "in global mode", ->
      beforeEach ->
        atom.config.set('tab-switcher.global', true)

      it "serializes a single global tab list", ->
        pane1 = atom.workspace.getActivePane()
        pane2 = pane1.splitRight()
        tabList = TabSwitcher.currentList()

        data = TabSwitcher.serialize()
        expect(data.version).toEqual 1
        expect(data.workspace).toEqual(tabList.serialize())
        expect(data.panes).toBeUndefined()

    describe "after switching from global to local mode", ->
      beforeEach ->
        atom.config.set('tab-switcher.global', true)
        TabSwitcher.currentList()
        atom.config.set('tab-switcher.global', false)
        TabSwitcher.currentList()

      it "serializes local tab lists only", ->
        data = TabSwitcher.serialize()
        expect(data.hasOwnProperty('panes')).toBe(true)
        expect(data.hasOwnProperty('workspace')).toBe(false)

    describe "after switching from local to global mode", ->
      beforeEach ->
        atom.config.set('tab-switcher.global', false)
        TabSwitcher.currentList()
        atom.config.set('tab-switcher.global', true)
        TabSwitcher.currentList()

      it "serializes the global tab list only", ->
        data = TabSwitcher.serialize()
        expect(data.hasOwnProperty('panes')).toBe(false)
        expect(data.hasOwnProperty('workspace')).toBe(true)

  describe "deserialize", ->
    beforeEach ->
      @originalMode = atom.config.get('tab-switcher.mode')

    afterEach ->
      atom.config.set('tab-switcher.mode', @originalMode)

    describe "when tab lists were serialized in local mode", ->
      beforeEach ->
        atom.config.set('tab-switcher.global', false)
        pane1 = atom.workspace.getActivePane()
        @pane1Id = pane1.id
        @tabList1Data = TabSwitcher.currentList().serialize()
        pane2 = pane1.splitRight()
        @pane2Id = pane2.id
        @tabList2Data = TabSwitcher.currentList().serialize()
        @data = TabSwitcher.serialize()
        TabSwitcher.reset()

      it "restores tab lists if still in local mode", ->
        atom.config.set('tab-switcher.global', false)
        TabSwitcher.deserialize(@data)
        expect(Object.getOwnPropertyNames(TabSwitcher.tabLists)).
          toEqual([@pane1Id.toString(), @pane2Id.toString()])
        expect(TabSwitcher.tabLists[@pane1Id].serialize()).toEqual(@tabList1Data)
        expect(TabSwitcher.tabLists[@pane2Id].serialize()).toEqual(@tabList2Data)

      it "does not restore lists if in global mode", ->
        atom.config.set('tab-switcher.global', true)
        TabSwitcher.deserialize(@data)
        expect(Object.getOwnPropertyNames(TabSwitcher.tabLists)).toEqual([])

    describe "when tab lists were serialized in global mode", ->
      beforeEach ->
        atom.config.set('tab-switcher.global', true)
        pane1 = atom.workspace.getActivePane()
        pane2 = pane1.splitRight()
        @tabListData = TabSwitcher.currentList().serialize()
        @data = TabSwitcher.serialize()
        TabSwitcher.reset()

      it "restores the tab list if still in global mode", ->
        atom.config.set('tab-switcher.global', true)
        TabSwitcher.deserialize(@data)
        expect(Object.getOwnPropertyNames(TabSwitcher.tabLists)).toEqual(['0'])
        expect(TabSwitcher.tabLists[0].serialize()).toEqual(@tabListData)

      it "does not restore lists if in local mode", ->
        atom.config.set('tab-switcher.global', false)
        TabSwitcher.deserialize(@data)
        expect(Object.getOwnPropertyNames(TabSwitcher.tabLists)).toEqual([])
