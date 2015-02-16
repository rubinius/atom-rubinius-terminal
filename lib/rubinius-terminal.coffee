RubiniusTerminalView = require './rubinius-terminal-view'
{CompositeDisposable} = require 'atom'
path = require 'path'

capitalize = (str)-> str[0].toUpperCase() + str[1..].toLowerCase()

module.exports = RubiniusTerminal =
  subscriptions: null
  terminalViews: []
  focusedTerminal: off

  configDefaults:
    autoRunCommand: null
    titleTemplate: "Terminal ({{ bashName }})"
    colors:
      normalBlack : '#2e3436'
      normalRed   : '#cc0000'
      normalGreen : '#4e9a06'
      normalYellow: '#c4a000'
      normalBlue  : '#3465a4'
      normalPurple: '#75507b'
      normalCyan  : '#06989a'
      normalWhite : '#d3d7cf'
      brightBlack : '#555753'
      brightRed   : '#ef2929'
      brightGreen : '#8ae234'
      brightYellow: '#fce94f'
      brightBlue  : '#729fcf'
      brightPurple: '#ad7fa8'
      brightCyan  : '#34e2e2'
      brightWhite : '#eeeeec'

    scrollback: 1000
    cursorBlink: yes
    shellArguments: do ({SHELL, HOME}=process.env)->
      switch path.basename SHELL.toLowerCase()
        when 'bash' then "--init-file #{path.join HOME, '.bash_profile'}"
        when 'zsh'  then ""
        else ''
    openPanesInSameSplit: no

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-package:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'rubinius-terminal:open': => @newTerminal()
    ['left', 'right', 'top', 'bottom'].forEach (direction) =>
      @subscriptions.add atom.commands.add 'atom-workspace', "rubinius-terminal:split-#{direction}", @splitTerminal(direction)
    @subscriptions.add atom.commands.add 'atom-workspace', 'rubinius-terminal:pipe-path': => @pipeTerminal

    ###
    TODO: update to current CommandRegistry
    https://atom.io/docs/api/v0.176.0/CommandRegistry
    ['up', 'right', 'down', 'left'].forEach (direction)=>
      atom.workspaceView.command "rubinius-terminal:open-split-#{direction}", @splitTerm.bind(this, direction)

    atom.workspaceView.command "rubinius-terminal:open", @newTerm.bind(this)
    atom.workspaceView.command "rubinius-terminal:pipe-path", @pipeTerm.bind(this, 'path')
    atom.workspaceView.command "rubinius-terminal:pipe-selection", @pipeTerm.bind(this, 'selection')
    ###

  getColors: ->
    {colors: {
      normalBlack, normalRed, normalGreen, normalYellow
      normalBlue, normalPurple, normalCyan, normalWhite
      brightBlack, brightRed, brightGreen, brightYellow
      brightBlue, brightPurple, brightCyan, brightWhite
    }} = atom.config.get('rubinius-terminal')
    [
      normalBlack, normalRed, normalGreen, normalYellow
      normalBlue, normalPurple, normalCyan, normalWhite
      brightBlack, brightRed, brightGreen, brightYellow
      brightBlue, brightPurple, brightCyan, brightWhite
    ]

  createTerminalView:->
    opts =
      runCommand    : atom.config.get 'rubinius-terminal.autoRunCommand'
      shellArguments: atom.config.get 'rubinius-terminal.shellArguments'
      titleTemplate : atom.config.get 'rubinius-terminal.titleTemplate'
      cursorBlink   : atom.config.get 'rubinius-terminal.cursorBlink'
      colors        : @getColors()

    terminalView = new RubiniusTerminalView opts
    terminalView.on 'remove', @handleRemoveTerm.bind this

    @terminalViews.push? terminalView
    terminalView

  splitTerminal: (direction)->
    openPanesInSameSplit = atom.config.get 'rubinius-terminal.openPanesInSameSplit'
    terminalView = @createTerminalView()
    terminalView.on "click", => @focusedTerminal = terminalView
    direction = capitalize direction

    splitter = =>
      pane = activePane["split#{direction}"] items: [terminalView]
      activePane.rubiniusTerminalSplits[direction] = pane
      @focusedTerminal = [pane, pane.items[0]]

    activePane = atom.workspace.getActivePane()
    activePane.rubiniusTerminalSplits or= {}
    if openPanesInSameSplit
      if activePane.rubiniusTerminalSplits[direction] and activePane.rubiniusTerminalSplits[direction].items.length > 0
        pane = activePane.rubiniusTerminalSplits[direction]
        item = pane.addItem terminalView
        pane.activateItem item
        @focusedTerminal = [pane, item]
      else
        splitter()
    else
      splitter()

  newTerminal: ->
    terminalView = @createTerminalView()
    pane = atom.workspace.getActivePane()
    item = pane.addItem terminalView
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

  handleRemoveTerm: (terminalView) ->
    @terminalViews.splice @terminalViews.indexOf(terminalView), 1

  deactivate: ->
    @terminalViews.forEach (view)-> view.deactivate()
    @subscriptions.dispose()

  serialize: ->
    terminalViewsState = this.terminalViews.map (view)-> view.serialize()
    {terminalViews: terminalViewsState}
