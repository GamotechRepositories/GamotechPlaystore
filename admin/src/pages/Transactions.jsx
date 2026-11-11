import { useState } from 'react';
import useApi from '../lib/useApi';
import { date, money } from '../lib/api';
import { Heading, Feedback, Pagination } from '../components/Shared';
export default function Transactions() {
  const [page, setPage] = useState(1);
  const state = useApi(`/admin/transactions?page=${page}`);
  return <><Heading title="Transactions" description="Completed credits and debits across player wallets."/><Feedback {...state}/>{state.data && <div className="panel overflow-hidden"><div className="overflow-x-auto"><table><thead><tr>{['Reference', 'Player', 'Type', 'Reason', 'Amount', 'Balance after', 'Date'].map(label => <th key={label}>{label}</th>)}</tr></thead><tbody>{state.data.transactions.map(record => <tr key={record._id}><td className="font-mono">{record.reference}</td><td>{record.wallet?.user?.username || 'Deleted user'}</td><td><span className={`badge ${record.type === 'credit' ? 'credit' : 'debit'}`}>{record.type}</span></td><td>{record.reason.replaceAll('_', ' ')}</td><td className="whitespace-nowrap font-semibold">{record.type === 'credit' ? '+' : '−'}{money(record.amount)}</td><td>{money(record.balanceAfter)}</td><td className="whitespace-nowrap">{date(record.createdAt)}</td></tr>)}{!state.data.transactions.length && <tr><td colSpan="7" className="text-center">No transactions yet.</td></tr>}</tbody></table></div><Pagination {...state.data} setPage={setPage}/></div>}</>;
}
