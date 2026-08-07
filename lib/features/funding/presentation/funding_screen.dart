import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/funding_service.dart';

class FundingScreen extends StatefulWidget {
  const FundingScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<FundingScreen> createState() => _FundingScreenState();
}

class _FundingScreenState extends State<FundingScreen> {
  Map<String, dynamic>? _campaign;
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  bool get _isOwner {
    final current = Supabase.instance.client.auth.currentUser?.id;
    return current != null && current == _campaign?['creator_id']?.toString();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final campaign = await FundingService.getCampaign(widget.projectId);
      final stats = campaign == null ? null : await FundingService.getPublicStats(widget.projectId);
      if (!mounted) return;
      setState(() {
        _campaign = campaign;
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger le financement.';
      });
    }
  }

  double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  String _money(double amount, String currency) => '${amount.toStringAsFixed(2)} $currency';

  Future<void> _createCampaign() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _CampaignDialog(),
    );
    if (result == null) return;

    try {
      await FundingService.createCampaign(
        projectId: widget.projectId,
        goalAmount: result['goal'] as double,
        currency: result['currency'] as String,
        description: result['description'] as String?,
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Création impossible : $error')));
    }
  }

  Future<void> _contribute() async {
    final campaign = _campaign;
    if (campaign == null) return;
    final result = await showDialog<double>(
      context: context,
      builder: (context) => _ContributionDialog(currency: campaign['currency']?.toString() ?? 'USD'),
    );
    if (result == null) return;

    try {
      await FundingService.createPendingContribution(
        campaignId: campaign['id'].toString(),
        amount: result,
        currency: campaign['currency']?.toString() ?? 'USD',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contribution créée. Le paiement sera finalisé avec le fournisseur de paiement.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contribution impossible : $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financement')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            if (_loading) const Padding(padding: EdgeInsets.symmetric(vertical: 100), child: Center(child: CircularProgressIndicator()))
            else if (_error != null) _Error(message: _error!, onRetry: _load)
            else if (_campaign == null) _NoCampaign(onCreate: _createCampaign)
            else _buildCampaign(),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaign() {
    final campaign = _campaign!;
    final stats = _stats;
    final currency = campaign['currency']?.toString() ?? 'USD';
    final goal = _number(stats?['goal_amount'] ?? campaign['goal_amount']);
    final collected = _number(stats?['collected_amount']);
    final remaining = _number(stats?['remaining_amount'] ?? (goal - collected));
    final progress = (_number(stats?['progress_percent']) / 100).clamp(0.0, 1.0);
    final contributors = (stats?['contributor_count'] as num?)?.toInt() ?? 0;
    final status = campaign['status']?.toString() ?? 'draft';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('Objectif', style: TextStyle(fontWeight: FontWeight.w700))),
              Chip(label: Text(status.toUpperCase())),
            ]),
            const SizedBox(height: 8),
            Text(_money(goal, currency), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(minHeight: 12, value: progress)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text('${(progress * 100).toStringAsFixed(1)} % atteint')),
              Text(_money(collected, currency), style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            Text('Reste ${_money(remaining, currency)} · $contributors contributeur${contributors == 1 ? '' : 's'}'),
          ]),
        ),
      ),
      if (campaign['description']?.toString().trim().isNotEmpty == true) ...[
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Text(campaign['description'].toString()))),
      ],
      const SizedBox(height: 18),
      if (!_isOwner && status == 'active')
        FilledButton.icon(onPressed: _contribute, icon: const Icon(Icons.volunteer_activism_rounded), label: const Text('Contribuer')),
      if (_isOwner) ...[
        OutlinedButton.icon(onPressed: _showOwnerStatus, icon: const Icon(Icons.tune_rounded), label: const Text('Gérer la campagne')),
      ],
      if (status != 'active' && !_isOwner)
        const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Cette campagne n’accepte pas actuellement de contributions.'))),
      const SizedBox(height: 12),
      const Text('Sécurité', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      const Text('Les statistiques publiques sont agrégées. Les contributions individuelles ne sont jamais affichées ici.'),
    ]);
  }

  Future<void> _showOwnerStatus() async {
    final status = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('État de la campagne'),
        children: ['draft', 'active', 'paused', 'completed', 'cancelled']
            .map((value) => SimpleDialogOption(onPressed: () => Navigator.pop(context, value), child: Text(value)))
            .toList(),
      ),
    );
    if (status == null) return;
    try {
      await FundingService.updateCampaign(campaignId: _campaign!['id'].toString(), status: status);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mise à jour impossible : $error')));
    }
  }
}

class _NoCampaign extends StatelessWidget {
  const _NoCampaign({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 90),
        child: Column(children: [
          Icon(Icons.savings_outlined, size: 62, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 18),
          Text('Pas encore de campagne', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Le propriétaire du projet peut lancer une campagne de financement.', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add_rounded), label: const Text('Créer une campagne')),
        ]),
      );
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 90), child: Column(children: [Text(message, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Réessayer'))]));
}

class _CampaignDialog extends StatefulWidget {
  const _CampaignDialog();
  @override
  State<_CampaignDialog> createState() => _CampaignDialogState();
}

class _CampaignDialogState extends State<_CampaignDialog> {
  final goal = TextEditingController();
  final description = TextEditingController();
  String currency = 'USD';
  @override
  void dispose() { goal.dispose(); description.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Nouvelle campagne'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: goal, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Objectif')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(initialValue: currency, items: ['USD', 'HTG', 'EUR', 'CAD'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => currency = v ?? 'USD'), decoration: const InputDecoration(labelText: 'Devise')),
          const SizedBox(height: 12),
          TextField(controller: description, maxLines: 4, decoration: const InputDecoration(labelText: 'Description')),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')), FilledButton(onPressed: () { final value = double.tryParse(goal.text.trim()); if (value == null || value <= 0) return; Navigator.pop(context, {'goal': value, 'currency': currency, 'description': description.text}); }, child: const Text('Créer'))],
      );
}

class _ContributionDialog extends StatefulWidget {
  const _ContributionDialog({required this.currency});
  final String currency;
  @override
  State<_ContributionDialog> createState() => _ContributionDialogState();
}

class _ContributionDialogState extends State<_ContributionDialog> {
  final amount = TextEditingController();
  @override
  void dispose() { amount.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Contribuer en ${widget.currency}'),
        content: TextField(controller: amount, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Montant')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')), FilledButton(onPressed: () { final value = double.tryParse(amount.text.trim()); if (value == null || value <= 0) return; Navigator.pop(context, value); }, child: const Text('Continuer'))],
      );
}
