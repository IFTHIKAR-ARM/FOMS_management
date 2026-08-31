const { handleOptions, setCors, readJson, sendJson } = require('./_vercel/http');
const { ensureCompatSchema, query } = require('./_vercel/db');

module.exports = async (req, res) => {
  if (handleOptions(req, res, 'POST,OPTIONS')) return;
  setCors(res, 'POST,OPTIONS');

  if (req.method !== 'POST') {
    return sendJson(res, { status: 'error', message: 'Method not allowed' }, 405);
  }

  try {
    await ensureCompatSchema();
    const data = readJson(req);

    if (!data.customer_phone || !data.created_at) {
      return sendJson(res, { status: 'error', message: 'Incomplete data' });
    }

    const phone = String(data.customer_phone).trim();
    const createdAtInput = String(data.created_at).trim();
    const createdAt = new Date(createdAtInput);
    if (isNaN(createdAt.getTime())) {
      return sendJson(res, { status: 'error', message: 'Invalid created_at value' });
    }

    const result = await query(
      `
        UPDATE orders
        SET cancel_request = 'pending'
        WHERE customer_phone = ?
          AND created_at = ?
          AND status IN ('pending', 'preparing')
          AND cancel_request = 'no'
      `,
      [phone, createdAt]
    );

    if (!result.affectedRows) {
      return sendJson(res, {
        status: 'error',
        message: 'Order not found or cannot be canceled',
      });
    }

    return sendJson(res, { status: 'success', message: 'Cancel request submitted' });
  } catch (error) {
    console.error('Request Cancel API Error:', error);
    return sendJson(
      res,
      { status: 'error', message: 'Failed to process cancel request', error: error.message },
      500
    );
  }
};
