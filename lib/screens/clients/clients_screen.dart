import 'package:flutter/material.dart';
import '../../data/models/client.dart';
import '../../data/repositories/client_repo.dart';
import '../../l10n/app_localizations.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});
  @override State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final repo = ClientRepository();
  final search = TextEditingController();
  late Future<List<ClientModel>> future;

  @override void initState() { super.initState(); future = repo.list(); search.addListener(reload); }
  void reload() => setState(() => future = repo.list(query: search.text));
  @override void dispose() { search.removeListener(reload); search.dispose(); super.dispose(); }

  Future<void> edit([ClientModel? client]) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => ClientDialog(client: client, repo: repo));
    if (ok == true && mounted) reload();
  }

  Future<void> remove(ClientModel client) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Supprimer le client ?'),
      content: Text('Supprimer « ${client.name} » ?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer'))],
    ));
    if (ok != true) return;
    try { await repo.delete(client.id); if (mounted) reload(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e'))); }
  }

  @override Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.clients)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: TextField(controller: search, decoration: InputDecoration(labelText: 'Rechercher un client', prefixIcon: const Icon(Icons.search), suffixIcon: search.text.isEmpty ? null : IconButton(onPressed: search.clear, icon: const Icon(Icons.clear)), border: const OutlineInputBorder()))),
        Expanded(child: FutureBuilder<List<ClientModel>>(future: future, builder: (context, s) {
          if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (s.hasError) return Center(child: Text('Impossible de charger les clients.\n${s.error}'));
          final list = s.data ?? const <ClientModel>[];
          if (list.isEmpty) return Center(child: Text(search.text.isEmpty ? 'Aucun client.\nAjoutez votre premier client.' : 'Aucun client trouvé.', textAlign: TextAlign.center));
          return RefreshIndicator(onRefresh: () async { reload(); await future; }, child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: list.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) {
            final c = list[i];
            final ids = [if (c.ice != null) 'ICE ${c.ice}', if (c.ifNumber != null) 'IF ${c.ifNumber}', if (c.rcNumber != null) 'RC ${c.rcNumber}'].join(' • ');
            final contact = [c.phone, c.email, c.city].whereType<String>().where((x) => x.isNotEmpty).join(' • ');
            return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.business_outlined)), title: Text(c.name), subtitle: Text([ids, contact].where((x) => x.isNotEmpty).join('\n')), onTap: () => edit(c), trailing: PopupMenuButton<String>(onSelected: (v) => v == 'edit' ? edit(c) : remove(c), itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Modifier')), PopupMenuItem(value: 'delete', child: Text('Supprimer'))])));
          }));
        }))
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => edit(), icon: const Icon(Icons.person_add_alt_1), label: const Text('Ajouter')),
    );
  }
}

class ClientDialog extends StatefulWidget {
  const ClientDialog({super.key, this.client, required this.repo});
  final ClientModel? client; final ClientRepository repo;
  @override State<ClientDialog> createState() => _ClientDialogState();
}

class _ClientDialogState extends State<ClientDialog> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, ice, ifNumber, rc, tp, phone, email, address, city;
  bool saving = false;
  @override void initState() { super.initState(); final c = widget.client; name=TextEditingController(text:c?.name); ice=TextEditingController(text:c?.ice); ifNumber=TextEditingController(text:c?.ifNumber); rc=TextEditingController(text:c?.rcNumber); tp=TextEditingController(text:c?.tpNumber); phone=TextEditingController(text:c?.phone); email=TextEditingController(text:c?.email); address=TextEditingController(text:c?.address); city=TextEditingController(text:c?.city); }
  @override void dispose() { for (final c in [name,ice,ifNumber,rc,tp,phone,email,address,city]) c.dispose(); super.dispose(); }
  String? requiredName(String? v) => v == null || v.trim().isEmpty ? 'Nom requis' : null;
  String? validEmail(String? v) => v == null || v.trim().isEmpty || v.contains('@') ? null : 'Email invalide';
  String? val(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
  Future<void> save() async {
    if (!form.currentState!.validate()) return; setState(() => saving=true);
    try {
      if (widget.client == null) { await widget.repo.create(name:name.text.trim(), ice:val(ice), ifNumber:val(ifNumber), rcNumber:val(rc), tpNumber:val(tp), phone:val(phone), email:val(email), address:val(address), city:val(city)); }
      else { await widget.repo.update(id:widget.client!.id, name:name.text.trim(), ice:val(ice), ifNumber:val(ifNumber), rcNumber:val(rc), tpNumber:val(tp), phone:val(phone), email:val(email), address:val(address), city:val(city)); }
      if (mounted) Navigator.pop(context, true);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e'))); } finally { if (mounted) setState(() => saving=false); }
  }
  @override Widget build(BuildContext context) => AlertDialog(title: Text(widget.client == null ? 'Nouveau client' : 'Modifier le client'), content: SizedBox(width:520, child: SingleChildScrollView(child: Form(key:form, child: Column(mainAxisSize:MainAxisSize.min, children:[field(name,'Nom / raison sociale',requiredName), Row(children:[Expanded(child:field(ice,'ICE')),const SizedBox(width:8),Expanded(child:field(ifNumber,'IF'))]), Row(children:[Expanded(child:field(rc,'RC')),const SizedBox(width:8),Expanded(child:field(tp,'TP'))]), Row(children:[Expanded(child:field(phone,'Téléphone')),const SizedBox(width:8),Expanded(child:field(email,'Email',validEmail))]), Row(children:[Expanded(child:field(city,'Ville')),const SizedBox(width:8),Expanded(child:field(address,'Adresse'))])])))), actions:[TextButton(onPressed:saving?null:()=>Navigator.pop(context),child:const Text('Annuler')),FilledButton(onPressed:saving?null:save,child:saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Text('Enregistrer'))]);
  Widget field(TextEditingController c,String label,[String? Function(String?)? validator]) => Padding(padding:const EdgeInsets.only(bottom:10),child:TextFormField(controller:c,validator:validator,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
}
