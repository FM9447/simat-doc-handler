import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';

class DutyLeaveRowData {
  String date;
  String hours;
  String reason;

  DutyLeaveRowData({
    required this.date,
    required this.hours,
    required this.reason,
  });

  Map<String, String> toJson() => {
    'Date': date,
    'Hours': hours,
    'Reason': reason,
  };
}

class DutyLeaveTableInput extends StatefulWidget {
  final ValueChanged<List<DutyLeaveRowData>> onChanged;

  const DutyLeaveTableInput({super.key, required this.onChanged});

  @override
  State<DutyLeaveTableInput> createState() => _DutyLeaveTableInputState();
}

class _DutyLeaveTableInputState extends State<DutyLeaveTableInput> {
  final List<DutyLeaveRowData> _rows = [];

  @override
  void initState() {
    super.initState();
    // Add default initial row
    _addRow();
  }

  void _addRow() {
    setState(() {
      _rows.add(DutyLeaveRowData(
        date: DateFormat('dd/MM/yyyy').format(DateTime.now()),
        hours: 'Periods 1 to 4',
        reason: '',
      ));
    });
    widget.onChanged(_rows);
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows.removeAt(index);
    });
    widget.onChanged(_rows);
  }

  Future<void> _selectDate(BuildContext context, int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _rows[index].date = DateFormat('dd/MM/yyyy').format(picked);
      });
      widget.onChanged(_rows);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.table_chart_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('DUTY LEAVE SCHEDULE (MULTI-DAY / HOURS)', style: AppTypography.labelSmall),
                ],
              ),
              TextButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                label: const Text('Add Row', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final row = _rows[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Row Number
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text('${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 10),
                        // Date Picker Button
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () => _selectDate(context, index),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(row.date, style: const TextStyle(fontSize: 12, color: AppColors.foreground)),
                                  const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.muted),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete row button
                        if (_rows.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: AppColors.rejected),
                            onPressed: () => _removeRow(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Hours Input
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: row.hours,
                            style: const TextStyle(fontSize: 12, color: AppColors.foreground),
                            decoration: const InputDecoration(
                              labelText: 'Hours / Periods',
                              hintText: 'e.g. Periods 1-4 or 6 Hrs',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (v) {
                              row.hours = v;
                              widget.onChanged(_rows);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Reason Input
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: row.reason,
                            style: const TextStyle(fontSize: 12, color: AppColors.foreground),
                            decoration: const InputDecoration(
                              labelText: 'Reason / Event Details',
                              hintText: 'e.g. Hackathon Representation',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (v) {
                              row.reason = v;
                              widget.onChanged(_rows);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
