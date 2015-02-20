RubiniusTerminalView = require './rubinius-terminal-view'
{CompositeDisposable} = require 'atom'
path = require 'path'

capitalize = (str)-> str[0].toUpperCase() + str[1..].toLowerCase()

module.exports = RubiniusTerminal =
  subscriptions: null
  terminalViews: []
  focusedTerminal: off

  config:
    autoRunCommand:
      type: 'string'; default: ''
    titleTemplate:
      type: 'string'; default: "Terminal ({{ bashName }})"
    scrollback:
      type: 'integer'; default: 1000
    cursorBlink:
      type: 'boolean'; default: yes
    shellArguments:
      type: 'string'
      default: do ({SHELL, HOME}=process.env) ->
        switch path.basename SHELL.toLowerCase()
          when 'bash' then "--init-file #{path.join HOME, '.bash_profile'}"
          when 'zsh'  then ""
          else ''
    colors:
      type: 'object'
      properties:
        normalBlack:
          type: 'color'; default: '#2e3436'
        normalRed:
          type: 'color'; default: '#cc0000'
        normalGreen:
          type: 'color'; default: '#4e9a06'
        normalYellow:
          type: 'color'; default: '#c4a000'
        normalBlue:
          type: 'color'; default: '#3465a4'
        normalPurple:
          type: 'color'; default: '#75507b'
        normalCyan:
          type: 'color'; default: '#06989a'
        normalWhite:
          type: 'color'; default: '#d3d7cf'
        brightBlack:
          type: 'color'; default: '#555753'
        brightRed:
          type: 'color'; default: '#ef2929'
        brightGreen:
          type: 'color'; default: '#8ae234'
        brightYellow:
          type: 'color'; default: '#fce94f'
        brightBlue:
          type: 'color'; default: '#729fcf'
        brightPurple:
          type: 'color'; default: '#ad7fa8'
        brightCyan:
          type: 'color'; default: '#34e2e2'
        brightWhite:
          type: 'color'; default: '#eeeeec'

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-rubinius-terminal:open': =>
        @newTerminal()

    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-rubinius-terminal:pipe-path': =>
        @pipeTerminal 'path'

    ['left', 'right', 'up', 'down'].forEach (direction) =>
      @subscriptions.add atom.commands.add 'atom-workspace',
        "atom-rubinius-terminal:split-#{direction}",
          @splitTerminal.bind this, direction

  getColors: ->
    {colors: {
      normalBlack, normalRed, normalGreen, normalYellow
      normalBlue, normalPurple, normalCyan, normalWhite
      brightBlack, brightRed, brightGreen, brightYellow
      brightBlue, brightPurple, brightCyan, brightWhite
    }} = atom.config.get('atom-rubinius-terminal')
    [
      normalBlack, normalRed, normalGreen, normalYellow
      normalBlue, normalPurple, normalCyan, normalWhite
      brightBlack, brightRed, brightGreen, brightYellow
      brightBlue, brightPurple, brightCyan, brightWhite
    ]

  createTerminalView: ->
    opts =
      runCommand    : atom.config.get 'atom-rubinius-terminal.autoRunCommand'
      shellArguments: atom.config.get 'atom-rubinius-terminal.shellArguments'
      titleTemplate : atom.config.get 'atom-rubinius-terminal.titleTemplate'
      cursorBlink   : atom.config.get 'atom-rubinius-terminal.cursorBlink'
      colors        : @getColors()

    terminalView = new RubiniusTerminalView opts
    terminalView.on 'remove', @handleRemoveTerminal.bind this

    @terminalViews.push? terminalView
    terminalView

  splitTerminal: (direction) ->
    terminalView = @createTerminalView()
    terminalView.on "click", => @focusedTerminal = terminalView
    direction = capitalize direction

    activePane = atom.workspace.getActivePane()
    activePane.rubiniusTerminalSplits or= {}

    pane = activePane["split#{direction}"] items: [terminalView]
    activePane.rubiniusTerminalSplits[direction] = pane
    @focusedTerminal = [pane, pane.items[0]]

  newTerminal: ->
    pane = atom.workspace.getActivePane()
    item = pane.addItem @createTerminalView()
    pane.activateItem item

  pipeTerminal: (action) ->
    editor = atom.workspace.getActiveEditor()
    stream = switch action
      when 'path'
        editor.getBuffer().file.path
      when 'selection'
        editor.getSelectedText()

    if stream and @focusedTerminal
      if Array.isArray @focusedTerminal
        [pane, item] = @focusedTerminal
        pane.activateItem item
      else
        item = @focusedTerminal

      item.pty.write stream.trim()
      item.term.focus()

  handleRemoveTerminal: (terminalView) ->
    @terminalViews.splice @terminalViews.indexOf(terminalView), 1

  deactivate: ->
    @terminalViews.forEach (view) -> view.deactivate()
    @subscriptions.dispose()

  serialize: ->
    terminalViewsState = @terminalViews().map (view) -> view.serialize()
    {terminalViews: terminalViewsState}
