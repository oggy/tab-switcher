Path = require 'path'
{TextEditor} = require 'atom'

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

    @ol = document.createElement('ol')
    @ol.classList.add('tab-switcher-tab-list')

    @modalPanel = atom.workspace.addModalPanel(item: @ol, visible: false)
    @ol.closest('atom-panel').classList.add('tab-switcher-panel')

    for tab in @tabSwitcher.tabs
      @initializeTab(tab)

  destroy: ->
    @modalPanel.destroy()

  initializeTab: (tab) ->
    label = document.createTextNode(tab.item.getTitle())
    if tab.item.constructor == TextEditor
      path = tab.item.getPath()
      icon = makeElement('span', {class: 'icon icon-file-text', 'data-name': Path.extname(path)})
      dir = Path.relative(atom.project.getPaths()[0], Path.dirname(path))
      sublabelText = document.createTextNode(dir)
      sublabel = makeElement('span', {class: 'sublabel'}, [sublabelText])
      labels = makeElement('span', {class: 'labels'}, [label, sublabel])
    else
      icon = makeElement('span', {class: 'icon icon-tools'})
      labels = label
    tab.view = makeElement('li', {}, [icon, labels])

  show: ->
    while @ol.children.length > 0
      @ol.removeChild(@ol.children[0])
    for tab, index in @tabSwitcher.tabs
      selected = @tabSwitcher.selection == index
      tab.view.classList[if selected then 'add' else 'remove']('selected')
      @ol.appendChild(tab.view)
    panel = @ol.closest('atom-panel')
    @modalPanel.show()
    panel.style.height = @ol.offsetHeight + 'px'

  hide: ->
    @modalPanel.hide()

module.exports = TabListView
