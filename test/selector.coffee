#x>
if not window?
  Selector = require('../src/selector.coffee')
  cheerio = require('cheerio')
  load = require('../lib/load.coffee')
else
  window.exports = {}
  window.selector = exports
  Selector = window.Selector
#<x

_setSelector = (selector, test) ->
  test.strictEqual(selector.$('html').find('body').find('div').length, 4, 'divs')
  test.strictEqual(selector.$('html').find('body').find('div').find('span').length, 3, 'spans')
  test.strictEqual(selector.$('td').find('hr').length, 6, 'hrs')
  test.strictEqual(selector.$('#testSelector').html().trim().replace(/\s+/g,''), '<span>1</span><span>2</span>')
  selector.$('#testSelector span').html('3')
  test.strictEqual(selector.$('#testSelector').html().trim().replace(/\s+/g,''), '<span>3</span><span>3</span>')
  selector.$('#testSelector').find('span').html('4')
  test.strictEqual(selector.$('#testSelector').html().trim().replace(/\s+/g,''), '<span>4</span><span>4</span>')
  test.done()

exports.setSelector = (test) ->
  if not window?
    load('/test/test.html', {}, (err, ans) ->
      _setSelector(new Selector({$:cheerio.load(ans)}), test)
    )
  else
    _setSelector(new Selector(), test)
