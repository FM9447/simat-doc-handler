import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/loading_logo.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  final UserModel user;
  const ProfileEditScreen({super.key, required this.user});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey      = GlobalKey<FormState>();
  late  TextEditingController _nameCtrl;
  late  TextEditingController _emailCtrl;
  String? _selectedDeptId;
  String? _selectedTutorId;
  int?    _selectedYear;
  String? _selectedDivision;
  bool    _isLoading  = false;
  List<dynamic> _departments = [];
  List<dynamic> _tutors      = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl          = TextEditingController(text: widget.user.name);
    _emailCtrl         = TextEditingController(text: widget.user.email);
    _selectedDeptId    = widget.user.departmentId;
    _selectedTutorId   = widget.user.tutorId;
    _selectedYear      = widget.user.year;
    _selectedDivision  = widget.user.division;
    _loadInitialData();
  }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final depts = await ref.read(authProvider.notifier).fetchDepartments();
      setState(() => _departments = depts);
      if (_selectedDeptId != null) await _loadTutors(_selectedDeptId!);
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _loadTutors(String deptId) async {
    final t = await ref.read(authProvider.notifier).fetchTutors(deptId);
    setState(() => _tutors = t);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).updateProfile({
        'name': _nameCtrl.text, 'email': _emailCtrl.text,
        'departmentId': _selectedDeptId, 'tutorId': _selectedTutorId,
        'year': _selectedYear, 'division': _selectedDivision,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.rejected));
      }
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _departments.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('Edit Profile', style: AppTypography.headingSmall)),
        body: Center(child: LoadingLogo(size: 80)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Edit Profile', style: AppTypography.headingSmall)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Form(
          key: _formKey,
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppColors.foreground),
                  decoration: const InputDecoration(labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.muted, size: 20)),
                  validator: (v) => v!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  style: const TextStyle(color: AppColors.foreground),
                  decoration: const InputDecoration(labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.muted, size: 20)),
                  validator: (v) => v!.isEmpty ? 'Email is required' : null,
                ),
                if (['student', 'tutor', 'hod'].contains(widget.user.role)) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDeptId,
                    decoration: const InputDecoration(labelText: 'Department',
                        prefixIcon: Icon(Icons.business_outlined, color: AppColors.muted, size: 20)),
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                    hint: const Text('Select Department', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    items: _departments.map((d) => DropdownMenuItem(
                      value: d['_id'].toString(), child: Text(d['name'].toString()),
                    )).toList(),
                    onChanged: (v) {
                      setState(() { _selectedDeptId = v; _selectedTutorId = null; _tutors = []; });
                      if (v != null) _loadTutors(v);
                    },
                  ),
                ],
                if (widget.user.role == 'student') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    decoration: const InputDecoration(labelText: 'Year',
                        prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.muted, size: 20)),
                    dropdownColor: AppColors.card,
                    items: [1, 2, 3, 4].map((y) => DropdownMenuItem(value: y, child: Text('Year $y'))).toList(),
                    onChanged: (v) => setState(() => _selectedYear = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDivision,
                    decoration: const InputDecoration(labelText: 'Division',
                        prefixIcon: Icon(Icons.class_outlined, color: AppColors.muted, size: 20)),
                    dropdownColor: AppColors.card,
                    items: ['A', 'B'].map((d) => DropdownMenuItem(value: d, child: Text('Div $d'))).toList(),
                    onChanged: (v) => setState(() => _selectedDivision = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTutorId,
                    decoration: const InputDecoration(labelText: 'Your Tutor',
                        prefixIcon: Icon(Icons.supervisor_account_outlined, color: AppColors.muted, size: 20)),
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                    hint: Text(_isLoading && _tutors.isEmpty ? 'Loading…' : 'Select Tutor',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                    items: _tutors.map((t) => DropdownMenuItem(
                      value: t['_id'].toString(),
                      child: Text(t['name']?.toString() ?? 'Unnamed Tutor'),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedTutorId = v),
                  ),
                ],
                const SizedBox(height: 32),
                GradientButton(
                  text: 'Save Profile',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _saveProfile,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
