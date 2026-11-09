import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/l10n.dart';

void main() {
  // The shared test config pins Arabic; restore it after each case here.
  tearDown(() => L.setLang(AppLang.ar));

  test('both tables carry the same ids and the same placeholders', () {
    expect(L.en.keys.toSet(), L.ar.keys.toSet());
    final placeholder = RegExp(r'\{(\w+)\}');
    for (final id in L.ar.keys) {
      final ar = placeholder.allMatches(L.ar[id]!).map((m) => m.group(1)).toSet();
      final en = placeholder.allMatches(L.en[id]!).map((m) => m.group(1)).toSet();
      expect(en, ar, reason: 'placeholders differ for $id');
      expect(L.en[id], isNotEmpty, reason: 'empty English string for $id');
    }
  });

  test('English is used when the language is English', () {
    L.setLang(AppLang.en);
    expect(L.isEnglish, isTrue);
    expect(L.dir, TextDirection.ltr);
    expect(L.locale.languageCode, 'en');
    expect(L.t('composer.send'), 'Send');
    expect(L.t('common.cancel'), 'Cancel');
  });

  test('Arabic keeps the original copy and RTL', () {
    L.setLang(AppLang.ar);
    expect(L.isEnglish, isFalse);
    expect(L.dir, TextDirection.rtl);
    expect(L.locale.languageCode, 'ar');
    expect(L.t('composer.send'), 'إرسال');
    expect(L.t('common.cancel'), 'إلغاء');
  });

  test('placeholders are substituted in both languages', () {
    L.setLang(AppLang.en);
    expect(L.t('queue.title', {'n': 3}), 'Queued (3)');
    expect(L.t('duration.seconds', {'n': 12}), '12 seconds');
    L.setLang(AppLang.ar);
    expect(L.t('queue.title', {'n': 3}), 'في الطابور (3)');
    expect(L.t('duration.seconds', {'n': 12}), '12 ثانية');
  });

  test('unknown ids fall back to the id instead of throwing', () {
    expect(L.t('does.not.exist'), 'does.not.exist');
  });

  test('the language follows the device locale, English as fallback', () {
    L.fromLocales(const [Locale('ar', 'SA')]);
    expect(L.current, AppLang.ar);
    L.fromLocales(const [Locale('en', 'US')]);
    expect(L.current, AppLang.en);
    L.fromLocales(const [Locale('fr', 'FR')]);
    expect(L.current, AppLang.en);
    L.fromLocales(const []);
    expect(L.current, AppLang.en);
  });
}
