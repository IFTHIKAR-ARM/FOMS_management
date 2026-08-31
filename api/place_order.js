const { handleOptions, setCors, readJson, sendJson } = require('./_vercel/http');
const { ensureCompatSchema, hasColumn, query } = require('./_vercel/db');

module.exports = async (req, res) => {
  if (handleOptions(req, res, 'POST,OPTIONS')) return;
  setCors(res, 'POST,OPTIONS');

  if (req.method !== 'POST') {
    return sendJson(res, { status: 'error', message: 'Method not allowed' }, 405);
  }

  try {
    await ensureCompatSchema();
    const data = readJson(req);

    if (!data.customer_phone || !data.items || !data.address) {
      return sendJson(res, { status: 'error', message: 'Incomplete data' }, 400);
    }

    const customerPhone = String(data.customer_phone).trim();
    const customerName = String(data.customer_name || '').trim();
    const address = String(data.address).trim();
    const status = 'pending';

    if (!customerPhone || !address) {
      return sendJson(res, { status: 'error', message: 'Incomplete data' }, 400);
    }

    const items = typeof data.items === 'string' ? data.items : JSON.stringify(data.items);
    const totalAmount = Math.max(0, Number(data.total_amount ?? data.amount ?? 0) || 0);

    const hasCustomerNameColumn = await hasColumn('orders', 'customer_name');
    const hasCancelRequestColumn = await hasColumn('orders', 'cancel_request');

    if (hasCustomerNameColumn && hasCancelRequestColumn) {
      await query(
        `
          INSERT INTO orders
            (customer_phone, customer_name, items, address, amount, status, cancel_request)
          VALUES (?, ?, ?, ?, ?, ?, 'no')
        `,
        [customerPhone, customerName, items, address, totalAmount, status]
      );
    } else if (hasCustomerNameColumn) {
      await query(
        `
          INSERT INTO orders
            (customer_phone, customer_name, items, address, amount, status)
          VALUES (?, ?, ?, ?, ?, ?)
        `,
        [customerPhone, customerName, items, address, totalAmount, status]
      );
    } else if (hasCancelRequestColumn) {
      await query(
        `
          INSERT INTO orders
            (customer_phone, items, address, amount, status, cancel_request)
          VALUES (?, ?, ?, ?, ?, 'no')
        `,
        [customerPhone, items, address, totalAmount, status]
      );
    } else {
      await query(
        `
          INSERT INTO orders
            (customer_phone, items, address, amount, status)
          VALUES (?, ?, ?, ?, ?)
        `,
        [customerPhone, items, address, totalAmount, status]
      );
    }

    return sendJson(res, { status: 'success', message: 'Order placed successfully' });
  } catch (error) {
    console.error('Place Order API Error:', error);
    return sendJson(
      res,
      { status: 'error', message: 'Failed to place order', error: error.message },
      500
    );
  }
};
