RubiniusTerminalView = require './rubinius-terminal-view'
{CompositeDisposable} = require 'atom'

module.exports = RubiniusTerminal =
  atomRubiniusTerminalView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @atomRubiniusTerminalView = new RubiniusTerminalView(state.atomRubiniusTerminalViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @atomRubiniusTerminalView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-rubinius-terminal:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atomRubiniusTerminalView.destroy()

  serialize: ->
    atomRubiniusTerminalViewState: @atomRubiniusTerminalView.serialize()

  toggle: ->
    console.log 'RubiniusTerminal was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
