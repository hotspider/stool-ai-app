import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:app/l10n/app_localizations.dart';

import '../models/record.dart';

class PdfExportService {
  static Future<File> exportRecordToPdfFile(
    StoolRecord record,
    AppLocalizations l10n,
  ) async {
    final fontData = await rootBundle.load('assets/fonts/NotoSansSC-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final df = DateFormat('yyyy/MM/dd HH:mm');
    final created = df.format(record.createdAt);

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttf,
        ),
        build: (context) => [
          _title(l10n.pdfTitle),
          pw.SizedBox(height: 8),
          _metaRow(l10n.pdfRecordTimeLabel, created),

          pw.SizedBox(height: 16),
          _sectionTitle(l10n.pdfSummaryTitle),
          _card([
            _kv(l10n.pdfRiskLabel, _riskLabel(l10n, record.analysis.riskLevel.name)),
            pw.SizedBox(height: 6),
            pw.Text(record.analysis.summary, style: const pw.TextStyle(fontSize: 12)),
          ]),

          pw.SizedBox(height: 14),
          _sectionTitle(l10n.pdfKeyTraitsTitle),
          _card([
            _kv(
              l10n.pdfBristolLabel,
              record.analysis.bristolType?.toString() ?? l10n.colorUnknown,
            ),
            _kv(
              l10n.pdfColorLabel,
              _safeText(l10n, _colorLabel(l10n, record.analysis.color.name)),
            ),
            _kv(
              l10n.pdfTextureLabel,
              _safeText(l10n, _textureLabel(l10n, record.analysis.texture.name)),
            ),
          ]),

          pw.SizedBox(height: 14),
          _sectionTitle(l10n.pdfQualityTitle),
          _card([
            _kv(l10n.pdfQualityScoreLabel, '${record.analysis.qualityScore}/100'),
            pw.SizedBox(height: 6),
            if (record.analysis.qualityIssues.isEmpty)
              pw.Text(l10n.pdfQualityGood, style: const pw.TextStyle(fontSize: 12))
            else
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: record.analysis.qualityIssues
                    .map((e) => pw.Bullet(
                          text: _safeText(l10n, e),
                          style: const pw.TextStyle(fontSize: 12),
                        ))
                    .toList(),
              ),
          ]),

          pw.SizedBox(height: 14),
          _sectionTitle(l10n.pdfActionsTitle),
          _card([
            if (record.advice.next48hActions.isEmpty)
              pw.Text(l10n.pdfActionsEmpty, style: const pw.TextStyle(fontSize: 12))
            else
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: record.advice.next48hActions
                    .map((e) => pw.Bullet(
                          text: _safeText(l10n, e),
                          style: const pw.TextStyle(fontSize: 12),
                        ))
                    .toList(),
              ),
          ]),

          pw.SizedBox(height: 14),
          _sectionTitle(l10n.pdfSeekCareTitle),
          _card([
            if (record.advice.seekCareIf.isEmpty)
              pw.Text(l10n.pdfSeekCareEmpty, style: const pw.TextStyle(fontSize: 12))
            else
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: record.advice.seekCareIf
                    .map((e) => pw.Bullet(
                          text: _safeText(l10n, e),
                          style: const pw.TextStyle(fontSize: 12),
                        ))
                    .toList(),
              ),
          ]),

          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.Text(
            _disclaimerText(l10n, record),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    return _writeTempPdf(bytes, record.id);
  }

  static Future<File> _writeTempPdf(Uint8List bytes, String id) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/stool_record_$id.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static pw.Widget _title(String text) => pw.Text(
        text,
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      );

  static pw.Widget _sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      );

  static pw.Widget _metaRow(String k, String v) => pw.Row(
        children: [
          pw.Text('$k：', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.Expanded(child: pw.Text(v, style: const pw.TextStyle(fontSize: 11))),
        ],
      );

  static pw.Widget _card(List<pw.Widget> children) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: children),
      );

  static pw.Widget _kv(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 86,
              child: pw.Text(k, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
            ),
            pw.Expanded(child: pw.Text(v, style: const pw.TextStyle(fontSize: 12))),
          ],
        ),
      );

  static String _disclaimerText(AppLocalizations l10n, StoolRecord record) {
    final disclaimers = record.advice.disclaimers;
    if (disclaimers.isNotEmpty) {
      return '${l10n.detailDisclaimerLabel}${disclaimers.join('、')}';
    }
    return '${l10n.detailDisclaimerLabel}${l10n.pdfDisclaimerDefault}';
  }

  static String _riskLabel(AppLocalizations l10n, String risk) {
    switch (risk) {
      case 'high':
        return l10n.pdfRiskHigh;
      case 'medium':
        return l10n.pdfRiskMedium;
      case 'low':
      default:
        return l10n.pdfRiskLow;
    }
  }

  static String _safeText(AppLocalizations l10n, String? s) =>
      (s == null || s.trim().isEmpty) ? l10n.detailEmptyValue : s.trim();

  // 下面两个 label 如你项目已有同名函数，可直接复用/删除这份
  static String _colorLabel(AppLocalizations l10n, String v) {
    switch (v) {
      case 'brown':
        return l10n.colorBrown;
      case 'yellow':
        return l10n.colorYellow;
      case 'green':
        return l10n.colorGreen;
      case 'black':
        return l10n.colorBlack;
      case 'red':
        return l10n.colorRed;
      case 'pale':
        return l10n.colorPale;
      case 'mixed':
        return l10n.colorMixed;
      default:
        return l10n.colorUnknown;
    }
  }

  static String _textureLabel(AppLocalizations l10n, String v) {
    switch (v) {
      case 'watery':
        return l10n.textureWatery;
      case 'mushy':
        return l10n.textureMushy;
      case 'normal':
        return l10n.textureNormal;
      case 'hard':
        return l10n.textureHard;
      case 'oily':
        return l10n.textureOily;
      case 'foamy':
        return l10n.textureFoamy;
      default:
        return l10n.textureUnknown;
    }
  }
}