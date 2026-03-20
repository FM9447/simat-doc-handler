import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../models/document_model.dart';

class PdfExportHelper {
  static Future<void> generateAndPrintDocument(DocumentModel document) async {
    final pdf = pw.Document();

    // Fetch signatures beforehand to avoid async issues in build
    final List<pw.ImageProvider?> signatureImages = [];
    for (var approval in document.approvals) {
      if (approval.signatureUrl != null && approval.signatureUrl!.isNotEmpty) {
        try {
          final image = await networkImage(approval.signatureUrl!);
          signatureImages.add(image);
        } catch (e) {
          signatureImages.add(null);
        }
      } else {
        signatureImages.add(null);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // College Header (Placeholder - can be customized)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('SIMAT SMART CAMPUS',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text('DIGITAL DOCUMENT HANDLER',
                    style: const pw.TextStyle(fontSize: 12)),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 10),
              ],
            ),

            // Document Title
            pw.Center(
              child: pw.Text(document.category.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline)),
            ),
            pw.SizedBox(height: 20),

            // Student Info Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Student Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(document.studentId is Map
                          ? document.studentId['name']
                          : 'Student ID: ${document.studentId}')),
                ]),
                if (document.studentId is Map)
                  pw.TableRow(children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Register No',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(document.studentId['registerNo'] ?? 'N/A')),
                  ]),
              ],
            ),
            pw.SizedBox(height: 20),

            // Main Content
            if (document.formData != null && document.formData!.isNotEmpty) ...[
              pw.Text('Request Content:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey200)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: document.formData!.entries.map((e) {
                    return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 5),
                        child: pw.RichText(
                            text: pw.TextSpan(children: [
                          pw.TextSpan(
                              text: '${e.key}: ',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.TextSpan(text: e.value),
                        ])));
                  }).toList(),
                ),
              ),
            ] else ...[
              pw.Text('Description / Purpose:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Paragraph(
                  text: document.description, style: const pw.TextStyle(fontSize: 12)),
            ],

            pw.SizedBox(height: 40),

            // Approval Signatures Grid
            pw.Text('Approvals & Signatures:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Wrap(
              spacing: 20,
              runSpacing: 20,
              children: document.approvals.asMap().entries.map((entry) {
                final idx = entry.key;
                final approval = entry.value;
                final signature = signatureImages[idx];
                final role = idx < document.workflow.length ? document.workflow[idx] : 'approver';

                return pw.Container(
                  width: 150,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey100)),
                  child: pw.Column(
                    children: [
                      if (signature != null)
                        pw.Image(signature, height: 40)
                      else
                        pw.Container(
                            height: 40,
                            child: pw.Center(
                                child: pw.Text('No Sig',
                                    style: const pw.TextStyle(
                                        fontSize: 8, color: PdfColors.grey)))),
                      pw.Divider(thickness: 0.5),
                      pw.Text(role.toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(approval.createdAt?.toString().substring(0, 10) ?? '',
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                );
              }).toList(),
            ),

            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by AntiGravity SIMAT',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                pw.Text('Verified Digital Document',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Request_${document.category}_${document.id}.pdf');
  }
}
