import 'package:flutter_test/flutter_test.dart';
import 'package:antigravity/models/document_model.dart';
import 'package:antigravity/models/user_model.dart';
import 'package:antigravity/models/duty_category_model.dart';
import 'package:antigravity/features/documents/presentation/widgets/duty_leave_table_input.dart';

void main() {
  group('DocumentModel Unit Tests', () {
    test('Should parse Document JSON correctly', () {
      final json = {
        '_id': 'doc123',
        'studentId': 'student123',
        'title': 'Test Bonafide',
        'description': 'Description text',
        'category': 'Bonafide Certificate',
        'priority': 'high',
        'status': 'pending',
        'workflow': ['tutor', 'hod', 'principal'],
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
        'title': 'Duty Leave Application',
        'description': 'IEDC Hackathon Duty Leave',
        'category': 'Duty Leave Application',
        'priority': 'medium',
        'status': 'final_approved',
      };

      final doc = DocumentModel.fromJson(json);
      expect(doc.status, DocumentStatus.finalApproved);
      expect(doc.category, 'Duty Leave Application');
    });
  });

  group('UserModel Unit Tests', () {
    test('Should parse UserModel JSON correctly', () {
      final json = {
        '_id': 'user456',
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'student',
        'dept': 'CSE'
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'user456');
      expect(user.role, 'student');
      expect(user.dept, 'CSE');
    });
  });

  group('Duty Leave & Category Unit Tests', () {
    test('Should parse DutyCategoryModel JSON correctly', () {
      final json = {
        '_id': 'cat1',
        'name': 'IEDC',
        'code': 'iedc',
        'description': 'Innovation & Entrepreneurship Development Centre',
        'facultyInChargeId': {
          '_id': 'faculty789',
          'name': 'Prof. Rahul',
          'email': 'rahul@simat.ac.in',
          'role': 'tutor'
        },
        'isActive': true
      };

      final category = DutyCategoryModel.fromJson(json);

      expect(category.id, 'cat1');
      expect(category.name, 'IEDC');
      expect(category.code, 'iedc');
      expect(category.facultyInCharge?['name'], 'Prof. Rahul');
      expect(category.isActive, isTrue);
    });

    test('Should format DutyLeaveRowData to JSON correctly', () {
      final row = DutyLeaveRowData(
        date: '25/07/2026',
        hours: 'Periods 1 to 4',
        reason: 'State Level IEDC Hackathon Representation',
      );

      final json = row.toJson();

      expect(json['Date'], '25/07/2026');
      expect(json['Hours'], 'Periods 1 to 4');
      expect(json['Reason'], 'State Level IEDC Hackathon Representation');
    });
  });
}
