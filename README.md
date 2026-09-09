# Comptaflow

Mobile business companion for Moroccan auto-entrepreneurs.

## Foundation

- Flutter + Material 3
- Arabic/French localization with Flutter `gen-l10n`
- Supabase Auth (phone OTP foundation + email/password repository support)
- Supabase Postgres models/repositories
- RLS ownership policies for user data
- CPU calculator foundation for activity-based rates
- Provider state management
- Persisted language preference

## Project structure

```text
lib/
  core/services/
  l10n/
  data/models/
  data/repositories/
  providers/
  screens/auth/
  screens/dashboard/
  screens/invoices/
  screens/clients/
  screens/cpu/
  screens/settings/
  main.dart
supabase/
  schema.sql
```

## Local setup

1. Install Flutter and create the platform scaffolding if this repository is cloned as a source-only project:

```bash
flutter create .
```

2. Install packages:

```bash
flutter pub get
```

3. Apply `supabase/schema.sql` in the Supabase SQL editor for the project used by this app.

4. Run with the Supabase project URL and **publishable key** supplied as compile-time values:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Never put a `service_role`/secret key in the Flutter client.

## Authentication flow

`AuthProvider` listens to `supabase.auth.onAuthStateChange`. A signed-out user sees Login; after phone OTP verification, the app checks `profiles` and routes a new user to Complete Profile before Dashboard.

## Next implementation phase

1. Finish profile validation and sync.
2. Build clients CRUD.
3. Build invoice creation/editing with line items and totals.
4. Generate invoice PDFs and secure Storage paths.
5. Build CPU declarations and period history.
6. Add notifications/reminders.
7. Add tests and Android CI/release workflow.
