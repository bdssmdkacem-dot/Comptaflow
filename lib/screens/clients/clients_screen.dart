import 'package:flutter/material.dart';

import '../../data/models/client.dart';
import '../../data/repositories/client_repo.dart';
import '../../l10n/app_localizations.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _repository = ClientRepository();
  late Future<List<ClientModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.list();
  }

  Future<void> _addClient() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final ice = TextEditingController();
    final phone = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouveau client'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nom / raison sociale'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nom requis'
                      : null,
                ),
                TextFormField(
                  controller: ice,
                  decoration: const InputDecoration(labelText: 'ICE (optionnel)'),
                ),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Téléphone (optionnel)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await _repository.create(
                  name: name.text.trim(),
                  ice: ice.text.trim().isEmpty ? null : ice.text.trim(),
                  phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } catch (error) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Erreur : $error')),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    name.dispose();
    ice.dispose();
    phone.dispose();

    if (created == true && mounted) {
      setState(() => _future = _repository.list());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.clients)),
      body: FutureBuilder<List<ClientModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Impossible de charger les clients.\n${snapshot.error}'),
              ),
            );
          }
          final clients = snapshot.data ?? const <ClientModel>[];
          if (clients.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun client.\nAjoutez votre premier client pour commencer à facturer.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _repository.list());
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: clients.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final client = clients[index];
                final details = [client.phone, client.ice]
                    .whereType<String>()
                    .where((value) => value.isNotEmpty)
                    .join(' • ');
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(client.name),
                    subtitle: details.isEmpty ? null : Text(details),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addClient,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Ajouter'),
      ),
    );
  }
}
