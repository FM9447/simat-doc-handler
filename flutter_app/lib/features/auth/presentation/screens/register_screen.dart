import 'dart:typed_data';
import 'package:flutter/material.dart';
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
  final _formKey            = GlobalKey<FormState>();
  final _nameCtrl           = TextEditingController();
  final _emailCtrl          = TextEditingController();
  final _passwordCtrl       = TextEditingController();
  final _registerNoCtrl     = TextEditingController();

  String  _role             = 'student';
  String? _selectedDeptId;
  String? _selectedTutorId;
  int?    _selectedYear;
  String? _selectedDivision;
  bool    _hasDivision      = false;
  bool    _obscurePassword  = true;

  List<dynamic> _departments     = [];
  List<dynamic> _tutors          = [];
  bool          _isFetchingDepts = false;
  bool          _isFetchingTutors= false;

  Uint8List? _signatureBytes;
  String?    _signatureFileName;

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
    } catch (e) { debugPrint('dept error: $e'); }
    finally { if (mounted) setState(() => _isFetchingDepts = false); }
  }

  Future<void> _fetchTutors(String deptId) async {
    setState(() { _isFetchingTutors = true; _tutors = []; _selectedTutorId = null; });
    try {
      final tutors = await ref.read(authProvider.notifier).fetchTutors(deptId);
      setState(() => _tutors = tutors);
    } catch (e) { debugPrint('tutor error: $e'); }
    finally { if (mounted) setState(() => _isFetchingTutors = false); }
  }

  Future<void> _pickSignature() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _signatureBytes   = result.files.single.bytes;
        _signatureFileName = result.files.single.name;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passwordCtrl.dispose(); _registerNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final userData = {
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passwordCtrl.text.trim(),
      'role': _role,
      'registerNo': _role == 'student' ? _registerNoCtrl.text.trim() : null,
      'departmentId': _selectedDeptId,
      'tutorId': _selectedTutorId,
      'year': _selectedYear,
      'division': _selectedDivision,
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
              maxWidth: 450,
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

                Form(
                  key: _formKey,
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name
                        TextFormField(
                          controller: _nameCtrl,
                          style: const TextStyle(color: AppColors.foreground),
                          decoration: _field('Full Name', Icons.person_outline_rounded),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.foreground),
                          decoration: _field('Email Address', Icons.email_outlined),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        // Password
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppColors.foreground),
                          decoration: _field('Password', Icons.lock_outline_rounded).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20, color: AppColors.muted),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                        ),
                        const SizedBox(height: 14),

                        // Role
                        DropdownButtonFormField<String>(
                          initialValue: _role,
                          decoration: _field('Role', Icons.work_outline_rounded),
                          dropdownColor: AppColors.card,
                          style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                          items: ['student', 'tutor', 'hod', 'office']
                              .map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase())))
                              .toList(),
                          onChanged: (v) => setState(() => _role = v!),
                        ),

                        // Department (not for principal/office/admin)
                        if (!['principal', 'office', 'admin'].contains(_role)) ...[
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedDeptId,
                            decoration: _field('Department', Icons.business_outlined),
                            dropdownColor: AppColors.card,
                            style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                            hint: Text(_isFetchingDepts ? 'Loading…' : 'Select Department',
                                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                            items: _departments.map((d) => DropdownMenuItem(
                              value: d['_id'].toString(),
                              child: Text(d['name'].toString()),
                            )).toList(),
                            onChanged: (v) {
                              setState(() { _selectedDeptId = v; _tutors = []; _selectedTutorId = null; });
                              if (v != null) _fetchTutors(v);
                            },
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        ],

                        // Student-only fields
                        if (_role == 'student') ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _registerNoCtrl,
                            style: const TextStyle(color: AppColors.foreground),
                            decoration: _field('Register Number', Icons.badge_outlined),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedYear,
                            decoration: _field('Year', Icons.calendar_today_outlined),
                            dropdownColor: AppColors.card,
                            style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                            items: [1, 2, 3, 4].map((y) => DropdownMenuItem(value: y, child: Text('Year $y'))).toList(),
                            onChanged: (v) => setState(() => _selectedYear = v),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Student has a Division?', style: AppTypography.bodyMedium),
                            value: _hasDivision,
                            activeThumbColor: AppColors.primary,
                            onChanged: (v) => setState(() { _hasDivision = v; if (!v) _selectedDivision = null; }),
                          ),
                          if (_hasDivision) ...[
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedDivision,
                              decoration: _field('Division', Icons.class_outlined),
                              dropdownColor: AppColors.card,
                              items: ['A', 'B'].map((d) => DropdownMenuItem(value: d, child: Text('Div $d'))).toList(),
                              onChanged: (v) => setState(() => _selectedDivision = v),
                              validator: (v) => _hasDivision && v == null ? 'Required' : null,
                            ),
                          ],
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedTutorId,
                            decoration: _field('Your Tutor', Icons.person_search_outlined),
                            dropdownColor: AppColors.card,
                            style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                            hint: Text(
                              _isFetchingTutors ? 'Loading Tutors…'
                                  : (_selectedDeptId == null ? 'Select Department first' : 'Choose a Tutor'),
                              style: const TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                            items: _tutors.map((t) => DropdownMenuItem(
                              value: t['_id'].toString(),
                              child: Text(t['name']?.toString() ?? 'Unnamed Tutor'),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedTutorId = v),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          Text('Digital Signature (Optional)', style: AppTypography.labelSmall),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickSignature,
                            child: Container(
                              height: 90,
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
                                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Icon(Icons.add_a_photo_outlined, color: AppColors.muted, size: 22),
                                        SizedBox(height: 4),
                                        Text('Upload Signature', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                                      ]),
                                    ),
                            ),
                          ),
                        ],

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
