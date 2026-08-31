const mysql = require('mysql2/promise');
const { md5 } = require('./passwords');
const { menuImagePath } = require('./menuImages');

let pool = null;
let ensurePromise = null;

function getPool() {
  if (!pool) {
    pool = mysql.createPool({
      host: process.env.DB_HOST || process.env.MYSQL_HOST || '127.0.0.1',
      user: process.env.DB_USER || process.env.MYSQL_USER || 'root',
      password: process.env.DB_PASSWORD || process.env.MYSQL_PASSWORD || '',
      database: process.env.DB_NAME || process.env.MYSQL_DATABASE || 'food_system',
      port: Number(process.env.DB_PORT || process.env.MYSQL_PORT || 3306),
      waitForConnections: true,
      connectionLimit: Number(process.env.DB_POOL_SIZE || 10),
      queueLimit: 0,
      charset: 'utf8mb4',
    });
  }
  return pool;
}

async function query(sql, params = []) {
  const [rows] = await getPool().query(sql, params);
  return rows;
}

async function hasTable(tableName) {
  const rows = await query('SHOW TABLES LIKE ?', [tableName]);
  return rows.length > 0;
}

async function hasColumn(tableName, columnName) {
  const rows = await query(
    `
      SELECT COUNT(*) AS total
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
    `,
    [tableName, columnName]
  );
  return Number(rows[0]?.total || 0) > 0;
}

async function ensureColumn(tableName, columnName, definitionSql) {
  if (!(await hasTable(tableName))) return;
  if (await hasColumn(tableName, columnName)) return;

  await query(`ALTER TABLE \`${tableName}\` ADD COLUMN \`${columnName}\` ${definitionSql}`);
}

async function ensureMenuTable() {
  await query(`
    CREATE TABLE IF NOT EXISTS menu_items (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(100) NOT NULL UNIQUE,
      price DECIMAL(10,2) NOT NULL,
      image VARCHAR(255) NULL,
      is_active TINYINT(1) NOT NULL DEFAULT 1
    )
  `);

  const rows = await query('SELECT COUNT(*) AS total FROM menu_items');
  const hasData = Number(rows[0]?.total || 0) > 0;
  if (hasData) return;

  const hasImage = await hasColumn('menu_items', 'image');
  if (hasImage) {
    await query(
      `
        INSERT INTO menu_items (name, price, image, is_active) VALUES
        (?, ?, ?, 1),
        (?, ?, ?, 1),
        (?, ?, ?, 1),
        (?, ?, ?, 1),
        (?, ?, ?, 1)
      `,
      [
        'Chicken Kottu',
        1200,
        menuImagePath('chicken'),
        'Fish Curry Rice',
        1100,
        menuImagePath('fish'),
        'Beef Fried Rice',
        1300,
        menuImagePath('beef'),
        'Veg Noodles',
        900,
        menuImagePath('veg'),
        'Egg Fried Rice',
        950,
        menuImagePath('egg'),
      ]
    );
    return;
  }

  await query(
    `
      INSERT INTO menu_items (name, price, is_active) VALUES
      (?, ?, 1),
      (?, ?, 1),
      (?, ?, 1),
      (?, ?, 1),
      (?, ?, 1)
    `,
    [
      'Chicken Kottu',
      1200,
      'Fish Curry Rice',
      1100,
      'Beef Fried Rice',
      1300,
      'Veg Noodles',
      900,
      'Egg Fried Rice',
      950,
    ]
  );
}

async function ensureLocationsTable() {
  await query(`
    CREATE TABLE IF NOT EXISTS locations (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(100) NOT NULL UNIQUE,
      is_active TINYINT(1) NOT NULL DEFAULT 1
    )
  `);

  const rows = await query('SELECT COUNT(*) AS total FROM locations');
  const hasData = Number(rows[0]?.total || 0) > 0;
  if (hasData) return;

  await query(
    `
      INSERT INTO locations (name, is_active) VALUES
      (?, 1),
      (?, 1),
      (?, 1),
      (?, 1),
      (?, 1)
    `,
    ['Colombo 01', 'Colombo 02', 'Colombo 03', 'Nugegoda', 'Maharagama']
  );
}

async function ensureDefaultAdmin() {
  if (!(await hasTable('admin'))) return;

  const rows = await query('SELECT COUNT(*) AS total FROM admin');
  const hasData = Number(rows[0]?.total || 0) > 0;
  if (hasData) return;

  await query('INSERT INTO admin (username, password) VALUES (?, ?)', [
    'restaurant',
    md5('password123'),
  ]);
}

async function ensureCompatSchema() {
  if (ensurePromise) {
    return ensurePromise;
  }

  ensurePromise = (async () => {
    await ensureColumn(
      'customers',
      'role',
      "ENUM('customer','delivery','admin') NOT NULL DEFAULT 'customer'"
    );
    await ensureColumn('customers', 'location', 'VARCHAR(100) NULL');
    await ensureColumn(
      'orders',
      'cancel_request',
      "ENUM('no','pending','approved') NOT NULL DEFAULT 'no'"
    );
    await ensureColumn('orders', 'customer_name', 'VARCHAR(100) NULL');
    await ensureMenuTable();
    await ensureLocationsTable();
    await ensureDefaultAdmin();
  })();

  try {
    await ensurePromise;
  } catch (error) {
    ensurePromise = null;
    throw error;
  }
}

module.exports = {
  query,
  hasTable,
  hasColumn,
  ensureCompatSchema,
};
