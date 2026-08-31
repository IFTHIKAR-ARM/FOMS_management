const { handleOptions, setCors, readJson, sendJson } = require('./_vercel/http');
const { ensureCompatSchema, hasColumn, query } = require('./_vercel/db');
const { verifyUserPassword } = require('./_vercel/passwords');

module.exports = async (req, res) => {
  if (handleOptions(req, res, 'POST,OPTIONS')) return;
  setCors(res, 'POST,OPTIONS');

  if (req.method !== 'POST') {
    return sendJson(res, { status: 'error', message: 'Method not allowed' }, 405);
  }

  try {
    await ensureCompatSchema();
    const data = readJson(req);

    if (!data.phone || !data.password) {
      return sendJson(res, { status: 'error', message: 'Incomplete data' });
    }

    const phone = String(data.phone).trim();
    const password = String(data.password);

    const hasRoleColumn = await hasColumn('customers', 'role');
    const hasLocationColumn = await hasColumn('customers', 'location');

    const fields = ['name', 'phone', 'password'];
    if (hasRoleColumn) fields.push('role');
    if (hasLocationColumn) fields.push('location');

    const users = await query(`SELECT ${fields.join(', ')} FROM customers WHERE phone = ?`, [
      phone,
    ]);

    if (users.length === 0) {
      return sendJson(res, { status: 'error', message: 'User not found' });
    }

    const user = users[0];
    if (!verifyUserPassword(password, user.password)) {
      return sendJson(res, { status: 'error', message: 'Invalid phone number or password' });
    }

    const role = hasRoleColumn && user.role ? String(user.role).trim().toLowerCase() : 'customer';
    const location = hasLocationColumn ? String(user.location || '').trim() : '';

    if (role === 'admin') {
      return sendJson(res, { status: 'error', message: 'Admin login is separate' });
    }

    return sendJson(res, {
      status: 'success',
      message: 'Login successful',
      user: {
        name: user.name,
        phone,
        role,
        location,
      },
    });
  } catch (error) {
    console.error('Login API Error:', error);
    return sendJson(res, { status: 'error', message: 'Login failed', error: error.message }, 500);
  }
};
