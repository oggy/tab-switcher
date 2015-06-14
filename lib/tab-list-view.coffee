Path = require 'path'
{TextEditor} = require 'atom'

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
    icon = document.createElement('span')
    if tab.item.constructor == TextEditor
      icon.classList.add('icon', 'icon-file-text')
      icon.setAttribute('data-name', Path.extname(tab.item.getPath()))
      sublabel = document.createElement('span')
      sublabel.classList.add('sublabel')
      sublabel.innerText = Path.relative(atom.project.getPaths()[0], Path.dirname(tab.item.getPath()))
    else
      icon.classList.add('icon', 'icon-tools')
    label = document.createTextNode(tab.item.getTitle())
    li = document.createElement('li')
    li.appendChild(icon)
    li.appendChild(label)
    if sublabel
      li.appendChild(sublabel)
    tab.view = li

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
