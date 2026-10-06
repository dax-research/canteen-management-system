enum UserRole {
  customer,
  staff,
  admin,
  unknown;

  bool get isCustomer => this == UserRole.customer;
  bool get isStaff => this == UserRole.staff;
  bool get isAdmin => this == UserRole.admin;

  String get displayName => switch (this) {
        UserRole.customer => 'Student',
        UserRole.staff => 'Staff',
        UserRole.admin => 'Administrator',
        UserRole.unknown => 'Unknown',
      };

  static UserRole fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'CUSTOMER':
        return UserRole.customer;
      case 'STAFF':
        return UserRole.staff;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.unknown;
    }
  }
}

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: UserRole.fromString(json['role']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name.toUpperCase(),
      };
}
