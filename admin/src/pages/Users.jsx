import { useState } from 'react';
import useApi from '../lib/useApi';
import { date } from '../lib/api';
import { Heading, Feedback, Pagination } from '../components/Shared';
export default function Users() {
  const [page, setPage] = useState(1);
  const state = useApi(`/admin/users?page=${page}`);
  return <><Heading title="Users" description="Browse registered player accounts."/><Feedback {...state}/>{state.data && <div className="panel overflow-hidden"><div className="overflow-x-auto"><table><thead><tr><th>Player</th><th>Email address</th><th>User ID</th><th>Joined</th></tr></thead><tbody>{state.data.users.map(user => <tr key={user._id}><td className="font-semibold">{user.username}</td><td>{user.email}</td><td className="font-mono text-slate-500">{user._id}</td><td>{date(user.createdAt)}</td></tr>)}{!state.data.users.length && <tr><td colSpan="4" className="text-center">No users yet.</td></tr>}</tbody></table></div><Pagination {...state.data} setPage={setPage}/></div>}</>;
}
