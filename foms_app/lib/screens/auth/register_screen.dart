import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/ios_glass_card.dart';
import '../../widgets/premium_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  String selectedRole = 'customer';
  List<String> _locations = [];
  String? _selectedLocation;
  bool _hidePassword = true;
  bool _isLoadingLocations = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoadingLocations = true);
    try {
      final locs = await ApiService.getLocations();
      if (!mounted) return;
      setState(() {
        _locations = locs;
        if (_locations.isNotEmpty) _selectedLocation = _locations.first;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locations = ['Main Street', 'City Center', 'Uptown Area'];
        _selectedLocation = _locations.first;
      });
    } finally {
      if (mounted) setState(() => _isLoadingLocations = false);
    }
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      _snack("Please fill all fields", isError: true);
      return;
    }

    setState(() => isLoading = true);
    try {
      final data = await ApiService.register(
        name,
        phone,
        password,
        selectedRole,
        _selectedLocation ?? 'General Area',
      );
      if (!mounted) return;

      if (data['status'] == 'success') {
        _snack("Registration successful! Please login.");
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        _snack(data['message'] ?? "Registration failed", isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _snack("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF0F172A)),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: const Text(
            "Create Account",
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: FadeTransition(
              opacity: _anim,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: IosGlassCard(
                  blur: 24,
                  borderRadius: 32,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      const Text(
                        "Join FOMS",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Fill in the details to register",
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 24),

                      // Segmented Role Selector
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            _buildRolePill("Customer", "customer", Icons.person_rounded),
                            _buildRolePill("Delivery", "delivery", Icons.delivery_dining_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Full Name
                      _buildInputField(
                        controller: nameController,
                        label: "Full Name",
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 14),

                      // Phone Number
                      _buildInputField(
                        controller: phoneController,
                        label: "Phone Number",
                        icon: Icons.phone_android_rounded,
                      ),
                      const SizedBox(height: 14),

                      // Password
                      _buildInputField(
                        controller: passwordController,
                        label: "Password",
                        icon: Icons.lock_outline_rounded,
                        obscure: _hidePassword,
                        suffix: IconButton(
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF64748B),
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Location Dropdown
                      if (!_isLoadingLocations && _locations.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedLocation,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                              items: _locations.map((loc) {
                                return DropdownMenuItem<String>(
                                  value: loc,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF64748B)),
                                      const SizedBox(width: 10),
                                      Text(loc),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedLocation = val);
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 26),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.5),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Create Account",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRolePill(String title, String role, IconData icon) {
    final isSelected = selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }
}
