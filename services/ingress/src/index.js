var request = require('request-promise-native');
const express = require('express');
const app = express();
const port = process.env.PORT || 8080;

const GREETER_URL = process.env.GREETER_URL;

const os = require('os');
const hostname = os.hostname();

if (!GREETER_URL) {
  throw new Error('Process requires that environment variable GREETER_URL be passed');
}

app.get('/health', function (req, res) {
  res.send("healthy");
});

app.get('*', function (req, res) {
  var greeter;
  request(GREETER_URL, function (err, resp, body) {
    if (err) {
      console.error('Error talking to the greeter service: ' + err);
      return res.send(200, 'Failed to communciate to the greeter service, check logs');
    }

    greeter = body.replace(/^"(.*)"$/, '$1');

    res.send(`From ${hostname}: ${greeter}`);
  })
});

app.listen(port, () => console.log(`Listening on port ${port}!`));

// This causes the process to respond to "docker stop" faster
process.on('SIGTERM', function () {
  console.log('Received SIGTERM, shutting down');
  app.close();
});