path = require 'path'
promiseHelper = require '../lib/promise-helper'

describe 'Promise helper', ->

  describe 'the fileExists method should', ->

    it 'return a filePath when file exists', ->
      result = null

      waitsForPromise ->
        filePath = path.join __dirname, '/promise-helper-spec.coffee'
        promiseHelper.fileExists(filePath).then (r) -> result = r

      runs ->
        expect(result).toMatch(/^.*promise-helper-spec.coffee$/)

    it 'return a error when file not exists', ->
      error = null

      waitsForPromise ->
        filePath = path.join __dirname, 'foobar'
        promiseHelper.fileExists(filePath).catch (r) -> error = r

      runs ->
        expect(error.errno).toBe -2
        expect(error.code).toBe 'ENOENT'
        expect(error.syscall).toBe 'stat'
        expect(error.path).toMatch /^.*foobar$/

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
        expect(error.errno).toBe -2
        expect(error.code).toBe 'ENOENT'
        expect(error.syscall).toBe 'open'
        expect(error.path).toMatch /^.*foobar$/

  describe 'the getDirectoryEntries method should', ->

    it 'return an entries when directory exists', ->
      result = null

      waitsForPromise ->
        directoryPath = path.join __dirname, '/fixtures/'
        promiseHelper.getDirectoryEntries(directoryPath).then (r) -> result = r

      runs ->
        expect(result).toHaveLength 1
        expect(result[0].path).toMatch /^.*sample01.cson$/

    it 'return a error when directory not exists', ->
      error = null

      waitsForPromise ->
        directoryPath = path.join __dirname, '/fixtures/foobar'
        promiseHelper.readCsonFile(directoryPath).catch (r) -> error = r

      runs ->
        expect(error.errno).toBe -2
        expect(error.code).toBe 'ENOENT'
        expect(error.syscall).toBe 'open'
        expect(error.path).toMatch /^.*foobar$/
