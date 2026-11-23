# stealth_chat

Instagram-style decoy client with a covert direct-message room underneath.

## Backend (Supabase)

The covert layer runs on Supabase: email/password auth from the
authorization card, a `users` directory keyed by username, and one
`dm_messages` table for the threads.

### 1. Create the project

1. <https://supabase.com/dashboard> → **New project** (any name / region /
   database password).
2. Wait for provisioning, then open **Project Settings → Data API** and copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon / publishable key** → `SUPABASE_ANON_KEY`
3. Put both in `.env` (template: `.env.example`).

   Phone builds cannot read a project file at runtime, so the same two values
   are also bundled as `assets/env.json`. Regenerate it whenever the keys
   change (it is gitignored, like `.env`):

   ```bash
   python -c "import json,re;s=dict(re.findall(r'^([A-Z_]+)=(.*)$',open('.env').read(),re.M));open('assets/env.json','w').write(json.dumps({k:s[k] for k in ('SUPABASE_URL','SUPABASE_ANON_KEY')},indent=2))"
   ```

   Explicit flags still win over both files:

   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=<anon key>
   ```

### 2. Create the tables

Open **SQL Editor → New query**, paste
[`supabase/migrations/0001_init.sql`](supabase/migrations/0001_init.sql), run it,
then paste and run
[`supabase/migrations/0002_contacts_and_media.sql`](supabase/migrations/0002_contacts_and_media.sql).
The first creates `users`, `dm_messages`, the row-level-security policies, the
`login_email_for(handle)` lookup used by "log in with a username", and the
trigger that mirrors every new auth user into `users`. The second adds the
`dm_contacts` friend list, the image/voice columns on `dm_messages`, and the
public `dm-media` storage bucket.

### 3. Auth settings

- **Authentication → Sign In / Providers → Email**: keep it on. If
  *Confirm email* is on, the card asks the user to confirm before the first
  login; turn it off while developing.
- **Authentication → URL Configuration**: add
  `io.supabase.stealthchat://login-callback` as a redirect URL if an OAuth
  provider is added later.

## What the app does with it

| Layer | File |
| --- | --- |
| SDK boot + session | `lib/backend/supabase_client.dart` |
| Login / sign-up / profile sync | `lib/backend/auth_service.dart` |
| Username directory (`findByUsername`, `searchUsernames`, `claimUsername`) | `lib/backend/users_service.dart` |
| Friend list | `lib/backend/contacts_service.dart` |
| Send / read / mark-read DMs, image + voice rows | `lib/backend/messages_service.dart` |
| Attachment uploads (`dm-media`) | `lib/backend/storage_service.dart` |

## Two inboxes

- **Messages tab** (`lib/screens/dm_screen.dart`) — the decoy. Seeded people,
  notes and previews from `lib/data/fixtures.dart`, held in memory only. Tapping
  a row opens a fixture conversation (`lib/screens/mock_chat_screen.dart`).
- **Hidden session** (`lib/screens/stealth_session_screen.dart`) — the real one.
  **Long-press the profile picture in the bottom bar** to open it; nothing else
  in the UI leads there. It reads `dm_contacts` / `dm_messages` and talks to no
  fixtures.

**Adding another user:** in the hidden session tap the person-add icon (or the
button in the empty state), search a username and hit **Add**. They land in
`dm_contacts` and the list shows only the people you added — with no friends it
reads "Add friends to start chatting". Tapping a row opens the real thread;
photos and recorded voice notes upload to the bucket and arrive as messages.

Without keys the app still opens: the splash hands off to the authorization
card, which shows the missing-keys warning instead of calling the backend.

## Run

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter test
```
