const { handleOptions, setCors, sendJson } = require('./_vercel/http');
const { ensureCompatSchema, query } = require('./_vercel/db');

module.exports = async (req, res) => {
  if (handleOptions(req, res, 'GET,OPTIONS')) return;
  setCors(res, 'GET,OPTIONS');

  if (req.method !== 'GET') {
    return sendJson(res, { status: 'error', message: 'Method not allowed' }, 405);
  }

  try {
    await ensureCompatSchema();

    // Ensure menu table exists (db.js also ensures this, but keep safety here)
    await query(`
      CREATE TABLE IF NOT EXISTS menu_items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL UNIQUE,
        price DECIMAL(10,2) NOT NULL,
        image VARCHAR(255) NULL,
        is_active TINYINT(1) NOT NULL DEFAULT 1
      )
    `);

    let rows = await query(
      'SELECT name, price, image FROM menu_items WHERE is_active = 1 ORDER BY id ASC'
    );

    if (!rows || rows.length === 0) {
      await query(
        `INSERT INTO menu_items (name, price, image, is_active) VALUES (?, ?, ?, 1), (?, ?, ?, 1), (?, ?, ?, 1)`,
        [
          'chicken',
          5.99,
          'assets/images/chicken.jpeg',
          'Pizza',
          8.99,
          'assets/images/fish.jpg',
          'Coke',
          1.99,
          'assets/images/logo.png',
        ]
      );
      rows = await query(
        'SELECT name, price, image FROM menu_items WHERE is_active = 1 ORDER BY id ASC'
      );
    }

    const data = (rows || []).map((row) => ({
      name: row.name,
      price: Number(row.price),
      image: row.image ? (row.image.startsWith('/') ? row.image : '/' + row.image) : null,
    }));

    return sendJson(res, { status: 'success', data });
  } catch (error) {
    console.error('Get Menu API Error:', error);
    return sendJson(
      res,
      { status: 'error', message: 'Failed to load menu', error: error.message },
      500
    );
  }
};
