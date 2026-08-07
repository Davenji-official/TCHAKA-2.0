import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../projects/data/project_service.dart';
import '../data/collaboration_service.dart';

class CollaborationScreen extends StatefulWidget {
  const CollaborationScreen({
    super.key,
    required this.projectId,
  });

  final String projectId;

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen> {
  static const _roles = <String>[
    'admin',
    'developer',
    'designer',
    'marketing',
    'mentor',
    'contributor',
  ];

  List<Map<String, dynamic>> _members = [];
  Map<String, dynamic>? _project;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  bool get _isOwner {
    final creatorId = _project?['creator_id']?.toString();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return creatorId != null && creatorId == userId;
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
      final results = await Future.wait<dynamic>([
        ProjectService.getProject(widget.projectId),
        CollaborationService.getMembers(widget.projectId),
      ]);

      if (!mounted) return;

      setState(() {
        _project = results[0] as Map<String, dynamic>;
        _members = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger l’équipe du projet.';
      });
    }
  }

  Future<void> _changeRole(Map<String, dynamic> member) async {
    if (!_isOwner || _actionLoading) return;

    final profileId = member['profile_id']?.toString();
    final currentRole = member['role']?.toString() ?? 'contributor';
    if (profileId == null || profileId.isEmpty || currentRole == 'owner') return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text('Changer le rôle', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: currentRole,
                onChanged: (value) {
                  if (value != null) Navigator.pop(context, value);
                },
                child: Column(
                  children: _roles
                      .map(
                        (role) => RadioListTile<String>(
                          value: role,
                          title: Text(_roleLabel(role)),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == currentRole || !mounted) return;

    setState(() => _actionLoading = true);

    try {
      await CollaborationService.updateMemberRole(
        projectId: widget.projectId,
        profileId: profileId,
        role: selected,
      );
      await _load();
      if (mounted) _showMessage('Rôle mis à jour.');
    } catch (_) {
      if (mounted) _showMessage('Impossible de modifier le rôle.');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _removeMember(Map<String, dynamic> member) async {
    if (!_isOwner || _actionLoading) return;

    final profileId = member['profile_id']?.toString();
    final role = member['role']?.toString();
    if (profileId == null || profileId.isEmpty || role == 'owner') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer ce membre ?'),
        content: const Text(
          'Cette personne ne fera plus partie de l’équipe active du projet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _actionLoading = true);

    try {
      await CollaborationService.removeMember(
        projectId: widget.projectId,
        profileId: profileId,
      );
      await _load();
      if (mounted) _showMessage('Membre retiré du projet.');
    } catch (_) {
      if (mounted) _showMessage('Impossible de retirer ce membre.');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrateur';
      case 'developer':
        return 'Développeur';
      case 'designer':
        return 'Designer';
      case 'marketing':
        return 'Marketing';
      case 'mentor':
        return 'Mentor';
      case 'owner':
        return 'Propriétaire';
      default:
        return 'Contributeur';
    }
  }

  String _memberName(Map<String, dynamic> member) {
    final fullName = member['full_name']?.toString().trim();
    final username = member['username']?.toString().trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    if (username != null && username.isNotEmpty) return '@$username';
    return 'Membre TCHAKA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collaboration')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.groups_outlined, size: 58),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        Center(
          child: FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final title = _project?['title']?.toString() ?? 'Projet';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.groups_rounded, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('${_members.length} membre${_members.length > 1 ? 's' : ''} actif${_members.length > 1 ? 's' : ''}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (_members.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, size: 48),
                  const SizedBox(height: 12),
                  Text('L’équipe est encore vide.', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  const Text('Les membres apparaîtront ici après acceptation des candidatures.', textAlign: TextAlign.center),
                ],
              ),
            ),
          )
        else
          ..._members.map(_buildMemberCard),
      ],
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final avatar = member['avatar_url']?.toString();
    final role = member['role']?.toString() ?? 'contributor';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
          child: avatar == null || avatar.isEmpty ? const Icon(Icons.person_outline_rounded) : null,
        ),
        title: Text(_memberName(member), style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Wrap(
            spacing: 6,
            children: [
              Chip(
                label: Text(_roleLabel(role)),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        trailing: _isOwner && role != 'owner'
            ? PopupMenuButton<String>(
                enabled: !_actionLoading,
                onSelected: (value) {
                  if (value == 'role') _changeRole(member);
                  if (value == 'remove') _removeMember(member);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'role', child: Text('Changer le rôle')),
                  PopupMenuItem(value: 'remove', child: Text('Retirer du projet')),
                ],
              )
            : null,
      ),
    );
  }
}
