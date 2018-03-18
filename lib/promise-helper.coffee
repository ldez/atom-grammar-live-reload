CSON = require 'season'

exports.readCsonFile = (filePath) ->
  new Promise (resolve, reject) ->
    CSON.readFile filePath, (error, data) ->
      if error then reject error else resolve data
