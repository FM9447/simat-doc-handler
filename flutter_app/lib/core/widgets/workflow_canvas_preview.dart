import 'package:flutter/material.dart';
import '../../models/workflow_element.dart';
import '../../models/workflow_model.dart';
import '../constants/app_constants.dart';

class WorkflowCanvasPreview extends StatelessWidget {
  final List<WorkflowElement> elements;
  final Map<String, dynamic> formData;
  final Map<String, dynamic> student;
  final WorkflowModel? workflow;

  const WorkflowCanvasPreview({
    super.key,
    required this.elements,
    required this.formData,
    required this.student,
    this.workflow,
  });

  @override
  Widget build(BuildContext context) {
    if (elements.isEmpty) {
      return const Center(
        child: Text('No layout defined for this document type.',
            style: TextStyle(color: AppConstants.hintColor, fontSize: 12)),
      );
    }

    // Find max height to set container height
    double maxHeight = 200;
    for (var e in elements) {
      if (e.y + e.h > maxHeight) {
        maxHeight = e.y + e.h;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double scale = constraints.maxWidth < 440 ? constraints.maxWidth / 440 : 1.0;
        
        return Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: Container(
                width: 440,
                height: maxHeight + 100, // Added height for seals
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Stack(
                  children: [
                    // Structured Letter Content (Background)
                    if (workflow != null)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (workflow!.includeLetterhead)
                              workflow!.customHeaderUrl != null
                                  ? Center(child: Image.network(workflow!.customHeaderUrl!, height: 60, fit: BoxFit.contain))
                                  : const Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text('SIMAT SMART CAMPUS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                        Text('VANIAMKULAM, PALAKKAD', style: TextStyle(fontSize: 8, color: Colors.black54)),
                                        Divider(height: 16, thickness: 1),
                                      ],
                                    ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (workflow!.includeRefDate) const Text('REF: SIMAT/2026/042', style: TextStyle(fontSize: 9, color: Colors.blueGrey)) else const SizedBox(),
                                if (workflow!.includeRefDate) const Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Date: 20 March 2026', style: TextStyle(fontSize: 9, color: Colors.blueGrey)),
                                    SizedBox(height: 2),
                                    Text('Place: Vavanoor', style: TextStyle(fontSize: 9, color: Colors.blueGrey)),
                                  ],
                                ) else const SizedBox(),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (workflow!.templateTo.isNotEmpty) ...[
                              const Text('To,', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: (workflow!.templateTo.replaceAll('{{name}}', student['name'] ?? 'Student')).split(',').map((part) => 
                                    Text(part.trim() + (part == (workflow!.templateTo.split(',').last) ? '' : ','), style: const TextStyle(fontSize: 10, color: Colors.black87))
                                  ).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            Text(
                              _getProcessedBody(workflow!.letterTemplate),
                              style: const TextStyle(fontSize: 10, color: Colors.black87, height: 1.4),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Column(
                                  children: [
                                    Text(workflow!.templateClosing, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    const SizedBox(height: 5),
                                    if (student['signatureUrl'] != null && student['signatureUrl'].toString().isNotEmpty)
                                      Image.network(student['signatureUrl'], height: 25)
                                    else
                                      const SizedBox(height: 25),
                                    const SizedBox(height: 5),
                                    Text((student['name'] ?? 'STUDENT').toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    Text(student['registerNo'] ?? 'LSPT24CS115', style: const TextStyle(fontSize: 8, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (workflow!.includeSeal)
                              Center(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.green.shade800, width: 1.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('APPROVED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                                ),
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  String _getProcessedBody(String body) {
    String processed = body;
    formData.forEach((k, v) => processed = processed.replaceAll('{{${k.replaceAll(' ', '_')}}}', v?.toString() ?? ''));
    student.forEach((k, v) => processed = processed.replaceAll('{{$k}}', v?.toString() ?? ''));
    return processed;
  }

  Widget _buildElement(WorkflowElement e) {
    final x = e.x;
    final y = e.y;
    final w = e.w;
    final h = e.h;

    return Positioned(
      left: x,
      top: y,
      width: w,
      height: h,
      child: _buildContent(e),
    );
  }

  Widget _buildContent(WorkflowElement e) {
    switch (e.kind) {
      case 'header':
        return Text(
          e.content ?? '',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        );
      case 'address':
        return Text(
          e.content ?? '',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
            height: 1.2,
          ),
        );
      case 'divider':
        return Center(
          child: Container(
            height: 1,
            color: Colors.black12,
          ),
        );

      case 'seal':
      case 'header_image':
        if (e.imageUrl != null && e.imageUrl!.isNotEmpty) {
          return Image.network(
            e.imageUrl!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.black12),
          );
        }
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12, style: BorderStyle.none),
            color: Colors.black.withOpacity(0.03),
          ),
          child: Center(
            child: Icon(
              e.kind == 'seal' ? Icons.verified_user_outlined : Icons.image_outlined,
              color: Colors.black12,
              size: 20,
            ),
          ),
        );

      case 'field':
      case 'system':
        String val = '—';
        if (e.kind == 'system') {
          if (e.sysKey == 'name') val = student['name'] ?? '—';
          if (e.sysKey == 'registerNo') val = student['registerNo'] ?? '—';
          if (e.sysKey == 'dept') val = student['dept'] ?? '—';
          if (e.sysKey == 'year') val = student['year']?.toString() ?? '—';
          if (e.sysKey == 'division') val = student['division'] ?? '—';
        } else {
          val = formData[e.label]?.toString() ?? '—';
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e.label ?? '', style: const TextStyle(fontSize: 8, color: Colors.black38, fontWeight: FontWeight.bold)),
            Text(val, style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600)),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
