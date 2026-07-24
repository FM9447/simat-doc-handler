import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../models/document_model.dart';
import '../../models/workflow_model.dart';
import 'dart:math';

class PdfExportHelper {
  static String _refNo() => 'SIMAT/${DateTime.now().year}/${Random().nextInt(9000) + 1000}';
  static String _nowDate() => DateFormat('dd MMMM yyyy').format(DateTime.now());

  static Future<void> generateAndPrintDocument(DocumentModel document, [List<WorkflowModel>? flows]) async {
    final pdf = pw.Document();

    // Find matching workflow for letter template - returns null if not found
    WorkflowModel? workflow;
    if (flows != null && flows.isNotEmpty) {
      try {
        workflow = flows.firstWhere(
          (f) => f.name == (document.flow ?? document.category),
        );
      } catch (_) {
        workflow = null;
      }
    }

    // 1. Pre-fetch all images concurrently
    final Set<String> urlsToFetch = {};
    if (workflow != null) {
      final wf = workflow;
      if (wf.customHeaderUrl?.isNotEmpty == true) urlsToFetch.add(wf.customHeaderUrl!);
      if (wf.customApprovedSealUrl?.isNotEmpty == true) urlsToFetch.add(wf.customApprovedSealUrl!);
      if (wf.customRejectedSealUrl?.isNotEmpty == true) urlsToFetch.add(wf.customRejectedSealUrl!);
      for (final el in wf.elements) {
        if (el.imageUrl?.isNotEmpty == true) urlsToFetch.add(el.imageUrl!);
      }
    }

    for (var approval in document.approvals) {
      if (approval.signatureUrl?.isNotEmpty == true) urlsToFetch.add(approval.signatureUrl!);
    }
    
    final String? studentSignatureUrl = document.studentSignatureUrl ??
        (document.studentId is Map ? document.studentId['signatureUrl'] as String? : null);
    if (studentSignatureUrl?.isNotEmpty == true) urlsToFetch.add(studentSignatureUrl!);

    final Map<String, pw.ImageProvider?> remoteImages = {};
    final fetchFutures = urlsToFetch.map((url) async {
      try {
        remoteImages[url] = await networkImage(url);
      } catch (_) {
        remoteImages[url] = null;
      }
    });
    await Future.wait(fetchFutures);

    // Approval signatures
    final List<pw.ImageProvider?> signatureImages = document.approvals.map((approval) {
      return approval.signatureUrl?.isNotEmpty == true ? remoteImages[approval.signatureUrl!] : null;
    }).toList();

    // 2. Build substitution map
    final studentName = document.studentId is Map ? document.studentId['name'] ?? '' : '';
    final studentReg = document.studentId is Map ? document.studentId['registerNo'] ?? '' : '';
    final studentDept = document.studentId is Map
        ? (document.studentId['departmentId'] is Map
            ? document.studentId['departmentId']['name']
            : document.studentId['dept']) ?? ''
        : '';
    final studentYear = document.studentId is Map ? document.studentId['year']?.toString() ?? '' : '';
    final studentDivision = document.studentId is Map ? document.studentId['division'] ?? '' : '';

    final subs = <String, String>{
      'name': studentName,
      'registerNo': studentReg,
      'dept': studentDept,
      'year': studentYear,
      'division': studentDivision,
      'date': document.createdAt?.toString().substring(0, 10) ?? DateFormat('dd-MM-yyyy').format(DateTime.now()),
      'ref_no': _refNo(),
      'To_Whom_It_May_Concern': 'To Whom It May Concern,',
      'Sincerely': 'Sincerely,',
    };

    if (document.formData != null) {
      document.formData!.forEach((k, v) {
        final valStr = v?.toString() ?? '';
        final rawKey = k.toString().trim();
        final lowerKey = rawKey.toLowerCase();
        final snakeKey = lowerKey.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');

        subs[rawKey] = valStr;
        subs[rawKey.replaceAll(' ', '_')] = valStr;
        subs[lowerKey] = valStr;
        subs[snakeKey] = valStr;

        // Specific aliases for Duty Leave
        if (lowerKey.contains('duty category') || lowerKey.contains('club')) {
          subs['duty_category'] = valStr;
          subs['dutyCategory'] = valStr;
        }
        if (lowerKey.contains('event') || lowerKey.contains('activity')) {
          subs['event_name'] = valStr;
          subs['eventName'] = valStr;
        }
        if (lowerKey.contains('schedule') || lowerKey.contains('table')) {
          subs['duty_leave_schedule'] = valStr;
          subs['dutyLeaveSchedule'] = valStr;
        }
        if (lowerKey.contains('total hours') || lowerKey.contains('granted') || lowerKey.contains('periods')) {
          subs['total_hours_granted'] = valStr;
          subs['totalHoursGranted'] = valStr;
        }

        // Specific aliases for Bonafide
        if (lowerKey.contains('purpose')) {
          subs['purpose_of_certificate'] = valStr;
          subs['purposeOfCertificate'] = valStr;
        }
        if (lowerKey.contains('academic year')) {
          subs['academic_year'] = valStr;
          subs['academicYear'] = valStr;
        }

        // Specific aliases for Transfer Certificate
        if (lowerKey.contains('admission') || lowerKey.contains('reg')) {
          subs['admission_no_or_reg'] = valStr;
          subs['admissionNoOrReg'] = valStr;
        }
        if (lowerKey.contains('birth')) {
          subs['date_of_birth'] = valStr;
          subs['dateOfBirth'] = valStr;
        }
        if (lowerKey.contains('leaving date') || lowerKey.contains('leaving')) {
          subs['leaving_date'] = valStr;
        }
        if (lowerKey.contains('reason')) {
          subs['reason_for_leaving'] = valStr;
        }
        if (lowerKey.contains('promotion')) {
          subs['promotion_status'] = valStr;
        }
        if (lowerKey.contains('conduct')) {
          subs['character_and_conduct'] = valStr;
          subs['overall_conduct'] = valStr;
        }

        // Specific aliases for NOC & Course Completion
        if (lowerKey.contains('company') || lowerKey.contains('institution')) {
          subs['company_or_institution'] = valStr;
        }
        if (lowerKey.contains('start date')) {
          subs['start_date'] = valStr;
        }
        if (lowerKey.contains('end date')) {
          subs['end_date'] = valStr;
        }
        if (lowerKey.contains('duration')) {
          subs['duration_of_study'] = valStr;
        }
      });
    }

    pw.ImageProvider? defaultHeaderImage;
    try {
      defaultHeaderImage = await imageFromAssetBundle('assets/images/simat_header.png');
    } catch (_) {}

    // Capture non-nullable local reference for use in closures
    final wf = workflow;

    // Build the letterhead widget for the header
    pw.Widget? letterheadWidget;
    final bool showLetterhead = wf == null || wf.includeLetterhead;
    if (showLetterhead) {
      final headerImageUrl = wf?.customHeaderUrl;
      final headerImage = (headerImageUrl != null && remoteImages[headerImageUrl] != null)
          ? remoteImages[headerImageUrl]
          : defaultHeaderImage;

      if (headerImage != null) {
        letterheadWidget = pw.Container(
          height: 110,
          margin: const pw.EdgeInsets.only(top: 10, left: 15, right: 15, bottom: 0),
          alignment: pw.Alignment.topCenter,
          child: pw.Image(headerImage, width: PdfPageFormat.a4.width, fit: pw.BoxFit.contain),
        );
      } else {
        letterheadWidget = pw.Container(
          width: PdfPageFormat.a4.width,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(height: 4),
              pw.Text('SREEPATHY INSTITUTE OF MANAGEMENT AND TECHNOLOGY', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('Affiliated to APJ Abdul Kalam Technological University (KTU)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.Text('Pattambi, Palakkad - 679 533 · Email: principal@simat.ac.in · www.simat.ac.in', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                child: pw.Divider(thickness: 1.2, color: PdfColors.grey300),
              ),
            ],
          ),
        );
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          final List<pw.Widget> widgets = [];

          if (letterheadWidget != null) {
            widgets.add(letterheadWidget);
          }

          // ── BODY CONTENT ────────────────────────────────────────────────
          if (wf != null) {
            final List<pw.Widget> bodyChildren = [];

            if (document.customHeading != null && document.customHeading!.trim().isNotEmpty) {
              bodyChildren.add(
                pw.Center(
                  child: pw.Text(
                    document.customHeading!.trim().toUpperCase(),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ),
              );
              bodyChildren.add(pw.SizedBox(height: 15));
            }

            // Ref & Date row
            if (wf.includeRefDate) {
              bodyChildren.add(
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Ref: ${subs['ref_no']}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Date: ${_nowDate()}', style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 2),
                        pw.Text('Place: Vavanoor', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              );
              bodyChildren.add(pw.SizedBox(height: 10));
            }

            // Recipient (To)
            if (wf.templateTo.isNotEmpty) {
              final toParts = wf.templateTo.replaceAll('{{name}}', studentName).split(',');
              bodyChildren.add(pw.Text('To,', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)));
              bodyChildren.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: toParts.asMap().entries.map((e) {
                      final isLast = e.key == toParts.length - 1;
                      return pw.Text(e.value.trim() + (isLast ? '' : ','), style: const pw.TextStyle(fontSize: 10));
                    }).toList(),
                  ),
                ),
              );
              bodyChildren.add(pw.SizedBox(height: 10));
            }

            // Subject Line
            if (document.title.trim().isNotEmpty) {
              bodyChildren.add(
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Subject: ', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
                    pw.Expanded(
                      child: pw.Text(document.title.trim(), style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
              );
              bodyChildren.add(pw.SizedBox(height: 10));
            }

            // Letter body
            final String rawTemplate = wf.letterTemplate.trim().replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
            final lines = rawTemplate.split('\n');
            for (final line in lines) {
              String processed = line;
              subs.forEach((k, v) => processed = processed.replaceAll('{{$k}}', v));
              processed = processed.replaceAllMapped(RegExp(r'\{\{\s*([a-zA-Z0-9_\s\/]+)\s*\}\}'), (match) {
                final tag = match.group(1)?.trim() ?? '';
                final tagLower = tag.toLowerCase();
                final tagSnake = tagLower.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');
                if (subs.containsKey(tag)) return subs[tag]!;
                if (subs.containsKey(tagLower)) return subs[tagLower]!;
                if (subs.containsKey(tagSnake)) return subs[tagSnake]!;
                return '';
              });

              // Detect pipe-delimited schedule table (e.g. from duty leave)
              final scheduleRows = processed.split('\n').where((r) => r.contains('|')).toList();
              if (scheduleRows.isNotEmpty && processed.contains('|')) {
                // Build a proper bordered table
                final tableData = scheduleRows.map((r) =>
                  r.split('|').map((c) => c.trim()).toList()
                ).toList();

                // Ensure every row has 3 columns
                for (final row in tableData) {
                  while (row.length < 3) { row.add('—'); }
                }

                bodyChildren.add(pw.SizedBox(height: 6));
                bodyChildren.add(
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(2.2),
                      1: pw.FlexColumnWidth(2.2),
                      2: pw.FlexColumnWidth(3.6),
                    },
                    children: [
                      // Header row
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: ['Date', 'Hours / Periods', 'Reason / Activity'].map((h) =>
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            child: pw.Text(h,
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                            ),
                          ),
                        ).toList(),
                      ),
                      // Data rows
                      ...tableData.map((cols) => pw.TableRow(
                        children: [cols[0], cols[1], cols[2]].map((cell) =>
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            child: pw.Text(cell, style: const pw.TextStyle(fontSize: 9)),
                          ),
                        ).toList(),
                      )),
                    ],
                  ),
                );
                bodyChildren.add(pw.SizedBox(height: 6));
              } else {
                bodyChildren.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Paragraph(
                      text: processed,
                      style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 3),
                    ),
                  ),
                );
              }
            }


            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 40, right: 40, top: 8, bottom: 15),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: bodyChildren,
                ),
              ),
            );

            // ── CLOSING & STAMP ─────────────────────────────────────────
            pw.Widget sealWidget = pw.SizedBox();
            if (wf.includeSeal) {
              final isApproved = document.status == DocumentStatus.finalApproved ||
                  document.status == DocumentStatus.partiallyApproved;
              final isRejected = document.status == DocumentStatus.rejected;

              if (isApproved) {
                final sealImg = wf.customApprovedSealUrl != null ? remoteImages[wf.customApprovedSealUrl!] : null;
                sealWidget = sealImg != null
                    ? pw.Image(sealImg, height: 50, width: 50, fit: pw.BoxFit.contain)
                    : pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.green800, width: 1.5), borderRadius: pw.BorderRadius.circular(4)),
                        child: pw.Text('APPROVED', style: pw.TextStyle(color: PdfColors.green800, fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      );
              } else if (isRejected) {
                final sealImg = wf.customRejectedSealUrl != null ? remoteImages[wf.customRejectedSealUrl!] : null;
                sealWidget = sealImg != null
                    ? pw.Image(sealImg, height: 50, width: 50, fit: pw.BoxFit.contain)
                    : pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.red800, width: 1.5), borderRadius: pw.BorderRadius.circular(4)),
                        child: pw.Text('REJECTED', style: pw.TextStyle(color: PdfColors.red800, fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      );
              }
            }

            final studentSigImage = studentSignatureUrl != null ? remoteImages[studentSignatureUrl] : null;

            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 40, right: 40, top: 10, bottom: 0),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    sealWidget,
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(wf.templateClosing.trim(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        studentSigImage != null
                            ? pw.Image(studentSigImage, height: 20, width: 50, fit: pw.BoxFit.contain)
                            : pw.SizedBox(height: 20),
                        pw.SizedBox(height: 4),
                        pw.Text(studentName.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(studentReg, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          // ── AUTHORIZED SIGNATURES ────────────────────────────────────
          if (document.approvals.isNotEmpty) {
            // Exclude the mark-duty-leave action from signature boxes
            // (it's a marking action, not an approval signature)
            final sigApprovals = document.approvals.asMap().entries.where((entry) {
              final comment = entry.value.comment ?? '';
              return !comment.contains('Duty Leave Marked');
            }).toList();

            if (sigApprovals.isNotEmpty) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 40, right: 40, top: 10, bottom: 5),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Authorized Signatures:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: sigApprovals.map((entry) {
                          final idx = entry.key;
                          final approval = entry.value;
                          final sig = signatureImages[idx];
                          final role = idx < document.workflow.length ? document.workflow[idx] : 'approver';
                          final name = approval.approverId is Map ? approval.approverId['name'] ?? role : role;
                          return pw.Container(
                            width: 90,
                            margin: const pw.EdgeInsets.only(right: 15),
                            child: pw.Column(
                              children: [
                                sig != null
                                    ? pw.Container(height: 20, width: 70, child: pw.Image(sig, fit: pw.BoxFit.contain))
                                    : pw.SizedBox(height: 20),
                                pw.Divider(thickness: 0.5),
                                pw.Text(name.toString().toUpperCase(), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                                pw.Text(role.toUpperCase(), style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            }
          }


          return widgets;
        },
        footer: (pw.Context context) {
          final docRef = document.documentCode ?? document.id;
          final verifyUrl = 'https://api.doctransit.live/verify/$docRef';
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12, left: 40, right: 40, top: 4),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Left: doc ID + generated by
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('Ref No: ${docRef.length >= 6 ? docRef.substring(docRef.length - 6).toUpperCase() : docRef}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                          pw.SizedBox(height: 2),
                          pw.Text('Generated by DocTransit · SIMAT', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                          pw.SizedBox(height: 2),
                          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey)),
                        ],
                      ),
                    ),
                    // Right: QR code
                    pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: verifyUrl,
                          width: 36,
                          height: 36,
                          drawText: false,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('Scan to verify', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },

      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${(document.flow ?? document.category).replaceAll(' ', '_')}_${document.id}.pdf',
    );
  }
}
