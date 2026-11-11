const base = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:5002/api/v1').replace(/\/$/, '');
let adminKey = '';
export function setAdminKey(key) { adminKey = key; }
export async function api(path, options = {}) {
  const response = await fetch(`${base}${path}`, {
    ...options,
    headers: { 'Content-Type': 'application/json', ...(adminKey ? { Authorization: `Bearer ${adminKey}` } : {}), ...options.headers },
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error([body.message || `Request failed (${response.status})`, ...(body.errors || [])].join(' · '));
  return body;
}
export const date = value => value ? new Date(value).toLocaleString('en-IN') : '—';
export const money = value => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format((value || 0) / 100);
