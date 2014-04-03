#x>
if not window?
  fs = require('fs')
  LayerControl = require('../src/layer-control.coffee')
  cheerio = require('cheerio')
  load = require('../lib/load.coffee')
  $ = cheerio.load(fs.readFileSync('./test/test.html'))
  Mustache = require('mustache')
else
  window.exports = {}
  window.layerControl = exports
  LayerControl = window.LayerControl
  Mustache = window.Mustache
#<x

exports.layerControlInit = (test) ->
  controller = new LayerControl({
    links: false
    addressBar: false
  })
  test.done()

