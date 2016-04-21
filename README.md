# Tab Switcher

[Atom][atom] package that let's you easily and elegantly switch between your
most recently active tabs. Like "Command-TAB" or "Alt-TAB" for applications.

![Screenshot](https://raw.githubusercontent.com/oggy/tab-switcher/master/doc/tab-switcher.gif)

Visual design is inspired by [Witch](http://manytricks.com/witch), a slick Mac
OS window switcher.

[atom]: https://atom.io/

## Default Keys

* `alt-[` previous tab
* `alt-]` next tab

### Using different keys

You can specify alternate key bindings in `keymap.cson` (menu: Atom -> Keymap).
A popular desire is to replace the built-in `ctrl-tab` and `ctrl-shift-tab`.

```
"atom-workspace":
  "ctrl-tab": "tab-switcher:next"
  "ctrl-tab ^ctrl": "unset!"
  "ctrl-shift-tab": "tab-switcher:previous"
  "ctrl-shift-tab ^ctrl": "unset!"

"ol.tab-switcher-tab-list":
  "^ctrl": "tab-switcher:select"
  "^shift": "tab-switcher:select"
  "ctrl-up": "tab-switcher:previous"
  "ctrl-down": "tab-switcher:next"
  "ctrl-escape": "tab-switcher:cancel"
  "ctrl-n": "tab-switcher:next"
  "ctrl-p": "tab-switcher:previous"
  "ctrl-w": "tab-switcher:close"
  "ctrl-s": "tab-switcher:save"
```

## Icons

Icons are optional, and are provided by the [file-icons][file-icons] package.

[file-icons]: https://github.com/DanBrooker/file-icons

## Contributing

 * [Bug reports](https://github.com/oggy/tab-switcher/issues)
 * [Source](https://github.com/oggy/tab-switcher)
 * Patches: Fork on Github, send pull request.
   * Include tests where practical.
   * Leave the version alone, or bump it in a separate commit.

## Copyright

Copyright (c) George Ogata. See LICENSE for details.
