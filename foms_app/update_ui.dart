import 'dart:io';

void main() {
  final files = [
    'lib/screens/auth/login_screen.dart',
    'lib/screens/auth/register_screen.dart',
    'lib/screens/customer/customer_dashboard.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    String content = file.readAsStringSync();

    // Fix opacity deprecation
    content = content.replaceAll('.withOpacity(', '.withValues(alpha: ');

    // 1. Update palettes
    content = content.replaceAll('Color(0xFF3B82F6)', 'Color(0xFF2563EB)'); // primary
    content = content.replaceAll('Color(0xFF0D0A14)', 'Color(0xFFF3F6FA)'); // bg
    content = content.replaceAll('Color(0xFF161124)', 'Color(0xFFFFFFFF)'); // surface
    content = content.replaceAll('Color(0xFF1C1438)', 'Color(0xFFFFFFFF)'); // card
    content = content.replaceAll('Color(0xFF3E3166)', 'Color(0xFFE2E8F0)'); // border
    
    // Instead of raw Colors.white replacement everywhere which might break buttons,
    // let's adjust specific text colors in the palette wrapper
    content = content.replaceAll('static const textH     = Colors.white;', 'static const textH     = Color(0xFF0F172A);');
    content = content.replaceAll('static const textB     = Colors.white70;', 'static const textB     = Color(0xFF334155);');
    content = content.replaceAll('static const textSub   = Colors.white60;', 'static const textSub   = Color(0xFF64748B);');

    // 2. Adjust backgrounds & Glassmorphism
    // Deep Space Gradients -> Bright Bluewise Gradients
    content = content.replaceAll(
      'colors: [ Color(0xFF1F1135), Color(0xFFF3F6FA) ]',
      'colors: [ Color(0xFFDBEAFE), Color(0xFFF8FAFC) ]', 
    );
    // (In case the original replacement didn't match perfectly, cover the base)
    content = content.replaceAll(
      'colors: [ Color(0xFF1F1135), Color(0xFF0D0A14) ]',
      'colors: [ Color(0xFFDBEAFE), Color(0xFFF8FAFC) ]',
    );
    
    // Neon Orb shadow color
    content = content.replaceAll(
      'BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.4)',
      'BoxShadow(color: const Color(0xFF60A5FA).withValues(alpha: 0.5)',
    );

    // Filter/Glass colors
    content = content.replaceAll(
      'color: Colors.white.withValues(alpha: 0.01)',
      'color: Colors.white.withValues(alpha: 0.7)',
    );
    content = content.replaceAll(
      'colors: [\n                                const Color(0xFFE2E8F0).withValues(alpha: 0.3),\n                                const Color(0xFF1E1638).withValues(alpha: 0.1),\n                              ]',
      'colors: [ Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0.5) ]',
    );
    content = content.replaceAll(
        'border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.2), width: 0.5)',
        'border: Border.all(color: Colors.white, width: 1.5)',
    );
    content = content.replaceAll(
      'BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 80, spreadRadius: -10, offset: const Offset(0, 30))',
      'BoxShadow(color: const Color(0xFF94A3B8).withValues(alpha: 0.2), blurRadius: 60, spreadRadius: 0, offset: const Offset(0, 20))',
    );

    // Textfields inside cards
    content = content.replaceAll(
      'fillColor: _isFocused ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03)',
      'fillColor: _isFocused ? Colors.white : const Color(0xFFF1F5F9)',
    );
    content = content.replaceAll(
      'enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5))',
      'enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: const Color(0xFFCBD5E1), width: 1.0))',
    );
    content = content.replaceAll(
        'color: Colors.white, fontSize: 15',
        'color: const Color(0xFF0F172A), fontSize: 15'
    );
    content = content.replaceAll(
        'color: Colors.white, fontSize: 34',
        'color: const Color(0xFF0F172A), fontSize: 34'
    );
    content = content.replaceAll(
        'color: Colors.white.withValues(alpha: 0.7), fontSize: 14',
        'color: const Color(0xFF475569), fontSize: 14'
    );
    content = content.replaceAll(
        'color: _isFocused ? Colors.white : Colors.white60',
        'color: _isFocused ? _P.primary : const Color(0xFF94A3B8)'
    );

    file.writeAsStringSync(content);
    print('Updated \$path');
  }
}
