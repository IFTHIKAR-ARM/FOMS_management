const bcrypt = require('bcryptjs');
const crypto = require('crypto');

function normalizePhpBcryptHash(hash) {
  if (typeof hash !== 'string') {
    return '';
  }
  if (hash.startsWith('$2y$')) {
    return `$2a$${hash.slice(4)}`;
  }
  return hash;
}

function md5(value) {
  return crypto.createHash('md5').update(String(value)).digest('hex');
}

function verifyUserPassword(plain, stored) {
  if (typeof stored !== 'string' || stored.trim() === '') {
    return false;
  }

  const hash = normalizePhpBcryptHash(stored.trim());
  if (!hash.startsWith('$2')) {
    return false;
  }

  try {
    return bcrypt.compareSync(String(plain), hash);
  } catch (_) {
    return false;
  }
}

function verifyAdminPassword(plain, stored) {
  return verifyUserPassword(plain, stored) || md5(plain) === String(stored || '');
}

function hashUserPassword(plain) {
  return bcrypt.hashSync(String(plain), 10);
}

module.exports = {
  md5,
  verifyUserPassword,
  verifyAdminPassword,
  hashUserPassword,
};
