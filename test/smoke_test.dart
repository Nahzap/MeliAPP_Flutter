import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/config/theme_config.dart';

void main() {
  test('el tema de la app se construye sin errores', () {
    final theme = AppTheme.lightTheme;

    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppTheme.primary);
    expect(theme.colorScheme.error, AppTheme.error);
  });
}
