import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/emotion_entry.dart';
import '../../data/models/trade_model.dart';
import '../providers/journal_provider.dart';

/// Final step of the trade flow: capture full trade journal details
/// (symbol, entry/exit, SL/target, quantity, strategy, screenshot,
/// mistakes, lessons) and persist via [JournalProvider].
class AddTradeScreen extends StatefulWidget {
  final String emotion;
  final bool checklistCompleted;
  final EmotionEntry? emotionEntry;

  const AddTradeScreen({
    super.key,
    required this.emotion,
    required this.checklistCompleted,
    this.emotionEntry,
  });

  @override
  State<AddTradeScreen> createState() => _AddTradeScreenState();
}

class _AddTradeScreenState extends State<AddTradeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _symbolCtrl = TextEditingController();
  final _entryCtrl = TextEditingController();
  final _slCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _strategyCtrl = TextEditingController();
  final _mistakesCtrl = TextEditingController();
  final _lessonsCtrl = TextEditingController();

  String? _screenshotPath;
  bool _saving = false;

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _entryCtrl.dispose();
    _slCtrl.dispose();
    _targetCtrl.dispose();
    _qtyCtrl.dispose();
    _strategyCtrl.dispose();
    _mistakesCtrl.dispose();
    _lessonsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _screenshotPath = file.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final journal = context.read<JournalProvider>();

    if (widget.emotionEntry != null) {
      await journal.recordEmotionEntry(widget.emotionEntry!);
    } else {
      await journal.recordEmotionEntry(EmotionEntry(emotion: widget.emotion));
    }

    final trade = TradeModel(
      symbol: _symbolCtrl.text.trim().toUpperCase(),
      entryPrice: double.parse(_entryCtrl.text),
      stopLoss: double.parse(_slCtrl.text),
      target: double.parse(_targetCtrl.text),
      quantity: int.parse(_qtyCtrl.text),
      strategy: _strategyCtrl.text.trim(),
      screenshotPath: _screenshotPath,
      emotionBeforeTrade: widget.emotion,
      mistakesMade: _mistakesCtrl.text.trim().isEmpty ? null : _mistakesCtrl.text.trim(),
      lessonsLearned: _lessonsCtrl.text.trim().isEmpty ? null : _lessonsCtrl.text.trim(),
      checklistCompleted: widget.checklistCompleted,
    );

    await journal.addTrade(trade, checklistCompleted: widget.checklistCompleted);

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Trade')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(_symbolCtrl, 'Stock / Symbol (e.g. RELIANCE)', required: true),
            _numField(_entryCtrl, 'Entry Price'),
            _numField(_slCtrl, 'Stop Loss'),
            _numField(_targetCtrl, 'Target'),
            _numField(_qtyCtrl, 'Quantity', isInt: true),
            _field(_strategyCtrl, 'Strategy Used (e.g. VWAP Reclaim)', required: true),
            const SizedBox(height: 8),
            _screenshotPicker(),
            const SizedBox(height: 8),
            _field(_mistakesCtrl, 'Mistakes Made (optional)', required: false, maxLines: 2),
            _field(_lessonsCtrl, 'Lessons Learned (optional)', required: false, maxLines: 2),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Trade to Journal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {required bool required, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String label, {bool isInt = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
        decoration: InputDecoration(labelText: label),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          final parsed = isInt ? int.tryParse(v) : double.tryParse(v);
          if (parsed == null) return 'Enter a valid number';
          return null;
        },
      ),
    );
  }

  Widget _screenshotPicker() {
    return InkWell(
      onTap: _pickScreenshot,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: _screenshotPath == null
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary),
                    SizedBox(height: 6),
                    Text('Attach chart screenshot',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(File(_screenshotPath!), fit: BoxFit.cover, width: double.infinity),
              ),
      ),
    );
  }
}
