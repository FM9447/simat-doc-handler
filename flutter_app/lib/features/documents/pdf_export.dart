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
      ...(document.formData?.map((k, v) => MapEntry(k.replaceAll(' ', '_'), v?.toString() ?? '')) ?? {}),
    };

    // Capture non-nullable local reference for use in closures
    final wf = workflow;

    // Build the letterhead widget for the header
    pw.Widget? letterheadWidget;
    final bool showLetterhead = wf == null || wf.includeLetterhead;
    if (showLetterhead) {
      final headerImageUrl = wf?.customHeaderUrl;
      final headerImage = headerImageUrl != null ? remoteImages[headerImageUrl] : null;
      if (headerImage != null) {
        letterheadWidget = pw.Container(
          height: 130, // constrain height to prevent large banner images from breaking layout
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
              pw.Text('SIMAT SMART CAMPUS', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.Text('VANIAMKULAM, PALAKKAD · Affiliated to APJ AKU', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text('Email: info@simat.edu · Phone: +91-466-2228900 · www.simat.edu', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
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
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 5),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    sealWidget,
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(wf.templateClosing.trim(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        studentSigImage != null
                            ? pw.Image(studentSigImage, height: 25, width: 50, fit: pw.BoxFit.contain)
                            : pw.SizedBox(height: 25),
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
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Authorized Signatures:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      children: document.approvals.asMap().entries.map((entry) {
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
                                  ? pw.Container(height: 25, width: 80, child: pw.Image(sig, fit: pw.BoxFit.contain))
                                  : pw.SizedBox(height: 25),
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

          return widgets;
        },
        footer: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 20, left: 40, right: 40),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Document ID: ${document.id}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey)),
                    pw.Text('Generated by docTransit', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text('docTransit SIMAT System', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey)),
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
