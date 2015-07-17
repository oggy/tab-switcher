Path = require 'path'
{CompositeDisposable, TextEditor} = require 'atom'

makeElement = (name, attributes, children) ->
  element = document.createElement(name)
  for name, value of attributes
    element.setAttribute(name, value)
  if children
    for child in children
      element.appendChild(child)
  return element

home = if process.platform == 'win32' then process.env.USERPROFILE else process.env.HOME

isUnder = (dir, path) ->
  Path.relative(path, dir).startsWith('..')

projectRelativePath = (path) ->
  path = Path.dirname(path)
  [root, relativePath] = atom.project.relativizePath(path)
  if root
    if atom.project.getPaths().length > 1
      relativePath = Path.basename(root) + Path.sep + relativePath
    relativePath
  else if home and isUnder(home, path)
    '~' + Path.sep + Path.relative(home, path)
  else
    path

class TabListView
  constructor: (tabSwitcher) ->
    @tabSwitcher = tabSwitcher
    @disposable = new CompositeDisposable
    @items = {}
    @currentItem = null

    for tab in tabSwitcher.tabs
      @items[tab.id] = @_makeItem(tab)

    @ol = makeElement('ol', 'class': 'tab-switcher-tab-list', 'tabindex': '-1')
    vert = makeElement('div', {'class': 'vertical-axis'}, [@ol])

    @_buildList()

    @modalPanel = atom.workspace.addModalPanel
      item: vert
      visible: false
      className: 'tab-switcher'
    @panel = vert.parentNode

    @disposable.add @ol.addEventListener 'mouseover', (event) =>
      if (li = event.target.closest('li'))
        id = parseInt(li.getAttribute('data-id'))
        tabSwitcher.setCurrentId(id)

    @disposable.add @ol.addEventListener 'click', (event) =>
      if (li = event.target.closest('li'))
        id = parseInt(li.getAttribute('data-id'))
        tabSwitcher.select(id)

  updateAnimationDelay: (delay) ->
    console.log 'updating animation delay', delay
    if delay == 0
      @panel.style.transitionDelay = ''
    else
      @panel.style.transitionDelay = "#{delay}s"

  tabAdded: (tab) ->
    @items[tab.id] = @_makeItem(tab)
    @_buildList()

  tabRemoved: (tab) ->
    delete @items[tab.id]
    @_buildList()

  tabsReordered: ->
    @_buildList()

  currentTabChanged: (tab) ->
    if @currentItem
      @currentItem.classList.remove('current')
    if tab
      @currentItem = @items[tab.id]
      @currentItem.classList.add('current')
      @scrollToCurrentTab()

  destroy: ->
    @modalPanel.destroy()
    @disposable.dispose()

  show: ->
    @scrollToCurrentTab()
    panel = @ol.closest('atom-panel')
    @modalPanel.show()
    @ol.focus()
    setTimeout => @panel.classList.add('is-visible')

    invokeSelect = (event) =>
      if not (event.ctrlKey or event.altKey or event.shiftKey or event.metaKey)
        @tabSwitcher.select()
        unbind()

    invokeCancel = (event) =>
      @tabSwitcher.cancel()
      unbind()

    document.addEventListener 'keyup', invokeSelect
    document.addEventListener 'mouseup', invokeSelect
    @ol.addEventListener 'blur', invokeCancel

    unbind = =>
      document.removeEventListener 'keyup', invokeSelect
      document.removeEventListener 'mouseup', invokeSelect
      @ol.removeEventListener 'blur', invokeCancel

  scrollToCurrentTab: ->
    if (currentTab = @tabSwitcher.tabs[@tabSwitcher.currentIndex])
      view = @items[currentTab.id]
      offset = view.offsetTop - (@ol.clientHeight - view.offsetHeight)/2
      @ol.scrollTop = Math.max(offset, 0)

  hide: ->
    @panel.classList.remove('is-visible')
    @modalPanel.hide()

  _makeItem: (tab) ->
    tab.isEditor = tab.item.constructor == TextEditor
    tab.modifiedIcon = makeElement('span', {class: 'modified-icon'})
    label = makeElement('span', {class: 'tab-label'}, [document.createTextNode(tab.item.getTitle())])

    if tab.isEditor
      toggleModified = ->
        action = if tab.item.isModified() then 'add' else 'remove'
        label.classList[action]('modified')
      @disposable.add tab.item.onDidChangeModified(toggleModified)
      toggleModified()
      path = tab.item.getPath()
      icon = makeElement('span', {class: 'icon icon-file-text', 'data-name': Path.extname(path)})
      dir = if path then projectRelativePath(path) else ''
      sublabelText = document.createTextNode(dir)
      sublabel = makeElement('span', {class: 'tab-sublabel'}, [sublabelText])
      labels = makeElement('span', {class: 'tab-labels'}, [tab.modifiedIcon, label, sublabel])
    else
      icon = makeElement('span', {class: 'icon icon-tools'})
      labels = label

    makeElement('li', {'data-id': tab.id}, [icon, labels])

  _buildList: ->
    while @ol.children.length > 0
      @ol.removeChild(@ol.children[0])
    for tab in @tabSwitcher.tabs
      @ol.appendChild(@items[tab.id])

module.exports = TabListView
