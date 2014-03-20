path = require('path')
connect = require('connect')

connect().use(connect.static(path.join(__dirname,'..'))).listen(3000)
console.log('http://127.0.0.1:3000/test')
