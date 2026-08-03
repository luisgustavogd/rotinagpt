import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/reports/weekly_summary.dart';

/// RF-082 — relatório semanal em PDF. Linguagem sempre descritiva (RF-073):
/// nunca inclui recomendação, diagnóstico ou conduta.
class PdfReportBuilder {
  const PdfReportBuilder();

  Future<Uint8List> buildWeeklyReport(WeeklySummary summary) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Resumo semanal',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Semana de ${_formatDate(summary.weekStart)}'),
              pw.SizedBox(height: 16),
              _row(
                'Proteína média diária',
                '${summary.averageProteinG.toStringAsFixed(1)} g',
              ),
              _row(
                'Variação de peso na semana',
                summary.weightVariationKg == null
                    ? 'Sem registros suficientes'
                    : '${summary.weightVariationKg!.toStringAsFixed(1)} kg',
              ),
              _row('Minutos de atividade', '${summary.activityMinutes} min'),
              _row('Atividades completas', '${summary.completedActivities}'),
              _row('Atividades parciais', '${summary.partialActivities}'),
              _row(
                'Dias com refeições confirmadas',
                '${summary.daysWithMealsConfirmed} de 7',
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'Este relatório é apenas informativo e não constitui diagnóstico, '
                'prescrição ou orientação médica/nutricional. Consulte sempre um '
                'profissional de saúde para interpretar esses dados.',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
