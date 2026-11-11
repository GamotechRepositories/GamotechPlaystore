export function Heading({ title, description, children }) {
  return <div className="mb-6 flex flex-wrap items-center justify-between gap-4"><div><p className="mb-2 text-slate-500">WORKSPACE / {title.toUpperCase()}</p><h1 className="text-xs font-bold text-slate-900">{title}</h1><p className="mt-2 text-slate-500">{description}</p></div>{children}</div>;
}
export function Feedback({ loading, error, reload }) {
  if (loading) return <div role="status" className="panel p-8 text-slate-500">Loading records…</div>;
  if (error) return <div role="alert" className="panel p-6 text-red-700">{error}<button className="button secondary ml-4" onClick={reload}>Try again</button></div>;
  return null;
}
export function Pagination({ page, hasMore, total, setPage }) {
  return <div className="flex items-center justify-between gap-3 border-t border-slate-100 p-4"><span className="text-slate-500">{total} records · Page {page}</span><div className="flex gap-2"><button className="button secondary" disabled={page === 1} onClick={() => setPage(page - 1)}>Previous</button><button className="button secondary" disabled={!hasMore} onClick={() => setPage(page + 1)}>Next</button></div></div>;
}
