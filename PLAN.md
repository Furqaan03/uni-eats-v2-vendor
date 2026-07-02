# Vendor Onboarding — Implementation Plan

Source spec: `~/Downloads/vendor-onboarding-implementation.md`. This file tracks how that
spec maps onto the **actual** repos on disk and the decisions taken where they diverge.

## Ground truth (differs from the spec's assumptions)

| Spec assumes | Reality on disk |
| --- | --- |
| `app_restaurant-main` (vendor Flutter app) | `uni-eats-v2-vendor-main` — this repo. Provider state mgmt. |
| `app_admin-main` (Flutter admin) | `uni-eats-v2-infra/admin-dashboard/public/index.html` — a single static HTML/JS dashboard. |
| Cloud Functions `functions/index.js` with `sendOtp` etc. | **No Functions codebase exists anywhere.** Being bootstrapped fresh in `uni-eats-v2-infra/functions` (Node 20). |
| Firestore/Storage rules | `uni-eats-v2-infra/firestore.rules` exists (env-aware). No `storage.rules` — being created. |

**Scope authorized this effort:** vendor app + infra only. Admin dashboard work (Phases 2 & 6)
is deferred → captured in `../ADMIN_DASHBOARD_TODO.md` for later.

**Email:** Resend key not yet provisioned. Code paths built; key read from functions config
(`RESEND_API_KEY`) — placeholder until supplied. Test sends go to Mujii's email (ask when needed).

**Do not deploy / do not commit** until Mujii says so.

## Environment model (must respect)

`AppEnv` (lib/services/firestore_order_service.dart): `test` → unprefixed collections (current
default), `live` → `live_`-prefixed. `restaurants` and `admins` are shared (never prefixed).
New `registrations` collection follows the same split: `registrations` + `live_registrations`.

## Key reconciliation decisions

1. **Claim gate vs. existing vendors-doc gate.** Existing rules derive vendor access from owning
   `vendors/{uid}` + `restaurants/{id}.ownerUid`. Adding `vendorStatus == "approved"` as a *hard*
   requirement on orders/menu/etc. would lock out every currently-live vendor until claims are
   backfilled. Decision: the **approval engine** (Admin SDK) is now the ONLY writer of
   `vendors/{uid}` docs; client `create` on `vendors` is removed. Post-migration `approved` ==
   has-vendors-doc == has-claim. A one-time backfill script sets claims for existing vendors.
   Operational-collection rules keep the `isVendorOf` boundary (already excludes pending accounts,
   who have no vendors doc), with `isApprovedVendor()`/`isPendingVendor()` helpers added for the
   registrations doc and future use. This keeps prod working while closing the self-serve hole.
2. **Self-serve signup replaced.** The old `signup_screen.dart` self-serve wizard (which let any
   signed-in user claim an unowned restaurant and mint their own vendors doc — an approval bypass)
   is retired from the routing tree. Account + vendors doc now only come into existence via the
   invite → approve path. Old files kept (spec: don't delete) but no longer routed to.
3. **Custom claims** (`vendorStatus`, `vendorRole`, `outletId`, `branchId`) are new; set only by
   functions via Admin SDK; client reads via `getIdTokenResult()`.

## Build sequence & status

- [x] Phase 0 — rules (firestore registrations + storage.rules + firebase.json wiring)
- [x] Phase 1 — Registration model (Dart) + composite indexes
- [x] Phase 4 — approval engine + claims + backfill (functions)
- [x] Phase 3 — email + auto-login token + bounce webhook (functions)
- [x] Phase 5 — vendor pending shell + 4 screens + claim routing + deep link + cold-apply
- [x] Phase 7 — analytics + `../ADMIN_DASHBOARD_TODO.md`
- Deferred — Phase 2 (rep invite) & Phase 6 (admin queue): admin dashboard, see TODO doc.

## Not yet done / needs Mujii (nothing deployed, nothing committed)

- **Deploy** rules, indexes, storage rules, and functions (Blaze + `firebase deploy`).
- **Run** `scripts/backfill_vendor_claims.js` (test + live) BEFORE relying on claim-gated
  behaviour, so existing vendors get `vendorStatus: approved`.
- **Resend**: set `RESEND_API_KEY` secret + `RESEND_FROM`/`OPS_EMAIL`/`DOWNLOAD_URL`; until
  then email is skipped (logged), the rest works.
- **Consequence of the new rules**: the old self-serve email signup + first-time Google-vendor
  setup now fail (client `vendors` create denied). New vendors go through invite / cold-apply →
  approval. Existing vendors keep working. `signup_screen.dart` / `google_vendor_setup_screen.dart`
  kept but no longer the entry path.
- **New packages added**: `cloud_functions`, `app_links` (approved), and `firebase_storage`
  (required for doc upload — flag if you object).
- Document upload uses `image_picker` (photo of the doc). PDF file-picking would need
  `file_picker` — not added.

## Firebase project

`uni-eats-v2-aabf5`. Functions bootstrap requires Blaze + deploy access (Mujii to deploy).
