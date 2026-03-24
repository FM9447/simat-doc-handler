import 'package:flutter_test/flutter_test.dart';
import 'package:antigravity/models/document_model.dart';
import 'package:antigravity/models/user_model.dart';

void main() {
  group('DocumentModel Unit Tests', () {
    test('Should parse Document JSON correctly', () {
      final json = {
        '_id': 'doc123',
        'studentId': 'student123',
        'title': 'Test Bonafide',
        'description': 'Description text',
        'category': 'Bonafide',
        'priority': 'high',
        'status': 'pending',
        'workflow': ['teacher1', 'hod2'],
        'approvals': []
      };

      final doc = DocumentModel.fromJson(json);

      expect(doc.id, 'doc123');
      expect(doc.title, 'Test Bonafide');
      expect(doc.priority, PriorityLevel.high);
      expect(doc.status, DocumentStatus.pending);
    });

    test('Should handle final_approved status correctly', () {
      final json = {
        '_id': 'doc123',
        'studentId': 'student123',
        'title': 'Leave Letter',
        'description': 'Sick Leave',
        'category': 'Leave',
        'priority': 'low',
        'status': 'final_approved',
      };

      final doc = DocumentModel.fromJson(json);
      expect(doc.status, DocumentStatus.finalApproved);
    });
  });

  group('UserModel Unit Tests', () {
    test('Should parse UserModel JSON correctly', () {
      final json = {
        '_id': 'user456',
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'student',
        'dept': 'CS'
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'user456');
      expect(user.role, 'student');
      expect(user.dept, 'CS');
    });
  });
}
