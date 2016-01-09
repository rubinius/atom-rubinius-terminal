[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/rubinius/atom-rubinius-terminal)

# Rubinius Terminal

Opens a terminal tab or pane within Atom that is configured to run Rubinius.

The main objective is to provide the simplest way to try Rubinius by providing direct access to an isolated install of Rubinius that does not interfere with a system Ruby or another Ruby switcher.

Another objective is creating better integration between the terminal and the editor without re-implementing terminal features in the editor or editor features in the terminal.

**Note: this project is alpha-stage. It is being developed on OS X first, but will eventually support Linux and Windows as well. For outstanding work, see the [issues](https://github.com/rubinius/atom-rubinius-terminal/issues).**

The Rubinius Terminal installs a binary build of Rubinius. When a terminal tab or pane is opened, the shell instance is configured so that Rubinius is the active Ruby.

## Code of Conduct

Participation in this project is governed by the Rubinius [Code of Conduct](http://rubinius.com/code-of-conduct/).

## License

Rubinius Terminal is licensed under [Mozilla Public License, 2.0](https://www.mozilla.org/MPL/2.0/). See the LICENSE file.

## Thanks

Rubinius Terminal is heavily inspired by term2, term, and terminal. Thanks to the authors of those packages. The term.js library is used. The copyright notice for term.js is included in lib/vendor/term.js.
