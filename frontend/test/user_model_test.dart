import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user.dart';

void main() {
  group('User model', () {
    test('parses backend roles and preserves profile details', () {
      final user = User.fromJson({
        'id': 'user-1',
        'name': 'Sam Student',
        'email': 'sam@example.test',
        'role': 'CUSTOMER',
      });

      expect(user.id, 'user-1');
      expect(user.name, 'Sam Student');
      expect(user.email, 'sam@example.test');
      expect(user.role, UserRole.customer);
      expect(user.role.displayName, 'Student');
    });

    test('recognizes STAFF and ADMIN role values', () {
      expect(UserRole.fromString('STAFF'), UserRole.staff);
      expect(UserRole.fromString('ADMIN'), UserRole.admin);
      expect(UserRole.fromString(null), UserRole.unknown);
    });

    test('serializes the backend role value for persistence', () {
      const user = User(
        id: 'staff-1',
        name: 'Pat Staff',
        email: 'pat@example.test',
        role: UserRole.staff,
      );

      expect(user.toJson()['role'], 'STAFF');
    });
  });
}
