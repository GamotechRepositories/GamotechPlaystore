import { useState } from 'react';
import { BrowserRouter, Routes, Route, NavLink, Outlet, Link } from 'react-router-dom';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import Games from './pages/Games';
import AddGame from './pages/AddGame';
import Transactions from './pages/Transactions';
import { api, setAdminKey } from './lib/api';
const navigation = [['/', 'Dashboard', 'M3 3h7v7H3z M14 3h7v7h-7z M3 14h7v7H3z M14 14h7v7h-7z'], ['/users', 'Users', 'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2 M16 3a4 4 0 0 1 0 8 M22 21v-2a4 4 0 0 0-3-3.87 M13 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0'], ['/games', 'Games', 'M7 8h10a5 5 0 0 1 5 5v4a3 3 0 0 1-5 2l-2-2H9l-2 2a3 3 0 0 1-5-2v-4a5 5 0 0 1 5-5z M7 11v6 M4 14h6 M16 12h.01 M19 15h.01'], ['/transactions', 'Transactions', 'M3 7h17 M16 3l4 4-4 4 M21 17H4 M8 13l-4 4 4 4']];
function Layout({ disconnect }) {
  return <div className="min-h-screen md:flex"><aside className="border-b border-slate-200 bg-white p-5 md:sticky md:top-0 md:flex md:h-screen md:w-56 md:shrink-0 md:flex-col md:border-r md:border-b-0"><Link to="/" className="flex items-center gap-3 font-bold tracking-wide"><span className="flex h-9 w-9 items-center justify-center rounded-xl bg-emerald-800 text-white">G</span>GAMOTECH</Link><p className="mb-4 mt-9 text-slate-400">ADMIN WORKSPACE</p><nav className="flex flex-wrap gap-2 md:flex-col" aria-label="Main navigation">{navigation.map(([to, label, icon]) => <NavLink key={to} to={to} end={to === '/'} className={({ isActive }) => `flex items-center gap-3 rounded-lg px-3 py-3 font-medium ${isActive ? 'bg-emerald-50 text-emerald-800' : 'text-slate-600 hover:bg-slate-50'}`}><svg aria-hidden="true" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d={icon}/></svg>{label}</NavLink>)}</nav><div className="mt-8 border-t border-slate-100 pt-4 md:mt-auto"><p className="font-medium">Platform administration</p><button onClick={disconnect} className="mt-3 text-slate-500 underline">Disconnect</button></div></aside><div className="min-w-0 flex-1"><header className="flex items-center justify-between border-b border-slate-200 bg-white px-5 py-5 md:px-8"><span className="text-slate-500">Gamotech / Control center</span><span className="badge credit">Admin workspace</span></header><main className="mx-auto max-w-7xl p-5 md:p-8"><Outlet/></main></div></div>;
}
export default function App() {
  const [connected, setConnected] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  async function connect(event) {
    event.preventDefault(); setBusy(true); setError('');
    setAdminKey(new FormData(event.currentTarget).get('key'));
    try { await api('/admin/overview'); setConnected(true); }
    catch (failure) { setAdminKey(''); setError(failure.message); }
    finally { setBusy(false); }
  }
  if (!connected) return <main className="flex min-h-screen items-center justify-center p-6"><form onSubmit={connect} className="panel w-full max-w-sm p-8"><p className="font-bold tracking-widest text-emerald-800">GAMOTECH ADMIN</p><h1 className="mt-7 text-xs font-bold">Connect to your workspace</h1><p className="mb-6 mt-2 text-slate-500">Enter your admin key to manage players, games, and transactions.</p>{error && <p role="alert" className="mb-4 text-red-700">{error}</p>}<label>Admin key<input type="password" name="key" required autoComplete="off"/></label><button className="button mt-5 w-full" disabled={busy}>{busy ? 'Connecting…' : 'Connect workspace'}</button></form></main>;
  return <BrowserRouter><Routes><Route element={<Layout disconnect={() => { setAdminKey(''); setConnected(false); }}/> }><Route index element={<Dashboard/>}/><Route path="users" element={<Users/>}/><Route path="games" element={<Games/>}/><Route path="games/new" element={<AddGame/>}/><Route path="transactions" element={<Transactions/>}/><Route path="*" element={<div className="panel p-8">Page not found. <Link className="text-emerald-700 underline" to="/">Return to dashboard</Link></div>}/></Route></Routes></BrowserRouter>;
}
