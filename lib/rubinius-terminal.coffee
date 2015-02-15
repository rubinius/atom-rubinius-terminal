path = require 'path'
RubiniusTerminalView = require './rubinius-terminal-view'

capitalize = (str)-> str[0].toUpperCase() + str[1..].toLowerCase()

module.exports =

    rubiniusTerminalViews: []
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

    activate: (@state)->

      ['up', 'right', 'down', 'left'].forEach (direction)=>
        atom.workspaceView.command "rubinius-terminal:open-split-#{direction}", @splitTerm.bind(this, direction)

      atom.workspaceView.command "rubinius-terminal:open", @newTerm.bind(this)
      atom.workspaceView.command "rubinius-terminal:pipe-path", @pipeTerm.bind(this, 'path')
      atom.workspaceView.command "rubinius-terminal:pipe-selection", @pipeTerm.bind(this, 'selection')

    getColors: ->
      {colors: {
        normalBlack, normalRed, normalGreen, normalYellow
        normalBlue, normalPurple, normalCyan, normalWhite
        brightBlack, brightRed, brightGreen, brightYellow
        brightBlue, brightPurple, brightCyan, brightWhite
      }} = atom.config.getSettings().rubinius-terminal
      [
        normalBlack, normalRed, normalGreen, normalYellow
        normalBlue, normalPurple, normalCyan, normalWhite
        brightBlack, brightRed, brightGreen, brightYellow
        brightBlue, brightPurple, brightCyan, brightWhite
      ]

    createRubiniusTerminalView:->
      opts =
        runCommand    : atom.config.get 'rubinius-terminal.autoRunCommand'
        shellArguments: atom.config.get 'rubinius-terminal.shellArguments'
        titleTemplate : atom.config.get 'rubinius-terminal.titleTemplate'
        cursorBlink   : atom.config.get 'rubinius-terminal.cursorBlink'
        colors        : @getColors()

      rubiniusTerminalView = new RubiniusTerminalView opts
      rubiniusTerminalView.on 'remove', @handleRemoveTerm.bind this

      @rubiniusTerminalViews.push? rubiniusTerminalView
      rubiniusTerminalView

    splitTerm: (direction)->
      openPanesInSameSplit = atom.config.get 'rubinius-terminal.openPanesInSameSplit'
      rubiniusTerminalView = @createRubiniusTerminalView()
      rubiniusTerminalView.on "click", => @focusedTerminal = rubiniusTerminalView
      direction = capitalize direction

      splitter = =>
        pane = activePane["split#{direction}"] items: [rubiniusTerminalView]
        activePane.rubiniusTerminalSplits[direction] = pane
        @focusedTerminal = [pane, pane.items[0]]

      activePane = atom.workspace.getActivePane()
      activePane.rubiniusTerminalSplits or= {}
      if openPanesInSameSplit
        if activePane.rubiniusTerminalSplits[direction] and activePane.rubiniusTerminalSplits[direction].items.length > 0
          pane = activePane.rubiniusTerminalSplits[direction]
          item = pane.addItem rubiniusTerminalView
          pane.activateItem item
          @focusedTerminal = [pane, item]
        else
          splitter()
      else
        splitter()

    newTerm: ->
      rubiniusTerminalView = @createRubiniusTerminalView()
      pane = atom.workspace.getActivePane()
      item = pane.addItem rubiniusTerminalView
      pane.activateItem item

    pipeTerm: (action)->
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

    handleRemoveTerm: (rubiniusTerminalView)->
      @rubiniusTerminalViews.splice @rubiniusTerminalViews.indexOf(rubiniusTerminalView), 1

    deactivate:->
      @rubiniusTerminalViews.forEach (view)-> view.deactivate()

    serialize:->
      rubiniusTerminalViewsState = this.rubiniusTerminalViews.map (view)-> view.serialize()
      {rubiniusTerminalViews: rubiniusTerminalViewsState}
