function setCors(res, methods = 'GET,POST,OPTIONS') {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', methods);
  res.setHeader(
    'Access-Control-Allow-Headers',
    'Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With'
  );
}

function handleOptions(req, res, methods = 'GET,POST,OPTIONS') {
  setCors(res, methods);
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return true;
  }
  return false;
}

function readJson(req) {
  if (req.body === undefined || req.body === null || req.body === '') {
    return {};
  }
  if (typeof req.body === 'object') {
    return req.body;
  }
  if (typeof req.body === 'string') {
    try {
      return JSON.parse(req.body);
    } catch (_) {
      return {};
    }
  }
  return {};
}

function sendJson(res, payload, status = 200) {
  res.status(status).json(payload);
}

module.exports = {
  setCors,
  handleOptions,
  readJson,
  sendJson,
};
