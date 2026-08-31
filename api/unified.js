const { handleOptions, setCors, readJson, sendJson } = require('./_vercel/http');
const { ensureCompatSchema, hasColumn, query } = require('./_vercel/db');
const { verifyUserPassword, verifyAdminPassword } = require('./_vercel/passwords');

module.exports = async (req, res) => {
  if (handleOptions(req, res, 'POST,OPTIONS')) return;
  setCors(res, 'POST,OPTIONS');

  if (req.method !== 'POST') {
    return sendJson(res, { status: 'error', message: 'Method not allowed' }, 405);
  }

  try {
    await ensureCompatSchema();

    const data = readJson(req);

    if (!data.identifier || !data.password) {
      return sendJson(res, { status: 'error', message: 'Incomplete data' });
    }

    const identifier = String(data.identifier).trim();
    const password = String(data.password);
    const role = data.role ? String(data.role).trim().toLowerCase() : '';
    const key = data.key ? String(data.key).trim() : '';

    // ========================
    // CUSTOMER / DELIVERY LOGIN
    // ========================

    const hasRoleColumn = await hasColumn('customers', 'role');
    const hasLocationColumn = await hasColumn('customers', 'location');

    let selectQuery = 'SELECT name, phone, password';

    if (hasRoleColumn) selectQuery += ', role';
    if (hasLocationColumn) selectQuery += ', location';

    selectQuery += ' FROM customers WHERE phone=?';

    const customers = await query(selectQuery, [identifier]);

    if (customers.length > 0) {
      const customer = customers[0];

      if (!verifyUserPassword(password, customer.password)) {
        return sendJson(res, { status: 'error', message: 'Invalid credentials' });
      }

      let storedRole =
        hasRoleColumn && customer.role ? String(customer.role).trim().toLowerCase() : 'customer';

      if (!['customer', 'delivery'].includes(storedRole)) {
        storedRole = 'customer';
      }

      if (role !== '' && storedRole !== role) {
        return sendJson(res, {
          status: 'error',
          message: `Role mismatch. Account role is ${storedRole}`,
        });
      }

      return sendJson(res, {
        status: 'success',
        message: 'Login successful',
        user: {
          name: customer.name,
          phone: customer.phone,
          role: storedRole,
          location: hasLocationColumn ? customer.location : '',
        },
      });
    }

    // ========================
    // ADMIN LOGIN
    // ========================

    const admins = await query('SELECT username, password FROM admin WHERE username=?', [
      identifier,
    ]);

    if (admins.length > 0) {
      const admin = admins[0];

      if (!verifyAdminPassword(password, admin.password)) {
        return sendJson(res, { status: 'error', message: 'Invalid admin credentials' });
      }

      return sendJson(res, {
        status: 'success',
        message: 'Login successful',
        user: {
          username: admin.username,
          role: 'admin',
        },
      });
    }

    return sendJson(res, { status: 'error', message: 'User not found' });
  } catch (error) {
    console.error('Login API Error:', error);

    return sendJson(
      res,
      {
        status: 'error',
        message: 'Login failed',
        error: error.message,
      },
      500
    );
  }
};
