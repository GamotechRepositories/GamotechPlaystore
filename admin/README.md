# Gamotech Admin

React + Tailwind CSS admin with React Router pages at `/`, `/users`, `/games`,
`/games/new`, and `/transactions`. All interface text uses `text-xs`.

1. Set a strong `ADMIN_API_KEY` in `backend/.env` and start the backend.
2. Copy `.env.example` to `.env` and set `VITE_API_BASE_URL` to the full backend API URL
   (for example, `http://localhost:5002/api/v1`). Requests go directly to the backend.
3. Run `npm install` if needed, then `npm run dev` in `admin`.
4. Enter the backend admin key on the connection screen. The key stays in memory
   and is cleared on reload or disconnect; do not put it in a VITE variable.

The dashboard and paginated users/transactions pages use protected
`GET /api/v1/admin/overview`, `/admin/users?page=1`, and
`/admin/transactions?page=1` endpoints with a Bearer admin key. Transactions
are completed wallet records, and amounts are converted from paise to INR.
User passwords and Google IDs are excluded from API responses.
Games use the existing `GET /api/v1/games` and `POST /api/v1/games` APIs.
The existing game creation endpoint retains its public backend behavior.

Run `npm run build` for production. Set `VITE_API_BASE_URL` to the hosted
backend API URL and allow the admin origin via backend `CORS_ORIGINS`.
Restart Vite after changing environment variables. Configure SPA fallback to `index.html` for page reloads.
Use HTTPS for a hosted admin panel.
