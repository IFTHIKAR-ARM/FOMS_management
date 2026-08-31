class MenuItem {
  final String name;
  final int price;
  final String image;

  MenuItem({
    required this.name,
    required this.price,
    required this.image,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final priceRaw = (json['price'] ?? '0').toString();
    final priceValue = num.tryParse(priceRaw)?.toInt() ?? 0;
    return MenuItem(
      name: json['name']?.toString() ?? 'Unknown',
      price: priceValue,
      image: json['image']?.toString() ?? '',
    );
  }
}
