const base = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:5002/api/v1').replace(/\/$/, '');
const sessionKey = 'gamotech.adminKey';
let adminKey = '';
try { adminKey = sessionStorage.getItem(sessionKey) || ''; } catch { /* Storage may be unavailable. */ }
export function getAdminKey() { return adminKey; }
export function setAdminKey(key, persist = false) {
  adminKey = key;
  try {
    if (!key) sessionStorage.removeItem(sessionKey);
    else if (persist) sessionStorage.setItem(sessionKey, key);
  } catch { /* Keep login usable when browser storage is unavailable. */ }
}
export async function api(path, options = {}) {
  const response = await fetch(`${base}${path}`, {
    ...options,
    headers: { 'Content-Type': 'application/json', ...(adminKey ? { Authorization: `Bearer ${adminKey}` } : {}), ...options.headers },
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const error = new Error([body.message || `Request failed (${response.status})`, ...(body.errors || [])].join(' · '));
    error.status = response.status;
    throw error;
  }
  return body;
}
export const date = value => value ? new Date(value).toLocaleString('en-IN') : '—';
export const money = value => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format((value || 0) / 100);
