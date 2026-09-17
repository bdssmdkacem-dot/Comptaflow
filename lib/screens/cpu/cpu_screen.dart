import 'package:flutter/material.dart';

import '../../core/services/cpu_calculator.dart';
import '../../data/models/cpu_declaration.dart';
import '../../data/repositories/cpu_declaration_repo.dart';
import '../../l10n/app_localizations.dart';

class CpuScreen extends StatefulWidget {
  const CpuScreen({super.key});

  @override
  State<CpuScreen> createState() => _CpuScreenState();
}

class _CpuScreenState extends State<CpuScreen> {
  final _ca = TextEditingController();
  final _repository = CpuDeclarationRepository();
  String _activity = 'services';
  DateTime _period = DateTime(DateTime.now().year, DateTime.now().month, 1);
  Future<List<CpuDeclaration>>? _future;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _repository.list();
  }

  @override
  void dispose() {
    _ca.dispose();
    super.dispose();
  }

  double get _rate => CpuCalculator.rateForActivity(_activity);

  double get _caValue => double.tryParse(_ca.text.replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    final ca = _caValue;
    if (ca < 0) return;
    setState(() => _saving = true);
    try {
      await _repository.save(
        period: _period,
        caEncaisse: ca,
        cpuRate: _rate,
      );
      if (!mounted) return;
      setState(() => _future = _repository.list());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Déclaration enregistrée')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _markDeclared(CpuDeclaration declaration) async {
    try {
      await _repository.markDeclared(declaration.id);
      if (mounted) setState(() => _future = _repository.list());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $error')),
      );
    }
  }

  Future<void> _delete(CpuDeclaration declaration) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la déclaration ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.delete(declaration.id);
      if (mounted) setState(() => _future = _repository.list());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $error')));
    }
  }

  Future<void> _pickPeriod() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _period,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Choisir le mois',
    );
    if (picked != null && mounted) {
      setState(() => _period = DateTime(picked.year, picked.month, 1));
    }
  }

  String _monthLabel(DateTime value) => '${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final amount = CpuCalculator.calculate(caEncaisse: _caValue, rate: _rate);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.cpu, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('Calculez, enregistrez et suivez vos déclarations CPU par période.'),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _activity,
          decoration: const InputDecoration(labelText: 'Activité'),
          items: const [
            DropdownMenuItem(value: 'services', child: Text('Services — 10%')),
            DropdownMenuItem(value: 'artisanal', child: Text('Artisanal — 5%')),
            DropdownMenuItem(value: 'commercial', child: Text('Commercial — 3%')),
          ],
          onChanged: (v) => setState(() => _activity = v ?? 'services'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ca,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'CA encaissé', suffixText: 'MAD'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickPeriod,
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text('Période : ${_monthLabel(_period)}'),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            title: const Text('CPU estimée'),
            subtitle: Text('Taux ${(100 * _rate).toStringAsFixed(0)}%'),
            trailing: Text('${amount.toStringAsFixed(2)} MAD', style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
          label: const Text('Enregistrer la déclaration'),
        ),
        const SizedBox(height: 28),
        Text('Historique', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        FutureBuilder<List<CpuDeclaration>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Card(child: ListTile(title: const Text('Impossible de charger l’historique'), subtitle: Text('${snapshot.error}')));
            }
            final items = snapshot.data ?? const <CpuDeclaration>[];
            if (items.isEmpty) return const Card(child: ListTile(title: Text('Aucune déclaration enregistrée')));
            return Column(
              children: items.map((item) => Card(
                child: ListTile(
                  title: Text(_monthLabel(item.period)),
                  subtitle: Text('CA ${item.caEncaisse.toStringAsFixed(2)} MAD • ${(item.cpuRate * 100).toStringAsFixed(0)}%'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'declare') _markDeclared(item);
                      if (action == 'delete') _delete(item);
                    },
                    itemBuilder: (_) => [
                      if (!item.isDeclared) const PopupMenuItem(value: 'declare', child: Text('Marquer déclarée')),
                      const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                    ],
                  ),
                  leading: CircleAvatar(child: Icon(item.isDeclared ? Icons.check : Icons.pending_outlined)),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}
