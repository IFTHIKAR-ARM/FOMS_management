const { handleOptions, setCors, readJson, sendJson } = require('./_vercel/http');
const { ensureCompatSchema, query } = require('./_vercel/db');
const { verifyAdminPassword } = require('./_vercel/passwords');

module.exports = async (req, res) => {
  if (handleOptions(req, res, 'POST,OPTIONS')) return;
  setCors(res, 'POST,OPTIONS');

  if (req.method !== 'POST') {
    return sendJson(res, { status: 'error', message: 'Method not allowed' }, 405);
  }

  try {
    await ensureCompatSchema();
    const data = readJson(req);

    if (!data.username || !data.password) {
      return sendJson(res, { status: 'error', message: 'Incomplete data' });
    }

    const username = String(data.username).trim();
    const password = String(data.password);

    const rows = await query('SELECT username, password FROM admin WHERE username = ?', [username]);

    if (rows.length === 0 || !verifyAdminPassword(password, rows[0].password)) {
      return sendJson(res, { status: 'error', message: 'Invalid admin credentials' });
    }

    return sendJson(res, {
      status: 'success',
      message: 'Admin login successful',
      user: {
        username: rows[0].username,
        role: 'admin',
      },
    });
  } catch (error) {
    console.error('Admin Login API Error:', error);
    return sendJson(
      res,
      { status: 'error', message: 'Admin login failed', error: error.message },
      500
    );
  }
};
