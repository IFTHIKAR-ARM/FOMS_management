const http = require('http');
const fs = require('fs');
const path = require('path');

const API_DIR = path.join(__dirname, 'api');

function loadHandlers() {
  const map = new Map();
  const files = fs.readdirSync(API_DIR);
  for (const file of files) {
    const abs = path.join(API_DIR, file);
    const stat = fs.statSync(abs);
    if (!stat.isFile()) continue;
    if (!file.endsWith('.js')) continue;
    if (file.startsWith('_')) continue;
    if (file.endsWith('.test.js')) continue;
    if (file === 'logo.jpg') continue;

    const name = path.basename(file, '.js');
    try {
      const handler = require(`./api/${file}`);
      map.set(`/api/${name}`, handler);
    } catch (err) {
      console.error('Failed to load handler', file, err);
    }
  }
  return map;
}

function createRes(raw) {
  return {
    setHeader: (k, v) => raw.setHeader(k, v),
    status(code) {
      this._status = code;
      return this;
    },
    json(payload) {
      const statusCode = this._status || 200;
      raw.writeHead(statusCode, { 'Content-Type': 'application/json' });
      raw.end(JSON.stringify(payload));
    },
    end: (...args) => raw.end(...args),
  };
}

function parseBody(req) {
  return new Promise((resolve) => {
    const chunks = [];
    req.on('data', (c) => chunks.push(c));
    req.on('end', () => {
      const raw = Buffer.concat(chunks).toString();
      if (!raw) return resolve('');
      try {
        return resolve(JSON.parse(raw));
      } catch (_) {
        return resolve(raw);
      }
    });
    req.on('error', () => resolve(''));
  });
}

const handlers = loadHandlers();

const server = http.createServer(async (req, rawRes) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const pathname = url.pathname;

  // Serve static api/logo.jpg if present
  if (pathname === '/api/logo.jpg' || pathname === '/api/logo.png') {
    const file = path.join(API_DIR, path.basename(pathname));
    if (fs.existsSync(file)) {
      const data = fs.readFileSync(file);
      rawRes.writeHead(200, { 'Content-Type': 'image/jpeg' });
      return rawRes.end(data);
    }
  }

  // Serve Flutter app assets (so API can return image URLs pointing to /assets/...)
  if (pathname.startsWith('/assets/')) {
    // Map /assets/... -> ./foms_app/assets/...
    const rel = pathname.replace('/assets/', '');
    const filePath = path.join(__dirname, 'foms_app', 'assets', rel);
    if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
      const ext = path.extname(filePath).toLowerCase();
      const type = ext === '.png' ? 'image/png' : ext === '.webp' ? 'image/webp' : 'image/jpeg';
      const data = fs.readFileSync(filePath);
      rawRes.writeHead(200, { 'Content-Type': type });
      return rawRes.end(data);
    }
  }

  const handler = handlers.get(pathname);
  if (!handler) {
    rawRes.writeHead(404, { 'Content-Type': 'application/json' });
    return rawRes.end(JSON.stringify({ status: 'error', message: 'Not found' }));
  }

  req.method = (req.method || 'GET').toUpperCase();
  req.query = Object.fromEntries(url.searchParams.entries());
  req.body = await parseBody(req);

  const res = createRes(rawRes);

  try {
    const maybePromise = handler(req, res);
    if (maybePromise && typeof maybePromise.then === 'function') {
      await maybePromise;
    }
  } catch (err) {
    console.error('Handler error for', pathname, err);
    if (!rawRes.finished) {
      rawRes.writeHead(500, { 'Content-Type': 'application/json' });
      rawRes.end(
        JSON.stringify({ status: 'error', message: 'Internal server error', error: String(err) })
      );
    }
  }
});

// Default to port 3000 so it matches the Flutter client's expected base URL.
const port = Number(process.env.PORT || process.env.NODE_PORT || 3000);
server.listen(port, () => {
  console.log(`Local API server listening on http://localhost:${port}`);
});

process.on('unhandledRejection', (e) => console.error('unhandledRejection', e));
process.on('uncaughtException', (e) => console.error('uncaughtException', e));
