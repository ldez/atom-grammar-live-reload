{Directory} = require 'atom'
fs = require 'fs'
CSON = require 'season'

module.exports =

  fileExists: (filePath) ->
    new Promise (resolve, reject) ->
      fs.stat filePath, (error, stats) ->
        if error? then reject error else resolve filePath

  readCsonFile: (filePath) ->
    new Promise (resolve, reject) ->
      CSON.readFile filePath, (error, data) ->
        if error? then reject error else resolve data

  getDirectoryEntries: (directoryPath) ->
    new Promise (resolve, reject) ->
      new Directory(directoryPath).getEntries (error, entries) ->
        if error? then reject error else resolve entries
