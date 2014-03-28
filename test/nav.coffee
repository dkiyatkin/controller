#x>
if not window?
  fs = require('fs')
  Nav = require('../src/nav.coffee')
  cheerio = require('cheerio')
  load = require('../lib/load.coffee')
  $ = cheerio.load(fs.readFileSync('./test/index.html'))
  Mustache = require('mustache')
else
  window.exports = {}
  window.nav = exports
  Nav = window.Nav
  Mustache = window.Mustache
#<x

exports.navInit = (test) ->
  controller = new Nav({
    links: false
    addressBar: false
  })
  test.done()
