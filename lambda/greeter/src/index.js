const http = require('http');

let GREETING_URL = process.env.GREETING_URL;
let NAME_URL = process.env.NAME_URL;

function getRequest(url) {
  if (!url) {
    throw new Error('Process requires that url for GREETING_URL and NAME_URL be passed');
  }

  return new Promise((resolve, reject) => {
    const req = http.get(url, res => {
      let data = '';

      res.on('data', chunk => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          resolve(data);
        } catch (err) {
          reject(new Error(err));
        }
      });
    });

    req.on('error', err => {
      reject(new Error(err));
    });
  });
}

exports.handler = async function (event) {
  const greeting = await getRequest(GREETING_URL);
  const name = await getRequest(NAME_URL);
  return `From lambda: ${greeting} ${name}`
}