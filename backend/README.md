# Backend API

Home banner endpoints are available under `/api/v1/home-banners`.

## Create a home banner

`POST /api/v1/home-banners` with `Content-Type: application/json`:

```json
{
  "title": "Play and win",
  "imageUrl": "https://example.com/banners/play-and-win.jpg",
  "linkUrl": "https://example.com/tournaments",
  "sortOrder": 0
}
```

`title` is a required, nonblank string of at most 200 characters. `imageUrl`
is a required absolute HTTP(S) URL. `linkUrl` is optional and must also be an
absolute HTTP(S) URL when supplied. `sortOrder` is an optional nonnegative safe
integer, defaulting to `0`; lower values appear first. Unknown fields are ignored.

Returns `201` with `{ "message": "Home banner created successfully", "banner": {...} }`.
The saved banner includes `_id`, `createdAt`, and `updatedAt`.
Invalid fields return `400`; database failures return `500`.

## List home banners

`GET /api/v1/home-banners`

Returns `200` with `{ "message": "Home banners fetched successfully", "banners": [...] }`.
Banners are sorted by `sortOrder` ascending, then newest first. An empty
collection returns an empty array. Database failures return `500`.

These routes follow the backend's existing unauthenticated route convention.

## Seed home banners

With `MONGO_URI` configured in `backend/.env`, run `npm run seed:home-banners`
from the `backend` directory. This inserts the supplied Teen Patti, Ludo, Rummy,
and Poker images in that order. The script matches by image URL, skips existing
banners, preserves other records, and verifies the seeded images after writing.

## Run checks

Run `node --test` from the `backend` directory. HTTP contract tests use model
stubs and real Mongoose validation; they do not connect to MongoDB.

## User wallets

`Wallet` stores a required, unique `user` reference, `balance` (default `0`),
`currency` (`INR`), and timestamps. Amounts use integer paise: `2500` means
INR 25. Negative, fractional, and unsafe integer balances are rejected.

`POST /api/v1/signup` and `/api/v1/create-user` now create the user and their
wallet together in a MongoDB transaction and return
`{ "message": "User created successfully", "user": {...}, "wallet": {...} }`.
Incoming wallet or balance fields are ignored. MongoDB must support transactions
(a replica set or sharded cluster, including Atlas). Future registration paths
should use `services/registrationService.js` to preserve this behavior.

Users have a virtual one-to-one relation; load it with
`User.findById(userId).populate("wallet")`. The stored owner link lives on the
wallet so it cannot disagree with a second stored link on the user.

Run `npm run backfill:wallets` from `backend` to create zero-balance wallets for
existing users. It initializes the wallet and record collections and their
indexes, preserves existing wallets and balances, and verifies every user has
a wallet. It is safe to rerun.

## Wallet records

`WalletRecord` is a separate collection for completed balance movements:

- `wallet`: required reference to `Wallet`; the wallet determines the owner.
- `type`: `credit` or `debit`.
- `amount`: positive safe integer paise.
- `balanceBefore` and `balanceAfter`: nonnegative safe integer paise; validated
  against the movement type and amount.
- `reason`: `deposit`, `withdrawal`, `game_entry`, `winnings`, `refund`, `bonus`,
  or `adjustment`.
- `reference`: required, globally unique transaction reference for duplicate detection.
- `description`: optional text, plus automatic timestamps.

History is indexed by wallet and creation time. Transaction fields are immutable
through normal Mongoose document updates. Creating a record does not itself
change a wallet's balance. Any future credit/debit service must update the balance
and insert its record in the same transaction, with a sufficient-balance condition
for debits. This change adds the data models and registration provisioning;
deposit/withdrawal endpoints are not part of it.

### Read the signed-in wallet and history

`GET /api/v1/wallet?page=1` requires `Authorization: Bearer <sign-in token>`.
Returns `{ wallet: { balance, currency }, records: [...], page, hasMore }`.
All amounts are integer paise. Records are sorted newest first, 20 per page.
The verified token identifies the user; records are filtered by that user's
wallet. Caller-supplied user and wallet IDs do not select another account.
Missing/expired/invalid tokens return 401, a missing wallet 404, malformed page
400, and service/database failures 503/500. Responses disable caching.

### Daily bonus

`GET /api/v1/wallet/daily-bonus` returns `{ amount, claimed, nextClaimAt }`.
`POST /api/v1/wallet/daily-bonus/claim` credits the authenticated user's wallet
and creates a `bonus` credit record in one MongoDB transaction, returning the
updated `{ wallet, amount, claimed, nextClaimAt }`. Both require the sign-in
Bearer token. The server selects the amount; request amounts are ignored.
`DAILY_BONUS_PAISE` defaults to `10000` (₹100). Claims reset at midnight India time.
A unique wallet-and-day record reference prevents duplicate awards; repeat
claims return 409. Missing wallets return 404. MongoDB must support transactions.
