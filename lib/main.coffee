{CompositeDisposable} = require 'atom'
{readCsonFile} = require './promise-helper'
path = require 'path'
fs = require 'fs'

toUnix = (path) -> path.replace /\\/g, '/'

resolveSymlink = (filePath) ->
  stats = fs.lstatSync filePath
  if stats.isSymbolicLink()
  then fs.realpathSync filePath
  else filePath

resolvePackageName = (grammarPath) ->
  packPath = resolveSymlink path.resolve grammarPath, '../..'
  for pack in atom.packages.getActivePackages()
    return pack.name if packPath is resolveSymlink pack.path

isGrammarPath = (filePath) ->
  grammarRE = atom.config.get 'grammar-live-reload.grammarRE'
  grammarRE = new RegExp grammarRE.replace /\//g, '\\/'
  grammarRE.test toUnix filePath

module.exports =

  config:
    enabled:
      title: 'Enable live reload (only in dev mode)'
      type: 'boolean'
      default: true
      order: 1

    blacklist:
      title: 'Disable live reload for specific grammars'
      description: 'eg: "language-git, language-swift"'
      type: 'string'
      default: ''
      order: 2

    grammarRE:
      title: 'Regular expression use to detect grammar files'
      type: 'string'
      default: '\/language-[^\/]+\/(grammars|settings)\/[^\/]+\.(?:c|j)son$'
      order: 3

  configSub: null
  editorSub: null
  buffers: new Map
  debug: false

  activate: (state) ->
    return if atom.inSpecMode() or not atom.inDevMode()

    @configSub = atom.config.observe 'grammar-live-reload.enabled', (enabled) =>

      unless enabled
        @editorSub?.dispose()
        @editorSub = null
        @buffers.forEach (subs) -> subs.dispose()
        @buffers.clear()
        return

      @editorSub = atom.workspace.observeTextEditors (editor) =>
        return if @buffers.has buffer = editor.getBuffer()

        filePath = buffer.getPath()
        return unless filePath and isGrammarPath filePath

        unless packName = resolvePackageName filePath
          @debug and console.log 'Grammar is not active: ' + filePath
          return

        # Check if the user defined a blacklist.
        if blacklist = atom.config.get 'grammar-live-reload.blacklist'
          # Support both comma-separated and space-separated names.
          if blacklist.split(/(?:,\s*)|\s+/g).indexOf(packName) >= 0
            @debug and console.log 'Grammar is on blacklist: ' + packName
            return

        subs = new CompositeDisposable

        # Stop watching when the file is deleted.
        subs.add buffer.onDidDelete stopWatching = =>
          @debug and console.log 'Stopped watching: ' + filePath
          @buffers.delete buffer
          subs.dispose()

        # Stop watching when all editors of this file are closed.
        subs.add buffer.onDidDestroy stopWatching

        # Stop watching when the package is deactivated.
        pack = atom.packages.getActivePackage packName
        subs.add packSub = pack.onDidDeactivate stopWatching

        subs.add buffer.onDidSave =>
          packSub.dispose()
          subs.remove packSub
          @reloadGrammar(packName).then ->
            pack = atom.packages.getActivePackage packName
            subs.add packSub = pack.onDidDeactivate stopWatching

        subs.add buffer.onDidChangePath (newPath) =>
          @debug and console.log 'Stopped watching: ' + filePath
          if isGrammarPath newPath
            @debug and console.log 'Started watching: ' + newPath
            filePath = newPath
          else
            @buffers.delete buffer
            subs.dispose()

        @debug and console.log 'Started watching: ' + filePath
        @buffers.set buffer, subs
        return

  reloadGrammar: (packName) ->
    {debug} = this

    # Unload the grammar package.
    debug and console.log 'Deactivating package: ' + packName
    atom.packages.deactivatePackage packName
      .then -> atom.packages.unloadPackage packName

      # Load the grammar package.
      .then ->
        debug and console.log 'Activating package: ' + packName
        atom.packages.activatePackage packName

      # Every grammar scope in the package has been reloaded,
      # so we need to update every editor that uses one of them.
      .then (pack) ->
        grammars = {}
        for grammar in pack.grammars
          grammars[grammar.scopeName] = grammar

        for editor in atom.workspace.getTextEditors()
          grammar = editor.getGrammar()
          if grammar.packageName is packName
            debug and console.log 'Updating grammar for editor: ', editor
            editor.setGrammar grammars[grammar.scopeName]

      # Report any errors.
      .catch console.error

  deactivate: ->
    @configSub?.dispose()
    @editorSub?.dispose()
