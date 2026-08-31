import 'package:flutter/material.dart';
import '../../models/admin_order.dart';
import '../../services/api_service.dart';
import '../../widgets/ios_glass_card.dart';
import '../../widgets/logout_dialog.dart';
import '../../widgets/premium_background.dart';

class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  bool _isOnline = true;
  bool _isLoading = true;
  String _deliveryName = 'Delivery Rider';
  List<AdminOrder> _orders = [];
  String _filter = 'active'; // 'all', 'active', 'delivered'

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final name = (args['name'] ?? '').toString().trim();
      if (name.isNotEmpty) _deliveryName = name;
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await ApiService.getAdminOrders();
      setState(() {
        _orders = orders;
      });
    } catch (_) {
      // Fallback
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
        _snack("Order updated to ${newStatus.replaceAll('_', ' ')}");
        await _loadOrders();
      } else {
        _snack("Failed to update status.", isError: true);
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
              // Header Card
              _buildHeader(),

              // Online / Status Switcher
              _buildStatusPill(),

              // Filter Tabs
              _buildFilterTabs(),

              // Order List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: const Color(0xFF2563EB),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                      : _buildOrdersList(),
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
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _deliveryName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Delivery Dispatch Partner",
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

  Widget _buildStatusPill() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: IosGlassCard(
        blur: 16,
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                    boxShadow: _isOnline
                        ? [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _isOnline ? "Active for Deliveries" : "Offline / On Break",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _isOnline ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            Switch(
              value: _isOnline,
              activeThumbColor: const Color(0xFF10B981),
              onChanged: (v) => setState(() => _isOnline = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            _buildFilterPill('active', 'Assigned & Active'),
            _buildFilterPill('delivered', 'Completed'),
            _buildFilterPill('all', 'All'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String filterKey, String label) {
    final active = _filter == filterKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = filterKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
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
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    final filtered = _orders.where((o) {
      final s = o.status.toLowerCase();
      if (_filter == 'active') {
        return s == 'preparing' || s == 'out_for_delivery' || s == 'pending';
      }
      if (_filter == 'delivered') return s == 'delivered';
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.two_wheeler_rounded, size: 64, color: Color(0xFF94A3B8)),
              SizedBox(height: 16),
              Text(
                "No delivery orders here",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      itemCount: filtered.length,
      itemBuilder: (ctx, idx) {
        final order = filtered[idx];
        final s = order.status.toLowerCase();

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
                    order.customerName.isNotEmpty ? order.customerName : "Customer",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                order.items,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.address,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ),
                  Text(
                    "LKR ${order.amount}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 8),

              // Action Buttons
              if (s == 'preparing' || s == 'pending')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(order, 'out_for_delivery'),
                    icon: const Icon(Icons.delivery_dining_rounded, size: 18, color: Colors.white),
                    label: const Text("Start Delivery", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                )
              else if (s == 'out_for_delivery')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(order, 'delivered'),
                    icon: const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                    label: const Text("Mark as Delivered", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    final s = status.toLowerCase();
    Color bg = const Color(0xFFFEF3C7);
    Color fg = const Color(0xFFD97706);
    String label = "Pending";

    if (s == 'preparing') {
      bg = const Color(0xFFE0E7FF);
      fg = const Color(0xFF4338CA);
      label = "Preparing";
    } else if (s == 'out_for_delivery') {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0284C7);
      label = "Out for Delivery";
    } else if (s == 'delivered') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
      label = "Delivered";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
