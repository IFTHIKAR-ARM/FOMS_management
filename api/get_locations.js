const { handleOptions, setCors, sendJson } = require('./_vercel/http');
const { ensureCompatSchema, query } = require('./_vercel/db');

module.exports = async (req, res) => {
  if (handleOptions(req, res, 'GET,OPTIONS')) return;
  setCors(res, 'GET,OPTIONS');

  if (req.method !== 'GET') {
    return sendJson(res, { status: 'error', message: 'Method not allowed' }, 405);
  }

  try {
    await ensureCompatSchema();

    const rows = await query('SELECT name FROM locations WHERE is_active = 1 ORDER BY name ASC');
    const locations = rows
      .map((row) => String(row.name || '').trim())
      .filter((name) => name !== '');

    return sendJson(res, { status: 'success', locations });
  } catch (error) {
    console.error('Get Locations API Error:', error);
    return sendJson(
      res,
      { status: 'error', message: 'Failed to load locations', error: error.message },
      500
    );
  }
};
