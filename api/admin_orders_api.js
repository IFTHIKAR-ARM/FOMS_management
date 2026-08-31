const { handleOptions, setCors, readJson, sendJson } = require('./_vercel/http');
const { ensureCompatSchema, hasColumn, query } = require('./_vercel/db');

function jsonError(res, message, code = 400) {
  return sendJson(res, { status: 'error', message }, code);
}

module.exports = async (req, res) => {
  if (handleOptions(req, res, 'GET,POST,OPTIONS')) return;
  setCors(res, 'GET,POST,OPTIONS');

  try {
    await ensureCompatSchema();

    if (req.method === 'GET') {
      const hasCustomerName = await hasColumn('orders', 'customer_name');
      const hasCancelRequest = await hasColumn('orders', 'cancel_request');

      const customerNameSql = hasCustomerName
        ? "COALESCE(NULLIF(o.customer_name, ''), c.name, '') AS customer_name"
        : "COALESCE(c.name, '') AS customer_name";
      const cancelRequestSql = hasCancelRequest ? 'o.cancel_request' : "'no' AS cancel_request";

      const orders = await query(
        `
          SELECT
            o.customer_phone,
            ${customerNameSql},
            o.items,
            o.address,
            o.amount,
            o.status,
            ${cancelRequestSql},
            o.created_at
          FROM orders o
          LEFT JOIN customers c ON c.phone = o.customer_phone
          ORDER BY o.created_at DESC
        `
      );

      return sendJson(res, { status: 'success', orders });
    }

    if (req.method !== 'POST') {
      return jsonError(res, 'Method not allowed', 405);
    }

    const data = readJson(req);
    if (!data.action || !data.customer_phone || !data.created_at) {
      return jsonError(res, 'Incomplete data');
    }

    const action = String(data.action).trim().toLowerCase();
    const phone = String(data.customer_phone).trim();
    const createdAt = String(data.created_at).trim();

    if (action === 'update_status') {
      if (!data.status) {
        return jsonError(res, 'Status is required');
      }
      const status = String(data.status).trim().toLowerCase();
      const allowed = ['pending', 'preparing', 'out_for_delivery', 'delivered', 'canceled'];
      if (!allowed.includes(status)) {
        return jsonError(res, 'Invalid status');
      }

      let cancelUpdateSql = '';
      if (status === 'canceled') {
        cancelUpdateSql =
          ", cancel_request = CASE WHEN cancel_request = 'pending' THEN 'approved' ELSE cancel_request END";
      } else if (['preparing', 'out_for_delivery', 'delivered'].includes(status)) {
        cancelUpdateSql =
          ", cancel_request = CASE WHEN cancel_request = 'pending' THEN 'rejected' ELSE cancel_request END";
      }

      const result = await query(
        `
          UPDATE orders
          SET status = ?
          ${cancelUpdateSql}
          WHERE customer_phone = ?
            AND created_at = ?
            AND status <> 'canceled'
        `,
        [status, phone, createdAt]
      );

      if (!result.affectedRows) {
        return jsonError(res, 'Order not found or cannot be updated');
      }

      return sendJson(res, { status: 'success', message: 'Order status updated' });
    }

    if (action === 'approve_cancel') {
      if (!(await hasColumn('orders', 'cancel_request'))) {
        return jsonError(res, 'No pending cancel request found');
      }

      const result = await query(
        `
          UPDATE orders
          SET cancel_request = 'approved', status = 'canceled'
          WHERE customer_phone = ?
            AND created_at = ?
            AND cancel_request = 'pending'
        `,
        [phone, createdAt]
      );

      if (!result.affectedRows) {
        return jsonError(res, 'No pending cancel request found');
      }

      return sendJson(res, { status: 'success', message: 'Cancel request approved' });
    }

    if (action === 'reject_cancel') {
      if (!(await hasColumn('orders', 'cancel_request'))) {
        return jsonError(res, 'No pending cancel request found');
      }

      const result = await query(
        `
          UPDATE orders
          SET cancel_request = 'rejected'
          WHERE customer_phone = ?
            AND created_at = ?
            AND cancel_request = 'pending'
        `,
        [phone, createdAt]
      );

      if (!result.affectedRows) {
        return jsonError(res, 'No pending cancel request found');
      }

      return sendJson(res, { status: 'success', message: 'Cancel request rejected' });
    }

    return jsonError(res, 'Invalid action');
  } catch (error) {
    console.error('Admin Orders API Error:', error);
    return jsonError(res, error.message || 'Server error', 500);
  }
};
