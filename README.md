# Campus Supply Desk — In Class 12 Variant B

Flutter Android product manager using Cloud Firestore `campus_products`.
All implementation is in `lib/main.dart`; `lib/firebase_options.dart` is a setup guard
that FlutterFire must replace using your own project. No fabricated Firebase values.

## Setup
Follow `BEFORE_SUBMISSION.txt`. Run `flutter pub get`, sign in with Firebase CLI,
then `flutterfire configure --platforms=android`. Provision a Standard `(default)`
Firestore database and enter the five numeric-price records from `fixtures/`.
Run `flutter analyze`, `flutter test`, and `flutter run -d DEVICE_ID`.

## Behavior
- Create, read live, update, and confirmed delete by document ID.
- Stable metadata-enabled snapshot stream; visible cache and pending-write status.
- Case-insensitive substring search, inclusive optional price bounds, combined matching,
  range errors, and Reset. Filtering is local and intended for the five fixture records.
- Finite nonnegative prices, trimmed nonempty names, loading/empty/error states.
- Awaited writes, disabled duplicate actions, visible failures and startup guidance.
- Saves/deletes can wait offline until server acknowledgement; reconnect to complete.
- Malformed records are excluded with a visible count; inspect and repair in Console.

## Submission
The Word report is in `evidence/`. Complete its marked fields and insert your own
T1–T8 evidence before submission. The app has no Auth flow. The rules file is an
UNPUBLISHED investigation design only, not deployment configuration.
Do not publish it to obtain screenshots or make permanent allow-all rules.

## Assistance
OpenAI Codex prepared code, filter tests, documentation and report answer drafts using
the instructor starter. The student must review, configure Firebase, run Android tests,
collect actual evidence and submit. No cloud behavior is claimed from local tests.
