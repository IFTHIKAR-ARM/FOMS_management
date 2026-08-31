import 'dart:io';

void main() {
  final files = [
    'lib/screens/auth/login_screen.dart',
    'lib/screens/auth/register_screen.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    String content = file.readAsStringSync();

    // 1. Role Tabs text and icons
    // Replace selected ? Colors.white with selected ? _P.primary
    content = content.replaceAll(
      'color: selected ? Colors.white : _P.textSub',
      'color: selected ? _P.primary : _P.textSub',
    );
    // Replace role tab background when selected
    content = content.replaceAll(
      'color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent',
      'color: selected ? _P.primary.withValues(alpha: 0.08) : Colors.transparent',
    );
    // Replace role tab border when selected
    content = content.replaceAll(
      'border: Border.all(color: selected ? Colors.white.withValues(alpha: 0.3) : Colors.transparent, width: 0.5)',
      'border: Border.all(color: selected ? _P.primary.withValues(alpha: 0.4) : Colors.transparent, width: 1.0)',
    );

    // 2. Forgot Password text
    content = content.replaceAll(
      'color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600',
      'color: _P.textSub, fontSize: 13, fontWeight: FontWeight.w600',
    );

    // 3. Footer texts (New here? Create Account / Sign In)
    content = content.replaceAll(
      'style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)',
      'style: const TextStyle(color: _P.primary, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)',
    );

    // 4. Loading indicator inside main button (should stay white) - ok

    // 5. Box shadow of the main container - currently too soft and invisible?
    // In screenshot, the block is a solid block of grey/white.
    // The previous update_ui.dart replaced it with white alpha 0.7
    // Let's make it a clear white card!
    content = content.replaceAll(
      'color: Colors.white.withValues(alpha: 0.7)',
      'color: Colors.white',
    );
    content = content.replaceAll(
      'colors: [\n                                Colors.white.withValues(alpha: 0.9),\n                                Colors.white.withValues(alpha: 0.5),\n                              ]',
      'colors: [ Colors.white, Colors.white ]',
    );
    content = content.replaceAll(
      'border: Border.all(color: Colors.white, width: 1.5)',
      'border: Border.all(color: Colors.transparent, width: 0)',
    );
    content = content.replaceAll(
      'color: const Color(0xFF94A3B8).withValues(alpha: 0.2),\n                                blurRadius: 60,\n                                spreadRadius: 0,\n                                offset: const Offset(0, 20)',
      'color: const Color(0xFF64748B).withValues(alpha: 0.15),\n                                blurRadius: 40,\n                                spreadRadius: -10,\n                                offset: const Offset(0, 20)',
    );

    // 6. Eye icon in password field
    content = content.replaceAll(
      'color: Colors.white60, size: 20',
      'color: _P.textSub, size: 20',
    );

    file.writeAsStringSync(content);
    print('Updated contrast for \$path');
  }
}
