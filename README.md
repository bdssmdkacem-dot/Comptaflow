# ComptaFlow

**ComptaFlow** is a mobile business companion for Moroccan auto-entrepreneurs, designed to centralize clients, products, invoices, expenses and CPU tracking in one professional Flutter application.

The project is being developed as a **complete production application**, not only as an MVP.

---

## 1. Product vision

ComptaFlow should provide a complete business workflow:

**Account → Company profile → Clients → Products → Invoices → PDF → Expenses → CPU → Dashboard → Settings → Notifications → Tests → Release**

The application is designed for Arabic/French use and uses Supabase for authentication and user-owned business data.

---

# 2. Development status

The project has already moved beyond the initial foundation stage.

### Current status

| Area | Status | Current state |
|---|---|---|
| Flutter architecture | ✅ Done | Core project structure established |
| Material 3 design system | ✅ Done | Dark professional ComptaFlow theme |
| Arabic/French localization foundation | 🟢 In progress | `gen-l10n` and locale persistence exist; remaining screens need full localization audit |
| Supabase foundation | ✅ Done | Auth, Postgres repositories and RLS foundation |
| Authentication | ✅ Done / QA pending | Phone OTP foundation + email/password repository support |
| Company profile | ✅ Done / QA pending | Legal/company fields integrated into signup/profile flow |
| Dashboard | ✅ Implemented | Revenue, collection, receivables, expenses, VAT and balance metrics |
| Clients | 🟢 Implemented | CRUD foundation exists; needs final UX/validation/QA pass |
| Products | 🟢 Implemented | Product management exists; needs final UX/validation/QA pass |
| Invoices | 🟢 Implemented | Creation, editing, lines, totals, draft/issued workflow, details and actions |
| Invoice PDF | 🟢 Implemented | Professional A4 visual design completed; final rendering QA remains |
| Expenses | 🟢 Implemented | Expense area exists; needs final business-rule and UX QA |
| CPU | 🟢 Implemented / foundation | Calculator and declaration foundation exists; full production workflow remains |
| Storage | 🟡 Partial | PDF URL field exists; secure Supabase Storage workflow must be completed/verified |
| Notifications | 🔴 Remaining | Reminder/notification system still needs implementation |
| Automated tests | 🟡 Partial | Existing tests/fixes exist; final coverage and regression suite remain |
| Android CI/release | 🟡 Partial | CI foundation exists; final release pipeline and artifact validation remain |
| Production hardening | 🔴 Remaining | Security, offline/error handling, performance, accessibility and final QA |
| Store release | 🔴 Remaining | Final Play release preparation after all QA gates pass |

---

# 3. Completed development phases

## Phase 0 — Product definition

### Goal
Define ComptaFlow as a Moroccan business-management application rather than a simple invoice generator.

### Scope established

- Company/business profile
- Clients
- Products/services
- Invoices
- Invoice items
- Expenses
- CPU declarations
- Dashboard
- Settings
- Arabic/French support
- Supabase backend
- Secure user ownership through RLS

**Status: ✅ Completed**

---

## Phase 1 — Flutter foundation

### Implemented

- Flutter application structure
- Provider state management
- Core services layer
- Data models
- Repository layer
- Screens grouped by feature
- Localization with Flutter `gen-l10n`
- Persisted language preference
- Material 3 application shell

Project structure:

```text
lib/
  core/
    services/
    theme/
  l10n/
  data/
    models/
    repositories/
  providers/
  screens/
    auth/
    dashboard/
    invoices/
    clients/
    expenses/
    products/
    cpu/
    settings/
  main.dart
supabase/
  schema.sql
```

**Status: ✅ Completed**

---

## Phase 2 — Visual Design System

ComptaFlow now has a consistent Material 3 visual language.

### Main design characteristics

- Professional dark interface
- Deep teal/green brand identity
- High-contrast typography
- Rounded cards and controls
- Consistent input fields
- Consistent buttons
- Consistent navigation
- Consistent success/warning/error states
- Responsive dashboard grids

### Brand palette

- Primary: `#0B6B5B`
- Primary dark: `#075447`
- Accent: `#14B8A6`
- Background: `#071B1B`
- Surface: `#102A29`
- Elevated surface: `#163634`
- Primary text: `#F8FAFC`
- Secondary text: `#A7B8B5`

**Status: ✅ Core design system completed**

Remaining work is feature-by-feature visual QA and final RTL/mobile refinement.

---

# 4. Authentication and company profile

## Implemented

- Supabase authentication foundation
- Auth state listening
- Signed-out → Login flow
- Phone OTP foundation
- Email/password repository support
- Profile completion gate
- Company information captured during registration
- Legal/business fields including:
  - Company name
  - Legal form
  - Address
  - City
  - Professional phone
  - RC
  - IF
  - ICE
- Profile persistence in Supabase
- User-owned profile policies through RLS

The database profile is tied to `auth.users(id)`.

**Status: 🟢 Implemented; final authentication/profile QA remains.**

---

# 5. Supabase database and security

The current database foundation contains:

- `profiles`
- `clients`
- `products`
- `invoices`
- `invoice_items`
- `expenses`
- `cpu_declarations`

RLS is enabled on the business tables, with ownership policies based on `auth.uid()`.

Invoice items are protected through ownership of their parent invoice.

The Flutter client is intended to use the Supabase **publishable key** only; a `service_role`/secret key must never be shipped inside the application.

**Status: 🟢 Foundation implemented.**

### Still required

- Production schema audit
- Constraints and business-rule audit
- Unique invoice-number strategy per company/user
- Referential-integrity review
- Storage policies
- Production backup/recovery strategy
- Security/RLS penetration-style tests

---

# 6. Dashboard

The Dashboard has already evolved into a real business dashboard rather than a placeholder.

### Current metrics

- Invoiced
- Collected
- Receivable
- Expenses
- VAT collected
- VAT on expenses
- Net VAT
- Operating balance

### Periods

- Month
- Quarter
- Year

### Additional UI

- Revenue hero card
- Metric cards
- Period comparison
- Quick statistics
- Business summary
- Pull-to-refresh
- Responsive grid layout

**Status: 🟢 Implemented.**

### Remaining

- Verify calculations against production business rules
- Add richer historical charts when appropriate
- Verify all metrics with realistic datasets
- Complete Arabic/French localization
- Empty/loading/error states QA

---

# 7. Clients module

## Current direction

Client management is part of the main business workflow and is connected to invoices.

Client information includes:

- Name
- ICE
- IF
- RC
- TP
- Phone
- Email
- Address
- City

### Remaining for final version

- Full CRUD QA
- Search
- Filtering/sorting
- Duplicate handling
- Validation of Moroccan business identifiers
- Empty states
- Delete confirmation
- Error/retry UX
- RTL/mobile QA
- Localization audit

**Status: 🟢 Implemented foundation; final production polish remains.**

---

# 8. Products and services module

Products/services support invoice creation and contain:

- Name
- Description
- Unit
- Unit price
- Tax rate
- Active/inactive state

### Remaining

- Full CRUD QA
- Search/filter
- Better product selection UX inside invoices
- Validation
- Duplicate handling
- Localization
- Mobile/RTL QA

**Status: 🟢 Implemented foundation; final production polish remains.**

---

# 9. Invoices — current major milestone

The invoice module is now one of the most advanced parts of the application.

## Implemented workflow

1. Create invoice
2. Select client
3. Add one or more lines
4. Select an existing product/service or enter a custom description
5. Set quantity
6. Set unit price HT
7. Set TVA rate
8. Calculate line totals
9. Calculate invoice HT
10. Calculate TVA
11. Calculate TTC
12. Save as draft
13. Edit draft
14. Issue invoice
15. Delete draft
16. Open invoice details
17. Preview PDF
18. Share PDF
19. Print PDF

### Invoice model contains seller snapshot/legal information

- Seller name
- ICE
- IF
- RC
- TP
- Address
- City
- Phone
- Email
- Payment terms

This information is used by the PDF layer so the invoice can present the seller's business identity.

**Status: 🟢 Core invoice workflow implemented.**

### Remaining before calling Invoices production-ready

- Final mobile invoice-entry UX
- Full RTL verification
- Full Arabic/French localization
- Invoice-number generation rules
- Duplicate invoice-number protection
- Tax/business-rule validation
- Status transition validation
- Paid/issued/cancelled lifecycle review
- Robust error handling
- Offline/network failure behavior
- Regression tests
- Large invoice QA
- Long descriptions and long client/company names QA

---

# 10. Invoice PDF — visual design milestone

The invoice PDF visual design has been upgraded to a professional ComptaFlow identity.

## Current PDF design

### Header

- Seller name hierarchy
- Contact details
- ICE/IF/RC/TP
- Brand line
- Invoice title
- Invoice number
- Issue date

### Client block

- `FACTURÉ À`
- Client identity
- Address/city
- Phone/email
- ICE/IF/RC/TP
- Branded accent treatment

### Invoice table

- Dark teal header
- Description
- Quantity
- Unit price HT
- TVA
- Line HT/TVA/TTC
- Zebra rows
- Numeric alignment
- Clean borders

### Totals

- Total HT
- TVA
- Total TTC
- Branded totals panel

### Footer

- ComptaFlow identity
- Page number
- Multi-page support

**Status: 🟢 Visual design implemented.**

### Remaining PDF work

- Test with real long invoices
- Test multiple pages
- Test long Arabic text
- Test RTL rendering
- Test missing optional client data
- Test missing seller fields
- Test large quantities/prices
- Test PDF generation failures
- Test preview/share/print on Android
- Verify fonts and Arabic glyph rendering
- Verify page-break behavior
- Verify final PDF output on representative devices

The visual design should be considered **complete only after rendering/printing QA passes**.

---

# 11. Expenses module

The database and dashboard already support expenses.

Expenses include:

- Date
- Amount
- Category
- Tax amount/business data through the model layer

### Remaining

- Complete expense CRUD review
- Expense categories
- Search/filter
- Date filtering
- Tax validation
- Receipt/document attachment strategy if required
- Dashboard integration QA
- Localization
- Tests

**Status: 🟢 Implemented foundation; production workflow still needs completion.**

---

# 12. CPU module

ComptaFlow includes a CPU calculator foundation and CPU declaration storage.

The database supports:

- Declaration period
- CA encaissé
- CPU rate
- CPU amount
- Declaration date

### Remaining for complete CPU workflow

- Final Moroccan CPU business-rule validation
- Activity-based rate configuration
- Period selection
- Declaration calculation
- Declaration history
- Status tracking
- Validation against official/current rules before production use
- Clear legal/tax disclaimer where appropriate
- Tests for calculation edge cases
- Arabic/French UX

**Status: 🟡 Foundation implemented; full production workflow remains.**

---

# 13. Notifications and reminders

This is still a major remaining feature.

Planned capabilities:

- Invoice payment reminders
- Upcoming declaration reminders
- Business reminders
- Optional local notifications
- Permission handling
- User-configurable notification settings

**Status: 🔴 Not complete.**

---

# 14. Secure PDF Storage

The invoice model already contains `pdfUrl`, but a production-grade Storage workflow still needs to be completed and verified.

Target architecture:

```text
Invoice
  ↓
Generate PDF locally
  ↓
Secure Supabase Storage path
  ↓
Upload PDF
  ↓
Store reference/url
  ↓
Authenticated access
  ↓
Preview / Share / Download
```

### Remaining

- Create/verify private Storage bucket
- Define RLS/storage policies
- User-scoped paths
- Upload/update/delete lifecycle
- Signed URL strategy if required
- Retry on network failure
- Avoid orphaned PDFs
- Verify access isolation between users

**Status: 🟡 Partial.**

---

# 15. Settings

Settings are part of the application shell.

The final settings area should cover:

- Company profile
- Language
- Notification preferences
- Invoice preferences
- Payment terms
- Tax preferences
- Account/session management
- Privacy/security information

### Remaining

- Final settings inventory
- Persistence verification
- Localization
- Profile editing QA
- Account deletion/data lifecycle strategy

**Status: 🟡 In progress.**

---

# 16. Localization and RTL

ComptaFlow targets Arabic and French users.

The project already uses Flutter localization infrastructure and persists the selected language.

### Final localization gate

Every visible string must be checked for:

- Arabic translation
- French translation
- RTL layout
- Numbers and currency
- Dates
- Invoice labels
- Validation messages
- Errors
- Empty states
- Notifications
- PDF language/content

There should be no accidental hard-coded French/English UI strings remaining where localization is expected.

**Status: 🟡 Foundation complete; full audit remains.**

---

# 17. Error handling and network resilience

Production use requires the application to remain understandable when Supabase/network operations fail.

### Required behavior

- Clear offline/network errors
- Retry actions
- Loading states
- Empty states
- Timeout handling
- Partial-operation recovery
- No duplicate invoices after retry
- No duplicate expenses after retry
- No orphaned invoice items
- No misleading success messages

**Status: 🔴 Final hardening remains.**

---

# 18. Automated testing

The final project needs tests at several levels.

## Unit tests

- Invoice calculations
- TVA calculations
- Totals
- CPU calculations
- Invoice status transitions
- Number formatting
- Date/period calculations

## Repository tests

- Auth/profile
- Clients
- Products
- Invoices
- Invoice items
- Expenses
- CPU

## Widget tests

- Login
- Profile completion
- Dashboard
- Client creation/editing
- Product creation/editing
- Invoice creation/editing
- Expense flow
- CPU flow

## PDF tests

- PDF generation succeeds
- Required seller fields appear
- Required invoice fields appear
- Multiple items
- Multiple pages
- Missing optional data

## Regression tests

Every bug fixed in production development should have a regression test where practical.

**Status: 🟡 Partial; final test suite remains.**

---

# 19. Android CI/CD and release

The project is intended to be built and validated through GitHub Actions rather than depending on a local developer build.

Final CI should validate:

```text
flutter pub get
↓
flutter analyze
↓
flutter test
↓
flutter build apk --release
↓
flutter build appbundle --release
↓
Artifact verification
```

### Final release requirements

- Correct application ID
- Release signing
- Version/versionCode management
- Android permissions audit
- ProGuard/R8 review if used
- Privacy/data-safety declarations
- Play Console metadata
- App icon/splash/final branding
- Release AAB verification
- Install/update testing
- Crash-free startup verification

**Status: 🟡 CI foundation exists; final release gate remains.**

---

# 20. Security and privacy

Before production, perform a complete security review.

### Required checks

- Supabase RLS for every user-owned table
- Storage policies
- No service-role key in client
- No secrets committed to Git
- Auth session handling
- Account deletion/data deletion behavior
- User isolation tests
- Secure PDF access
- Logging review
- Error messages must not leak sensitive data

**Status: 🟡 Foundation exists; final audit remains.**

---

# 21. Performance and production hardening

Before release:

- Avoid unnecessary database requests
- Paginate large client/product/invoice lists
- Optimize dashboard queries
- Avoid rebuilding expensive widgets unnecessarily
- Handle large invoices efficiently
- Verify PDF generation performance
- Verify startup performance
- Test poor network conditions
- Test low-memory Android devices

**Status: 🔴 Final hardening remains.**

---

# 22. Final UX acceptance checklist

The application should not be considered complete until the following workflows work from beginning to end:

### Account

- [ ] Sign up
- [ ] Verify account
- [ ] Complete company profile
- [ ] Login/logout
- [ ] Restore session

### Clients

- [ ] Create
- [ ] Edit
- [ ] Search
- [ ] Delete
- [ ] Use client in invoice

### Products

- [ ] Create
- [ ] Edit
- [ ] Search/filter
- [ ] Activate/deactivate
- [ ] Use product in invoice

### Invoice

- [ ] Create draft
- [ ] Add multiple lines
- [ ] Calculate HT/TVA/TTC
- [ ] Edit
- [ ] Issue
- [ ] View details
- [ ] Generate PDF
- [ ] Preview PDF
- [ ] Share PDF
- [ ] Print PDF
- [ ] Store PDF securely

### Expenses

- [ ] Create
- [ ] Edit
- [ ] Delete
- [ ] Filter
- [ ] Dashboard integration

### CPU

- [ ] Calculate
- [ ] Save declaration
- [ ] View history
- [ ] Validate period/rate rules

### Dashboard

- [ ] Correct monthly figures
- [ ] Correct quarterly figures
- [ ] Correct yearly figures
- [ ] Correct comparisons
- [ ] Correct VAT calculations

### Localization

- [ ] French complete
- [ ] Arabic complete
- [ ] RTL complete
- [ ] PDF language verified

### Reliability

- [ ] Offline/network failures handled
- [ ] Retry works
- [ ] No duplicate operations
- [ ] Loading states
- [ ] Empty states
- [ ] Error states

---

# 23. Final development roadmap

The remaining work should now be executed in this order:

## Stage A — Finish the current visual/business modules

1. Finish invoice UI/mobile UX
2. Finish invoice PDF rendering QA
3. Finish clients UX
4. Finish products UX
5. Finish expenses UX
6. Finish CPU workflow

## Stage B — Complete backend/business integrity

7. Audit Supabase schema
8. Complete invoice numbering/status rules
9. Complete Storage + PDF security
10. Verify RLS isolation
11. Add robust error/retry behavior

## Stage C — Complete product UX

12. Full Arabic/French localization
13. Full RTL audit
14. Complete Settings
15. Notifications/reminders
16. Empty/loading/error states everywhere

## Stage D — Quality

17. Unit tests
18. Repository tests
19. Widget tests
20. PDF tests
21. Regression tests
22. Performance testing
23. Security testing

## Stage E — Release

24. Final Android CI
25. APK/AAB validation
26. Release signing verification
27. Privacy/data-safety review
28. Play Store preparation
29. Production release candidate
30. Final production release

---

# 24. Definition of Done — ComptaFlow 1.0

ComptaFlow 1.0 is considered complete only when:

- Authentication is reliable.
- Company/legal profile is complete.
- Clients are fully manageable.
- Products/services are fully manageable.
- Invoices work from creation to payment lifecycle.
- Invoice calculations are tested.
- PDFs are professionally rendered and tested on real data.
- PDFs can be securely stored and accessed.
- Expenses are fully manageable.
- CPU calculations/declarations are validated for the supported Moroccan rules.
- Dashboard numbers match the underlying records.
- Arabic and French are complete.
- RTL is verified.
- Notifications work reliably.
- Supabase RLS and Storage security are verified.
- Network failures are handled without corrupting data.
- Automated tests pass.
- `flutter analyze` passes.
- Release APK builds successfully.
- Release AAB builds successfully.
- Android release configuration is verified.
- Privacy and Play Store declarations match the final application.
- A final end-to-end acceptance test passes.

---

# 25. Technology stack

- Flutter / Dart
- Material 3
- Provider
- Supabase Auth
- Supabase PostgreSQL
- Supabase Row Level Security
- Supabase Storage
- `pdf`
- `printing`
- Flutter `gen-l10n`

---

# 26. Security note

The Flutter client must use only the Supabase project URL and publishable key supplied through compile-time configuration.

**Never put a Supabase `service_role` or other secret key inside the mobile application.**

Example:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

---

# 27. Current conclusion

ComptaFlow is **past the MVP foundation stage**. The core architecture, authentication foundation, database/RLS foundation, design system, dashboard, clients/products foundations, invoice workflow and professional PDF design are already in place.

The remaining work is primarily the **production-completion layer**: business-rule validation, final UX/RTL/localization, secure PDF Storage, notifications, CPU completion, resilience, automated testing, security/performance audits and final Android/Play release validation.

The next development priority is therefore **not rebuilding the foundation**. It is finishing and validating each existing module until the complete end-to-end workflow is production-ready.
