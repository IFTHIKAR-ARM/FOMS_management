class Order {
  final String createdAt;
  final String items;
  final int amount;
  final String address;
  final String status;
  final String cancelRequest;

  Order({
    required this.createdAt,
    required this.items,
    required this.amount,
    required this.address,
    required this.status,
    required this.cancelRequest,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final amountRaw = (json['amount'] ?? '0').toString();
    final amountValue = num.tryParse(amountRaw)?.toInt() ?? 0;
    return Order(
      createdAt: json['created_at']?.toString() ?? '',
      items: json['items']?.toString() ?? '',
      amount: amountValue,
      address: json['address']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      cancelRequest: json['cancel_request']?.toString() ?? 'no',
    );
  }
}
