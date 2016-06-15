# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.


describe 'TabSwitcher', ->
  activeItemTitle = -> atom.workspace.getActivePane().getActiveItem().getTitle()
  dispatchCommand = (cmd) -> atom.commands.dispatch(atom.views.getView(atom.workspace), cmd)
  internalListTitles = -> (tabSwitcher.currentList().tabs[n].item.getTitle() for n in [0..3]).join(' ')
  atomTabTitles = -> (atom.workspace.getActivePane().itemAtIndex(n).getTitle() for n in [0..3]).join(' ')

  tabSwitcher = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = null

    runs ->
      activationPromise = atom.packages.activatePackage('tab-switcher')
      dispatchCommand('tab-switcher:next')
      dispatchCommand('tab-switcher:cancel')
      jasmine.attachToDOM(workspaceElement)

    waitsForPromise ->
      activationPromise.then ->
        tabSwitcher = atom.packages.getActivePackage('tab-switcher').mainModule

    waitsForPromise ->
      atom.workspace.open('E1').then ->
        atom.workspace.open('E2').then ->
          atom.workspace.open('E3').then ->
            atom.workspace.open('E4')

  afterEach ->
    atom.workspace.getActivePane().destroyItems()

  describe 'when activated the package', ->
    it 'looks stuff is ready to go', ->
      expect(atom.packages.isPackageActive('tab-switcher')).toBe true

  describe 'pane item selection command', ->
    it 'changes active item in pane to next list item', ->
      expect(activeItemTitle()).toBe 'E4'
      dispatchCommand('tab-switcher:next')
      dispatchCommand('tab-switcher:next')
      dispatchCommand('tab-switcher:next')
      dispatchCommand('tab-switcher:select')
      expect(activeItemTitle()).toBe 'E1'

    it 'changes active item in pane to previous list item', ->
      expect(activeItemTitle()).toBe 'E4'
      dispatchCommand('tab-switcher:previous')
      dispatchCommand('tab-switcher:previous')
      dispatchCommand('tab-switcher:previous')
      dispatchCommand('tab-switcher:select')
      expect(activeItemTitle()).toBe 'E3'

    it 'does not change when cancelled', ->
      expect(activeItemTitle()).toBe 'E4'
      dispatchCommand('tab-switcher:previous')
      dispatchCommand('tab-switcher:previous')
      dispatchCommand('tab-switcher:next')
      dispatchCommand('tab-switcher:cancel')
      expect(activeItemTitle()).toBe 'E4'

  describe 'reorder list', ->
    it 'moves item to a head of the internal list when activated', ->
      expect(activeItemTitle()).toBe 'E4'
      atom.workspace.getActivePane().activateItemAtIndex(0)
      expect(internalListTitles()).toBe 'E1 E4 E3 E2'

  describe 'UI check', ->
    modalPanel = null

    beforeEach ->
      atom.config.set('tab-switcher.fadeInDelay', 0.1)
      modalPanel = atom.workspace.getModalPanels().filter((item) -> item.className == 'tab-switcher')[0]

    it 'makes popup ready', ->
      nodeList = workspaceElement.querySelectorAll('atom-panel.modal.tab-switcher')
      expect(nodeList).toBeInstanceOf(NodeList)
      expect(nodeList.item(0)).not.toBeNull()

    it 'pops modal panel up/down (next, select)', ->
      expect(modalPanel.isVisible()).toBe false
      dispatchCommand('tab-switcher:next')
      advanceClock(150)
      expect(modalPanel.isVisible()).toBe true
      dispatchCommand('tab-switcher:select')
      expect(modalPanel.isVisible()).toBe false
      dispatchCommand('tab-switcher:next')
      dispatchCommand('tab-switcher:next')
      advanceClock(150)
      expect(modalPanel.isVisible()).toBe true
      dispatchCommand('tab-switcher:select')
      expect(modalPanel.isVisible()).toBe false

    it 'pops modal panel up/down (prev, cancel)', ->
      expect(modalPanel.isVisible()).toBe false
      dispatchCommand('tab-switcher:previous')
      advanceClock(150)
      expect(modalPanel.isVisible()).toBe true
      dispatchCommand('tab-switcher:cancel')
      expect(modalPanel.isVisible()).toBe false
      dispatchCommand('tab-switcher:previous')
      dispatchCommand('tab-switcher:previous')
      advanceClock(150)
      expect(modalPanel.isVisible()).toBe true
      dispatchCommand('tab-switcher:cancel')
      expect(modalPanel.isVisible()).toBe false

  describe 'tab order synchronization', ->
    it "does reflect the internal list to atom tabs", (done) ->
      atom.config.set('tab-switcher.reorderTabs', true)

      atom.workspace.getActivePane().activateItemAtIndex(n) for n in [0..3]
      setTimeout (->
        expect(internalListTitles()).toBe 'E4 E3 E2 E1'
        expect(atomTabTitles()).toBe 'E4 E3 E2 E1'
        atom.workspace.getActivePane().activateItemAtIndex(3)
        expect(internalListTitles()).toBe 'E1 E4 E3 E2'
        expect(atomTabTitles()).toBe 'E1 E4 E3 E2'
        done()
      ), 0

    it "does NOT reflect the internal list to atom tabs", (done) ->
      atom.config.set('tab-switcher.reorderTabs', false)
      oldAtomTabTitles = atomTabTitles()
      atom.workspace.getActivePane().activateItemAtIndex(0)
      expect(internalListTitles()).toBe 'E1 E4 E3 E2'
      expect(atomTabTitles()).toBe oldAtomTabTitles
