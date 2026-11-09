import 'dart:async';

import 'package:hermes_mobile/l10n.dart';

/// Runs before every test file.
///
/// The suite asserts against the original Arabic copy, and the app now picks its
/// language from the device locale (English by default). Pinning the tests to
/// Arabic keeps those assertions meaningful; `localization_test.dart` covers the
/// English side explicitly.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  L.setLang(AppLang.ar);
  await testMain();
}
