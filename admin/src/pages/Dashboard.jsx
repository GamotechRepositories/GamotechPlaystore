import { Link } from 'react-router-dom';
import useApi from '../lib/useApi';
import { Heading, Feedback } from '../components/Shared';
export default function Dashboard() {
  const state = useApi('/admin/overview');
  return <><Heading title="Dashboard" description="Your gaming platform at a glance."/><Feedback {...state}/>{state.data && <><div className="grid gap-4 sm:grid-cols-3">{[['users', 'Registered users', '/users'], ['games', 'Games in catalog', '/games'], ['transactions', 'Wallet transactions', '/transactions']].map(([key, label, url]) => <Link key={key} to={url} className="panel p-6 hover:border-emerald-400"><p className="text-slate-500">{label}</p><p className="my-4 font-bold text-slate-900">{state.data[key].toLocaleString()}</p><span className="text-emerald-700">View records ↗</span></Link>)}</div><div className="panel mt-6 flex flex-wrap items-center justify-between gap-4 p-6"><div><h2 className="font-semibold">Build your next player experience</h2><p className="mt-2 text-slate-500">Add a game to make it available in your app catalog.</p></div><Link className="button" to="/games/new">+ Add game</Link></div></>}</>;
}
