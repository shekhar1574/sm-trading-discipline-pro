import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/trade_model.dart';

/// Report scope, matching the "Report" menu pattern (All Trades, Month
/// Wise, Profitable, Losing, Strategy Overview).
enum ReportScope { all, monthWise, profitable, losing, strategyOverview }

/// Generates Excel (.xlsx) and PDF trade reports from the journal, and
/// shares them via the platform share sheet so the user can save to
/// Drive, email, WhatsApp, etc.
class ReportExportService {
  List<TradeModel> _filterForScope(List<TradeModel> trades, ReportScope scope) {
    switch (scope) {
      case ReportScope.profitable:
        return trades.where((t) => t.isClosed && t.isWin).toList();
      case ReportScope.losing:
        return trades.where((t) => t.isClosed && !t.isWin).toList();
      case ReportScope.all:
      case ReportScope.monthWise:
      case ReportScope.strategyOverview:
        return trades;
    }
  }

  String _scopeLabel(ReportScope scope) {
    switch (scope) {
      case ReportScope.all:
        return 'All Trades';
      case ReportScope.monthWise:
        return 'Month Wise Trades';
      case ReportScope.profitable:
        return 'Profitable Trades';
      case ReportScope.losing:
        return 'Losing Trades';
      case ReportScope.strategyOverview:
        return 'Strategy Overview';
    }
  }

  Future<File> exportToExcel(List<TradeModel> trades, ReportScope scope) async {
    final filtered = _filterForScope(trades, scope);
    final workbook = xl.Excel.createExcel();
    final sheet = workbook[workbook.getDefaultSheet()!];

    const headers = [
      'Date', 'Symbol', 'Segment', 'Strategy', 'Entry', 'Exit', 'Stop Loss',
      'Target', 'Qty', 'P&L', 'R:R', 'Emotion', 'Checklist OK', 'Mistakes', 'Lessons',
    ];
    sheet.appendRow(headers.map((h) => xl.TextCellValue(h)).toList());

    if (scope == ReportScope.strategyOverview) {
      final byStrategy = <String, List<TradeModel>>{};
      for (final t in filtered) {
        byStrategy.putIfAbsent(t.strategy, () => []).add(t);
      }
      sheet.appendRow([
        xl.TextCellValue('Strategy'), xl.TextCellValue('Trades'),
        xl.TextCellValue('Wins'), xl.TextCellValue('Win Rate %'), xl.TextCellValue('Net P&L'),
      ]);
      byStrategy.forEach((strategy, list) {
        final closed = list.where((t) => t.isClosed).toList();
        final wins = closed.where((t) => t.isWin).length;
        final winRate = closed.isEmpty ? 0.0 : (wins / closed.length) * 100;
        final netPnl = closed.fold<double>(0, (s, t) => s + (t.pnl ?? 0));
        sheet.appendRow([
          xl.TextCellValue(strategy),
          xl.IntCellValue(list.length),
          xl.IntCellValue(wins),
          xl.DoubleCellValue(winRate),
          xl.DoubleCellValue(netPnl),
        ]);
      });
    } else {
      for (final t in filtered) {
        sheet.appendRow([
          xl.TextCellValue('${t.createdAt.year}-${t.createdAt.month.toString().padLeft(2, '0')}-${t.createdAt.day.toString().padLeft(2, '0')}'),
          xl.TextCellValue(t.symbol),
          xl.TextCellValue(t.segment),
          xl.TextCellValue(t.strategy),
          xl.DoubleCellValue(t.entryPrice),
          t.exitPrice == null ? xl.TextCellValue('OPEN') : xl.DoubleCellValue(t.exitPrice!),
          xl.DoubleCellValue(t.stopLoss),
          xl.DoubleCellValue(t.target),
          xl.IntCellValue(t.quantity),
          t.pnl == null ? xl.TextCellValue('-') : xl.DoubleCellValue(t.pnl!),
          xl.DoubleCellValue(t.riskRewardRatio),
          xl.TextCellValue(t.emotionBeforeTrade),
          xl.TextCellValue(t.checklistCompleted ? 'Yes' : 'No'),
          xl.TextCellValue(t.mistakesMade ?? ''),
          xl.TextCellValue(t.lessonsLearned ?? ''),
        ]);
      }
    }

    final bytes = workbook.encode()!;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sm_trading_report_${scope.name}.xlsx');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<File> exportToPdf(List<TradeModel> trades, ReportScope scope) async {
    final filtered = _filterForScope(trades, scope);
    final doc = pw.Document();
    final closed = filtered.where((t) => t.isClosed).toList();
    final wins = closed.where((t) => t.isWin).length;
    final winRate = closed.isEmpty ? 0.0 : (wins / closed.length) * 100;
    final netPnl = closed.fold<double>(0, (s, t) => s + (t.pnl ?? 0));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('SM Trading Discipline Pro')),
          pw.Text(_scopeLabel(scope), style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Trades: ${filtered.length}'),
              pw.Text('Win Rate: ${winRate.toStringAsFixed(1)}%'),
              pw.Text('Net P&L: ₹${netPnl.toStringAsFixed(0)}'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['Date', 'Symbol', 'Strategy', 'Entry', 'Exit', 'Qty', 'P&L', 'Emotion'],
            data: filtered
                .map((t) => [
                      '${t.createdAt.year}-${t.createdAt.month.toString().padLeft(2, '0')}-${t.createdAt.day.toString().padLeft(2, '0')}',
                      t.symbol,
                      t.strategy,
                      t.entryPrice.toStringAsFixed(2),
                      t.exitPrice?.toStringAsFixed(2) ?? 'OPEN',
                      '${t.quantity}',
                      t.pnl == null ? '-' : t.pnl!.toStringAsFixed(0),
                      t.emotionBeforeTrade,
                    ])
                .toList(),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sm_trading_report_${scope.name}.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  Future<void> shareFile(File file, String label) async {
    await Share.shareXFiles([XFile(file.path)], text: label);
  }
}
