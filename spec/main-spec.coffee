temp = require('temp').track()
path = require 'path'

describe 'Grammars Live reload', ->

  beforeEach ->
    temp.cleanupSync()
    directory = temp.mkdirSync()
    atom.project.setPaths([directory])
    atom.views.getView(atom.workspace)
    filePath = path.join(directory, 'atom-live-grammar-reload.js')
    fs.writeFileSync(filePath, '', 'console.log("foobar");')

    waitsForPromise ->
      atom.workspace.open(filePath).then (o) -> editor = o

    runs ->
      buffer = editor.getBuffer()

    waitsForPromise ->
      atom.packages.activatePackage('whitespace')

  it 'test', ->
    called = false
    callback = -> called = true
    atom.config.set 'live-grammar-reload.enabled', true
    atom.config.set 'live-grammar-reload.grammarsPackageName', 'language-foo'

    console.log atom.config.get('live-grammar-reload.enabled')
