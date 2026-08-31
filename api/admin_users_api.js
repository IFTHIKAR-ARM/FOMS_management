const { handleOptions, setCors, readJson, sendJson } = require('./_vercel/http');
const { ensureCompatSchema, query } = require('./_vercel/db');

function jsonError(res, message, code = 400) {
  return sendJson(res, { status: 'error', message }, code);
}

module.exports = async (req, res) => {
  if (handleOptions(req, res, 'GET,POST,OPTIONS')) return;
  setCors(res, 'GET,POST,OPTIONS');

  try {
    await ensureCompatSchema();
    if (req.method === 'GET') {
      const users = await query('SELECT phone, name, role FROM customers ORDER BY role, name');
      return sendJson(res, { status: 'success', users });
    }

    if (req.method !== 'POST') {
      return jsonError(res, 'Method not allowed', 405);
    }

    const data = readJson(req);
    if (!data.action || !data.phone) {
      return jsonError(res, 'Incomplete data');
    }

    const action = String(data.action).trim().toLowerCase();
    const phone = String(data.phone).trim();

    if (action === 'delete_user') {
      const result = await query('DELETE FROM customers WHERE phone = ?', [phone]);
      if (!result.affectedRows) {
        return jsonError(res, 'User not found');
      }
      return sendJson(res, { status: 'success', message: 'User deleted' });
    }

    if (action === 'update_role') {
      if (!data.role) return jsonError(res, 'Role is required');
      const role = String(data.role).trim().toLowerCase();
      const allowed = ['customer', 'delivery', 'admin'];
      if (!allowed.includes(role)) return jsonError(res, 'Invalid role');

      const result = await query('UPDATE customers SET role = ? WHERE phone = ?', [role, phone]);
      if (!result.affectedRows) {
        return jsonError(res, 'User not found');
      }
      return sendJson(res, { status: 'success', message: 'User role updated' });
    }

    return jsonError(res, 'Invalid action');
  } catch (error) {
    console.error('Admin Users API Error:', error);
    return jsonError(res, error.message || 'Server error', 500);
  }
};
