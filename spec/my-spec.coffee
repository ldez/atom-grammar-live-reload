# path = require 'path'
# fs = require 'fs-plus'
# CSON = require 'season'
# {Directory} = require 'atom'
#
# describe 'Grammars Live reload', ->
#
#   debug = (arg) ->
#     console.log JSON.stringify arg, null, ' '
#
#   fileExists = (path) ->
#     new Promise (resolve, reject) ->
#       fs.stat path, (error, stats) ->
#         if error? then reject error else resolve path
#
#   csonReadFile = (path) ->
#     new Promise (resolve, reject) ->
#       CSON.readFile path, (error, data) ->
#         if error? then reject error else resolve data
#
#   getDirectoryEntries = (directory) ->
#     new Promise (resolve, reject) ->
#       directory.getEntries (error, entries) ->
#         if error? then reject error else resolve entries
#
#   beforeEach ->
#     atom.project.setPaths([
#       '/home/ldez/sources/ldez/others/atom/language-foo'
#       '/home/ldez/sources/ldez/others/atom/language-gitattributes'
#       '/home/ldez/sources/ldez/others/atom/language-ignore'
#       # '/home/ldez/sources/others/asciidoctor/atom-language-asciidoc'
#     ])
#     atom.views.getView(atom.workspace)
#
#   it 'test', ->
#     called = false
#     callback = -> called = true
#
#     prs = atom.project.rootDirectories.map (rootDir) ->
#       packageJsonPath = path.join rootDir.path, 'package.json'
#
#       fileExists(packageJsonPath)
#         .then (path) ->
#           csonReadFile(path)
#             .then (projectPackage) ->
#               if projectPackage.name is 'language-ignore'
#                 getDirectoryEntries new Directory path.join rootDir.path, 'grammars'
#                   .then (entries) ->
#                     Promise.all(
#                       entries.filter (entry) -> entry.isFile() and entry.getBaseName().endsWith '.cson'
#                       .map (entry) -> csonReadFile(entry.path)
#                     )
#                   .then (grammars) ->
#                     grammars.map (grammar) ->
#                       {scopeName} = grammar
#                       console.log scopeName
#
#                       # Remove grammars
#                       atom.grammars.removeGrammarForScopeName scopeName
#                   .then ->
#                     # Remove loaded package (Hack force reload)
#                     delete atom.packages.loadedPackages['language-ignore']
#
#                     # Load package
#                     atom.packages.loadPackage('language-ignore').loadGrammars()
#                   .then ->
#                     # Reload grammars for each editor
#                     atom.workspace.getTextEditors().forEach (editor) ->
#                       if editor.getGrammar().packageName is 'language-ignore'
#                         editor.reloadGrammar()
#                     Promise.resolve 'success'
#               else
#                 Promise.resolve 'not the rigth package'
#         .catch (error) -> Promise.resolve "file doesn't exists"
#
#     Promise.all(prs)
#       .then (msg) ->
#         console.log msg
#         console.log 'async'
#         callback()
#       .catch (error) ->
#         console.log 'async'
#         console.log error
#         callback()
#
#       waitsFor 'request to be done', -> called is true
#
#
#   xit 'test', ->
#     for rootDir in atom.project.rootDirectories
#       # debug rootDir
#
#       packageJsonPath = path.join rootDir.path, 'package.json'
#
#       if fs.existsSync packageJsonPath
#         projectPackage = CSON.readFileSync(packageJsonPath)
#
#         if projectPackage.name is 'language-asciidoc'
#           directory = new Directory(path.join rootDir.path, 'grammars')
#           entries = directory.getEntriesSync()
#           for entry in entries
#             if (entry.isFile() and entry.getBaseName().endsWith '.cson')
#               {scopeName, fileTypes} = CSON.readFileSync(entry.path)
#               console.log scopeName
#               debug fileTypes
