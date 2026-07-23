import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/animated_cosmic_background.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../dashboard/presentation/screens/main_screen.dart';
import '../../../../shared/widgets/branded_title.dart';
import '../../../../shared/widgets/responsive_layout.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _registerNoCtrl = TextEditingController();

  String _role = 'student';
  String? _selectedDeptId;
  String? _selectedTutorId;
  int? _selectedYear;
  String? _selectedDivision;
  bool _hasDivision = false;
  bool _obscurePassword = true;

  List<dynamic> _departments = [];
  List<dynamic> _tutors = [];
  bool _isFetchingDepts = false;
  bool _isFetchingTutors = false;

  Uint8List? _signatureBytes;
  String? _signatureFileName;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    setState(() => _isFetchingDepts = true);
    try {
      final depts = await ref.read(authProvider.notifier).fetchDepartments();
      setState(() => _departments = depts);
    } catch (e) {
      debugPrint('dept error: $e');
    } finally {
      if (mounted) setState(() => _isFetchingDepts = false);
    }
  }

  Future<void> _onDeptChanged(String? deptId) async {
    setState(() {
      _selectedDeptId = deptId;
      _selectedTutorId = null;
      _tutors = [];
    });
    if (deptId == null) return;
    setState(() => _isFetchingTutors = true);
    try {
      final tutors = await ref.read(authProvider.notifier).fetchTutors(deptId);
      setState(() => _tutors = tutors);
    } catch (e) {
      debugPrint('tutor error: $e');
    } finally {
      if (mounted) setState(() => _isFetchingTutors = false);
    }
  }

  Future<void> _pickSignature() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes != null) {
        setState(() {
          _signatureBytes = bytes;
          _signatureFileName = file.name;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _registerNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    final userData = {
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passwordCtrl.text.trim(),
      'role': _role,
      'registerNo': _role == 'student' ? _registerNoCtrl.text.trim() : null,
      'departmentId': _selectedDeptId,
      'tutorId': _selectedTutorId,
      'year': _selectedYear,
      'division': _hasDivision ? _selectedDivision : null,
    };

    try {
      await ref.read(authProvider.notifier).register(userData);
      if (_signatureBytes != null && _signatureFileName != null) {
        await ref.read(authProvider.notifier).uploadSignature(_signatureBytes!, _signatureFileName!);
      }
      if (mounted && ref.read(authProvider).valueOrNull != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (_) {}
  }

  InputDecoration _field(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.muted),
      );

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    ref.listen(authProvider, (_, next) {
      if (next is AsyncError) DialogUtils.showErrorDialog(context, next.error.toString());
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedCosmicBackground(
        child: SafeArea(
          child: Center(
            child: MaxWidthWrapper(
              maxWidth: 500,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back + Branding
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.muted),
                        ),
                        const SizedBox(width: 4),
                        const BrandedTitle(fontSize: 20, logoHeight: 30),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text('Create your account', style: AppTypography.headingMedium),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text('Join the paperless document system', style: AppTypography.bodyMuted),
                    ),
                    const SizedBox(height: 24),

                    AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Name
                              TextFormField(
                                controller: _nameCtrl,
                                autofillHints: const [AutofillHints.name],
                                style: const TextStyle(color: AppColors.foreground),
                                decoration: _field('Full Name', Icons.person_outline_rounded),
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 14),

                              // Email
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.username, AutofillHints.email],
                                style: const TextStyle(color: AppColors.foreground),
                                decoration: _field('Email Address', Icons.email_outlined),
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 14),

                              // Password
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                autofillHints: const [AutofillHints.newPassword],
                                style: const TextStyle(color: AppColors.foreground),
                                decoration: _field('Password', Icons.lock_outline_rounded).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 20,
                                      color: AppColors.muted,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                              ),
                              const SizedBox(height: 14),

                              // Role
                              DropdownButtonFormField<String>(
                                value: _role,
                                decoration: _field('Account Role', Icons.badge_outlined),
                                dropdownColor: AppColors.card,
                                style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                                items: const [
                                  DropdownMenuItem(value: 'student', child: Text('Student')),
                                  DropdownMenuItem(value: 'tutor', child: Text('Class Tutor')),
                                  DropdownMenuItem(value: 'hod', child: Text('HOD')),
                                  DropdownMenuItem(value: 'principal', child: Text('Principal')),
                                  DropdownMenuItem(value: 'office', child: Text('Office Staff')),
                                ],
                                onChanged: (v) => setState(() => _role = v!),
                              ),
                              const SizedBox(height: 14),

                              // Department
                              DropdownButtonFormField<String>(
                                value: _selectedDeptId,
                                decoration: _field('Department', Icons.account_balance_outlined),
                                dropdownColor: AppColors.card,
                                style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                                hint: Text(
                                  _isFetchingDepts ? 'Loading departments...' : 'Select Department',
                                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                ),
                                items: _departments.map((d) {
                                  return DropdownMenuItem<String>(
                                    value: d['_id'] as String,
                                    child: Text(d['name'] as String),
                                  );
                                }).toList(),
                                onChanged: _onDeptChanged,
                                validator: (v) => v == null ? 'Please select a department' : null,
                              ),
                              const SizedBox(height: 14),

                              // Student specific fields
                              if (_role == 'student') ...[
                                TextFormField(
                                  controller: _registerNoCtrl,
                                  style: const TextStyle(color: AppColors.foreground),
                                  decoration: _field('KTU Register Number', Icons.confirmation_number_outlined),
                                  validator: (v) => (_role == 'student' && (v == null || v.isEmpty)) ? 'Required for students' : null,
                                ),
                                const SizedBox(height: 14),

                                DropdownButtonFormField<String>(
                                  value: _selectedTutorId,
                                  decoration: _field('Assigned Class Tutor', Icons.person_search_outlined),
                                  dropdownColor: AppColors.card,
                                  style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                                  hint: Text(
                                    _selectedDeptId == null
                                        ? 'Select Department first'
                                        : _isFetchingTutors
                                            ? 'Loading tutors...'
                                            : _tutors.isEmpty
                                                ? 'No tutors in department'
                                                : 'Select Tutor',
                                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                  ),
                                  items: _tutors.map((t) {
                                    return DropdownMenuItem<String>(
                                      value: t['_id'] as String,
                                      child: Text('${t['name']} (${t['email']})'),
                                    );
                                  }).toList(),
                                  onChanged: (v) => setState(() => _selectedTutorId = v),
                                  validator: (v) => (_role == 'student' && v == null) ? 'Required' : null,
                                ),
                                const SizedBox(height: 14),

                                DropdownButtonFormField<int>(
                                  value: _selectedYear,
                                  decoration: _field('Current Year of Study', Icons.calendar_today_outlined),
                                  dropdownColor: AppColors.card,
                                  style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                                  items: const [
                                    DropdownMenuItem(value: 1, child: Text('1st Year (S1 / S2)')),
                                    DropdownMenuItem(value: 2, child: Text('2nd Year (S3 / S4)')),
                                    DropdownMenuItem(value: 3, child: Text('3rd Year (S5 / S6)')),
                                    DropdownMenuItem(value: 4, child: Text('4th Year (S7 / S8)')),
                                  ],
                                  onChanged: (v) => setState(() => _selectedYear = v),
                                  validator: (v) => (_role == 'student' && v == null) ? 'Required' : null,
                                ),
                                const SizedBox(height: 14),

                                CheckboxListTile(
                                  title: const Text('My Department has Divisions (A/B)', style: TextStyle(color: AppColors.foreground, fontSize: 13)),
                                  value: _hasDivision,
                                  activeColor: AppColors.primary,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (v) => setState(() {
                                    _hasDivision = v ?? false;
                                    if (!_hasDivision) _selectedDivision = null;
                                  }),
                                ),

                                if (_hasDivision) ...[
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedDivision,
                                    decoration: _field('Division', Icons.class_outlined),
                                    dropdownColor: AppColors.card,
                                    style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                                    items: const [
                                      DropdownMenuItem(value: 'A', child: Text('Division A')),
                                      DropdownMenuItem(value: 'B', child: Text('Division B')),
                                      DropdownMenuItem(value: 'C', child: Text('Division C')),
                                    ],
                                    onChanged: (v) => setState(() => _selectedDivision = v),
                                    validator: (v) => (_hasDivision && v == null) ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                              ],

                              // Digital Signature Upload
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: _pickSignature,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.glassBorder),
                                  ),
                                  child: _signatureBytes != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.memory(_signatureBytes!, fit: BoxFit.contain),
                                        )
                                      : const Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add_a_photo_outlined, color: AppColors.muted, size: 22),
                                              SizedBox(height: 4),
                                              Text('Upload Signature', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              GradientButton(
                                text: 'Create Account',
                                icon: Icons.person_add_alt_1_rounded,
                                isLoading: isLoading,
                                onPressed: isLoading ? null : _register,
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
