import 'package:flutter/material.dart';
import '../../core/services/cpu_calculator.dart';
import '../../l10n/app_localizations.dart';

class CpuScreen extends StatefulWidget {
  const CpuScreen({super.key});
  @override
  State<CpuScreen> createState() => _CpuScreenState();
}

class _CpuScreenState extends State<CpuScreen> {
  final _ca = TextEditingController();
  String _activity = 'services';

  @override
  void dispose() { _ca.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final rate = CpuCalculator.rateForActivity(_activity);
    final ca = double.tryParse(_ca.text.replaceAll(',', '.')) ?? 0;
    final amount = CpuCalculator.calculate(caEncaisse: ca, rate: rate);
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.cpu, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(initialValue: _activity, items: const [
          DropdownMenuItem(value: 'services', child: Text('Services — 10%')),
          DropdownMenuItem(value: 'artisanal', child: Text('Artisanal — 5%')),
          DropdownMenuItem(value: 'commercial', child: Text('Commercial — 3%')),
        ], onChanged: (v) => setState(() => _activity = v ?? 'services')),
        const SizedBox(height: 12),
        TextField(controller: _ca, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'CA encaissé', suffixText: 'MAD')),
        const SizedBox(height: 20),
        Card(child: ListTile(title: const Text('CPU estimée'), trailing: Text('${amount.toStringAsFixed(2)} MAD'))),
      ],
    );
  }
}
