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

class TabListView
  constructor: (tabSwitcher) ->
    @tabSwitcher = tabSwitcher
    @disposable = new CompositeDisposable
    @items = {}

    @ol = makeElement('ol', 'class': 'tab-switcher-tab-list', 'tabindex': '-1')
    vert = makeElement('div', {'class': 'vertical-axis'}, [@ol])

    @modalPanel = atom.workspace.addModalPanel(item: vert, visible: false)
    vert.closest('atom-panel').classList.add('tab-switcher')

    @disposable.add tabSwitcher.onDidAddTab (tab) =>
      @items[tab.id] = @_initializeTab(tab)

    @disposable.add tabSwitcher.onDidRemoveTab (tab) =>
      delete @items[tab.id]

  destroy: ->
    @modalPanel.destroy()
    @disposable.dispose()

  show: ->
    while @ol.children.length > 0
      @ol.removeChild(@ol.children[0])
    for tab, index in @tabSwitcher.tabs
      current = @tabSwitcher.currentIndex == index
      @items[tab.id].classList[if current then 'add' else 'remove']('current')
      @ol.appendChild(@items[tab.id])
    if (currentTab = @tabSwitcher.tabs[@tabSwitcher.currentIndex])
      view = @items[currentTab.id]
      offset = view.offsetTop - (@ol.clientHeight - view.offsetHeight)/2
      @ol.scrollTop = Math.max(offset, 0)
    panel = @ol.closest('atom-panel')
    @modalPanel.show()
    @ol.focus()

  hide: ->
    @modalPanel.hide()

  _initializeTab: (tab) ->
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
      dir = Path.relative(atom.project.getPaths()[0], Path.dirname(path))
      sublabelText = document.createTextNode(dir)
      sublabel = makeElement('span', {class: 'tab-sublabel'}, [sublabelText])
      labels = makeElement('span', {class: 'tab-labels'}, [tab.modifiedIcon, label, sublabel])
    else
      icon = makeElement('span', {class: 'icon icon-tools'})
      labels = label

    makeElement('li', {}, [icon, labels])

module.exports = TabListView
