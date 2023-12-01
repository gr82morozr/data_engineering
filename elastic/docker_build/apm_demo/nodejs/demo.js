var apm = require('elastic-apm-node').start({
  serviceName: 'node-app-1',
  secretToken: 'abcdedfgtyyy',
  serverUrl: 'http://apm-svr:8200',
  verifyServerCert: false,
  environment: 'production',
  logLevel:'debug'
})


console.log('Hello World');


const express = require('express')
const app = express()
const port = 5000

app.get('/', (req, res) => {
  res.send('Hello World')
})

app.get('/demo', (req, res) => {
  res.send('Welcome to APM Demo')
})

app.get('/span_demo', (req, res) => {
  const span = apm.startSpan("Start span demo here")
  var ip = req.socket.remoteAddress 
  res.send('Welcome to APM SPAN Demo, your IP is ${ip}')
  
  console.log(ip)
  span.end()

})


app.get('/error', (req, res) => {
  res.send('Capture Error')
  const err=new Error ('Triggered Error')
  apm.captureError(err)

})


app.listen(port, () => {
  console.log("App listening on port ${port}")
})