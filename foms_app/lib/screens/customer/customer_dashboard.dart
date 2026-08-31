import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/menu_item.dart';
import '../../models/orders.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../widgets/ios_glass_card.dart';
import '../../widgets/logout_dialog.dart';
import '../../widgets/premium_background.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _placing = false;
  String? _phone;
  String _name = 'Customer';
  String _address = '';

  List<MenuItem> _menu = [];
  List<Order> _orders = [];
  final Map<String, int> _qty = {};
  final TextEditingController _addrCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  int _selectedTab = 0; // 0 = Menu, 1 = Orders

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _addrCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _restoreSession();
    await _loadAll();
  }

  Future<void> _restoreSession() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _phone = (args['phone'] ?? '').toString().trim();
      _name = (args['name'] ?? _name).toString().trim().isNotEmpty
          ? (args['name'] ?? _name).toString().trim()
          : _name;
      _address = (args['location'] ?? '').toString().trim();
      if (_address.isNotEmpty) _addrCtrl.text = _address;
    }
    if ((_phone ?? '').isNotEmpty) return;

    final session = await SessionService.read();
    final sPhone = (session['phone'] ?? '').toString().trim();
    final sName = (session['name'] ?? '').toString().trim();
    final sLoc = (session['location'] ?? '').toString().trim();
    if (sPhone.isNotEmpty) _phone = sPhone;
    if (sName.isNotEmpty) _name = sName;
    if (sLoc.isNotEmpty) {
      _address = sLoc;
      _addrCtrl.text = _address;
    }
  }

  Future<void> _loadAll() async {
    if ((_phone ?? '').isEmpty) {
      setState(() {
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
    });

    try {
      final menuFuture = ApiService.getMenu().timeout(const Duration(seconds: 12));
      final ordersFuture = ApiService.getOrders(_phone!).timeout(const Duration(seconds: 12));

      final results = await Future.wait([menuFuture, ordersFuture]);
      final menu = results[0] as List<MenuItem>;
      final orders = results[1] as List<Order>;

      setState(() {
        _menu = menu;
        _orders = orders;
        for (final m in menu) {
          _qty.putIfAbsent(m.name, () => 0);
        }
      });
    } catch (e) {
      _snack("Could not sync latest menu and orders.", isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalAmount {
    int total = 0;
    for (final item in _menu) {
      final count = _qty[item.name] ?? 0;
      total += count * item.price;
    }
    return total;
  }

  int get _totalCount {
    int count = 0;
    _qty.forEach((k, v) => count += v);
    return count;
  }

  void _showCheckoutSheet() {
    if (_totalCount == 0) {
      _snack("Your cart is empty. Please select food items.");
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: IosGlassCard(
              blur: 28,
              borderRadius: 32,
              padding: const EdgeInsets.all(28),
              margin: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Order Summary",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        "LKR $_totalAmount",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),

                  // Selected items list
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView(
                      shrinkWrap: true,
                      children: _menu
                          .where((m) => (_qty[m.name] ?? 0) > 0)
                          .map(
                            (m) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Text(
                                    "${_qty[m.name]}x",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2563EB),
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      m.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "LKR ${m.price * (_qty[m.name] ?? 0)}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delivery Address
                  const Text(
                    "Delivery Location",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: TextField(
                      controller: _addrCtrl,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "Enter full delivery address",
                        prefixIcon: Icon(Icons.location_on_rounded, color: Color(0xFF2563EB), size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _placing
                          ? null
                          : () async {
                              final addr = _addrCtrl.text.trim();
                              if (addr.isEmpty) {
                                _snack("Please provide a delivery address", isError: true);
                                return;
                              }
                              Navigator.pop(ctx);
                              await _submitOrder(addr);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _placing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              "Confirm & Place Order",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitOrder(String address) async {
    setState(() => _placing = true);
    final itemsMap = <String, int>{};
    _qty.forEach((k, v) {
      if (v > 0) itemsMap[k] = v;
    });

    try {
      final success = await ApiService.placeOrder(
        _phone!,
        address,
        itemsMap,
        _totalAmount,
      );

      if (success) {
        _snack("Order placed successfully!");
        setState(() {
          for (final key in _qty.keys) {
            _qty[key] = 0;
          }
          _selectedTab = 1; // Switch to Orders tab
        });
        await _loadAll();
      } else {
        _snack("Failed to place order. Please try again.", isError: true);
      }
    } catch (e) {
      _snack("Error placing order: $e", isError: true);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<void> _requestCancel(String createdAt) async {
    try {
      final ok = await ApiService.requestCancel(createdAt);
      if (ok) {
        _snack("Cancellation request submitted.");
        await _loadAll();
      } else {
        _snack("Failed to request cancellation.", isError: true);
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
              // Top Frosted Glass Header
              _buildTopHeader(),

              // Segmented Tab Switcher Pills
              _buildSegmentedTab(),

              // Tab View Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadAll,
                  color: const Color(0xFF2563EB),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                      : _selectedTab == 0
                          ? _buildMenuTab()
                          : _buildOrdersTab(),
                ),
              ),

              // Bottom Floating Cart Pill
              if (_selectedTab == 0 && _totalCount > 0) _buildFloatingCartBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
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
                  colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, $_name",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _phone ?? "Customer",
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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

  Widget _buildSegmentedTab() {
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
            _buildTabItem(0, "Explore Menu", Icons.restaurant_rounded),
            _buildTabItem(1, "My Orders (${_orders.length})", Icons.receipt_long_rounded),
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
              Icon(
                icon,
                size: 16,
                color: active ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
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

  Widget _buildMenuTab() {
    final filtered = _menu.where((m) {
      if (_searchQuery.isEmpty) return true;
      return m.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        // Search Bar
        IosGlassCard(
          blur: 16,
          borderRadius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
            decoration: InputDecoration(
              hintText: "Search dishes, rice, curries...",
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 18),

        if (filtered.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                "No menu items match your search.",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
              ),
            ),
          )
        else
          ...filtered.map((item) => _buildFoodCard(item)),
      ],
    );
  }

  Widget _buildFoodCard(MenuItem item) {
    final count = _qty[item.name] ?? 0;
    return IosGlassCard(
      blur: 20,
      borderRadius: 24,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Food Icon Avatar
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFFE0E7FF), Color(0xFFC7D2FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: Color(0xFF4338CA),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "LKR ${item.price}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),

          // Quantity Stepper Pill (iOS 26 Style)
          Container(
            decoration: BoxDecoration(
              color: count > 0 ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: count > 0 ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (count > 0)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _qty[item.name] = (count - 1).clamp(0, 99);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: const Icon(Icons.remove_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _qty[item.name] = count + 1;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: count > 0 ? 8 : 14,
                      vertical: 8,
                    ),
                    child: Text(
                      count > 0 ? "$count" : "+ Add",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: count > 0 ? Colors.white : const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
                if (count > 0)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _qty[item.name] = count + 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_rounded, size: 64, color: Color(0xFF94A3B8)),
              SizedBox(height: 16),
              Text(
                "No orders placed yet",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 6),
              Text(
                "Your active and completed orders will show here.",
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      itemCount: _orders.length,
      itemBuilder: (ctx, idx) {
        final order = _orders[idx];
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
                  Text(
                    order.createdAt.length > 16 ? order.createdAt.substring(0, 16) : order.createdAt,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 12),
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
                      Text(
                        order.address,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  Text(
                    "LKR ${order.amount}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
              if (order.status.toLowerCase() == 'pending' && order.cancelRequest != 'yes') ...[
                const SizedBox(height: 14),
                const Divider(color: Color(0xFFE2E8F0)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _requestCancel(order.createdAt),
                    icon: const Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFEF4444)),
                    label: const Text("Request Cancellation", style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    final s = status.toLowerCase();
    Color bg = const Color(0xFFFEF3C7);
    Color fg = const Color(0xFFD97706);
    String label = "Pending";

    if (s == 'preparing') {
      bg = const Color(0xFFE0E7FF);
      fg = const Color(0xFF4338CA);
      label = "Preparing";
    } else if (s == 'out_for_delivery' || s == 'out for delivery') {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0284C7);
      label = "Out for Delivery";
    } else if (s == 'delivered') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
      label = "Delivered";
    } else if (s == 'canceled' || s == 'cancelled') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
      label = "Canceled";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildFloatingCartBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: IosGlassCard(
        blur: 28,
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        surfaceColor: const Color(0xFF0F172A),
        surfaceOpacity: 0.90,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$_totalCount items in Cart",
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                Text(
                  "LKR $_totalAmount",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showCheckoutSheet,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              label: const Text(
                "Checkout",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
