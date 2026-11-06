import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';
import '../../data/export_service.dart';
import '../../data/tx_store.dart';

/// Pop-up with the export choices: a PDF report for one month, or a CSV file.
Future<void> showExportSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      side: BorderSide(color: AppColors.black, width: kBorder),
    ),
    builder: (_) => const _ExportSheet(),
  );
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet();

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  late DateTime _month;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _shift(int delta) {
    if (delta > 0 && _isCurrentMonth) return;
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Future<void> _run(Future<void> Function() job) async {
    if (TxStore.instance.items.isEmpty) {
      setState(() => _message = 'Add some transactions first.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await job();
    } catch (e) {
      debugPrint('Export error: $e');
      _message = 'Could not create the file. Please try again.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('EXPORT', style: uStyle(14)),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const BrutalTag(
                    'CLOSE',
                    color: AppColors.black,
                    textColor: AppColors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('PDF REPORT', style: uStyle(11)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _shift(-1),
                  child: const BrutalTag('<', color: AppColors.cyan),
                ),
                Text(
                  '${_months[_month.month - 1]} ${_month.year}',
                  style: mStyle(13, weight: FontWeight.w700),
                ),
                Opacity(
                  opacity: _isCurrentMonth ? 0.3 : 1,
                  child: GestureDetector(
                    onTap: () => _shift(1),
                    child: const BrutalTag('>', color: AppColors.cyan),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BrutalButton(
              label: _busy ? 'Please wait...' : 'Share PDF report',
              color: AppColors.cyan,
              onPressed: _busy
                  ? null
                  : () => _run(
                      () => ExportService.sharePdf(
                        TxStore.instance.items,
                        _month,
                      ),
                    ),
            ),
            const SizedBox(height: 28),
            Text('SPREADSHEET', style: uStyle(11)),
            const SizedBox(height: 6),
            Text(
              'Every transaction, ready for Excel or Google Sheets.',
              style: mStyle(10, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            BrutalButton(
              label: _busy ? 'Please wait...' : 'Share CSV file',
              color: AppColors.green,
              onPressed: _busy
                  ? null
                  : () => _run(
                      () => ExportService.shareCsv(TxStore.instance.items),
                    ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                style: mStyle(
                  11,
                  weight: FontWeight.w700,
                  color: AppColors.expense,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
