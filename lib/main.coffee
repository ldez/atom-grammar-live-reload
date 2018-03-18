{readCsonFile} = require './promise-helper'
path = require 'path'
fs = require 'fs'

toUnix = (path) -> path.replace /\\/g, '/'

getPackageNameByFilePath = (currentPath) ->
  rootPath = path.resolve currentPath, '../..'
  for pack in atom.packages.getActivePackages()
    stats = fs.lstatSync pack.path
    packPath = if stats.isSymbolicLink then fs.realpathSync pack.path else pack.path
    if packPath is rootPath
      return pack.name
  ""

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
      title: 'Regular expression us to detect grammar files'
      type: 'string'
      default: '\/language-[^\/]+\/(grammars|settings)\/[^\/]+\.(?:c|j)son$'
      order: 3

  configSub: null
  editorSub: null
  watching: Object.create null
  debug: false

  activate: (state) ->
    return if atom.inSpecMode() or not atom.inDevMode()

    @configSub = atom.config.observe 'grammar-live-reload.enabled', (enabled) =>
      return @editorSub?.dispose() unless enabled

      reload = @reload.bind this
      @editorSub = atom.workspace.observeTextEditors (editor) =>
        grammarRE = ///#{atom.config.get 'grammar-live-reload.grammarRE'}///
        if grammarRE.test toUnix filePath = editor.getPath()

          # See if the file's package is blacklisted.
          if blacklist = atom.config.get 'grammar-live-reload.blacklist'

            unless packName = getPackageNameByFilePath filePath
              debug and console.log 'Package does not exist: ' + filePath
              return

            # Support both comma-separated and space-separated names.
            for name in blacklist.split /(?:,\s*)|\s+/g
              if name is packName
                debug and console.log 'Package reload was prevented: ' + packName
                return

          # Avoid watching the same file twice.
          unless @watching[filePath]
            @debug and console.log 'Watching file for changes: ' + filePath
            @watching[filePath] = true
            editor.onDidSave reload
            editor.onDidDestroy =>
              delete @watching[filePath]

  reload: (event) ->
    {debug} = this

    unless packName = getPackageNameByFilePath event.path
      debug and console.log 'Package does not exist: ' + event.path
      return

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

      atom.workspace.getTextEditors().forEach (editor) ->
        grammar = editor.getGrammar()
        if grammar.packageName is packName
          debug and console.log 'Updating grammar for editor: ', editor
          editor.setGrammar grammars[grammar.scopeName]

    # Report any errors.
    .catch console.error

  deactivate: ->
    @configSub?.dispose()
    @editorSub?.dispose()
