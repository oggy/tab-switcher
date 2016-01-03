{TabSwitcher, TabList} = require '../lib/tab-switcher'
{matchers} = require './helpers'

describe "TabSwitcherView", ->
  beforeEach ->
    @addMatchers(matchers)
    atom.views.getView(atom.workspace)  # So TabListView can be attached
    waitsForPromise =>
      atom.workspace.open().then (editor) =>
        TabSwitcher.reset()

        @pane = atom.workspace.getActivePane()
        @pane.addItem(atom.workspace.buildTextEditor())
        @items = @pane.getItems()
        @tabList = new TabList(@pane)
        @panel = @tabList.view.panel

  afterEach: ->
    @tabList?.destroy()

  describe "constructor", ->
    beforeEach ->
      @tabList.destroy()
      @pathSpies = [
        spyOn(@items[0], 'getPath').andReturn('path/to/file0.txt')
        spyOn(@items[1], 'getPath').andReturn('path/to/file1.coffee')
      ]

    it "renders item names in an ordered list", ->
      @tabList = new TabList(@pane)
      @panel = @tabList.view.panel

      labels = @panel.querySelectorAll('ol li .tab-label')
      expect(labels[0].innerText).toEqual('file0.txt')
      expect(labels[1].innerText).toEqual('file1.coffee')

    it "renders directories as sublabels for text editors", ->
      @tabList = new TabList(@pane)
      @panel = @tabList.view.panel

      sublabels = @panel.querySelectorAll('li .tab-sublabel')
      expect(sublabels[0].innerText).toEqual('path/to')
      expect(sublabels[1].innerText).toEqual('path/to')

    it "replaces the home directory in the sublabel with '~'", ->
      @tabList = new TabList(@pane)
      @panel = @tabList.view.panel

      @pathSpies[0].andReturn("#{process.env.HOME}/file0.txt")
      @items[0].emitter.emit('did-change-title', @items[0].getTitle())
      sublabels = @panel.querySelectorAll('li .tab-sublabel')
      expect(sublabels[0].innerText).toEqual('~')

    it "replaces a dir under the home directory in the sublabel with '~/PATH'", ->
      @tabList = new TabList(@pane)
      @panel = @tabList.view.panel

      @pathSpies[0].andReturn("#{process.env.HOME}/a/b/file0.txt")
      @items[0].emitter.emit('did-change-title', @items[0].getTitle())
      sublabels = @panel.querySelectorAll('li .tab-sublabel')
      expect(sublabels[0].innerText).toEqual('~/a/b')

    it "renders and maintains modified icons", ->
      @tabList = new TabList(@pane)
      @panel = @tabList.view.panel

      lis = @panel.querySelectorAll('li')
      labels = @panel.querySelectorAll('li .tab-label')
      expect(@panel.querySelectorAll('li .modified-icon').length).toBe(2)

      expect(l.classList.contains('modified') for l in labels).toEqual([false, false])
      @items[0].insertText('x')  # This doesn't trigger the hook, so do manually.
      @items[0].getBuffer().emitter.emit('did-change-modified')
      expect(l.classList.contains('modified') for l in labels).toEqual([true, false])

    it "renders file type icons", ->
      @tabList = new TabList(@pane)
      @panel = @tabList.view.panel

      icons = @panel.querySelectorAll('li .icon.icon-file-text')
      expect(icons[0].getAttribute('data-name')).toEqual('.txt')
      expect(icons[1].getAttribute('data-name')).toEqual('.coffee')

  describe "when the tab list is activated", ->
    beforeEach ->
      expect(@panel.getModel().isVisible()).toBe(false)
      @tabList.next()
      expect(@tabList.currentIndex).toBe(1)

    it "shows the tab list", ->
      expect(@panel.getModel().isVisible()).toBe(true)

    it "maintains the 'current' class on the current item", ->
      lis = @panel.querySelectorAll('li')
      flags = (li.classList.contains('current') for li in lis)
      expect(flags).toEqual([false, true])

      @tabList.previous()
      flags = (li.classList.contains('current') for li in lis)
      expect(flags).toEqual([true, false])

    it "cancels selection if the list loses focus", ->
      event = new FocusEvent('blur', 'bubbles': true)
      @panel.querySelector('ol').dispatchEvent(event)

      expect(@panel.getModel().isVisible()).toBe(false)
      expect(@tabList.currentIndex).toBe(null)
      expect(@pane.getActiveItem()).toEqualById(@items[0])

    it "selects if all modifiers are released", ->
      event = new KeyboardEvent('keyup', 'bubbles': true)
      document.dispatchEvent(event)

      expect(@panel.getModel().isVisible()).toBe(false)
      expect(@tabList.currentIndex).toBe(null)
      expect(@pane.getActiveItem()).toEqualById(@items[1])

    it "does not select yet if any modifiers are still pressed", ->
      expect(@tabList.currentIndex).toBe(1)
      event = new KeyboardEvent('keyup', 'bubbles': true, 'altKey': true)
      document.dispatchEvent(event)

      expect(@panel.getModel().isVisible()).toBe(true)
      expect(@tabList.currentIndex).toBe(1)
      expect(@pane.getActiveItem()).toEqualById(@items[0])

    it "sets an item current when moused over", ->
      @tabList.previous()
      expect(@tabList.currentIndex).toBe(0)
      event = new MouseEvent('mouseover', 'bubbles': true)
      @panel.querySelectorAll('li')[1].dispatchEvent(event)
      expect(@tabList.currentIndex).toBe(1)
      expect(@pane.getActiveItem()).toEqualById(@items[0])

    it "selects an item when clicked", ->
      @tabList.previous()
      expect(@tabList.currentIndex).toBe(0)
      event = new MouseEvent('click', 'bubbles': true)
      @panel.querySelectorAll('li')[1].dispatchEvent(event)
      expect(@tabList.currentIndex).toBe(null)
      expect(@pane.getActiveItem()).toEqualById(@items[1])

    it "does not set an item current on a second move event at the same coordinates", ->
      @tabList.previous()
      expect(@tabList.currentIndex).toBe(0)

      event = new MouseEvent('mouseover', 'bubbles': true, 'screenX': 1, 'screenY': 1)
      @panel.querySelectorAll('li')[1].dispatchEvent(event)
      expect(@tabList.currentIndex).toBe(1)

      @tabList.previous()
      expect(@tabList.currentIndex).toBe(0)

      event = new MouseEvent('mouseover', 'bubbles': true, 'screenX': 1, 'screenY': 1)
      @panel.querySelectorAll('li')[1].dispatchEvent(event)
      expect(@tabList.currentIndex).toBe(0)

    it "does set an item current on a second move event at different coordinates", ->
      @tabList.previous()
      expect(@tabList.currentIndex).toBe(0)

      event = new MouseEvent('mouseover', 'bubbles': true, 'screenX': 1, 'screenY': 1)
      @panel.querySelectorAll('li')[1].dispatchEvent(event)
      expect(@tabList.currentIndex).toBe(1)

      @tabList.previous()
      expect(@tabList.currentIndex).toBe(0)

      event = new MouseEvent('mouseover', 'bubbles': true, 'screenX': 1, 'screenY': 2)
      @panel.querySelectorAll('li')[1].dispatchEvent(event)
      expect(@tabList.currentIndex).toBe(1)

  it "shows the tab list when activated, until an item is selected", ->
    expect(@panel.getModel().isVisible()).toBe(false)
    @tabList.next()
    expect(@panel.getModel().isVisible()).toBe(true)
    @tabList.select()
    expect(@panel.getModel().isVisible()).toBe(false)

  describe "when a tab is added", ->
    it "adds the tab to the correct position in the list", ->
      @pane.addItem(atom.workspace.buildTextEditor(), 2)
      ids = (li.getAttribute('data-id') for li in @panel.querySelectorAll('li'))
      expect(ids).toEqual(['1', '2', '3'])

  describe "when a tab is removed", ->
    it "removes the tab from the list", ->
      @pane.removeItem(@items[0])
      ids = (li.getAttribute('data-id') for li in @panel.querySelectorAll('li'))
      expect(ids).toEqual(['2'])

  describe "when a tab is moved to the top", ->
    it "reorders the list according to the model", ->
      ids = (li.getAttribute('data-id') for li in @panel.querySelectorAll('li'))
      expect(ids).toEqual(['1', '2'])

      @tabList.next()
      @tabList.select()

      ids = (li.getAttribute('data-id') for li in @panel.querySelectorAll('li'))
      expect(ids).toEqual(['2', '1'])

  describe "when a file path changes", ->
    it "updates the label & sublabel", ->
      spy = spyOn(@items[0], 'getPath')

      spy.andReturn('path/to/file0.txt')
      @items[0].emitter.emit('did-change-title', @items[0].getTitle())

      label = @panel.querySelector('li[data-id="1"] .tab-label')
      sublabel = @panel.querySelector('li[data-id="1"] .tab-sublabel')
      expect(label.innerText).toEqual('file0.txt')
      expect(sublabel.innerText).toEqual('path/to')

      spy.andReturn('new/path/to/new-name.txt')
      @items[0].emitter.emit('did-change-title', @items[0].getTitle())

      label = @panel.querySelector('li[data-id="1"] .tab-label')
      sublabel = @panel.querySelector('li[data-id="1"] .tab-sublabel')
      expect(label.innerText).toEqual('new-name.txt')
      expect(sublabel.innerText).toEqual('new/path/to')
