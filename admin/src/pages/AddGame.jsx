import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { api } from '../lib/api';
import { Heading } from '../components/Shared';
export default function AddGame() {
  const navigate = useNavigate();
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  async function submit(event) {
    event.preventDefault();
    const values = Object.fromEntries(new FormData(event.currentTarget));
    for (const key of Object.keys(values)) values[key] = values[key].trim();
    values.sortOrder = Number(values.sortOrder);
    if (!values.linkUrl) delete values.linkUrl;
    if (!Number.isSafeInteger(values.sortOrder) || values.sortOrder < 0) { setError('Display order must be a nonnegative safe integer.'); return; }
    setSaving(true); setError('');
    try { await api('/games', { method: 'POST', body: JSON.stringify(values) }); navigate('/games', { replace: true, state: { created: true } }); }
    catch (failure) { setError(failure.message); setSaving(false); }
  }
  return <><Heading title="Add game" description="Create a new game for your app catalog."/><form onSubmit={submit} className="panel max-w-3xl p-6"><div className="mb-6 border-b border-slate-100 pb-4 font-semibold">Game details</div>{error && <p role="alert" className="mb-4 rounded-lg bg-red-50 p-4 text-red-700">{error}</p>}<fieldset disabled={saving} className="grid gap-5 sm:grid-cols-2"><label>Game name *<input name="name" required maxLength={200} placeholder="e.g. Ludo"/></label><label>Display order<input name="sortOrder" type="number" min="0" step="1" defaultValue="0" required/></label><label className="sm:col-span-2">Image URL *<input name="imageUrl" type="url" pattern="https?://.*" required placeholder="https://example.com/ludo.png"/><span className="mt-2 block text-slate-500">Use a publicly accessible HTTP or HTTPS image.</span></label><label className="sm:col-span-2">Description<textarea name="description" rows="4" maxLength={2000} placeholder="Tell players about this game"/></label><label className="sm:col-span-2">Play URL<input name="linkUrl" type="url" pattern="https?://.*" placeholder="https://example.com/play/ludo"/></label></fieldset><div className="mt-6 flex justify-end gap-3 border-t border-slate-100 pt-5">{!saving && <Link className="button secondary" to="/games">Cancel</Link>}<button className="button" disabled={saving}>{saving ? 'Creating game…' : 'Create game'}</button></div></form></>;
}
