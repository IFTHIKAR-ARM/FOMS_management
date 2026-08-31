# Vercel Backend Migration (PHP-Compatible Routes)

This project now includes Node.js Vercel Functions that mirror the app-used PHP endpoints without changing Flutter request URLs.

## Implemented Function Routes

These functions are in `api/*.js`:

- `api/login.js`
- `api/unified_login.js`
- `api/admin_login.js`
- `api/register.js`
- `api/get_locations.js`
- `api/get_menu.js`
- `api/get_orders.js`
- `api/place_order.js`
- `api/request_cancel_api.js`
- `api/update_order_api.js`
- `api/admin_orders_api.js`

`vercel.json` rewrites keep old PHP paths working, for example:

- `/api/login.php` -> `/api/login`
- `/api/get_menu.php` -> `/api/get_menu`

## Required Environment Variables

Set these in Vercel project settings:

- `DB_HOST`
- `DB_PORT` (usually `3306`)
- `DB_USER`
- `DB_PASSWORD`
- `DB_NAME` (for this project: `food_system`)

Optional:

- `FOMS_ADMIN_LOGIN_KEY` (default fallback: `FOMS2026`)
- `PUBLIC_ASSET_BASE` (example on Vercel: `/public_assets/images`)

## Notes

- Existing PHP files are untouched for local XAMPP usage.
- Functions include schema compatibility checks (role/location/cancel_request/customer_name, menu table, locations table, default admin).
- Node dependencies are declared in root `package.json`.
