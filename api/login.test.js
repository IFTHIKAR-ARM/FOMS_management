const login = require('./login');
const { sendJson, readJson, handleOptions, setCors } = require('./_vercel/http');
const { ensureCompatSchema, hasColumn, query } = require('./_vercel/db');
const { verifyUserPassword } = require('./_vercel/passwords');

jest.mock('./_vercel/http', () => ({
  handleOptions: jest.fn(),
  setCors: jest.fn(),
  readJson: jest.fn(),
  sendJson: jest.fn(),
}));

jest.mock('./_vercel/db', () => ({
  ensureCompatSchema: jest.fn(),
  hasColumn: jest.fn(),
  query: jest.fn(),
}));

jest.mock('./_vercel/passwords', () => ({
  verifyUserPassword: jest.fn(),
}));

describe('Login API', () => {
  let req;
  let res;

  beforeEach(() => {
    req = { method: 'POST' };
    res = {};
    handleOptions.mockClear();
    setCors.mockClear();
    readJson.mockClear();
    sendJson.mockClear();
    ensureCompatSchema.mockClear();
    hasColumn.mockClear();
    query.mockClear();
    verifyUserPassword.mockClear();
  });

  it('should handle OPTIONS request', async () => {
    req.method = 'OPTIONS';
    await login(req, res);
    expect(handleOptions).toHaveBeenCalledWith(req, res, 'POST,OPTIONS');
  });

  it('should return 405 for non-POST requests', async () => {
    req.method = 'GET';
    await login(req, res);
    expect(sendJson).toHaveBeenCalledWith(
      res,
      { status: 'error', message: 'Method not allowed' },
      405
    );
  });

  it('should return error for incomplete data', async () => {
    readJson.mockReturnValue({});
    await login(req, res);
    expect(sendJson).toHaveBeenCalledWith(res, { status: 'error', message: 'Incomplete data' });
  });

  it('should return error for user not found', async () => {
    readJson.mockReturnValue({ phone: '123', password: 'password' });
    hasColumn.mockResolvedValue(true);
    query.mockResolvedValue([]);
    await login(req, res);
    expect(query).toHaveBeenCalledWith(
      'SELECT name, phone, password, role, location FROM customers WHERE phone = ?',
      ['123']
    );
    expect(sendJson).toHaveBeenCalledWith(res, { status: 'error', message: 'User not found' });
  });

  it('should return error for invalid password', async () => {
    readJson.mockReturnValue({ phone: '123', password: 'password' });
    hasColumn.mockResolvedValue(true);
    query.mockResolvedValue([
      {
        name: 'Test User',
        phone: '123',
        password: 'hashed_password',
        role: 'customer',
        location: 'Test Location',
      },
    ]);
    verifyUserPassword.mockReturnValue(false);
    await login(req, res);
    expect(verifyUserPassword).toHaveBeenCalledWith('password', 'hashed_password');
    expect(sendJson).toHaveBeenCalledWith(res, {
      status: 'error',
      message: 'Invalid phone number or password',
    });
  });

  it('should return error for admin login', async () => {
    readJson.mockReturnValue({ phone: '123', password: 'password' });
    hasColumn.mockResolvedValue(true);
    query.mockResolvedValue([
      {
        name: 'Test Admin',
        phone: '123',
        password: 'hashed_password',
        role: 'admin',
        location: 'Test Location',
      },
    ]);
    verifyUserPassword.mockReturnValue(true);
    await login(req, res);
    expect(sendJson).toHaveBeenCalledWith(res, {
      status: 'error',
      message: 'Admin login is separate',
    });
  });

  it('should return success for valid login', async () => {
    readJson.mockReturnValue({ phone: '123', password: 'password' });
    hasColumn.mockResolvedValue(true);
    query.mockResolvedValue([
      {
        name: 'Test User',
        phone: '123',
        password: 'hashed_password',
        role: 'customer',
        location: 'Test Location',
      },
    ]);
    verifyUserPassword.mockReturnValue(true);
    await login(req, res);
    expect(sendJson).toHaveBeenCalledWith(res, {
      status: 'success',
      message: 'Login successful',
      user: {
        name: 'Test User',
        phone: '123',
        role: 'customer',
        location: 'Test Location',
      },
    });
  });
});
