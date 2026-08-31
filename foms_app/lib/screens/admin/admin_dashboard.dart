import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/admin_order.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../widgets/ios_glass_card.dart';
import '../../widgets/logout_dialog.dart';
import '../../widgets/premium_background.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<AdminOrder> _orders = [];
  List<UserModel> _users = [];

  static const List<String> _statuses = [
    'pending',
    'preparing',
    'out_for_delivery',
    'delivered',
    'canceled',
  ];

  int _selectedTab = 0; // 0 = Live Orders, 1 = User Accounts
  String _orderFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ordersFuture = ApiService.getAdminOrders().timeout(const Duration(seconds: 12));
      final usersFuture = ApiService.getUsers().timeout(const Duration(seconds: 12));

      final results = await Future.wait([ordersFuture, usersFuture]);
      setState(() {
        _orders = results[0] as List<AdminOrder>;
        _users = results[1] as List<UserModel>;
      });
    } catch (e) {
      _snack("Failed to sync admin data: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(AdminOrder order, String newStatus) async {
    try {
      final ok = await ApiService.updateOrderStatus(
        order.customerPhone,
        order.createdAt,
        newStatus,
      );
      if (ok) {
        _snack("Order updated to $newStatus");
        await _loadAll();
      } else {
        _snack("Failed to update status.", isError: true);
      }
    } catch (e) {
      _snack("Error: $e", isError: true);
    }
  }

  Future<void> _approveCancel(AdminOrder order) async {
    try {
      final ok = await ApiService.approveCancel(order.customerPhone, order.createdAt);
      if (ok) {
        _snack("Cancellation approved.");
        await _loadAll();
      }
    } catch (e) {
      _snack("Error: $e", isError: true);
    }
  }

  Future<void> _rejectCancel(AdminOrder order) async {
    try {
      final ok = await ApiService.rejectCancel(order.customerPhone, order.createdAt);
      if (ok) {
        _snack("Cancellation rejected.");
        await _loadAll();
      }
    } catch (e) {
      _snack("Error: $e", isError: true);
    }
  }

  Future<void> _updateUserRole(String phone, String newRole) async {
    try {
      final ok = await ApiService.updateUserRole(phone, newRole);
      if (ok) {
        _snack("User role updated to $newRole");
        await _loadAll();
      }
    } catch (e) {
      _snack("Error: $e", isError: true);
    }
  }

  Future<void> _deleteUser(String phone) async {
    try {
      final ok = await ApiService.deleteUser(phone);
      if (ok) {
        _snack("User account removed.");
        await _loadAll();
      }
    } catch (e) {
      _snack("Error: $e", isError: true);
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
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Admin Frosted Header
              _buildHeader(),

              // Segmented Tab Switcher
              _buildSegmentedTabs(),

              // Content View
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadAll,
                  color: const Color(0xFF2563EB),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                      : _selectedTab == 0
                          ? _buildOrdersStream()
                          : _buildUsersList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: IosGlassCard(
        blur: 24,
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Admin Center",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Kitchen & Operations Control",
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
              ),
              onPressed: () => LogoutDialog.show(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            _buildTabItem(0, "Live Orders (${_orders.length})", Icons.receipt_long_rounded),
            _buildTabItem(1, "Accounts (${_users.length})", Icons.people_alt_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String title, IconData icon) {
    final active = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: active
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
              Icon(icon, size: 16, color: active ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersStream() {
    final filtered = _orders.where((o) {
      if (_orderFilter == 'all') return true;
      return o.status.toLowerCase() == _orderFilter;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill('all', 'All Orders'),
              _buildFilterPill('pending', 'Pending'),
              _buildFilterPill('preparing', 'Preparing'),
              _buildFilterPill('out_for_delivery', 'Out for Delivery'),
              _buildFilterPill('delivered', 'Delivered'),
              _buildFilterPill('canceled', 'Canceled'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (filtered.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                "No orders in this category.",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
              ),
            ),
          )
        else
          ...filtered.map((order) => _buildAdminOrderCard(order)),
      ],
    );
  }

  Widget _buildFilterPill(String filterKey, String label) {
    final active = _orderFilter == filterKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _orderFilter = filterKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF2563EB) : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminOrderCard(AdminOrder order) {
    return IosGlassCard(
      blur: 20,
      borderRadius: 24,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_outline_rounded, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName.isNotEmpty ? order.customerName : "Customer",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        order.customerPhone,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              _buildStatusDropdown(order),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            order.items,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(order.address, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
              Text(
                "LKR ${order.amount}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          if (order.cancelRequest == 'yes') ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Cancellation requested by customer",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _approveCancel(order),
                    child: const Text("Approve", style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w700)),
                  ),
                  TextButton(
                    onPressed: () => _rejectCancel(order),
                    child: const Text("Reject", style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(AdminOrder order) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statuses.contains(order.status.toLowerCase()) ? order.status.toLowerCase() : 'pending',
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          items: _statuses.map((s) {
            return DropdownMenuItem<String>(
              value: s,
              child: Text(s.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 12)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) _updateStatus(order, val);
          },
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    if (_users.isEmpty) {
      return const Center(
        child: Text("No registered users found.", style: TextStyle(color: Color(0xFF64748B))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      itemCount: _users.length,
      itemBuilder: (ctx, idx) {
        final user = _users[idx];
        return IosGlassCard(
          blur: 20,
          borderRadius: 22,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.phone,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: ['customer', 'delivery', 'admin'].contains(user.role.toLowerCase())
                        ? user.role.toLowerCase()
                        : 'customer',
                    items: ['customer', 'delivery', 'admin'].map((r) {
                      return DropdownMenuItem<String>(
                        value: r,
                        child: Text(r.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _updateUserRole(user.phone, val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                onPressed: () => _deleteUser(user.phone),
              ),
            ],
          ),
        );
      },
    );
  }
}
