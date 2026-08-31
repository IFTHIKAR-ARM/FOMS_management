const { handleOptions, setCors, readJson, sendJson } = require('./_vercel/http');
const { ensureCompatSchema, hasColumn, query } = require('./_vercel/db');
const { hashUserPassword } = require('./_vercel/passwords');

module.exports = async (req, res) => {
  if (handleOptions(req, res, 'POST,OPTIONS')) return;
  setCors(res, 'POST,OPTIONS');

  if (req.method !== 'POST') {
    return sendJson(res, { status: 'error', message: 'Method not allowed' }, 405);
  }

  try {
    await ensureCompatSchema();
    const data = readJson(req);

    if (!data.name || !data.phone || !data.password) {
      return sendJson(res, { status: 'error', message: 'Incomplete data' });
    }

    const name = String(data.name).trim();
    const phone = String(data.phone).trim();
    const password = String(data.password);
    let location = String(data.location || '').trim();

    if (!/^\d{10}$/.test(phone)) {
      return sendJson(res, { status: 'error', message: 'Phone number must be exactly 10 digits' });
    }

    const existing = await query('SELECT phone FROM customers WHERE phone = ?', [phone]);
    if (existing.length > 0) {
      return sendJson(res, { status: 'error', message: 'Phone number already registered' });
    }

    let role = String(data.role || 'customer')
      .trim()
      .toLowerCase();
    if (!['customer', 'delivery'].includes(role)) {
      role = 'customer';
    }

    if (role === 'customer' && location === '') {
      return sendJson(res, { status: 'error', message: 'Please select a location' });
    }

    const hasRoleColumn = await hasColumn('customers', 'role');
    const hasLocationColumn = await hasColumn('customers', 'location');
    const hashedPassword = hashUserPassword(password);

    if (hasRoleColumn && hasLocationColumn) {
      await query(
        'INSERT INTO customers (name, phone, password, role, location) VALUES (?, ?, ?, ?, ?)',
        [name, phone, hashedPassword, role, location]
      );
    } else if (hasRoleColumn) {
      await query('INSERT INTO customers (name, phone, password, role) VALUES (?, ?, ?, ?)', [
        name,
        phone,
        hashedPassword,
        role,
      ]);
      location = '';
    } else {
      await query('INSERT INTO customers (name, phone, password) VALUES (?, ?, ?)', [
        name,
        phone,
        hashedPassword,
      ]);
      role = 'customer';
      location = '';
    }

    return sendJson(res, {
      status: 'success',
      message: 'Registration successful',
      user: { name, phone, role, location },
    });
  } catch (error) {
    console.error('Register API Error:', error);
    return sendJson(
      res,
      { status: 'error', message: 'Registration failed', error: error.message },
      500
    );
  }
};
