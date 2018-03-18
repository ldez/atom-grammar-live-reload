path = require 'path'
promiseHelper = require '../lib/promise-helper'

describe 'Promise helper', ->

  describe 'the readCsonFile method should', ->

    it 'return a object when file exists', ->
      result = null

      waitsForPromise ->
        filePath = path.join __dirname, '/fixtures/sample01.cson'
        promiseHelper.readCsonFile(filePath).then (r) -> result = r

      runs ->
        expect(result).toEqualJson name: 'foobar', code: 'foo', value: 1

    it 'return a error when file not exists', ->
      error = null

      waitsForPromise ->
        filePath = path.join __dirname, 'foobar'
        promiseHelper.readCsonFile(filePath).catch (r) -> error = r

      runs ->
        expect(error.errno).toBeLessThan 0
        expect(error.code).toBe 'ENOENT'
        expect(error.syscall).toBe 'open'
        expect(error.path).toMatch /^.*foobar$/
