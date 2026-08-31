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

    if (!data.customer_phone || !data.created_at || !data.address || data.items === undefined) {
      return sendJson(res, { status: 'error', message: 'Incomplete data' });
    }

    const phone = String(data.customer_phone).trim();
    const createdAtInput = String(data.created_at).trim();
    const createdAt = new Date(createdAtInput);
    if (isNaN(createdAt.getTime())) {
      return sendJson(res, { status: 'error', message: 'Invalid created_at value' });
    }
    const address = String(data.address).trim();
    const items =
      typeof data.items === 'string' || typeof data.items === 'number'
        ? String(data.items)
        : JSON.stringify(data.items);

    const result = await query(
      `
        UPDATE orders
        SET items = ?, address = ?
        WHERE customer_phone = ?
          AND created_at = ?
          AND (cancel_request = 'no' OR cancel_request IS NULL)
          AND LOWER(status) IN ('pending', 'preparing')
      `,
      [items, address, phone, createdAt]
    );

    if (!result.affectedRows) {
      return sendJson(res, {
        status: 'error',
        message: 'Order not found or cannot be updated',
      });
    }

    return sendJson(res, { status: 'success', message: 'Order updated successfully' });
  } catch (error) {
    console.error('Update Order API Error:', error);
    return sendJson(
      res,
      { status: 'error', message: 'Failed to update order', error: error.message },
      500
    );
  }
};
