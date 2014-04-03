#x>
if not window?
  fs = require('fs')
  Cache = require('../src/cache.coffee')
  cheerio = require('cheerio')
  load = require('../lib/load.coffee')
  $ = cheerio.load(fs.readFileSync('./test/test.html'))
  Mustache = require('mustache')
else
  window.exports = {}
  window.cache = exports
  Cache = window.Cache
  Mustache = window.Mustache
#<x

exports.cacheInit = (test) ->
  controller = new Cache({
    links: false
    addressBar: false
  })
  test.done()
