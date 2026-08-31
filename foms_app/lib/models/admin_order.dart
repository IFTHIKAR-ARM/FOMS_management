class AdminOrder {
  final String customerPhone;
  final String customerName;
  final String createdAt;
  final String items;
  final String address;
  final int amount;
  final String status;
  final String cancelRequest;

  const AdminOrder({
    required this.customerPhone,
    required this.customerName,
    required this.createdAt,
    required this.items,
    required this.address,
    required this.amount,
    required this.status,
    required this.cancelRequest,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    final amountRaw = (json['amount'] ?? '0').toString();
    final amountValue = num.tryParse(amountRaw)?.toInt() ?? 0;
    return AdminOrder(
      customerPhone: (json['customer_phone'] ?? '').toString(),
      customerName: (json['customer_name'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      items: (json['items'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      amount: amountValue,
      status: (json['status'] ?? 'pending').toString(),
      cancelRequest: (json['cancel_request'] ?? 'no').toString(),
    );
  }
}
