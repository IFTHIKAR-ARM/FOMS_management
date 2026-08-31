class UserModel {
  final String phone;
  final String name;
  final String role;

  UserModel({
    required this.phone,
    required this.name,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      phone: json['phone']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      role: json['role']?.toString() ?? 'customer',
    );
  }
}
