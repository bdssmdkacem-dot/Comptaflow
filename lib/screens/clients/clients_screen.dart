import 'package:flutter/material.dart';
import '../../data/models/client.dart';
import '../../data/repositories/client_repo.dart';
import '../../l10n/app_localizations.dart';
import 'client_detail_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});
  @override State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final repo = ClientRepository();
  final search = TextEditingController();
  late Future<List<ClientModel>> future;

  @override
  void initState() {
    super.initState();
    future = repo.list();
    search.addListener(reload);
  }

  void reload() => setState(() => future = repo.list(query: search.text));

  @override
  void dispose() {
    search.removeListener(reload);
    search.dispose();
    super.dispose();
  }

  Future<void> edit([ClientModel? client]) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ClientDialog(client: client, repo: repo),
    );
    if (ok == true && mounted) reload();
  }

  Future<void> detail(ClientModel client) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client)),
    );
    if (mounted) reload();
  }

  Future<void> remove(ClientModel client) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteClientTitle),
        content: Text(
          'Supprimer « ${client.name} » ? Les clients liés à des factures ne peuvent pas être supprimés.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context).cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context).delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await repo.delete(client.id);
      if (mounted) reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.clients)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: search,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).clientsSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(onPressed: search.clear, icon: const Icon(Icons.clear_rounded)),
                filled: true,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ClientModel>>(
              future: future,
              builder: (context, s) {
                if (s.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (s.hasError) {
                  return _StateMessage(
                    icon: Icons.cloud_off_rounded,
                    title: 'Impossible de charger les clients',
                    subtitle: '${s.error}',
                  );
                }
                final list = s.data ?? const <ClientModel>[];
                if (list.isEmpty) {
                  return _StateMessage(
                    icon: search.text.isEmpty ? Icons.people_outline_rounded : Icons.search_off_rounded,
                    title: search.text.isEmpty ? AppLocalizations.of(context).noClients : AppLocalizations.of(context).noClientsFound,
                    subtitle: search.text.isEmpty ? AppLocalizations.of(context).addFirstClient : AppLocalizations.of(context).tryAnotherSearch,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    reload();
                    await future;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final c = list[i];
                      final ids = [
                        if (c.ice != null) 'ICE ${c.ice}',
                        if (c.ifNumber != null) 'IF ${c.ifNumber}',
                        if (c.rcNumber != null) 'RC ${c.rcNumber}',
                      ].join(' • ');
                      final contact = [c.phone, c.email, c.city]
                          .whereType<String>()
                          .where((x) => x.isNotEmpty)
                          .join(' • ');
                      final subtitle = [ids, contact].where((x) => x.isNotEmpty).join('\n');
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor: theme.colorScheme.onPrimaryContainer,
                            child: const Icon(Icons.business_rounded),
                          ),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: subtitle.isEmpty ? null : Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                          onTap: () => detail(c),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) => v == 'edit' ? edit(c) : remove(c),
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => edit(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(AppLocalizations.of(context).add),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ),
  );
}

class ClientDialog extends StatefulWidget {
  const ClientDialog({super.key, this.client, required this.repo});
  final ClientModel? client;
  final ClientRepository repo;
  @override State<ClientDialog> createState() => _ClientDialogState();
}

class _ClientDialogState extends State<ClientDialog> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, ice, ifNumber, rc, tp, phone, email, address, city;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    name = TextEditingController(text: c?.name);
    ice = TextEditingController(text: c?.ice);
    ifNumber = TextEditingController(text: c?.ifNumber);
    rc = TextEditingController(text: c?.rcNumber);
    tp = TextEditingController(text: c?.tpNumber);
    phone = TextEditingController(text: c?.phone);
    email = TextEditingController(text: c?.email);
    address = TextEditingController(text: c?.address);
    city = TextEditingController(text: c?.city);
  }

  @override
  void dispose() {
    for (final c in [name, ice, ifNumber, rc, tp, phone, email, address, city]) c.dispose();
    super.dispose();
  }

  String? requiredName(String? v) => v == null || v.trim().isEmpty ? AppLocalizations.of(context).requiredField : null;
  String? validEmail(String? v) => v == null || v.trim().isEmpty || v.contains('@') ? null : 'Email invalide';
  String? val(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      if (widget.client == null) {
        await widget.repo.create(name: name.text.trim(), ice: val(ice), ifNumber: val(ifNumber), rcNumber: val(rc), tpNumber: val(tp), phone: val(phone), email: val(email), address: val(address), city: val(city));
      } else {
        await widget.repo.update(id: widget.client!.id, name: name.text.trim(), ice: val(ice), ifNumber: val(ifNumber), rcNumber: val(rc), tpNumber: val(tp), phone: val(phone), email: val(email), address: val(address), city: val(city));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.client == null ? AppLocalizations.of(context).newClient : AppLocalizations.of(context).editClient),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            field(name, AppLocalizations.of(context).nameOrCompany, requiredName),
            Row(children: [Expanded(child: field(ice, 'ICE')), const SizedBox(width: 8), Expanded(child: field(ifNumber, 'IF'))]),
            Row(children: [Expanded(child: field(rc, 'RC')), const SizedBox(width: 8), Expanded(child: field(tp, 'TP'))]),
            Row(children: [Expanded(child: field(phone, 'Téléphone')), const SizedBox(width: 8), Expanded(child: field(email, 'Email', validEmail))]),
            Row(children: [Expanded(child: field(city, 'Ville')), const SizedBox(width: 8), Expanded(child: field(address, 'Adresse'))]),
          ]),
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: Text(AppLocalizations.of(context).cancel)),
      FilledButton(onPressed: saving ? null : save, child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(AppLocalizations.of(context).save)),
    ],
  );

  Widget field(TextEditingController c, String label, [String? Function(String?)? validator]) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(controller: c, validator: validator, decoration: InputDecoration(labelText: label)),
  );
}
