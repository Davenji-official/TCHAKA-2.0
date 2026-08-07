import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/messaging_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _profiles = [];
  bool _loading = true;
  bool _searching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final conversations = await MessagingService.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger tes conversations.';
      });
    }
  }

  Future<void> _searchProfiles(String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _profiles = []);
      return;
    }

    setState(() => _searching = true);
    try {
      final profiles = await MessagingService.searchProfiles(query);
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profiles = [];
        _searching = false;
      });
    }
  }

  Future<void> _startConversation(Map<String, dynamic> profile) async {
    final profileId = profile['id']?.toString() ?? '';
    if (profileId.isEmpty) return;

    try {
      final conversationId = await MessagingService.createDirectConversation(profileId);
      if (!mounted) return;
      _searchController.clear();
      setState(() => _profiles = []);
      await context.push('/messages/$conversationId');
      await _loadConversations();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de démarrer la conversation : $error')),
      );
    }
  }

  String _displayName(Map<String, dynamic>? profile) {
    if (profile == null) return 'Conversation';
    final fullName = profile['full_name']?.toString().trim();
    final username = profile['username']?.toString().trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    if (username != null && username.isNotEmpty) return '@$username';
    return 'Utilisateur TCHAKA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadConversations,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              TextField(
                controller: _searchController,
                onChanged: _searchProfiles,
                decoration: InputDecoration(
                  hintText: 'Rechercher quelqu’un...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              if (_profiles.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionTitle('Nouveau message'),
                ..._profiles.map(
                  (profile) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _Avatar(url: profile['avatar_url']?.toString()),
                    title: Text(_displayName(profile)),
                    subtitle: profile['username'] == null
                        ? null
                        : Text('@${profile['username']}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _startConversation(profile),
                  ),
                ),
                const Divider(height: 24),
              ],
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _ErrorState(message: _error!, onRetry: _loadConversations)
              else if (_conversations.isEmpty)
                const _EmptyState()
              else ...[
                const _SectionTitle('Tes conversations'),
                const SizedBox(height: 8),
                ..._conversations.map((conversation) {
                  final profile = conversation['other_profile'] as Map<String, dynamic>?;
                  final conversationId = conversation['id']?.toString() ?? '';
                  final name = conversation['type'] == 'group'
                      ? (conversation['title']?.toString() ?? 'Groupe')
                      : _displayName(profile);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: _Avatar(url: profile?['avatar_url']?.toString()),
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        conversation['is_muted'] == true ? 'Notifications désactivées' : 'Ouvrir la conversation',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 17),
                      onTap: conversationId.isEmpty
                          ? null
                          : () async {
                              await context.push('/messages/$conversationId');
                              await _loadConversations();
                            },
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim();
    if (value == null || value.isEmpty) {
      return CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
        child: Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.primary),
      );
    }
    return CircleAvatar(backgroundImage: NetworkImage(value));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Icon(Icons.forum_outlined, size: 58, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Aucune conversation', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Recherche un créateur pour commencer à discuter.', textAlign: TextAlign.center),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Réessayer')),
          ],
        ),
      );
}
