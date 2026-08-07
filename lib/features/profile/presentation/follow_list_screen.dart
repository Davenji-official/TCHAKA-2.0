import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/follow_service.dart';

enum FollowListMode { followers, following }

class FollowListScreen extends StatefulWidget {
  const FollowListScreen({
    super.key,
    required this.profileId,
    required this.mode,
  });

  final String profileId;
  final FollowListMode mode;

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  final List<Map<String, dynamic>> _entries = [];

  bool _loading = true;
  String? _error;

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
      final entries = widget.mode == FollowListMode.followers
          ? await FollowService.getFollowers(widget.profileId)
          : await FollowService.getFollowing(widget.profileId);

      if (!mounted) return;

      setState(() {
        _entries
          ..clear()
          ..addAll(entries);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger cette liste.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == FollowListMode.followers
        ? 'Abonnés'
        : 'Abonnements';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.cloud_off_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
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

    if (_entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(
            widget.mode == FollowListMode.followers
                ? Icons.people_outline
                : Icons.person_search_outlined,
            size: 52,
          ),
          const SizedBox(height: 16),
          Text(
            widget.mode == FollowListMode.followers
                ? 'Aucun abonné pour l’instant.'
                : 'Ne suit encore personne.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final profile =
            _entries[index]['profile'] as Map<String, dynamic>;

        final avatarUrl = profile['avatar_url'] as String?;
        final fullName = profile['full_name'] as String?;
        final username = profile['username'] as String?;

        final displayName = fullName?.trim().isNotEmpty == true
            ? fullName!
            : (username ?? 'Utilisateur TCHAKA');

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: avatarUrl?.trim().isNotEmpty == true
                ? NetworkImage(avatarUrl!)
                : null,
            child: avatarUrl?.trim().isNotEmpty != true
                ? const Icon(Icons.person_outline)
                : null,
          ),
          title: Text(displayName),
          subtitle: username?.trim().isNotEmpty == true
              ? Text('@$username')
              : null,
          onTap: () => context.push('/profile/${profile['id']}'),
        );
      },
    );
  }
}
