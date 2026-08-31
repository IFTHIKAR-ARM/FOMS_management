const { handleOptions, setCors, sendJson } = require('./_vercel/http');
const { ensureCompatSchema, query } = require('./_vercel/db');

module.exports = async (req, res) => {
  if (handleOptions(req, res, 'GET,OPTIONS')) return;
  setCors(res, 'GET,OPTIONS');

  if (req.method !== 'GET') {
    return sendJson(res, { status: 'error', message: 'Method not allowed' }, 405);
  }

  const phone = String(req.query?.phone || '').trim();
  if (!phone) {
    return sendJson(res, { status: 'error', message: 'Phone number required' });
  }

  try {
    await ensureCompatSchema();
    const orders = await query(
      'SELECT * FROM orders WHERE customer_phone = ? ORDER BY created_at DESC',
      [phone]
    );
    return sendJson(res, { status: 'success', orders });
  } catch (error) {
    console.error('Get Orders API Error:', error);
    return sendJson(
      res,
      { status: 'error', message: 'Failed to load orders', error: error.message },
      500
    );
  }
};
